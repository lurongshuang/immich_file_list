import 'dart:async';
import 'package:flutter/material.dart';

/// 一个通用的防抖容器，专门用于处理桌面/Web端的窗口拉伸稳定性。
/// 
/// 目的：作为容器包裹一个子组件（通常是网格），防止在拖动窗口边缘时频繁触发 [builder] 回调。
/// 特性：
/// 1. **拖拽内容稳定**：在 [LayoutBuilder] 的约束变化时，内部宽度锁定在上次的稳定值。
/// 2. **松开/停止后更新**：只有在调整停止超过 [debounceDuration] 后，才会根据最新宽度重新触发 [builder]。
/// 3. **留白与裁剪支持**：拖大时自动居左留白，缩小时自动居左裁剪，始终保证中心内容不发生“形变”。
class AdaptiveContainer extends StatefulWidget {
  /// 内容构建回调。只有在宽度稳定后才会触发更新。
  final Widget Function(BuildContext context, double stableWidth) builder;

  /// 防抖检测时长（默认 300ms）。
  final Duration debounceDuration;

  const AdaptiveContainer({
    super.key,
    required this.builder,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AdaptiveContainer> createState() => _AdaptiveContainerState();
}

class _AdaptiveContainerState extends State<AdaptiveContainer> {
  double? _stableWidth;
  double? _lastWidth;
  Timer? _debounceTimer;

  void _onResize(double width) {
    if (_lastWidth == width) return;
    _lastWidth = width;
    
    // 初始化首帧稳定宽度
    _stableWidth ??= width;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      
      if (_stableWidth != width) {
        setState(() {
          _stableWidth = width;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _onResize(constraints.maxWidth);
        
        final currentStableWidth = _stableWidth ?? constraints.maxWidth;

        return Container(
          alignment: Alignment.topLeft,
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: currentStableWidth,
                child: widget.builder(context, currentStableWidth),
              ),
            ),
          ),
        );
      },
    );
  }
}
