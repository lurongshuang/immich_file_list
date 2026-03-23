import 'package:flutter/material.dart';

// Pages
import 'pages/basic_scrubber_page.dart';
import 'pages/large_snap_page.dart';
import 'pages/custom_grid_page.dart';
import 'pages/normal_list_page.dart';
import 'pages/list_view_page.dart';
import 'pages/selection_page.dart';
import 'pages/desktop_adaptive_page.dart';
import 'pages/desktop_macos_page.dart';
import 'pages/scrubber_custom_page.dart';

void main() {
  runApp(const PhotoGridExampleApp());
}

class PhotoGridExampleApp extends StatelessWidget {
  const PhotoGridExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '照片时间轴组件 测试案例',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('多维度组件拆解测试')),
      body: ListView(
        children: [
          _buildCategoryHeader('时间轴滑块测试 (Scrubber)'),
          ListTile(
            leading: const Icon(Icons.linear_scale),
            title: const Text('1. 基础平滑滑动 (小数据量)'),
            subtitle: const Text('生成 5 个月跨度测试。支持长按多选。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BasicScrubberExample())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('2. 磁吸锚点跳转 (三万级别数据)'),
            subtitle: const Text('相册跨度 24 个月。超越 12 个月触发磁吸节点。同样支持全域勾选。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LargeSnapExample())),
          ),
          
          _buildCategoryHeader('项视图形态测试 (Layouts)'),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('3. 宫格定制形态 (按日分组)'),
            subtitle: const Text('改变 assetsPerRow 和间距，测试双列展示，支持日期全选。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomGridExample())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_headline),
            title: const Text('4. 普通流水列表 (不分组)'),
            subtitle: const Text('传统的单列列表视图，无任何日期分组，支持顺滑拖拽反选。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NormalListExample())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_list),
            title: const Text('5. 复合列表视图 (SliverAppBar)'),
            subtitle: const Text('利用 topSliver 注入原生 SliverAppBar。顶层头部会随拖动联动。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListViewExample())),
          ),

          _buildCategoryHeader('交互测试 (Interactions)'),
          ListTile(
            leading: const Icon(Icons.select_all),
            title: const Text('6. 纯净的选择交互模式 (拖拽反选)'),
            subtitle: const Text('测试关闭右侧滑块，仅进行极速拖拽、框选、反选操作的手感。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectionExample())),
          ),

          _buildCategoryHeader('桌面端专用测试 (Desktop)'),
          ListTile(
            leading: const Icon(Icons.mouse),
            title: const Text('7. 桌面级 macOS 交互方案 (框选/键鼠/自动滚动)'),
            subtitle: const Text('支持鼠标左键在空白处框选。支持 Shift 连选、Ctrl 增选、方向键焦点导航。媲美系统级体验。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesktopMacOSExample())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('8. Scrubber 自定义样式大赏'),
            subtitle: const Text('演示如何通过 Builder 完全重写滑动条与气泡的视觉风格。包含现代玻璃拟态、iOS 与 Google 风格。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScrubberCustomExample())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.desktop_windows),
            title: const Text('9. 桌面端自适应 (窗口弹性测试)'),
            subtitle: const Text('利用 LayoutBuilder 动态计算列数。支持防抖更新与留白裁剪。'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesktopAdaptiveExample())),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
    );
  }
}
