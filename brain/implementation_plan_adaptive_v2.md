# Generic Adaptive Container Implementation Plan

Refactor the adaptive logic into a generic `AdaptiveContainer` that uses a `builder` pattern to avoid redundant builds during resizing.

## Proposed Changes

### [MODIFY] [photo_grid_adaptive.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/lib/photo_grid_library/photo_grid_adaptive.dart)

Replace `AdaptivePhotoGridView` with `AdaptiveContainer`:
- `debounceDuration` (Duration, default 300ms).
- `builder` (Widget Function(BuildContext context, double width)).
- Uses the same internal `_appliedWidth` and `Timer` logic.
- During resizing, it renders the child at the previous `_appliedWidth` using the horizontal clipper.

### [MODIFY] [desktop_adaptive_page.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/example/lib/pages/desktop_adaptive_page.dart)
- Update to use `AdaptiveContainer` and move the `assetsPerRow` calculation back to the example page (inside the `builder`).

## Verification Plan

### Automated Tests
- Run `dart analyze lib/photo_grid_library` to ensure the new generic API is correct.

### Manual Verification
- Verify that resizing in Case 7 only triggers the inner `PhotoGridView` rebuild after the drag is stopped.
