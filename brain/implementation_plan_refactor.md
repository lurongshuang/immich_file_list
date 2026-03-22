# Example App Refactoring Implementation Plan

The user requested each example case to be in its own file to improve code organization and readability.

## Proposed Changes

### Example App Structure

New directory structure:
```
example/lib/
├── main.dart                      # App Entry & Navigation
├── dummy_data.dart                # Data generation (Existing)
├── widgets/
│   └── example_page_wrapper.dart  # Shared logic & wrapper
└── pages/
    ├── basic_scrubber_page.dart   # Case 1
    ├── large_snap_page.dart       # Case 2
    ├── custom_grid_page.dart      # Case 3
    ├── normal_list_page.dart      # Case 4
    ├── list_view_page.dart        # Case 5
    ├── selection_page.dart        # Case 6
    └── desktop_adaptive_page.dart # Case 7
```

### Components to Extract

#### [NEW] [example_page_wrapper.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/example/lib/widgets/example_page_wrapper.dart)
- Move `ExamplePageWrapper` and `_handleTap` here.

#### [NEW] Case Pages
- Move each case class (e.g., `BasicScrubberExample`) to its respective file in `pages/`.

#### [MODIFY] [main.dart](file:///Users/lurongshuang/Documents/AndroidStudioProjects/immich_file_list/example/lib/main.dart)
- Clean up imports and remove extracted classes.
- Keep only `PhotoGridExampleApp` and `ExampleHomePage`.

## Verification Plan

### Automated Tests
- Run `dart analyze example/lib` to verify all imports and structures are correct.

### Manual Verification
- Run the example app and navigate through all 7 cases to ensure they still function perfectly.
