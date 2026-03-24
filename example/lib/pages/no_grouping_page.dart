import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../widgets/example_page_wrapper.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

enum ViewMode { grid, list }

class NoGroupingExample extends StatefulWidget {
  const NoGroupingExample({super.key});

  @override
  State<NoGroupingExample> createState() => _NoGroupingExampleState();
}

class _NoGroupingExampleState extends State<NoGroupingExample> {
  bool _enableGrouping = true;
  ViewMode _viewMode = ViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final items = DummyDataFactory.generateDummyData(2, 10000, mixedTypes: true);

    return ExamplePageWrapper(
      title: '分组开关示例',
      items: items,
      builder: (context, items, controller) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _enableGrouping ? Icons.view_week : Icons.view_module,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _enableGrouping ? '分组模式' : '不分组模式',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<ViewMode>(
                      segments: const [
                        ButtonSegment(value: ViewMode.grid, icon: Icon(Icons.grid_view), label: Text('宫格')),
                        ButtonSegment(value: ViewMode.list, icon: Icon(Icons.view_list), label: Text('列表')),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _viewMode = selected.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _enableGrouping = !_enableGrouping;
                        });
                      },
                      icon: Icon(_enableGrouping ? Icons.toggle_on : Icons.toggle_off),
                      label: Text(_enableGrouping ? '关闭分组' : '开启分组'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _viewMode == ViewMode.grid
                ? PhotoGridGallery.grid(
                    items: items,
                    crossAxisCount: 4,
                    mainAxisSpacing: 3.0,
                    crossAxisSpacing: 3.0,
                    groupBy: GroupPhotoBy.month,
                    enableGrouping: _enableGrouping,
                    showScrubber: true,
                    selectionController: controller,
                    onTap: (item) => handleTap(context, item, controller),
                    itemBuilder: buildDummyThumbnail,
                  )
                : PhotoGridGallery.list(
                    items: items,
                    itemHeight: 80.0,
                    groupBy: GroupPhotoBy.month,
                    enableGrouping: _enableGrouping,
                    showScrubber: true,
                    selectionController: controller,
                    onTap: (item) => handleTap(context, item, controller),
                    itemBuilder: buildDummyThumbnail,
                  ),
          ),
        ],
      ),
    );
  }
}
