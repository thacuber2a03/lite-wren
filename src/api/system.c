#include "api.h"
#include "rencache.h"
#include <SDL2/SDL.h>
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>
#ifdef _WIN32
#include <windows.h>
#endif

extern SDL_Window *window;

static const char *button_name(int button)
{
    switch (button)
    {
    case 1:
        return "left";
    case 2:
        return "middle";
    case 3:
        return "right";
    default:
        return "?";
    }
}

static char *key_name(char *dst, int sym)
{
    strcpy(dst, SDL_GetKeyName(sym));
    char *p = dst;
    while (*p)
    {
        *p = tolower(*p);
        p++;
    }
    return dst;
}

static void f_poll_event(WrenVM *vm)
{
    char buf[16];
    int mx, my, wx, wy;
    SDL_Event e;

top:
    if (!SDL_PollEvent(&e))
    {
        RETURN_NULL(vm);
        return;
    }

    wrenEnsureSlots(vm, 2);
    wrenSetSlotNewList(vm, 0);

#define INSERT_IN_LIST(T, i, e)                                                                                        \
    do                                                                                                                 \
    {                                                                                                                  \
        wrenSetSlot##T(vm, 1, (e));                                                                                    \
        wrenInsertInList(vm, 0, (i), 1);                                                                               \
    } while (0)

    switch (e.type)
    {
    case SDL_QUIT:
        INSERT_IN_LIST(String, 0, "quit");
        break;

    case SDL_WINDOWEVENT:
        if (e.window.event == SDL_WINDOWEVENT_RESIZED)
        {
            INSERT_IN_LIST(String, 0, "resized");
            INSERT_IN_LIST(Double, 1, e.window.data1);
            INSERT_IN_LIST(Double, 2, e.window.data2);
            return;
        }
        else if (e.window.event == SDL_WINDOWEVENT_EXPOSED)
        {
            rencache_invalidate();
            INSERT_IN_LIST(String, 0, "exposed");
            return;
        }
        /* on some systems, when alt-tabbing to the window SDL will queue up
        ** several KEYDOWN events for the `tab` key; we flush all keydown
        ** events on focus so these are discarded */
        if (e.window.event == SDL_WINDOWEVENT_FOCUS_GAINED)
        {
            SDL_FlushEvent(SDL_KEYDOWN);
        }
        goto top;

    case SDL_DROPFILE:
        SDL_GetGlobalMouseState(&mx, &my);
        SDL_GetWindowPosition(window, &wx, &wy);
        INSERT_IN_LIST(String, 0, "filedropped");
        INSERT_IN_LIST(String, 1, e.drop.file);
        INSERT_IN_LIST(Double, 2, mx - wx);
        INSERT_IN_LIST(Double, 3, my - wy);
        SDL_free(e.drop.file);
        return;

    case SDL_KEYDOWN:
        INSERT_IN_LIST(String, 0, "keypressed");
        INSERT_IN_LIST(String, 1, key_name(buf, e.key.keysym.sym));
        return;

    case SDL_KEYUP:
        INSERT_IN_LIST(String, 0, "keyreleased");
        INSERT_IN_LIST(String, 1, key_name(buf, e.key.keysym.sym));
        return;

    case SDL_TEXTINPUT:
        INSERT_IN_LIST(String, 0, "textinput");
        INSERT_IN_LIST(String, 1, e.text.text);
        return;

    case SDL_MOUSEBUTTONDOWN:
        if (e.button.button == 1)
            SDL_CaptureMouse(1);
        INSERT_IN_LIST(String, 0, "mousepressed");
        INSERT_IN_LIST(String, 1, button_name(e.button.button));
        INSERT_IN_LIST(Double, 2, e.button.x);
        INSERT_IN_LIST(Double, 3, e.button.y);
        INSERT_IN_LIST(Double, 4, e.button.clicks);
        return;

    case SDL_MOUSEBUTTONUP:
        if (e.button.button == 1)
            SDL_CaptureMouse(0);
        INSERT_IN_LIST(String, 0, "mousereleased");
        INSERT_IN_LIST(String, 1, button_name(e.button.button));
        INSERT_IN_LIST(Double, 2, e.button.x);
        INSERT_IN_LIST(Double, 3, e.button.y);
        return;

    case SDL_MOUSEMOTION:
        INSERT_IN_LIST(String, 0, "mousemoved");
        INSERT_IN_LIST(Double, 1, e.motion.x);
        INSERT_IN_LIST(Double, 2, e.motion.y);
        INSERT_IN_LIST(Double, 3, e.motion.xrel);
        INSERT_IN_LIST(Double, 4, e.motion.yrel);
        return;

    case SDL_MOUSEWHEEL:
        INSERT_IN_LIST(String, 0, "mousewheel");
        INSERT_IN_LIST(Double, 1, e.wheel.y);
        return;

    default:
        goto top;
    }

#undef INSERT_IN_LIST
}

static void f_wait_event(WrenVM *vm)
{
    double n = wrenGetSlotDouble(vm, 1);
    RETURN_BOOL(vm, SDL_WaitEventTimeout(NULL, n * 1000));
}

static SDL_Cursor *cursor_cache[SDL_SYSTEM_CURSOR_HAND + 1];

static const char *cursor_opts[] = {"arrow", "ibeam", "sizeh", "sizev", "hand", NULL};

static const int cursor_enums[] = {SDL_SYSTEM_CURSOR_ARROW, SDL_SYSTEM_CURSOR_IBEAM, SDL_SYSTEM_CURSOR_SIZEWE,
                                   SDL_SYSTEM_CURSOR_SIZENS, SDL_SYSTEM_CURSOR_HAND};

static void f_set_cursor(WrenVM *vm)
{
    int opt = apiAuxCheckOption(vm, 1, "arrow", cursor_opts);
    int n = cursor_enums[opt];
    SDL_Cursor *cursor = cursor_cache[n];
    if (!cursor)
    {
        cursor = SDL_CreateSystemCursor(n);
        cursor_cache[n] = cursor;
    }
    SDL_SetCursor(cursor);
    RETURN_NULL(vm);
}

static void f_set_window_title(WrenVM *vm)
{
    const char *title = wrenGetSlotString(vm, 1);
    SDL_SetWindowTitle(window, title);
    RETURN_NULL(vm);
}

static const char *window_opts[] = {"normal", "maximized", "fullscreen", 0};
enum
{
    WIN_NORMAL,
    WIN_MAXIMIZED,
    WIN_FULLSCREEN
};

static void f_set_window_mode(WrenVM *vm)
{
    int n = apiAuxCheckOption(vm, 1, "normal", window_opts);
    SDL_SetWindowFullscreen(window, n == WIN_FULLSCREEN ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
    if (n == WIN_NORMAL)
    {
        SDL_RestoreWindow(window);
    }
    if (n == WIN_MAXIMIZED)
    {
        SDL_MaximizeWindow(window);
    }
    RETURN_NULL(vm);
}

static void f_window_has_focus(WrenVM *vm)
{
    RETURN_BOOL(vm, SDL_GetWindowFlags(window) & SDL_WINDOW_INPUT_FOCUS);
}

static void f_show_confirm_dialog(WrenVM *vm)
{
    const char *title = wrenGetSlotString(vm, 1);
    const char *msg = wrenGetSlotString(vm, 2);

#if _WIN32
    int id = MessageBox(0, msg, title, MB_YESNO | MB_ICONWARNING);
    RETURN_BOOL(vm, id == IDYES);

#else
    SDL_MessageBoxButtonData buttons[] = {
        {SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, 1, "Yes"},
        {SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT, 0, "No"},
    };
    SDL_MessageBoxData data = {
        .title = title,
        .message = msg,
        .numbuttons = 2,
        .buttons = buttons,
    };
    int buttonid;
    SDL_ShowMessageBox(&data, &buttonid);
    RETURN_BOOL(vm, buttonid == 1);
#endif
}

static void f_chdir(WrenVM *vm)
{
    const char *path = wrenGetSlotString(vm, 1);
    int err = chdir(path);
    if (err)
        THROW_ERROR(vm, "chdir() failed");
    RETURN_NULL(vm);
}

static void f_list_dir(WrenVM *vm)
{
    const char *path = wrenGetSlotString(vm, 1);

    DIR *dir = opendir(path);
    if (!dir)
    {
        THROW_ERROR(vm, strerror(errno));
        return;
    }

    wrenEnsureSlots(vm, 3);
    wrenSetSlotNewList(vm, 0);
    int i = 1;
    struct dirent *entry;
    while ((entry = readdir(dir)))
    {
        if (strcmp(entry->d_name, ".") == 0)
            continue;
        if (strcmp(entry->d_name, "..") == 0)
            continue;
        wrenSetSlotString(vm, 1, entry->d_name);
        wrenInsertInList(vm, 0, i, 1);
        i++;
    }

    closedir(dir);
    // RETURN_LIST(vm, 0);
}

#ifdef _WIN32
#include <windows.h>
#define realpath(x, y) _fullpath(y, x, MAX_PATH)
#endif

static void f_absolute_path(WrenVM *vm)
{
    const char *path = wrenGetSlotString(vm, 1);
    char *res = realpath(path, NULL);
    if (!res)
        return RETURN_NULL(vm);
    RETURN_STRING(vm, res);
    free(res);
}

static void f_get_file_info(WrenVM *vm)
{
    const char *path = wrenGetSlotString(vm, 1);

    struct stat s;
    int err = stat(path, &s);
    if (err < 0)
    {
        THROW_ERROR(vm, strerror(errno));
        return;
    }

    wrenEnsureSlots(vm, 3);
    wrenSetSlotNewMap(vm, 0);

    wrenSetSlotString(vm, 1, "modified");
    wrenSetSlotDouble(vm, 2, s.st_mtime);
    wrenSetMapValue(vm, 0, 1, 2);

    wrenSetSlotString(vm, 1, "size");
    wrenSetSlotDouble(vm, 2, s.st_size);
    wrenSetMapValue(vm, 0, 1, 2);

    if (S_ISREG(s.st_mode))
        wrenSetSlotString(vm, 1, "file");
    else if (S_ISDIR(s.st_mode))
        wrenSetSlotString(vm, 1, "dir");
    else
        wrenSetSlotNull(vm, 1);
    wrenSetMapValue(vm, 0, 1, 2);
    // RETURN_MAP(vm, 0);
}

static void f_get_clipboard(WrenVM *vm)
{
    char *text = SDL_GetClipboardText();
    if (!text)
        return RETURN_NULL(vm);
    RETURN_STRING(vm, text);
    SDL_free(text);
}

static void f_set_clipboard(WrenVM *vm)
{
    const char *text = wrenGetSlotString(vm, 1);
    SDL_SetClipboardText(text);
    RETURN_NULL(vm);
}

static void f_now(WrenVM *vm)
{
    RETURN_NUM(vm, SDL_GetPerformanceCounter() / (double)SDL_GetPerformanceFrequency());
}

static void f_sleep(WrenVM *vm)
{
    double n = wrenGetSlotDouble(vm, 1);
    SDL_Delay(n * 1000);
    RETURN_NULL(vm);
}

static void f_exec(WrenVM *vm)
{
    int len;
    const char *cmd = wrenGetSlotBytes(vm, 1, &len);
    char *buf = malloc((size_t)len + 32);
    if (!buf)
    {
        THROW_ERROR(vm, "buffer allocation failed");
        return;
    }
#if _WIN32
    sprintf(buf, "cmd /c \"%s\"", cmd);
    WinExec(buf, SW_HIDE);
#else
    sprintf(buf, "%s &", cmd);
    int res = system(buf);
    (void)res;
#endif
    free(buf);
    RETURN_NULL(vm);
}

static void f_args(WrenVM *vm)
{
    wrenSetSlotHandle(vm, 0, api_context.args);
}

static void f_exit(WrenVM *vm)
{
    exit(wrenGetSlotDouble(vm, 1));
    RETURN_NULL(vm);
}

static void f_fuzzy_match(WrenVM *vm)
{
    const char *str = wrenGetSlotString(vm, 1);
    const char *ptn = wrenGetSlotString(vm, 2);
    int score = 0;
    int run = 0;

    while (*str && *ptn)
    {
        while (*str == ' ')
        {
            str++;
        }
        while (*ptn == ' ')
        {
            ptn++;
        }
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
        return RETURN_NULL(vm);

    RETURN_NUM(vm, score - (int)strlen(str));
}

static void f_get_version(WrenVM *vm)
{
    RETURN_STRING(vm, "0.1");
}

static void f_get_platform(WrenVM *vm)
{
    RETURN_STRING(vm, SDL_GetPlatform());
}

static void f_get_scale(WrenVM *vm)
{
#if _WIN32
    float dpi;
    SDL_GetDisplayDPI(0, NULL, &dpi, NULL);
    RETURN_NUM(vm, dpi / 96.0);
#else
    RETURN_NUM(vm, 1);
#endif
}

static void f_get_exename(WrenVM *vm)
{
#define sz 2048
    char buf[2048];
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
    RETURN_STRING(vm, buf);
#undef sz
}

WrenForeignMethodFn apiBindSystemMethods(WrenVM *vm, const char *className, bool isStatic, const char *signature)
{
    if (!strcmp(className, "Clock"))
    {
        if (!strcmp(signature, "now"))
            return f_now;
        else if (!strcmp(signature, "sleep(_)"))
            return f_sleep;
    }
    else if (!strcmp(className, "Events"))
    {
        if (!strcmp(signature, "poll"))
            return f_poll_event;
        else if (!strcmp(signature, "wait(_)"))
            return f_wait_event;
    }
    else if (!strcmp(className, "Window"))
    {
        if (!strcmp(signature, "cursor=(_)"))
            return f_set_cursor;
        else if (!strcmp(signature, "title=(_)"))
            return f_set_window_title;
        else if (!strcmp(signature, "mode=(_)"))
            return f_set_window_mode;
        else if (!strcmp(signature, "hasFocus"))
            return f_window_has_focus;
    }
    else if (!(strcmp(className, "Dialog") && strcmp(signature, "confirm(_,_)")))
    {
        return f_show_confirm_dialog;
    }
    else if (!strcmp(className, "Filesystem"))
    {
        if (!strcmp(signature, "list(_)"))
            return f_list_dir;
        else if (!strcmp(signature, "chdir(_)"))
            return f_chdir;
        else if (!strcmp(signature, "abs(_)"))
            return f_absolute_path;
        else if (!strcmp(signature, "info(_)"))
            return f_get_file_info;
    }
    else if (!strcmp(className, "Process"))
    {
        if (!strcmp(signature, "exec(_)"))
            return f_exec;
        else if (!strcmp(signature, "args"))
            return f_args;
        else if (!strcmp(signature, "exit(_)"))
            return f_exit;
    }
    else if (!strcmp(className, "Program"))
    {
        if (!strcmp(signature, "version"))
            return f_get_version;
        else if (!strcmp(signature, "scale"))
            return f_get_scale;
        else if (!strcmp(signature, "platform"))
            return f_get_platform;
        else if (!strcmp(signature, "executableName"))
            return f_get_exename;
        else if (!strcmp(signature, "clipboard"))
            return f_get_clipboard;
        else if (!strcmp(signature, "clipboard=(_)"))
            return f_set_clipboard;
    }
    else if (!(strcmp(className, "Text") && strcmp(signature, "fuzzyMatch(_,_)")))
    {
        return f_fuzzy_match;
    }

    if (!isStatic)
        return NULL;

    return NULL;
}
