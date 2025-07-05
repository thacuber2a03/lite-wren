#ifndef API_H
#define API_H

#include "lib/wren/wren.h"

extern const char *system_source;
extern const char *renderer_source;

extern struct APIContext api_context;

#define RETURN_NUM(vm, n) wrenSetSlotDouble(vm, 0, n)
#define RETURN_BOOL(vm, b) wrenSetSlotBool(vm, 0, b)
#define RETURN_NULL(vm) wrenSetSlotNull(vm, 0)
#define RETURN_STRING(vm, s) wrenSetSlotString(vm, 0, s)

#define THROW_ERROR(vm, e)                                                                                             \
    do                                                                                                                 \
    {                                                                                                                  \
        wrenSetSlotString(vm, 0, (e));                                                                                 \
        wrenAbortFiber(vm, 0);                                                                                         \
    } while (0)

struct APIContext
{
    WrenHandle *args;
};

int apiAuxCheckOption(WrenVM *vm, int argSlot, const char *def, const char *const *lst);

WrenForeignMethodFn apiBindForeignMethods(WrenVM *vm, const char *module, const char *className, bool isStatic,
                                          const char *signature);

WrenForeignClassMethods apiBindForeignClasses(WrenVM *vm, const char *module, const char *className);

#endif

