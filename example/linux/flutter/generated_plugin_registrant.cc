//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <immich_file_list/immich_file_list_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) immich_file_list_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ImmichFileListPlugin");
  immich_file_list_plugin_register_with_registrar(immich_file_list_registrar);
}
