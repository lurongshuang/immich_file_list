#include "include/immich_file_list/immich_file_list_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "immich_file_list_plugin.h"

void ImmichFileListPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  immich_file_list::ImmichFileListPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
