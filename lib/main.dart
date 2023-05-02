import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ex_tabcontroller/tab_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MyApp',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends ConsumerState<MyHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TabItem>> future = ref.watch(itemListFutureProvider);

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                addButtonTapped();
              },
            ),
            title: const Text('My App'),
            bottom: future.when(
              data: (items) {
                _tabController =
                    TabController(vsync: this, length: items.length);
                _tabController.animateTo(items.length - 1);

                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: items.map((TabItem tab) {
                    return Tab(
                      child: Text(tab.title),
                    );
                  }).toList(),
                );
              },
              error: (error, stack) => null,
              loading: () => null,
            )),
        body: future.when(
          data: (items) {
            return TabBarView(
              controller: _tabController,
              children: items.map((TabItem tab) {
                return TabPage(tab: tab);
              }).toList(),
            );
          },
          error: (error, stack) => Text('$error'),
          loading: () => const CircularProgressIndicator(),
        ));
  }

  addButtonTapped() async {
    final state = ref.watch(itemListProvider);
    final notifier = ref.read(itemListProvider.notifier);
    await notifier.add(title: (state.length + 1).toString());
  }
}

class TabPage extends StatefulWidget {
  const TabPage({super.key, required this.tab});
  final TabItem tab;

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
          widget.tab.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ));
  }
}

class ItemListNotifier extends StateNotifier<List<TabItem>> {
  static const String keyName = 'item';

  ItemListNotifier() : super([]) {
    initialized();
  }

  Future initialized() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getStringList(keyName);
    if (loaded == null) {
      state = [
        const TabItem(
          title: '1',
        )
      ];
    } else {
      state = loaded.map((f) => TabItem.fromJson(json.decode(f))).toList();
    }
  }

  Future<bool> add({required String title}) async {
    final TabItem item = TabItem(
      title: title,
    );
    final items = [...state, item];

    final result = await _saveItemList(items);
    if (result == true) {
      state = items;
    }
    return result;
  }

  Future<void> update(List<TabItem> items) async {
    await _saveItemList(items).then((value) {
      if (value == true) {
        state = items;
      }
    });
  }

  Future<bool> _saveItemList(List<TabItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> itemStrings =
    items.map((f) => json.encode(f.toJson())).toList();

    return Future.value(prefs.setStringList(keyName, itemStrings));
  }
}

final itemListProvider = StateNotifierProvider<ItemListNotifier, List<TabItem>>(
      (ref) => ItemListNotifier(),
);

final itemListFutureProvider = FutureProvider<List<TabItem>>((ref) async {
  await ref.watch(itemListProvider.notifier).initialized();
  return ref.watch(itemListProvider);
});
