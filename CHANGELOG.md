## 1.0.0

* **Initial Stable Release**
* **Strict Decoupling**: Completely separated data models from UI rendering logic using the `ItemBuilder` pattern.
* **100% Core Purity**: The core layout engine is now pure Dart, making it highly portable and testable.
* **High-Performance Grid**: Sliver-based segmented rendering for handling 100,000+ items at 60FPS.
* **Desktop PRO Interaction**: 
    - macOS Finder-style mouse selection (marquee).
    - Full keyboard navigation with focus ring and auto-scroll.
    - Shift/Ctrl multi-selection support.
* **Customizable Scrubber**: Advanced side-slider with `labelBuilder`, `thumbBuilder`, and `segmentBuilder`.
* **Adaptive Layout**: Debounced container support for smooth window resizing on Desktop/Web.
* **Professional Documentation**: Comprehensive Chinese and English documentation.
