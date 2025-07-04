#include <stdio.h>
#include <string.h>

#include "api.h"

int apiAuxCheckOption(WrenVM *vm, int argSlot, const char *def, const char *const *lst)
{
    const char *name = NULL;

    bool missing = (argSlot >= wrenGetSlotCount(vm)) || (wrenGetSlotType(vm, argSlot) == WREN_TYPE_NULL);

    if (missing)
    {
        if (def == NULL)
        {
            THROW_ERROR(vm, "missing option");
            return -1;
        }
        name = def;
    }
    else
    {
        if (wrenGetSlotType(vm, argSlot) != WREN_TYPE_STRING)
        {
            THROW_ERROR(vm, "option must be a string");
            return -1;
        }
        name = wrenGetSlotString(vm, argSlot);
    }

    for (int i = 0; lst[i]; i++)
        if (strcmp(lst[i], name) == 0)
            return i;

    char buf[128];
    snprintf(buf, sizeof(buf), "invalid option '%s'", name);
    THROW_ERROR(vm, buf);
    return -1;
}

WrenForeignMethodFn apiBindSystemMethods(WrenVM *vm, const char *className, bool isStatic, const char *signature);
WrenForeignMethodFn apiBindRendererMethods(WrenVM *vm, const char *className, bool isStatic, const char *signature);

WrenForeignMethodFn apiBindForeignMethods(WrenVM *vm, const char *module, const char *className, bool isStatic,
                                          const char *signature)
{
    if (strcmp(module, "renderer"))
        return apiBindRendererMethods(vm, className, isStatic, signature);
    if (strcmp(module, "system"))
        return apiBindSystemMethods(vm, className, isStatic, signature);
    return NULL;
}

const char *system_source = "class Program {\n"
                            "    foreign static scale\n"
                            "    static pathSep { \""
#ifdef _WIN32
                            "\\"
#else
                            "/"
#endif
                            "\" }\n"
                            "    foreign static platform\n"
                            "    foreign static executableName\n"
                            "}\n"
                            "\n"
                            "class Clock {\n"
                            "    foreign static now\n"
                            "    foreign static sleep(ms)\n"
                            "}\n"
                            "\n"
                            "class Events {\n"
                            "    foreign static poll\n"
                            "    foreign static wait\n"
                            "}\n"
                            "\n"
                            "class Window {\n"
                            "    foreign static setCursor(cursor)\n"
                            "    foreign static setTitle(title)\n"
                            "    foreign static setMode(mode)\n"
                            "    foreign static hasFocus\n"
                            "}\n"
                            "\n"
                            "class Dialog {\n"
                            "    foreign static confirm(title, msg)\n"
                            "}\n"
                            "\n"
                            "class Filesystem {\n"
                            "    foreign static chdir(path)\n"
                            "    foreign static list(path)\n"
                            "    foreign static abs(path)\n"
                            "    foreign static info(path)\n"
                            "}\n"
                            "\n"
                            "class Clipboard {\n"
                            "    foreign static get()\n"
                            "    foreign static set(s)\n"
                            "}\n"
                            "\n"
                            "\n"
                            "class Process {\n"
                            "    foreign static exec(cmd)\n"
                            "    foreign static args\n"
                            "}\n"
                            "\n"
                            "class Text {\n"
                            "    foreign static fuzzyMatch(needle, haystack)\n"
                            "}\n";

