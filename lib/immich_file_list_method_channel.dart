import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'immich_file_list_platform_interface.dart';

/// An implementation of [ImmichFileListPlatform] that uses method channels.
class MethodChannelImmichFileList extends ImmichFileListPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('immich_file_list');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
