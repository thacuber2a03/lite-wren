#ifndef API_H
#define API_H

#include "lib/wren/wren.h"

typedef struct {
  const char* signature;
  WrenForeignMethodFn func;
} APIRegistry;

WrenForeignClassMethods api_foreign_class(WrenVM* vm, const char* className);
WrenForeignMethodFn api_foreign_method(WrenVM* vm, const char* className, const char* signature);

void throwerror(WrenVM* vm, const char* fmt, ...);
bool checkbool(WrenVM* vm, int slot);
double checkdouble(WrenVM* vm, int slot);
void checklist(WrenVM* vm, int slot);
void checkmap(WrenVM* vm, int slot);
void checknull(WrenVM* vm, int slot);
const char* checkstring(WrenVM* vm, int slot);
void* checkforeign(WrenVM* vm, int slot);
void checkunknown(WrenVM* vm, int slot);

#endif
