
import 'immich_file_list_platform_interface.dart';

class ImmichFileList {
  Future<String?> getPlatformVersion() {
    return ImmichFileListPlatform.instance.getPlatformVersion();
  }
}
