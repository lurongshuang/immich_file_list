# Photo Grid Extraction Task

- [x] Create `implementation_plan.md` for user review
- [x] Check/add `scrollable_positioned_list` to `pubspec.yaml`
- [x] Create data structure `photo_grid_data_structure.dart` for flattening `GridItem`
- [x] Create `draggable_scrollbar.dart` for the fast scroll thumb
- [x] Create `photo_drag_region.dart` for the swipe selection
- [x] Create `photo_grid_view.dart` for the main grid UI
- [x] Expose index file `photo_grid.dart`
- [x] Create a runnable example in `example/lib/main.dart`

# Linear Scrubber Extraction (Fixing jumpy scrolling)

- [x] Create `segment.model.dart` equivalent in library (`photo_grid_segment.dart`)
- [x] Implement `SegmentBuilder` logic for offset pre-calculation
- [x] Copy `_SliverSegmentedList` and `_RenderSliverTimelineBoxAdaptor` into our library
- [x] Rewire `PhotoGridView` to use `CustomScrollView` + exact slivers instead of `ScrollablePositionedList`
- [x] Revert `PhotoGridScrubber` to rely strictly on `ScrollController.offset` like the original code
- [x] Fix touch thumb jump offset calculations
- [x] Implement magnetic snapping to nodes
- [x] Add haptic feedback string dragging
- [x] Replace scrubber logic with 1:1 identical Immich copy
- [x] Fix compilation errors originating from duplicate import removals
- [x] Add childAspectRatio support to support List Views alongside Grid Views
- [x] Increase max test case to 30,000 items and append List vs Grid view explicit views
- [x] Fix Scrubber slide out of bounds crash during iOS native edge over-scrolling
- [x] Fix Scrubber initial thumb jump down by correcting `_dragStartOffsetDiff` tracking
- [x] Integrate `topSliver` property to allow combining `PhotoGridView` alongside external `SliverAppBar` headers seamlessly
- [x] Refactor Drag Engine to support Drag-to-Deselect based on initial anchor state
- [x] Segregate tests into 6 distinct categorized testing widgets including Normal List View and SliverAppBar example
- [x] Architecturally Decouple multi-select state using the `PhotoSelectionController` Builder pattern, entirely removing business logic from `PhotoGridView` internals.
- [x] Deploy universally injected `ExamplePageWrapper` granting global Selection/Drag-tracking coverage across ALL 6 test cases.
- [x] Write thorough Chinese Inline `DartDoc` (///) API comments to all primary controllers, UI structs and rendering algorithms across the `photo_grid_library`.
- [x] Optimize Drag Engine Frame Rate: Redesign timer offsets (50ms -> 16ms) and swap conflicting `animateTo()` loops with raw `jumpTo()` sub-pixels, ensuring ultra-smooth high-frequency polling selection. 
- [x] Massive Performance Test Scenario: Upgraded test data loads to 48 months (>10,000 photos).
- [x] **V-Sync Smoothness Upgrade**: Fully migrated to hardware-synced `Ticker` with variable-speed edge scrolling (500~2500 px/s) based on finger depth. Zero-jitter guarantee.
- [x] **Magnetic Snap Stress Build**: Expanded Scrubber test case to a full 48-month range with 30,000 items.
- [x] **Zero-Rebuild Rendering Engine**: Optimized Scrubber with `ValueNotifier` and GridView with segment caching to eliminate "downward flicker" in large-scale datasets.
- [x] **Debounced Adaptive Desktop Layout**: Recalculate column count only after window resize stabilization (300ms) to simulate "release-to-apply" behavior.
- [x] **Modular Example Architecture**: Refactored the monolithic `main.dart` into a clean structure with separate files for each example case.
- [x] **AdaptiveContainer Component**: Encapsulated debounced layout stability logic into a generic wrapper component (using the builder pattern) to avoid redundant builds during resizing.
- [x] **Documentation Cleanup**: Enriched `README.md` with detailed widget usage scenarios and property descriptions.
- [x] **Source Control Sync**: Initialized standalone Git repository and pushed 60FPS optimized library to GitHub `master` branch.
