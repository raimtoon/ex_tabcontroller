
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tab_item.freezed.dart';
part 'tab_item.g.dart';

@freezed
class TabItem with _$TabItem {
  const factory TabItem({
    required String title,
  }) = _TabItem;

  factory TabItem.fromJson(Map<String, dynamic> json) =>
      _$TabItemFromJson(json);
}

