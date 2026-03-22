# Desktop Adaptive Layout Implementation

The user needs a desktop-specific example where the number of columns (`assetsPerRow`) is dynamically calculated based on the available width.

## Proposed Changes

### Example App

#### [MODIFY] [main.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/example/lib/main.dart)
- Add `DesktopAdaptiveExample` class.
- Use `LayoutBuilder` to calculate `assetsPerRow` based on a 150-200px target width for each item.
- Add a new entry in `ExampleHomePage` for this desktop test.

## Verification Plan

### Manual Verification
- Run the example app on a desktop-sized window.
- Resize the window and verify that the column count updates smoothly as its width crosses various thresholds.
- Ensure the scrubber and selection still work in adaptive mode.
