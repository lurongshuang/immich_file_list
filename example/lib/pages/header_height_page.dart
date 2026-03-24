import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../widgets/example_page_wrapper.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

enum ViewMode { grid, list }

class HeaderHeightExample extends StatefulWidget {
  const HeaderHeightExample({super.key});

  @override
  State<HeaderHeightExample> createState() => _HeaderHeightExampleState();
}

class _HeaderHeightExampleState extends State<HeaderHeightExample> {
  bool _useCustomHeight = false;
  ViewMode _viewMode = ViewMode.grid;

  double customHeaderHeight(HeaderType type) {
    switch (type) {
      case HeaderType.year:
        return 120.0;
      case HeaderType.month:
        return 60.0;
      case HeaderType.day:
        return 45.0;
      case HeaderType.monthAndDay:
        return 80.0;
      case HeaderType.none:
        return 0.0;
    }
  }

  static const Map<HeaderType, double> defaultHeights = {
    HeaderType.year: 96.0,
    HeaderType.month: 80.0,
    HeaderType.day: 72.0,
    HeaderType.monthAndDay: 128.0,
  };

  @override
  Widget build(BuildContext context) {
    final items = DummyDataFactory.generateDummyData(2, 10000, mixedTypes: true);

    return ExamplePageWrapper(
      title: '自定义 Header 高度',
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
                      _useCustomHeight ? Icons.height : Icons.straighten,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _useCustomHeight
                            ? '自定义高度: year=120, month=60, day=45'
                            : '默认高度: year=96, month=80, day=72',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
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
                          _useCustomHeight = !_useCustomHeight;
                        });
                      },
                      icon: Icon(_useCustomHeight ? Icons.restore : Icons.edit),
                      label: Text(_useCustomHeight ? '恢复默认' : '自定义高度'),
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
                    enableGrouping: true,
                    headerExtentCalculator: _useCustomHeight ? customHeaderHeight : null,
                    showScrubber: true,
                    selectionController: controller,
                    onTap: (item) => handleTap(context, item, controller),
                    itemBuilder: buildDummyThumbnail,
                  )
                : PhotoGridGallery.list(
                    items: items,
                    itemHeight: 80.0,
                    groupBy: GroupPhotoBy.month,
                    enableGrouping: true,
                    headerExtentCalculator: _useCustomHeight ? customHeaderHeight : null,
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
