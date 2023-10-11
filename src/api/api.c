#include "api.h"
#include <string.h>
#include <stdio.h>

void throwerror(WrenVM* vm, const char* fmt, ...)
{
  wrenEnsureSlots(vm, 1);
  char error[2048];

  va_list arg;
  va_start(arg, fmt);
  vsprintf(error, fmt, arg);
  va_end(arg);

  wrenSetSlotString(vm, 0, error);
  wrenAbortFiber(vm, 0);
}

int checkoption(WrenVM* vm, int slot, const char* def, const char* list[])
{
  const char* name = def;
  if (wrenGetSlotType(vm, 1) != WREN_TYPE_NULL) name = wrenGetSlotString(vm, slot);

  for (int i = 0; list[i]; i++)
    if (!strcmp(list[i], name)) return i;

  throwerror(vm, "Invalid option %s", name);
  return -1;
}


static const char* typetostring(WrenType type)
{
  switch (type)
  {
    case WREN_TYPE_BOOL:    return "boolean";
    case WREN_TYPE_NUM:     return "number";
    case WREN_TYPE_LIST:    return "list";
    case WREN_TYPE_MAP:     return "map";
    case WREN_TYPE_NULL:    return "null";
    case WREN_TYPE_STRING:  return "string";
    case WREN_TYPE_FOREIGN: return "foreign";
    case WREN_TYPE_UNKNOWN: return "unknown";
    default: return NULL; // unreachable
  }
}

#define checktype(vm, slot, expected) \
  do { \
    WrenType got = wrenGetSlotType(vm, slot); \
    if (got != expected) { \
      throwerror(vm, \
        "Expected argument %i to have type %s, got %s instead", \
        slot, typetostring(expected), typetostring(got) \
      ); \
    } \
  } while(0)

bool checkbool(WrenVM* vm, int slot)
{
  checktype(vm, slot, WREN_TYPE_BOOL);
  return wrenGetSlotBool(vm, slot);
}

double checkdouble(WrenVM* vm, int slot)
{
  checktype(vm, slot, WREN_TYPE_NUM);
  return wrenGetSlotDouble(vm, slot);
}

void checklist(WrenVM* vm, int slot) { checktype(vm, slot, WREN_TYPE_LIST); }
void checkmap(WrenVM* vm, int slot) { checktype(vm, slot, WREN_TYPE_MAP); }
void checknull(WrenVM* vm, int slot) { checktype(vm, slot, WREN_TYPE_NULL); }

const char* checkstring(WrenVM* vm, int slot)
{
  checktype(vm, slot, WREN_TYPE_STRING);
  return wrenGetSlotString(vm, slot);
}

void* checkforeign(WrenVM* vm, int slot)
{
  checktype(vm, slot, WREN_TYPE_FOREIGN);
  return wrenGetSlotForeign(vm, slot);
}

void checkunknown(WrenVM* vm, int slot) { checktype(vm, slot, WREN_TYPE_UNKNOWN); }

WrenForeignMethodFn program_foreign_method(WrenVM* vm, const char* signature);
WrenForeignMethodFn renderer_foreign_method(WrenVM* vm, const char* signature);
WrenForeignClassMethods font_foreign_class(WrenVM* vm);
WrenForeignMethodFn font_foreign_method(WrenVM* vm, const char* signature);
WrenForeignClassMethods file_foreign_class(WrenVM* vm);
WrenForeignMethodFn file_foreign_method(WrenVM* vm, const char* signature);

WrenForeignClassMethods api_foreign_class(WrenVM* vm, const char* className)
{
  // well not anymore
  if (!strcmp(className, "File")) return file_foreign_class(vm);
  return font_foreign_class(vm);
}

WrenForeignMethodFn api_foreign_method(WrenVM* vm, const char* className, const char* signature)
{
  if (!strcmp(className, "Program" )) return program_foreign_method(vm, signature);
  if (!strcmp(className, "Renderer")) return renderer_foreign_method(vm, signature);
  if (!strcmp(className, "Font"    )) return font_foreign_method(vm, signature);
  if (!strcmp(className, "File"    )) return file_foreign_method(vm, signature);
  return NULL;
}
