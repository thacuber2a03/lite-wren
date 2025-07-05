#include "renderer.h"
#include "api.h"
#include "lib/wren/wren.h"
#include "rencache.h"

static void f_show_debug(WrenVM *vm)
{
    bool res = (wrenGetSlotType(vm, 1) == WREN_TYPE_BOOL && wrenGetSlotBool(vm, 1)) ||
               wrenGetSlotType(vm, 1) != WREN_TYPE_NULL;
    rencache_show_debug(res);
    RETURN_NULL(vm);
}

static void f_get_size(WrenVM *vm)
{
    int w, h;
    ren_get_size(&w, &h);
    wrenSetSlotNewList(vm, 0);
    wrenSetSlotDouble(vm, 1, w);
    wrenInsertInList(vm, 0, 0, 1);
    wrenSetSlotDouble(vm, 1, h);
    wrenInsertInList(vm, 0, 1, 1);
    // RETURN_LIST(vm, 0);
}

static void f_begin_frame(WrenVM *vm)
{
    rencache_begin_frame();
    RETURN_NULL(vm);
}

static void f_end_frame(WrenVM *vm)
{
    rencache_end_frame();
    RETURN_NULL(vm);
}

static void f_set_clip_rect(WrenVM *vm)
{
    RenRect rect;
    rect.x = wrenGetSlotDouble(vm, 1);
    rect.y = wrenGetSlotDouble(vm, 2);
    rect.width = wrenGetSlotDouble(vm, 3);
    rect.height = wrenGetSlotDouble(vm, 4);
    rencache_set_clip_rect(rect);
    RETURN_NULL(vm);
}

static void unpackColor(WrenVM *vm, int idx, RenColor *color)
{
#define GET_INDEX(vm, i, v)                                                                                            \
    do                                                                                                                 \
    {                                                                                                                  \
        wrenGetListElement(vm, idx, (i), idx + 1);                                                                     \
        *(v) = wrenGetSlotDouble(vm, idx + 1);                                                                         \
    } while (0)

    wrenEnsureSlots(vm, idx + 2);
    GET_INDEX(vm, 0, &color->r);
    GET_INDEX(vm, 1, &color->g);
    GET_INDEX(vm, 2, &color->b);
    if (wrenGetListCount(vm, idx) == 4)
        GET_INDEX(vm, 3, &color->a);

#undef GET_INDEX
}

static void f_draw_rect(WrenVM *vm)
{
    RenRect rect;
    rect.x = wrenGetSlotDouble(vm, 1);
    rect.y = wrenGetSlotDouble(vm, 2);
    rect.width = wrenGetSlotDouble(vm, 3);
    rect.height = wrenGetSlotDouble(vm, 4);
    RenColor color;
    unpackColor(vm, 5, &color);
    rencache_draw_rect(rect, color);
    RETURN_NULL(vm);
}

static void f_draw_text(WrenVM *vm)
{
    RenFont **font = wrenGetSlotForeign(vm, 1);
    const char *text = wrenGetSlotString(vm, 2);
    int x = wrenGetSlotDouble(vm, 3);
    int y = wrenGetSlotDouble(vm, 4);
    RenColor color;
    unpackColor(vm, 5, &color);
    x = rencache_draw_text(*font, text, x, y, color);
    RETURN_NUM(vm, x);
}

WrenForeignMethodFn apiBindRendererFontMethods(WrenVM *vm, bool isStatic, const char *signature);
WrenForeignClassMethods apiCreateFontForeign(WrenVM *vm);

WrenForeignMethodFn apiBindRendererMethods(WrenVM *vm, const char *className, bool isStatic, const char *signature)
{
    if (!strcmp(className, "Font"))
        return apiBindRendererFontMethods(vm, isStatic, signature);

    if (strcmp(className, "Renderer"))
        return NULL;
    if (!isStatic)
        return NULL;

    if (!strcmp(signature, "debug=(_)"))
        return f_show_debug;
    if (!strcmp(signature, "size"))
        return f_get_size;
    if (!strcmp(signature, "beginFrame()"))
        return f_begin_frame;
    if (!strcmp(signature, "endFrame()"))
        return f_end_frame;

    if (!strcmp(signature, "drawText_(_,_,_,_,_)"))
        return f_draw_text;
    if (!strcmp(signature, "drawRect_(_,_,_,_,_)"))
        return f_draw_rect;
    if (!strcmp(signature, "setClipRect(_,_,_,_)"))
        return f_set_clip_rect;

    return NULL;
}
