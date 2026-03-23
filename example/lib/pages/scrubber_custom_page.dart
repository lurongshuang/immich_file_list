import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/example_page_wrapper.dart';
import '../widgets/photo_grid_gallery.dart';

enum ScrubberPreset {
  standard,
  modernGlass,
  iosClassic,
  googlePhotos,
  cyberpunk,
  yearlySnapshot,
}

class ScrubberCustomExample extends StatefulWidget {
  const ScrubberCustomExample({super.key});

  @override
  State<ScrubberCustomExample> createState() => _ScrubberCustomExampleState();
}

class _ScrubberCustomExampleState extends State<ScrubberCustomExample> {
  final List<DummyPhotoItem> _items = DummyDataFactory.generateDummyData(120, 5000); // 增加数据量以展示年度效果
  ScrubberPreset _currentPreset = ScrubberPreset.modernGlass;
  GroupPhotoBy _groupBy = GroupPhotoBy.month;
  bool _alwaysShow = false;

  @override
  void initState() {
    super.initState();
    _updateConfigForPreset(_currentPreset);
  }

  void _updateConfigForPreset(ScrubberPreset preset) {
    setState(() {
      _currentPreset = preset;
      // 为特定预设提供默认配置
      if (preset == ScrubberPreset.yearlySnapshot) {
        _groupBy = GroupPhotoBy.year;
        _alwaysShow = true;
      } else if (preset == ScrubberPreset.modernGlass) {
        _alwaysShow = true; // 玻璃拟态默认常驻增加质感
      } else {
        _groupBy = GroupPhotoBy.month;
        _alwaysShow = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: 'Scrubber 自定义样式大赏',
      items: _items,
      initialSelectionActive: false,
      builder: (context, items, controller) {
        return Column(
          children: [
            // 风格与功能切换器
            _buildControls(),
            
            Expanded(
              child: PhotoGridGallery(
                key: ValueKey("$_currentPreset-$_groupBy-$_alwaysShow"), // 切换时重建
                items: items,
                assetsPerRow: _groupBy == GroupPhotoBy.year ? 8 : 4, // 年度视图更密集
                margin: 2.0,
                childAspectRatio: 1.0,
                groupBy: _groupBy,
                showScrubber: true,
                alwaysShowScrubber: _alwaysShow,
                selectionController: controller,
                onTap: (item) => handleTap(context, item, controller),
                
                // 配置 Builder 与 参数
                scrubberThumbBuilder: _getThumbBuilder(),
                scrubberLabelBuilder: _getLabelBuilder(),
                scrubberSegmentBuilder: _getSegmentBuilder(),
                
                // 透传参数
                scrubberFadeInDuration: _getFadeInDuration(),
                scrubberAutoHideDuration: _getAutoHideDuration(),
                scrubberThumbHeight: _getThumbHeight(),
                scrubberSegmentEndOffset: _getSegmentEndOffset(),
                scrubberLabelEndOffset: _getLabelEndOffset(),
                scrubberThumbEndOffset: _getThumbEndOffset(),
                scrubberMinSegmentSpacing: _getMinSegmentSpacing(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(50))),
      ),
      child: Column(
        children: [
          // 预设切换
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ScrubberPreset.values.map((preset) {
                final isSelected = _currentPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getPresetName(preset)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) _updateConfigForPreset(preset);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // 功能细调
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                const Text("聚合维度:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildEnumToggle<GroupPhotoBy>(
                  value: _groupBy,
                  values: GroupPhotoBy.values,
                  onChanged: (val) => setState(() => _groupBy = val),
                  labelBuilder: (v) => v.name.toUpperCase(),
                ),
                const Spacer(),
                const Text("常驻展示:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Switch(
                  value: _alwaysShow,
                  onChanged: (val) => setState(() => _alwaysShow = val),
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnumToggle<T>({
    required T value,
    required List<T> values,
    required ValueChanged<T> onChanged,
    required String Function(T) labelBuilder,
  }) {
    return ToggleButtons(
      isSelected: values.map((v) => v == value).toList(),
      onPressed: (index) => onChanged(values[index]),
      constraints: const BoxConstraints(minHeight: 28, minWidth: 50),
      borderRadius: BorderRadius.circular(8),
      children: values.map((v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(labelBuilder(v), style: const TextStyle(fontSize: 10)),
      )).toList(),
    );
  }

  String _getPresetName(ScrubberPreset preset) {
    switch (preset) {
      case ScrubberPreset.standard: return '标准系统式';
      case ScrubberPreset.modernGlass: return '现代玻璃拟态';
      case ScrubberPreset.iosClassic: return 'iOS 极简';
      case ScrubberPreset.googlePhotos: return 'Google 相册风';
      case ScrubberPreset.cyberpunk: return '赛博霓虹 (高性能)';
      case ScrubberPreset.yearlySnapshot: return '年度全景 (极紧凑)';
    }
  }

  // --- 核心参数配置 ---

  Duration _getFadeInDuration() {
    switch (_currentPreset) {
      case ScrubberPreset.cyberpunk: return const Duration(milliseconds: 50); // 极速响应
      case ScrubberPreset.googlePhotos: return const Duration(milliseconds: 300); // 优雅缓冲
      default: return const Duration(milliseconds: 150);
    }
  }

  Duration _getAutoHideDuration() {
    switch (_currentPreset) {
      case ScrubberPreset.googlePhotos: return const Duration(seconds: 5); // 停留更久
      case ScrubberPreset.iosClassic: return const Duration(milliseconds: 800); // 快速消失
      default: return const Duration(seconds: 2);
    }
  }

  double _getThumbHeight() {
    switch (_currentPreset) {
      case ScrubberPreset.iosClassic: return 80;
      case ScrubberPreset.googlePhotos: return 40;
      case ScrubberPreset.cyberpunk: return 120; // 宽大的交互区
      default: return 48;
    }
  }

  double _getSegmentEndOffset() {
    switch (_currentPreset) {
      case ScrubberPreset.iosClassic: return 40; // 靠右极近
      case ScrubberPreset.googlePhotos: return 120; // 留出空间给大圆点
      case ScrubberPreset.cyberpunk: return 150; // 悬浮感
      default: return 100;
    }
  }

  double _getLabelEndOffset() {
    switch (_currentPreset) {
      case ScrubberPreset.cyberpunk: return 40; // 贴近滑块
      default: return 16;
    }
  }

  double _getThumbEndOffset() {
    switch (_currentPreset) {
      case ScrubberPreset.cyberpunk: return 12; // 悬浮在屏幕内部
      default: return 0;
    }
  }

  double _getMinSegmentSpacing() {
    switch (_currentPreset) {
      case ScrubberPreset.iosClassic: return 15; // 紧凑型刻度
      default: return 32;
    }
  }

  ScrubberThumbBuilder? _getThumbBuilder() {
    switch (_currentPreset) {
      case ScrubberPreset.standard:
        return null; // 使用默认
      case ScrubberPreset.modernGlass:
        return (context, offset, isDragging) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isDragging ? 12 : 8,
              height: 60,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isDragging ? Theme.of(context).primaryColor : Colors.grey.withAlpha(150),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isDragging ? [BoxShadow(color: Theme.of(context).primaryColor.withAlpha(100), blurRadius: 10)] : [],
              ),
            );
      case ScrubberPreset.iosClassic:
        return (context, offset, isDragging) => Container(
              width: 4,
              height: 100,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(200),
                borderRadius: BorderRadius.circular(2),
              ),
            );
      case ScrubberPreset.googlePhotos:
        return (context, offset, isDragging) => Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4)],
              ),
              child: const Icon(Icons.unfold_more, color: Colors.white, size: 16),
            );
      case ScrubberPreset.cyberpunk:
        return (context, offset, isDragging) => Container(
              width: 4,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyan, Colors.pinkAccent, Colors.cyan],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withAlpha(200),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
      case ScrubberPreset.yearlySnapshot:
        return (context, offset, isDragging) => Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(2),
              ),
            );
    }
  }

  ScrubberLabelBuilder? _getLabelBuilder() {
    switch (_currentPreset) {
      case ScrubberPreset.standard:
        return null;
      case ScrubberPreset.modernGlass:
        return (context, label, isDragging) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(230),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
      case ScrubberPreset.iosClassic:
        return (context, label, isDragging) => Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            );
      case ScrubberPreset.googlePhotos:
        return (context, label, isDragging) => Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 12, spreadRadius: 2)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ],
              ),
            );
      case ScrubberPreset.cyberpunk:
        return (context, label, isDragging) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.cyan, width: 2),
                boxShadow: const [BoxShadow(color: Colors.cyan, blurRadius: 10)],
              ),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            );
      case ScrubberPreset.yearlySnapshot:
        return (context, label, isDragging) => Chip(
              backgroundColor: Colors.black,
              label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              padding: const EdgeInsets.all(8),
            );
    }
  }

  ScrubberSegmentBuilder? _getSegmentBuilder() {
    switch (_currentPreset) {
      case ScrubberPreset.standard:
        return null;
      case ScrubberPreset.modernGlass:
        return (context, label, date) => Container(
              margin: const EdgeInsets.only(right: 28),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withAlpha(180),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            );
      case ScrubberPreset.iosClassic:
        return (context, label, date) => Container(
              margin: const EdgeInsets.only(right: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 1, color: Colors.grey.withAlpha(100)),
                  const SizedBox(width: 8),
                  Text(
                    '${date.month}',
                    style: TextStyle(color: Colors.grey.withAlpha(150), fontSize: 10),
                  ),
                ],
              ),
            );
      case ScrubberPreset.googlePhotos:
        return (context, label, date) => Container(
              margin: const EdgeInsets.only(right: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            );
      case ScrubberPreset.cyberpunk:
        return (context, label, date) => Container(
              margin: const EdgeInsets.only(right: 60),
              child: Row(
                children: [
                  Container(width: 40, height: 2, color: Colors.pinkAccent.withAlpha(150)),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            );
      case ScrubberPreset.yearlySnapshot:
        return (context, label, date) => Container(
              margin: const EdgeInsets.only(right: 20),
              child: Text(
                '${date.year}',
                style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            );
    }
  }
}
