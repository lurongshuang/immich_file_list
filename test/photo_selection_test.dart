import 'package:flutter_test/flutter_test.dart';
import 'package:immich_file_list/photo_grid/logic/photo_selection_controller.dart';

void main() {
  group('PhotoSelectionController', () {
    late PhotoSelectionController controller;

    setUp(() {
      controller = PhotoSelectionController();
    });

    test('startDragSelection with null anchorId should not select any item', () {
      controller.startDragSelection(null);
      expect(controller.selectedIds, isEmpty);
      expect(controller.isSelectionActive, isTrue);
    });

    test('startDragSelection with empty anchorId should not select any item', () {
      controller.startDragSelection("");
      expect(controller.selectedIds, isEmpty);
      expect(controller.isSelectionActive, isTrue);
    });

    test('startDragSelection with valid anchorId should select it if not selected', () {
      controller.startDragSelection("item1");
      expect(controller.selectedIds, contains("item1"));
    });

    test('startDragSelection with valid anchorId should deselect it if already selected', () {
      controller.selectItem("item1");
      controller.startDragSelection("item1");
      expect(controller.selectedIds, isNot(contains("item1")));
    });

    test('updateDragSelection after starting with null anchor should add items', () {
      controller.startDragSelection(null);
      controller.updateDragSelection({"item1", "item2"});
      expect(controller.selectedIds, equals({"item1", "item2"}));
    });

    test('clicking empty space clears existing selection', () {
      controller.selectItem("item1", index: 5);
      expect(controller.selectedIds, contains("item1"));
      
      // Simulate PhotoDesktopSelectionRegion clicking empty space
      controller.clearSelection();
      
      expect(controller.selectedIds, isEmpty);
    });

    test('setSelectionActive(false) clears existing selection', () {
      controller.setSelectionActive(true);
      controller.selectItem("item1", index: 5);
      controller.setSelectionActive(false);
      
      expect(controller.selectedIds, isEmpty);
    });

    test('toggleItem should be debounced after selectItem', () async {
      controller.selectItem("item1");
      expect(controller.selectedIds, contains("item1"));
      
      // Immediate toggle should be ignored
      controller.toggleItem("item1");
      expect(controller.selectedIds, contains("item1"), reason: "Toggle should be ignored due to debounce");
      
      // Wait for debounce period (50ms)
      await Future.delayed(const Duration(milliseconds: 60));
      controller.toggleItem("item1");
      expect(controller.selectedIds, isEmpty, reason: "Toggle should work after wait");
    });
  });
}
