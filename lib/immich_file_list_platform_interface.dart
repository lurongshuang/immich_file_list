import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'immich_file_list_method_channel.dart';

abstract class ImmichFileListPlatform extends PlatformInterface {
  /// Constructs a ImmichFileListPlatform.
  ImmichFileListPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImmichFileListPlatform _instance = MethodChannelImmichFileList();

  /// The default instance of [ImmichFileListPlatform] to use.
  ///
  /// Defaults to [MethodChannelImmichFileList].
  static ImmichFileListPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImmichFileListPlatform] when
  /// they register themselves.
  static set instance(ImmichFileListPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
