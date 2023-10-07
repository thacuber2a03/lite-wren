#include "api.h"

WrenForeignClassMethods api_foreign_class(WrenVM* vm, const char* module, const char* className)
{
	return (WrenForeignClassMethods) {0};
}

WrenForeignMethodFn api_foreign_method(WrenVM* vm, const char* module, const char* className, bool isStatic, const char* signature)
{

}
