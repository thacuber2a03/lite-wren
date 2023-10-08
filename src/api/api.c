#include "api.h"
#include <string.h>

WrenForeignMethodFn program_foreign_method(WrenVM* vm, bool isStatic, const char* signature);

WrenForeignClassMethods api_foreign_class(WrenVM* vm, const char* className)
{
  return (WrenForeignClassMethods) {0};
}

WrenForeignMethodFn api_foreign_method(WrenVM* vm, const char* className, bool isStatic, const char* signature)
{
  if (!strcmp(className, "Program")) return program_foreign_method(vm, isStatic, signature);
  return NULL;
}
