#include <SDL2/SDL.h>
#include <stdbool.h>
#include <ctype.h>
#include <dirent.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include "api.h"
#include "rencache.h"
#ifdef _WIN32
  #include <windows.h>
#endif

extern SDL_Window *window;


static const char* button_name(int button) {
  switch (button) {
    case 1  : return "left";
    case 2  : return "middle";
    case 3  : return "right";
    default : return "?";
  }
}


static char* key_name(char *dst, int sym) {
  strcpy(dst, SDL_GetKeyName(sym));
  char *p = dst;
  while (*p) {
    *p = tolower(*p);
    p++;
  }
  return dst;
}

static void f_poll_event(WrenVM* vm)
{
  char buf[16];
  int mx, my, wx, wy;
  SDL_Event e;

  wrenSetSlotNull(vm, 0);

top:
  if (!SDL_PollEvent(&e)) return;

  wrenEnsureSlots(vm, 2);
  wrenSetSlotNewList(vm, 0);

  switch (e.type)
  {
    case SDL_QUIT:
      wrenSetSlotString(vm, 1, "quit");
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_WINDOWEVENT:
      if (e.window.event == SDL_WINDOWEVENT_RESIZED)
      {
        wrenSetSlotString(vm, 1, "resized");
        wrenInsertInList(vm, 0, -1, 1);
        wrenSetSlotDouble(vm, 1, e.window.data1);
        wrenInsertInList(vm, 0, -1, 1);
        wrenSetSlotDouble(vm, 1, e.window.data2);
        wrenInsertInList(vm, 0, -1, 1);
        return;
      }
      else if (e.window.event == SDL_WINDOWEVENT_EXPOSED)
      {
        rencache_invalidate();
        wrenSetSlotString(vm, 1, "exposed");
        wrenInsertInList(vm, 0, -1, 1);
        return;
      }

      if (e.window.event == SDL_WINDOWEVENT_FOCUS_GAINED) SDL_FlushEvent(SDL_KEYDOWN);
      wrenSetSlotNull(vm, 0);
      goto top;

    case SDL_DROPFILE:
      SDL_GetGlobalMouseState(&mx, &my);
      SDL_GetWindowPosition(window, &wx, &wy);
      wrenSetSlotString(vm, 1, "filedropped");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, e.drop.file);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, mx-wx);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, my-wy);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_KEYDOWN:
      wrenSetSlotString(vm, 1, "keypressed");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, key_name(buf, e.key.keysym.sym));
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_KEYUP:
      wrenSetSlotString(vm, 1, "keyreleased");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, key_name(buf, e.key.keysym.sym));
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_TEXTINPUT:
      wrenSetSlotString(vm, 1, "textinput");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, e.text.text);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_MOUSEBUTTONDOWN:
      if (e.button.button == 1) { SDL_CaptureMouse(true); }
      wrenSetSlotString(vm, 1, "mousepressed");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, button_name(e.button.button));
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.button.x);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.button.y);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.button.clicks);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_MOUSEBUTTONUP:
      if (e.button.button == 1) { SDL_CaptureMouse(false); }
      wrenSetSlotString(vm, 1, "mousereleased");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotString(vm, 1, button_name(e.button.button));
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.button.x);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.button.y);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_MOUSEMOTION:
      wrenSetSlotString(vm, 1, "mousemoved");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.motion.x);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.motion.y);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.motion.xrel);
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.motion.yrel);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    case SDL_MOUSEWHEEL:
      wrenSetSlotString(vm, 1, "mousewheel");
      wrenInsertInList(vm, 0, -1, 1);
      wrenSetSlotDouble(vm, 1, e.wheel.y);
      wrenInsertInList(vm, 0, -1, 1);
      return;

    default: goto top;
  }
}

static void f_wait_event(WrenVM* vm)
{
  int n = wrenGetSlotDouble(vm, 1);
  wrenSetSlotBool(vm, 0, SDL_WaitEventTimeout(NULL, n * 1000));
}

static void throwerror(WrenVM* vm, const char* fmt, ...)
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

static int checkoption(WrenVM* vm, int slot, const char* def, const char* list[])
{
  const char* name = def;
  if (wrenGetSlotType(vm, 0) == WREN_TYPE_NULL) name = wrenGetSlotString(vm, slot);

  for (int i = 0; list[i]; i++)
    if (!strcmp(list[i], name)) return i;

  throwerror(vm, "Invalid option %s", name);
  return -1;
}

static SDL_Cursor* cursor_cache[SDL_SYSTEM_CURSOR_HAND + 1];

static const char *cursor_opts[] = {
  "arrow",
  "ibeam",
  "sizeh",
  "sizev",
  "hand",
  NULL
};

static const int cursor_enums[] = {
  SDL_SYSTEM_CURSOR_ARROW,
  SDL_SYSTEM_CURSOR_IBEAM,
  SDL_SYSTEM_CURSOR_SIZEWE,
  SDL_SYSTEM_CURSOR_SIZENS,
  SDL_SYSTEM_CURSOR_HAND
};

static void f_set_cursor(WrenVM* vm) {
  int opt = checkoption(vm, 1, "arrow", cursor_opts);
  if (opt == -1) return;
  int n = cursor_enums[opt];
  SDL_Cursor *cursor = cursor_cache[n];
  if (!cursor) {
    cursor = SDL_CreateSystemCursor(n);
    cursor_cache[n] = cursor;
  }
  SDL_SetCursor(cursor);
  wrenSetSlotNull(vm, 0);
}

static void f_set_window_title(WrenVM* vm)
{
  SDL_SetWindowTitle(window, wrenGetSlotString(vm, 1));
  wrenSetSlotNull(vm, 0);
}

static const char *window_opts[] = { "normal", "maximized", "fullscreen", NULL };
enum { WIN_NORMAL, WIN_MAXIMIZED, WIN_FULLSCREEN };

static void f_set_window_mode(WrenVM* vm)
{
  int n = checkoption(vm, 1, "normal", window_opts);

  SDL_SetWindowFullscreen(window,
    n == WIN_FULLSCREEN ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
  if (n == WIN_NORMAL) { SDL_RestoreWindow(window); }
  if (n == WIN_MAXIMIZED) { SDL_MaximizeWindow(window); }
  wrenSetSlotNull(vm, 0);
}

static void f_window_has_focus(WrenVM* vm)
{
  wrenSetSlotBool(vm, 0, SDL_GetWindowFlags(window) & SDL_WINDOW_INPUT_FOCUS);
}

static void f_show_confirm_dialog(WrenVM* vm)
{
  const char* title = wrenGetSlotString(vm, 1);
  const char* msg = wrenGetSlotString(vm, 1);

#if _WIN32
  int id = MessageBox(0, msg, title, MB_YESNO | MB_ICONWARNING);
  wrenSetSlotBool(vm, 0, id == IDYES);
#else
  SDL_MessageBoxButtonData buttons[] = {
    { SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, 1, "Yes" },
    { SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT, 0, "No"  },
  };
  SDL_MessageBoxData data = {
    .title = title,
    .message = msg,
    .numbuttons = 2,
    .buttons = buttons,
  };
  int buttonid;
  SDL_ShowMessageBox(&data, &buttonid);
  wrenSetSlotBool(vm, 0, buttonid == 1);
#endif
}

static void f_chdir(WrenVM* vm)
{
  const char* path = wrenGetSlotString(vm, 1);
  int err = chdir(path);
  if (err) throwerror(vm, "chdir() failed");
  wrenSetSlotNull(vm, 0);
}

static void f_list_dir(WrenVM* vm)
{
  const char* path = wrenGetSlotString(vm, 1);

  DIR* dir = opendir(path);
  if (!dir)
  {
    wrenSetSlotString(vm, 0, strerror(errno));
    return;
  }

  wrenEnsureSlots(vm, 2);
  wrenSetSlotNewList(vm, 0);
  struct dirent* entry;
  while ((entry = readdir(dir)))
  {
    if (!strcmp(entry->d_name, "." )) continue;
    if (!strcmp(entry->d_name, "..")) continue;
    wrenSetSlotString(vm, 1, entry->d_name);
    wrenInsertInList(vm, 0, -1, 1);
  }

  closedir(dir);
}

#ifdef _WIN32
  #include <windows.h>
  #define realpath(x, y) _fullpath(y, x, MAX_PATH)
#endif

static void f_absolute_path(WrenVM* vm) {
  const char *path = wrenGetSlotString(vm, 1);
  char *res = realpath(path, NULL);
  if (!res) return;
  wrenSetSlotString(vm, 0, res);
  free(res);
}

static void f_get_file_info(WrenVM* vm)
{
  const char* path = wrenGetSlotString(vm, 0);

  struct stat s;
  int err = stat(path, &s);
  if (err < 0)
  {
    wrenSetSlotString(vm, 0, strerror(errno));
    return;
  }

  wrenEnsureSlots(vm, 3);
  wrenSetSlotNewMap(vm, 0);

  wrenSetSlotDouble(vm, 1, s.st_mtime);
  wrenSetSlotString(vm, 2, "modified");
  wrenSetMapValue(vm, 0, 2, 1);

  wrenSetSlotDouble(vm, 1, s.st_size);
  wrenSetSlotString(vm, 2, "size");
  wrenSetMapValue(vm, 0, 2, 1);

  if (S_ISREG(s.st_mode))
    wrenSetSlotString(vm, 1, "file");
  else if (S_ISDIR(s.st_mode))
    wrenSetSlotString(vm, 1, "dir");
  else
    wrenSetSlotNull(vm, 1);

  wrenSetSlotString(vm, 2, "type");
  wrenSetMapValue(vm, 0, 2, 1);
}

static void f_get_clipboard(WrenVM* vm)
{
  char* text = SDL_GetClipboardText();
  if (!text) wrenSetSlotNull(vm, 0);
  wrenSetSlotString(vm, 0, text);
  SDL_free(text);
}

static void f_set_clipboard(WrenVM* vm)
{
  const char* text = wrenGetSlotString(vm, 1);
  SDL_SetClipboardText(text);
  wrenSetSlotNull(vm, 0);
}

static void f_get_time(WrenVM* vm)
{
  double n = SDL_GetPerformanceCounter() / (double) SDL_GetPerformanceFrequency();
  wrenSetSlotDouble(vm, 0, n);
}

static void f_sleep(WrenVM* vm)
{
  double n = wrenGetSlotDouble(vm, 0);
  SDL_Delay(n * 1000);
  wrenSetSlotNull(vm, 0);
}

static void f_exec(WrenVM* vm)
{
  const char* cmd = wrenGetSlotString(vm, 1);
  char* buf = malloc(strlen(cmd) + 32);
  if (!buf)
  {
    throwerror(vm, "buffer allocation failed");
    return;
  }
#if _WIN32
  sprintf(buf, "cmd /c \"%s\"", cmd);
  WinExec(buf, SW_HIDE);
#else
  sprintf(buf, "%s &", cmd);
  int _ = system(buf); (void) _;
#endif
  free(buf);
}

static void f_fuzzy_match(WrenVM* vm)
{
  const char* str = wrenGetSlotString(vm, 1);
  const char* ptn = wrenGetSlotString(vm, 2);
  int score = 0;
  int run = 0;

  while (*str && *ptn)
  {
    while (*str == ' ') str++;
    while (*ptn == ' ') ptn++;
    if (tolower(*str) == tolower(*ptn))
    {
      score += run * 10 - (*str != *ptn);
      run++;
      ptn++;
    }
    else
    {
      score -= 10;
      run = 0;
    }
    str++;
  }

  if (*ptn)
  {
    wrenSetSlotNull(vm, 0);
    return;
  }

  wrenSetSlotDouble(vm, 0, score - (int) strlen(str));
}

static void f_exit(WrenVM* vm) { exit(wrenGetSlotDouble(vm, 1)); }

APIRegistry program_api[] = {
  { "poll_event()",             f_poll_event          },
  { "wait_event(_)",            f_wait_event          },
  { "set_cursor(_)",            f_set_cursor          },
  { "set_window_title(_)",      f_set_window_title    },
  { "set_window_mode(_)",       f_set_window_mode     },
  { "window_has_focus()",       f_window_has_focus    },
  { "show_confirm_dialog(_,_)", f_show_confirm_dialog },
  { "chdir(_)",                 f_chdir               },
  { "list_dir(_)",              f_list_dir            },
  { "absolute_path(_)",         f_absolute_path       },
  { "get_file_info(_)",         f_get_file_info       },
  { "get_clipboard()",          f_get_clipboard       },
  { "set_clipboard(_)",         f_set_clipboard       },
  { "get_time()",               f_get_time            },
  { "sleep(_)",                 f_sleep               },
  { "exec(_)",                  f_exec                },
  { "fuzzy_match(_,_)",         f_fuzzy_match         },
  { "exit(_)",                  f_exit                },
  { NULL,                       NULL                  },
};

WrenForeignMethodFn program_foreign_method(WrenVM* vm, bool isStatic, const char* signature)
{
  for (int i = 0; program_api[i].signature != NULL; i++)
  {
    APIRegistry* api = program_api + i;
    if (!strcmp(signature, api->signature)) return api->func;
  }
  return NULL;
}
