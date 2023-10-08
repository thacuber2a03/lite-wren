#include "api.h"
#include "renderer.h"
#include "rencache.h"

static RenColor checkcolor(WrenVM* vm, int idx, int def)
{
  RenColor color;
  if (idx >= wrenGetSlotCount(vm) || wrenGetSlotType(vm, idx) == WREN_TYPE_NULL)
  {
    return (RenColor) { def, def, def, 255 };
  }

  wrenEnsureSlots(vm, idx+1);

  wrenGetListElement(vm, idx, 0, idx+1);
  color.r = (uint8_t)wrenGetSlotDouble(vm, idx+1);
  wrenGetListElement(vm, idx, 1, idx+1);
  color.g = (uint8_t)wrenGetSlotDouble(vm, idx+1);
  wrenGetListElement(vm, idx, 2, idx+1);
  color.b = (uint8_t)wrenGetSlotDouble(vm, idx+1);

  if (wrenGetListCount(vm, idx) >= 4)
  {
    wrenGetListElement(vm, idx, 0, idx+1);
    color.a = (uint8_t)wrenGetSlotDouble(vm, idx+1);
  }
  else color.a = 255;

  return color;
}

static void f_show_debug(WrenVM* vm)
{
  rencache_show_debug(wrenGetSlotBool(vm, 1));
  wrenSetSlotNull(vm, 0);
}

static void f_get_size(WrenVM* vm)
{
  int w = 0, h = 0;
  ren_get_size(&w, &h);

  wrenEnsureSlots(vm, 2);
  wrenSetSlotNewList(vm, 0);
  
  wrenSetSlotDouble(vm, 1, w);
  wrenInsertInList(vm, 0, -1, 1);
  wrenSetSlotDouble(vm, 1, h);
  wrenInsertInList(vm, 0, -1, 1);
}

static void f_begin_frame(WrenVM* vm)
{
  rencache_begin_frame();
  wrenSetSlotNull(vm, 0);
}

static void f_end_frame(WrenVM* vm)
{
  rencache_end_frame();
  wrenSetSlotNull(vm, 0);
}

static void f_set_clip_rect(WrenVM* vm)
{
  RenRect rect;
  rect.x = wrenGetSlotDouble(vm, 1);
  rect.y = wrenGetSlotDouble(vm, 2);
  rect.width = wrenGetSlotDouble(vm, 3);
  rect.height = wrenGetSlotDouble(vm, 4);
  rencache_set_clip_rect(rect);
  wrenSetSlotNull(vm, 0);
}

static void f_draw_rect(WrenVM* vm)
{
  RenRect rect;
  rect.x = wrenGetSlotDouble(vm, 1);
  rect.y = wrenGetSlotDouble(vm, 2);
  rect.width = wrenGetSlotDouble(vm, 3);
  rect.height = wrenGetSlotDouble(vm, 4);
  RenColor color = checkcolor(vm, 5, 255);
  rencache_draw_rect(rect, color);
  wrenSetSlotNull(vm, 0);
}

static void f_draw_text(WrenVM* vm)
{
  RenFont** font = wrenGetSlotForeign(vm, 1);
  const char* text = wrenGetSlotString(vm, 2);
  int x = wrenGetSlotDouble(vm, 3);
  int y = wrenGetSlotDouble(vm, 4);
  RenColor color = checkcolor(vm, 5, 255);
  x = rencache_draw_text(*font, text, x, y, color);
  wrenSetSlotDouble(vm, 0, x);
}

APIRegistry renderer_api[] = {
  { "show_debug(_)",          f_show_debug    },
  { "get_size()",             f_get_size      },
  { "begin_frame()",          f_begin_frame   },
  { "end_frame()",            f_end_frame     },
  { "set_clip_rect(_,_,_,_)", f_set_clip_rect },
  { "draw_rect(_,_,_,_,_)",   f_draw_rect     },
  { "draw_text(_,_,_,_,_)",   f_draw_text     },
  { NULL,                     NULL            }
};

WrenForeignMethodFn renderer_foreign_method(WrenVM* vm, bool isStatic, const char* signature)
{
  for (int i = 0; renderer_api[i].signature != NULL; i++)
  {
    APIRegistry* api = renderer_api + i;
    if (!strcmp(signature, api->signature)) return api->func;
  }
  return NULL;
}
