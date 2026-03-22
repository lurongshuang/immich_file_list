# immich_file_list

一个专为高性能相册体验设计的 Flutter 插件库。支持超大数据量（万级）的顺滑滚动、分级别逻辑吸附、多端自适应布局以及极致的 60FPS 渲染优化。

## 核心组件概览

### 1. PhotoGridView
**使用场景**：
相册列表的主体展示组件。适用于需要按时间（日/月）分组、支持极速侧边导航（Scrubber）以及大规模数据渲染的场景。

**主要属性介绍**：
| 属性名 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `items` | `List<PhotoGridItem>` | **必填** | 待渲染的元素集合，需实现 `PhotoGridItem` 接口。 |
| `assetsPerRow` | `int` | `4` | 每行展示的缩略图数量。 |
| `margin` | `double` | `3.0` | 宫格项之间的间距。 |
| `childAspectRatio` | `double` | `1.0` | 项的纵横比。`1.0` 为正方形，较大值适用于列表形态。 |
| `groupBy` | `GroupPhotoBy` | `month` | 分组规则：`day` (按日), `month` (按月), `none` (不分组)。 |
| `selectionController` | `PhotoSelectionController?` | `null` | 选中状态控制器，用于开启多选/拖拽选择功能。 |
| `showDragScroll` | `bool` | `true` | 是否显示右侧的悬浮日期滑块（Scrubber）。 |
| `topSliver` | `Widget?` | `null` | 顶部插入的自定义 Sliver（如 `SliverAppBar`），随列表联动。 |
| `onTap` | `Function(PhotoGridItem)?` | `null` | 点击项的回调。 |

---

### 2. AdaptiveContainer
**使用场景**：
专门用于**桌面端或 Web 端**。当用户拉伸窗口边缘时，该组件作为“稳定容器”，防止内部组件随拉伸频繁重绘。

**主要属性介绍**：
| 属性名 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `builder` | `Widget Function(context, width)` | **必填** | 内容构建回调。仅在宽度稳定后触发，返回最新的稳定宽度供内部计算（如计算列数）。 |
| `debounceDuration` | `Duration` | `300ms` | 防抖时长。停止拖动该时间后才会触发 `builder`。 |

**特性**：拖拽过程中自动处理“留白”与“裁剪”，确保视觉上不会因列数闪烁而感到乱。

---

### 3. PhotoSelectionController
**使用场景**：
多选逻辑的“指挥中心”。用于手动代码控制选中项、监听选中数量变化、开启/关闭选择模式。

**常用方法/属性**：
- `isSelectionActive`: 当前是否处于多选状态。
- `selectedIds`: 当前已选中的 ID 集合。
- `toggleItem(id)`: 切换某个 ID 的选中状态。
- `clearSelection()`: 清空所有选择。
- `setSelectionActive(bool)`: 切换选择模式开关。

---

### 4. PhotoGridItem (Interface)
**使用场景**：
数据模型接口。您的业务数据模型需要实现此接口才能被组件库识别。

**要求实现方法**：
- `id`: 唯一标识符。
- `dateTime`: 用于排序和分组的时间戳。
- `itemBuilder(context, size)`: 定义该项如何被渲染（返回 Widget）。

## 性能优化建议
1. **Scrubber 隔离**：由于组件内部使用了 `ValueNotifier` 监听，滑动 Scrubber 时**不会**触发整个列表的 `build`。
2. **Segment 缓存**：按月/日分组后的片段会自动缓存，确保万级数据量下滚动依然保持 60FPS。
3. **AdaptiveContainer**：在桌面端布局时，请务必使用此容器，可大幅减少 GPU 负担。

## 快速开始
参考 `example/lib/pages/` 目录下的 7 个独立模块化案例，涵盖了从基础滑动到复杂自适应的所有场景。
