#include <stdio.h>
#include <string.h>

#include "api.h"
#include "lib/wren/wren.h"

const char *system_source = "class Program {\n"
                            "    foreign static scale\n"
                            ""
                            "    static pathSep { \"" // sorry not sorry
#ifdef _WIN32
                            "\\"
#else
                            "/"
#endif
                            "\" }\n"
                            ""
                            "    foreign static platform\n"
                            "    foreign static executableName\n"
                            "    foreign static clipboard\n"
                            "    foreign static clipboard=(s)\n"
                            "}\n"
                            "\n"
                            "class Clock {\n"
                            "    foreign static now\n"
                            "    foreign static sleep(ms)\n"
                            "}\n"
                            "\n"
                            "class Events {\n"
                            "    foreign static poll\n"
                            "    foreign static wait(timeout)\n"
                            "}\n"
                            "\n"
                            "class Window {\n"
                            "    foreign static cursor=(v)\n"
                            "    foreign static title=(v)\n"
                            "    foreign static mode=(v)\n"
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
                            "class Process {\n"
                            "    foreign static exec(cmd)\n"
                            "    foreign static args\n"
                            "    foreign static exit(code)\n"
                            "    static exit() { exit(0) }\n"
                            "}\n"
                            "\n"
                            "class Text {\n"
                            "    foreign static fuzzyMatch(needle, haystack)\n"
                            "}\n";

const char *renderer_source =
    "class Renderer {\n"
    "    foreign static debug=(v)\n"
    "    foreign static size\n"
    "    foreign static beginFrame()\n"
    "    foreign static endFrame()\n"
    "\n"
    "    static clip=(v) { Renderer.clipRect = v }\n"
    "    static clipRect=(v) { setClipRect(v[0], v[1], v[2], v[3]) }\n"
    "    foreign static setClipRect(x,y,w,h)\n"
    "\n"
    "    static checkColor_(c) {\n"
    "        if ((c is List) && (c.count == 3 || c.count == 4)) {\n"
    "            return c\n"
    "        }\n"
    "        Fiber.abort(\"expected a list of length 3 or 4 for a color, got %(c)\")\n"
    "    }\n"
    "\n"
    "    static drawText(font, text, x, y, color) { drawText_(font, text, x, y, checkColor_(color)) }\n"
    "    static drawText(font, text, x, y) { drawText_(font, text, x, y, List.filled(4,255)) }\n"
    "    foreign static drawText_(font, text, x, y, color)\n"
    "\n"
    "    static drawRect(x, y, w, h, color) { drawRect_(x, y, w, h, checkColor_(color)) }\n"
    "    static drawRect(x, y, w, h) { drawRect_(x, y, w, h, List.filled(4,255)) }\n"
    "    foreign static drawRect_(x,y,w,h,color)\n"
    "}\n"
    "\n"
    "foreign class Font {\n"
    "    construct load(filename, size) {}\n"
    "    foreign tabWidth=(w)\n"
    "    foreign width(text)\n"
    "    foreign height\n"
    "}\n";

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
WrenForeignClassMethods apiCreateFontForeign(WrenVM *vm);

WrenForeignMethodFn apiBindForeignMethods(WrenVM *vm, const char *module, const char *className, bool isStatic,
                                          const char *signature)
{
    if (!strcmp(module, "renderer"))
        return apiBindRendererMethods(vm, className, isStatic, signature);
    if (!strcmp(module, "system"))
        return apiBindSystemMethods(vm, className, isStatic, signature);
    return NULL;
}

WrenForeignClassMethods apiBindForeignClasses(WrenVM *vm, const char *module, const char *className)
{
    if (!(strcmp(module, "renderer") && strcmp(className, "Font")))
        return apiCreateFontForeign(vm);

    return (WrenForeignClassMethods){
        .allocate = NULL,
        .finalize = NULL,
    };
}

