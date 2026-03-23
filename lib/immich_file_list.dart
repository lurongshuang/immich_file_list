library immich_file_list;
import 'immich_file_list_platform_interface.dart';
export 'photo_grid/photo_grid.dart';
export 'immich_file_list_platform_interface.dart';

class ImmichFileList {
  Future<String?> getPlatformVersion() {
    return ImmichFileListPlatform.instance.getPlatformVersion();
  }
}
