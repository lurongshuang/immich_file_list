# Encapsulating Desktop Adaptive Grid Implementation Plan

Move the "debounced, white-space/clipping" adaptive logic from the example app into a reusable component in the core library.

## Proposed Changes

### [NEW] [photo_grid_adaptive.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/lib/photo_grid_library/photo_grid_adaptive.dart)

Create a `StatefulWidget` named `AdaptivePhotoGridView` that:
- Takes `targetItemWidth` (double, default 180.0).
- Takes all standard `PhotoGridView` parameters except `assetsPerRow`.
- Handles `LayoutBuilder` internal state.
- Implements the 300ms debounce.
- Implements the `SingleChildScrollView` (horizontal) + `SizedBox` + `Container` layout to support "留白" (growing) and "裁剪" (shrinking).

### [MODIFY] [photo_grid.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/lib/photo_grid_library/photo_grid.dart)
- Export the new `photo_grid_adaptive.dart`.

### [MODIFY] [desktop_adaptive_page.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/example/lib/pages/desktop_adaptive_page.dart)
- Simplify the example to use the new `AdaptivePhotoGridView`.

## Verification Plan

### Automated Tests
- Run `dart analyze lib/photo_grid_library` to ensure the new component is correctly typed and exported.

### Manual Verification
- Run the 7th example case (now using the encapsulated component) and verify it still behaves correctly (clipping/white space/debounce).
