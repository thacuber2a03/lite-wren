#ifndef API_H
#define API_H

#include "lib/wren/wren.h"

WrenForeignClassMethods api_foreign_class(WrenVM* vm, const char* module, const char* className);
WrenForeignMethodFn api_foreign_method(WrenVM* vm, const char* module, const char* className, bool isStatic, const char* signature);

#endif
