#include <stdio.h>
#include <SDL2/SDL.h>
#include "api/api.h"
#include "renderer.h"

#include <sys/stat.h>

#ifdef _WIN32
  #include <windows.h>
#elif __linux__
  #include <unistd.h>
#elif __APPLE__
  #include <mach-o/dyld.h>
#endif

#define VERSION "1.11"

#ifdef _WIN32
  #define PATHSEP "\\"
#else
  #define PATHSEP "/"
#endif

SDL_Window *window;

static WrenHandle *ARGS = NULL, *PLATFORM = NULL, *SCALE = NULL, *EXEFILE = NULL;

static void* check_alloc(void *ptr) {
  if (!ptr) {
    fprintf(stderr, "Fatal error: memory allocation failed\n");
    exit(EXIT_FAILURE);
  }
  return ptr;
}

static double get_scale(void) {
#if _WIN32
  float dpi;
  SDL_GetDisplayDPI(0, NULL, &dpi, NULL);
  return dpi / 96.0;
#else
  return 1.0;
#endif
}


static void get_exe_filename(char *buf, int sz) {
#if _WIN32
  int len = GetModuleFileName(NULL, buf, sz - 1);
  buf[len] = '\0';
#elif __linux__
  char path[512];
  sprintf(path, "/proc/%d/exe", getpid());
  int len = readlink(path, buf, sz - 1);
  buf[len] = '\0';
#elif __APPLE__
  unsigned size = sz;
  _NSGetExecutablePath(buf, &size);
#else
  strcpy(buf, "./lite");
#endif
}

static void write_func(WrenVM* vm, const char* text) { printf("%s", text); }

static void error_func(WrenVM* vm, WrenErrorType type,
                      const char* module, int line, const char* message)
{
  switch (type)
  {
    case WREN_ERROR_COMPILE:
      fprintf(stderr, "[module %s, line %i] Compile error: %s\n", module, line, message);
      break;
    case WREN_ERROR_RUNTIME:
      fprintf(stderr, "Error: %s\n", message);
      break;
    case WREN_ERROR_STACK_TRACE:
      fprintf(stderr, "[module %s, line %i] in %s\n", module, line, message);
      break;
  }
}

#define DATA_FOLDER   "data"
#define INIT_FILENAME "init.wren"

static const char* apiModuleName = "api";
static const char* api = "\
class Program {                                     \n\
  foreign static poll_event()                       \n\
  foreign static wait_event(seconds)                \n\
  foreign static set_cursor(cursor)                 \n\
  foreign static set_window_title(title)            \n\
  foreign static set_window_mode(mode)              \n\
  foreign static window_has_focus()                 \n\
  foreign static show_confirm_dialog(title, msg)    \n\
  foreign static chdir(dir)                         \n\
  foreign static list_dir(path)                     \n\
  foreign static absolute_path(path)                \n\
  foreign static get_file_info(file)                \n\
  foreign static get_clipboard()                    \n\
  foreign static set_clipboard(contents)            \n\
  foreign static get_time()                         \n\
  foreign static sleep(seconds)                     \n\
  foreign static exec(command)                      \n\
  foreign static fuzzy_match(str, pattern)          \n\
  foreign static exit(code)                         \n\
  static exit() { exit(0) }                         \n\
                                                    \n\
  foreign static ARGS                               \n\
  static VERSION { \"" VERSION "\" }                \n\
  static PATHSEP { \"" PATHSEP "\" }                \n\
  foreign static PLATFORM                           \n\
  foreign static SCALE                              \n\
  foreign static EXEFILE                            \n\
  static EXEDIR {                                   \n\
    if (__exedir) return __exedir                   \n\
    var exefile = Program.EXEFILE                   \n\
    for (i in (exefile.count-1)..0) {               \n\
      if (exefile[i] == Program.PATHSEP) {          \n\
        __exedir = exefile[0...i]                   \n\
        return __exedir                             \n\
      }                                             \n\
    }                                               \n\
    __exedir = \".\"                                \n\
    return __exedir                                 \n\
  }                                                 \n\
}                                                   \n\
\n\
class Renderer {                                    \n\
  foreign static show_debug(enable)                 \n\
  foreign static get_size()                         \n\
  foreign static begin_frame()                      \n\
  foreign static end_frame()                        \n\
  foreign static set_clip_rect(x, y, w, h)          \n\
  foreign static set_clip_rect(l)                   \n\
  foreign static draw_rect(x, y, w, h, color)       \n\
  foreign static draw_text(font, text, x, y, color) \n\
}                                                   \n\
\n\
foreign class Font {                                \n\
  construct load(filename, size) {}                 \n\
  foreign set_tab_width(width)                      \n\
  foreign get_width(text)                           \n\
  foreign get_height()                              \n\
}                                                   \n\
";

static void import_complete(WrenVM* vm, const char* name, WrenLoadModuleResult res)
{
  if (res.source && res.source != api)
    free((char*) res.source);
}

static WrenLoadModuleResult import_func(WrenVM* vm, const char* name)
{
  WrenLoadModuleResult res = { NULL, import_complete, NULL };

  if (!strcmp(name, apiModuleName))
  {
    res.source = api;
    return res;
  }

  char* path;
  int len = (sizeof(DATA_FOLDER) + 1 + strlen(name) + 1 + 1) * sizeof *path;
  path = malloc(len);
  check_alloc(path);

  /* convert "name" to folder relative to "data/" */
  sprintf(path, "%s%s%s%s", DATA_FOLDER, PATHSEP, name, PATHSEP);

  struct stat s;
  if (stat(path, &s) < 0)
  {
    /* look for a file with that name instead */
    path[(--len)-2] = '\0';
    len += sizeof ".wren";
    path = realloc(path, len);
    strcat(path, ".wren");
    path[len-1] = '\0';

    if (stat(path, &s) < 0) return res;
  }
  else
  {
    /* open it's init.wren file */
    len += sizeof(INIT_FILENAME);
    path = realloc(path, len);
    check_alloc(path);
    strcat(path, INIT_FILENAME);
    path[len-1] = '\0';

    if (stat(path, &s) < 0) return res;
  }

  FILE* fp = fopen(path, "rb");
  if (fp == NULL) return res;
  fseek(fp, 0, SEEK_END);
  int sourceLen = ftell(fp);
  rewind(fp);

  char* source = malloc(sourceLen);
  check_alloc(source);
  if (!fread(source, sizeof(char), sourceLen, fp)) return res;
  source[sourceLen-1] = '\0';
  res.source = source;

  fclose(fp);
  return res;
}

static WrenForeignClassMethods foreign_class(WrenVM* vm, const char* module, const char* className)
{
  if (strcmp(module, apiModuleName)) return (WrenForeignClassMethods) {0};
  return api_foreign_class(vm, className);
}

#define PROPREF(name) foreign_##name
#define PROPERTY(name) \
  static void PROPREF(name)(WrenVM* vm) { \
    wrenEnsureSlots(vm, 1); \
    wrenSetSlotHandle(vm, 0, name); \
  }

PROPERTY(ARGS);
PROPERTY(PLATFORM);
PROPERTY(SCALE);
PROPERTY(EXEFILE);

static WrenForeignMethodFn foreign_method(WrenVM* vm,
  const char* module, const char* className, bool isStatic,
  const char* signature)
{
  if (!strcmp(module, apiModuleName))
  {
    if (!strcmp(className, "Program"))
    {
      if (!strcmp(signature, "ARGS"    )) return PROPREF(ARGS);
      if (!strcmp(signature, "PLATFORM")) return PROPREF(PLATFORM);
      if (!strcmp(signature, "SCALE"   )) return PROPREF(SCALE);
      if (!strcmp(signature, "EXEFILE" )) return PROPREF(EXEFILE);
      /* fallthrough */
    }
    return api_foreign_method(vm, className, signature);
  }
  return NULL;
}

#undef PROPREF
#undef PROPERTY

#ifndef _WIN32
static void init_window_icon(void) {
  #include "../icon.inl"
  (void) icon_rgba_len; /* unused */
  SDL_Surface *surf = SDL_CreateRGBSurfaceFrom(
    icon_rgba, 64, 64,
    32, 64 * 4,
    0x000000ff,
    0x0000ff00,
    0x00ff0000,
    0xff000000);
  SDL_SetWindowIcon(window, surf);
  SDL_FreeSurface(surf);
}
#endif

int main(int argc, char **argv) {
#ifdef _WIN32
  HINSTANCE lib = LoadLibrary("user32.dll");
  int (*SetProcessDPIAware)() = (void*) GetProcAddress(lib, "SetProcessDPIAware");
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

  window = SDL_CreateWindow(
    "", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, dm.w * 0.8, dm.h * 0.8,
    SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_HIDDEN);
#ifndef _WIN32
  init_window_icon();
  ren_init(window);
#endif

  WrenConfiguration config;
  wrenInitConfiguration(&config);
  config.writeFn = &write_func;
  config.errorFn = &error_func;
  config.loadModuleFn = &import_func;
  config.bindForeignMethodFn = &foreign_method;
  config.bindForeignClassFn = &foreign_class;

  WrenVM* vm = wrenNewVM(&config);

  /* set up args list */
  wrenEnsureSlots(vm, 2);
  wrenSetSlotNewList(vm, 0);
  for (int i = 0; i < argc; i++)
  {
    wrenSetSlotString(vm, 1, argv[i]);
    wrenInsertInList(vm, 0, i, 1);
  }
  ARGS = wrenGetSlotHandle(vm, 0);

  /* set up other handles */
  wrenEnsureSlots(vm, 1);
  wrenSetSlotString(vm, 0, SDL_GetPlatform());
  PLATFORM = wrenGetSlotHandle(vm, 0);

  char exename[2048];
  get_exe_filename(exename, sizeof(exename));
  wrenSetSlotString(vm, 0, exename);
  EXEFILE = wrenGetSlotHandle(vm, 0);

  wrenEnsureSlots(vm, 1);
  wrenSetSlotDouble(vm, 0, get_scale());
  SCALE = wrenGetSlotHandle(vm, 0);

  /* compile prelude */
  wrenInterpret(vm, "prelude",
    "import \"core\" for Core\n"
    "Core.init()\n"
    "Core.run()\n"
  );

  /* end program */
  wrenReleaseHandle(vm, ARGS);
  wrenReleaseHandle(vm, PLATFORM);
  wrenReleaseHandle(vm, SCALE);
  wrenReleaseHandle(vm, EXEFILE);
  wrenFreeVM(vm);
  SDL_DestroyWindow(window);

  return EXIT_SUCCESS;
}
