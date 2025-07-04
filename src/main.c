#include "api/api.h"
#include "renderer.h"
#include <SDL2/SDL.h>
#include <errno.h>
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#elif __linux__
#include <unistd.h>
#elif __APPLE__
#include <mach-o/dyld.h>
#endif

SDL_Window *window;
struct APIContext api_context;

static void init_window_icon(void)
{
#ifndef _WIN32
#include "../icon.inl"
    (void)icon_rgba_len; /* unused */
    SDL_Surface *surf =
        SDL_CreateRGBSurfaceFrom(icon_rgba, 64, 64, 32, 64 * 4, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
    SDL_SetWindowIcon(window, surf);
    SDL_FreeSurface(surf);
#endif
}

static void writeFn(WrenVM *vm, const char *text)
{
    printf("%s", text);
}

static void errorFn(WrenVM *vm, WrenErrorType type, const char *module, int line, const char *message)
{
    switch (type)
    {
    case WREN_ERROR_STACK_TRACE:
    case WREN_ERROR_COMPILE:
        fprintf(stderr, "[at module %s, line %i] %s\n", module, line, message);
        break;
    case WREN_ERROR_RUNTIME:
        fprintf(stderr, "%s\n", message);
        break;
    }
}

void onCompleteLoadModule(WrenVM *vm, const char *name, struct WrenLoadModuleResult result)
{
    if (strcmp(name, "renderer") && strcmp(name, "system"))
    {
        free((char *)result.source);
    }
}

static void die(void)
{
    fprintf(stderr, "fatal error: %s\n", strerror(errno));
    exit(-1);
}

static WrenLoadModuleResult loadModuleFn(WrenVM *vm, const char *name)
{
    WrenLoadModuleResult res;
    res.onComplete = onCompleteLoadModule;
    res.source = NULL;
    res.userData = NULL;

    if (!strcmp(name, "renderer"))
        res.source = renderer_source;
    else if (!strcmp(name, "system"))
        res.source = system_source;
    else
    {
        int namelen = strlen(name);
        char *filepath = malloc(sizeof "data/.wren" - 1 + namelen + 1);
        if (!filepath)
            die();

        filepath[0] = '\0';
        strcat(filepath, "data/");
        strcat(filepath, name);
        strcat(filepath, ".wren");
        filepath[strlen(filepath)] = '\0';

        FILE *fp = fopen(filepath, "rb");
        if (!fp)
        {
            void *ptr = realloc(filepath, sizeof "data//init.wren" - 1 + namelen + 1);
            if (!ptr)
            {
                free(filepath);
                die();
            }
            filepath = ptr;

            filepath[0] = '\0';
            strcat(filepath, "data/");
            strcat(filepath, name);
            strcat(filepath, "/init.wren");
            filepath[strlen(filepath)] = '\0';

            fp = fopen(filepath, "rb");
            if (!fp)
            {
                free(filepath);
                return res;
            }
        }

        free(filepath);

        fseek(fp, 0, SEEK_END);
        int size = ftell(fp);
        rewind(fp);

        char *source = malloc(size + 1);
        if (fread(source, 1, size + 1, fp) != size)
        {
            free(source);
            fclose(fp);
            die();
        }

        source[size - 1] = '\0';
        res.source = source;
        fclose(fp);
    }

    return res;
}

int main(int argc, char **argv)
{
#ifdef _WIN32
    HINSTANCE lib = LoadLibrary("user32.dll");
    int (*SetProcessDPIAware)() = (void *)GetProcAddress(lib, "SetProcessDPIAware");
    SetProcessDPIAware();
#endif

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS);
    SDL_EnableScreenSaver();
    SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
    atexit(SDL_Quit);

#ifdef SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR /* Available since 2.0.8 */
    SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0");
#endif
#if SDL_VERSION_ATLEAST(2, 0, 5)
    SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
#endif

    SDL_DisplayMode dm;
    SDL_GetCurrentDisplayMode(0, &dm);

    window = SDL_CreateWindow("", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, dm.w * 0.8, dm.h * 0.8,
                              SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_HIDDEN);
    init_window_icon();
    ren_init(window);

    WrenConfiguration config;
    wrenInitConfiguration(&config);
    config.bindForeignMethodFn = apiBindForeignMethods;
    config.bindForeignClassFn = apiBindForeignClasses;
    config.writeFn = writeFn;
    config.errorFn = errorFn;
    config.loadModuleFn = loadModuleFn;
    WrenVM *vm = wrenNewVM(&config);

    wrenEnsureSlots(vm, 2);
    wrenSetSlotNewList(vm, 0);
    for (int i = 0; i < argc; i++)
    {
        wrenSetSlotString(vm, 1, argv[i]);
        wrenInsertInList(vm, 0, i, 1);
    }
    api_context.args = wrenGetSlotHandle(vm, 0);

    // TODO(thacuber2a03): okay honestly this just sucks
    (void)wrenInterpret(vm, "prelude",
                        "// import \"system\" for Program\n"
                        "import \"core\" for Core\n"
                        "\n"
                        "var core = Core.new()\n"
                        "var res = Fiber.new { core.run() }.try()\n"
                        "\n"
                        "if (res is String) {\n"
                        "	System.print(\"Error: \" + res.toString)\n"
                        "	Fiber.new { core.onError() }.try()\n"
                        "}\n"
                        /*
                        "local core\n"
                        "xpcall(function()\n"
                        "  SCALE = tonumber(os.getenv(\"LITE_SCALE\")) or SCALE\n"
                        "  PATHSEP = package.config:sub(1, 1)\n"
                        "  EXEDIR = EXEFILE:match(\"^(.+)[/\\\\].*$\")\n"
                        "  package.path = EXEDIR .. '/data/?.lua;' .. package.path\n"
                        "  package.path = EXEDIR .. '/data/?/init.lua;' .. package.path\n"
                        "  core = require('core')\n"
                        "  core.init()\n"
                        "  core.run()\n"
                        "end, function(err)\n"
                        "  print('Error: ' .. tostring(err))\n"
                        "  print(debug.traceback(nil, 2))\n"
                        "  if core and core.on_error then\n"
                        "    pcall(core.on_error, err)\n"
                        "  end\n"
                        "  os.exit(1)\n"
                        "end)");
                        */

    );

    SDL_DestroyWindow(window);
    wrenReleaseHandle(vm, api_context.args);
    wrenFreeVM(vm);

    return EXIT_SUCCESS;
}
