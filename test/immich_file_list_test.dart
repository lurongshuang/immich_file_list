import 'package:flutter_test/flutter_test.dart';
import 'package:immich_file_list/immich_file_list.dart';
import 'package:immich_file_list/immich_file_list_platform_interface.dart';
import 'package:immich_file_list/immich_file_list_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImmichFileListPlatform
    with MockPlatformInterfaceMixin
    implements ImmichFileListPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ImmichFileListPlatform initialPlatform = ImmichFileListPlatform.instance;

  test('$MethodChannelImmichFileList is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImmichFileList>());
  });

  test('getPlatformVersion', () async {
    ImmichFileList immichFileListPlugin = ImmichFileList();
    MockImmichFileListPlatform fakePlatform = MockImmichFileListPlatform();
    ImmichFileListPlatform.instance = fakePlatform;

    expect(await immichFileListPlugin.getPlatformVersion(), '42');
  });
}
