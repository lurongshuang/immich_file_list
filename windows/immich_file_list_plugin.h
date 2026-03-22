#ifndef FLUTTER_PLUGIN_IMMICH_FILE_LIST_PLUGIN_H_
#define FLUTTER_PLUGIN_IMMICH_FILE_LIST_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace immich_file_list {

class ImmichFileListPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ImmichFileListPlugin();

  virtual ~ImmichFileListPlugin();

  // Disallow copy and assign.
  ImmichFileListPlugin(const ImmichFileListPlugin&) = delete;
  ImmichFileListPlugin& operator=(const ImmichFileListPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace immich_file_list

#endif  // FLUTTER_PLUGIN_IMMICH_FILE_LIST_PLUGIN_H_
