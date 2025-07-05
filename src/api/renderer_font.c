#include "api.h"
#include "lib/wren/wren.h"
#include "rencache.h"
#include "renderer.h"

WrenForeignMethodFn apiBindRendererFontMethods(WrenVM *vm, bool isStatic, const char *signature);

static void apiAllocateFont(WrenVM *vm)
{
    const char *filename = wrenGetSlotString(vm, 1);
    float size = wrenGetSlotDouble(vm, 2);
    RenFont **self = wrenSetSlotNewForeign(vm, 0, 0, sizeof(*self));
    *self = ren_load_font(filename, size);
    if (!*self)
    {
        THROW_ERROR(vm, "failed to load font");
        RETURN_NULL(vm);
        return;
    }
}

static void apiFinalizeFont(void *data)
{
    RenFont **self = (RenFont **)data;
    if (*self)
        rencache_free_font(*self);
}

static void f_set_tab_width(WrenVM *vm)
{
    RenFont **self = wrenGetSlotForeign(vm, 0);
    int n = wrenGetSlotDouble(vm, 1);
    ren_set_font_tab_width(*self, n);
    RETURN_NULL(vm);
}

static void f_get_width(WrenVM *vm)
{
    RenFont **self = wrenGetSlotForeign(vm, 0);
    const char *text = wrenGetSlotString(vm, 1);
    RETURN_NUM(vm, ren_get_font_width(*self, text));
}

static void f_get_height(WrenVM *vm)
{
    RenFont **self = wrenGetSlotForeign(vm, 0);
    RETURN_NUM(vm, ren_get_font_height(*self));
}

WrenForeignMethodFn apiBindRendererFontMethods(WrenVM *vm, bool isStatic, const char *signature)
{
    if (!strcmp(signature, "tabWidth=(_)"))
        return f_set_tab_width;
    if (!strcmp(signature, "width(_)"))
        return f_get_width;
    if (!strcmp(signature, "height"))
        return f_get_height;

    if (isStatic)
        return NULL;

    return NULL;
}

WrenForeignClassMethods apiCreateFontForeign(WrenVM *vm)
{
    return (WrenForeignClassMethods){
        .allocate = apiAllocateFont,
        .finalize = apiFinalizeFont,
    };
}
