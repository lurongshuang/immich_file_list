# Photo Grid (immich_file_list)

一个专为极致体验设计的 Flutter 高性能网格库。支持十万级数据的顺滑滚动、分级别日期吸附、专业级桌面端交互，以及**核心逻辑与 UI 的完全解耦**。

[![pub package](https://img.shields.io/pub/v/immich_file_list.svg)](https://pub.dev/packages/immich_file_list)
[![license](https://img.shields.io/github/license/imagey/immich_file_list.svg)](https://opensource.org/licenses/MIT)

---

## 🌟 核心特性 (Key Features)

- **🚀 极致性能**: 基于分段异步渲染逻辑，轻松应对 100,000+ 照片数据的秒级加载，保持丝滑 60FPS。
- **📑 真正解耦 (Design)**: 核心层 (Core) 100% 纯 Dart，不依赖 Flutter UI。通过 `itemBuilder` 彻底分离数据模型与渲染。
- **🖥️ 专业桌面方案 (Desktop Pro)**:
    - **Finder 级选择**: 支持类似 macOS 访达的鼠标框选（Marquee Selection）。
    - **键盘导航**: 完整的方向键支持、焦点环显示，支持 Shift 范围选择与 Ctrl/Cmd 组合选。
    - **智能自动跟随**: 键盘切换或拖拽至边缘时，视图智能补正滚动位置。
- **📱 手机端连滑多选**: 继承自桌面端的高性能 `PhotoDragRegion` 让手机端也能实现丝滑的“划过即选”体验。
- **🎨 深度定制 Scrubber**: 内置高度可定制的时间轴滑块，支持气泡标签、手柄、刻度线的全 Builders 模式定制。

---

## 🧱 核心组件 API (Core Components)

### 1. PhotoGridView
照片网格的主体容器，负责高性能滚动与分段渲染。

| 属性 | 类型 | 描述 |
| :--- | :--- | :--- |
| `items` | `List<PhotoGridItem>` | **必填**。照片数据源。 |
| `itemBuilder` | `PhotoGridItemBuilder` | **必填**。单项展现：`(context, item, isSelected, isFocused, selectionActive) => Widget`。 |
| `headerBuilder` | `PhotoGridHeaderBuilder?` | 可选。自定义分组头部渲染方式。 |
| `crossAxisCount` | `int` | 每行显示的列数（默认 4）。 |
| `mainAxisSpacing` | `double` | 主轴（垂直）间距（默认 4.0）。 |
| `crossAxisSpacing` | `double` | 横轴（水平）间距（默认 4.0）。 |
| `groupBy` | `GroupPhotoBy` | 分组策略：`year`, `month`, `day`, `none`。 |
| `selectionController` | `PhotoSelectionController?` | 绑定多选状态控制器。 |
| `onTap` | `Function(PhotoGridItem)?` | 点击项的回调。 |
| `topSlivers` | `List<Widget>?` | 在列表顶部插入自定义 Sliver 组件列表。 |

### 2. PhotoGridScrubber
悬浮在右侧的时间轴快速定位工具。

| 属性 | 类型 | 描述 |
| :--- | :--- | :--- |
| `controller` | `ScrollController` | **必填**。需与 PhotoGridView 使用同一个控制器。 |
| `segments` | `List<Segment>` | **必填**。由 PhotoGridView 的 `onSegmentsChanged` 提供。 |
| `timelineHeight` | `double` | **必填**。由外部计算或约束提供。 |
| `labelBuilder` | `ScrubberLabelBuilder?` | 定制弹出气泡。 |
| `thumbBuilder` | `ScrubberThumbBuilder?` | 定制滑块手柄样式。 |
| `segmentBuilder` | `ScrubberSegmentBuilder?` | 定制背景年度/月份切片样式。 |
| `alwaysShow` | `bool` | 是否禁止自动隐藏滑块。 |

### 3. PhotoDragRegion
实现全平台通用的“长按+滑动”连滑多选容器。

| 属性 | 类型 | 描述 |
| :--- | :--- | :--- |
| `child` | `Widget` | **必填**。包裹的内容（通常为 GridView）。 |
| `onStart` | `Function(PhotoGridItemIndex)` | **必填**。当长按项开始滑动时的起始回调。 |
| `onAssetEnter` | `Function(PhotoGridItemIndex)` | **必填**。当手指划入某个项时的连续回调。 |
| `onEnd` | `Function()` | **必填**。当拖动结束时触发。 |
| `onScroll` | `Function(double)` | **必填**。当触及边界需要触发滚动时的像素相对位移。 |

### 4. PhotoDesktopSelectionRegion
专为桌面端（macOS/Windows/Web）打造的鼠标框选与键盘操作容器。

| 属性 | 类型 | 描述 |
| :--- | :--- | :--- |
| `selectionController` | `PhotoSelectionController` | **必填**。多选逻辑状态控制器。 |
| `allItemIds` | `List<String>` | **必填**。全量项 ID 列表，用于范围计算。 |
| `assetsPerRow` | `int` | 每行显示的项数（默认 4），用于键盘上下移动计算。 |
| `scrollController` | `ScrollController?` | 滚动控制器，用于框选时的自动滚动同步。 |
| `itemLayoutMap` | `Map<String, Rect>?` | 每个项相对于内容的几何坐标映射（由 PhotoGridView 实时产出）。 |
| `selectionBoxPainterBuilder` | `SelectionBoxPainterBuilder?` | 自定义桌面端拖拽选框 (Marquee) 的 Painter 构建器。 |

---

## 📖 完整最小案例 (Complete Minimal Example)

这是一个展示如何将上述组件组合在一起的完整示例：

```dart
import 'package:flutter/material.dart';
import 'package:immich_file_list/immich_file_list.dart';

// 实现数据接口
class MyItem implements PhotoGridItem {
  @override final String id;
  @override final DateTime date;
  MyItem(this.id, this.date);
}

class PhotoGalleryPage extends StatefulWidget {
  @override
  _PhotoGalleryPageState createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final List<MyItem> _items = List.generate(1000, (i) => MyItem('$i', DateTime.now().subtract(Duration(days: i))));
  final ScrollController _scrollController = ScrollController();
  final PhotoSelectionController _selectionController = PhotoSelectionController();
  List<Segment> _segments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoDesktopSelectionRegion(
        selectionController: _selectionController,
        allItemIds: _items.map((e) => e.id).toList(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return PhotoGridScrubber(
              controller: _scrollController,
              segments: _segments,
              timelineHeight: constraints.maxHeight,
              child: PhotoGridView(
                items: _items,
                controller: _scrollController,
                selectionController: _selectionController,
                onSegmentsChanged: (s) => setState(() => _segments = s),
                itemBuilder: (context, item, isSelected, isFocused, selectionActive) => Container(
                   color: isSelected ? Colors.blue.withAlpha(50) : Colors.grey[300],
                   child: Stack(
                     children: [
                       Center(child: Text(item.id)),
                       if (isFocused)
                         Container(decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2))),
                     ],
                   ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 🎨 极高度定制 (Scrubber)

如果您想要打造不同的视觉风格（如赛博朋克深色模式），可以轻松使用 Builders 定制：

```dart
PhotoGridScrubber(
  labelBuilder: (context, label, isDragging) => Chip(label: Text(label)),
  thumbBuilder: (context, offset, isDragging) => MyNeonThumb(dragging: isDragging),
  // ... 其他属性
)
```

---

## 许可证
MIT License.
