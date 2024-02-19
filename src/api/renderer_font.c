#include "api.h"
#include "renderer.h"
#include "rencache.h"

static void font_allocate(WrenVM* vm)
{
  const char* filename = checkstring(vm, 1);
  float size = checkdouble(vm, 2);
  wrenSetSlotNewForeign(vm, 0, 0, sizeof(RenFont*));
  RenFont** self = wrenGetSlotForeign(vm, 0);
  *self = ren_load_font(filename, size);
  if (!*self) throwerror(vm, "failed to load font");
}

static void font_finalize(void* data)
{
  RenFont** self = (RenFont**) data;
  if (*self) rencache_free_font(*self);
  *self = NULL;
}

static void f_set_tab_width(WrenVM* vm) {
  RenFont **self = (RenFont**)checkforeign(vm, 0);
  int n = checkdouble(vm, 1);
  ren_set_font_tab_width(*self, n);
  wrenSetSlotNull(vm, 0);
}

static void f_get_width(WrenVM* vm) {
  RenFont **self = checkforeign(vm, 0);
  const char *text = checkstring(vm, 1);
  wrenSetSlotDouble(vm, 0, ren_get_font_width(*self, text));
}

static void f_get_height(WrenVM* vm) {
  RenFont **self = checkforeign(vm, 0);
  wrenSetSlotDouble(vm, 0, ren_get_font_height(*self));
}

WrenForeignClassMethods font_foreign_class(WrenVM* vm)
{
  return (WrenForeignClassMethods) {
    .allocate = font_allocate,
    .finalize = font_finalize,
  };
}

APIRegistry font_api[] = {
  { "tab_width=(_)",    f_set_tab_width },
  { "width_(_)",        f_get_width     },
  { "height",           f_get_height    },
  { NULL,               NULL            },
};

WrenForeignMethodFn font_foreign_method(WrenVM* vm, const char* signature)
{
  for (int i = 0; font_api[i].signature != NULL; i++)
  {
    APIRegistry* api = font_api + i;
    if (!strncmp(signature, api->signature, strlen(signature)))
      return api->func;
  }
  return NULL;
}
