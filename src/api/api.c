#include "api.h"
#include <string.h>
#include <stdio.h>

const char* apiModuleName = "api";
const char* api = "\
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
class Renderer {                                                                             \n\
  foreign static show_debug(enable)                                                          \n\
  foreign static get_size()                                                                  \n\
  foreign static begin_frame()                                                               \n\
  foreign static end_frame()                                                                 \n\
  foreign static set_clip_rect(x, y, w, h)                                                   \n\
  foreign static set_clip_rect(l)                                                            \n\
  foreign static draw_rect(x, y, w, h, color)                                                \n\
  static draw_text(font, text, x, y, color) { draw_text_(font, text.toString, x, y, color) } \n\
  foreign static draw_text_(font, text, x, y, color)                                         \n\
}                                                                                            \n\
\n\
foreign class Font {                \n\
  construct load(filename, size) {} \n\
  foreign set_tab_width(width)      \n\
  foreign width(text)               \n\
  foreign height                    \n\
}                                   \n\
\n\
foreign class File {                \n\
  construct load(filename, mode) {} \n\
  foreign read(bytes)               \n\
  foreign read_line()               \n\
  foreign write(string)             \n\
  foreign seek(off, whence)         \n\
  seek(off) { seek(off, \"cur\") }  \n\
  foreign tell()                    \n\
  foreign close()                   \n\
}                                   \n\
";

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
