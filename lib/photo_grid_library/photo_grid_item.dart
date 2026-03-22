import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// 网格时间轴内照片的分组聚合维度配置枚举
enum GroupPhotoBy {
  /// 按天聚合：每一天生成一个新的 Date Bucket 头。
  day,
  /// 按月聚合：每一个自然月生成一个新的 Date Bucket 头。
  month,
  /// 不做任何聚合：传统的全平铺流水列表。
  none,
}

/// 照片时间轴网格所需展示的基础数据模型契约。
///
/// 宿主应用的数据模型必须实现该接口才能被注入到 [PhotoGridView] 中。
/// 它要求提供唯一标识符、时间戳（用于分组）以及具体的缩略图渲染实现。
abstract class PhotoGridItem {
  /// 资源的唯一标识符 (例如：本地数据库 ID、远程 URL Hash 等)
  String get id;

  /// 该资源的创建时间或相关时间戳，用于时间轴的聚合分组 (如按月、日分组)
  DateTime get date;

  /// 构建用于在网格中展示的照片缩略图。
  /// 请确保返回一个受固定大小约束的 Widget（例如使用 [Image.file] / [Image.network] 并配合 [BoxFit.cover]）。
  Widget buildThumbnail(BuildContext context);
}


