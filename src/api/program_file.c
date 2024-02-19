#include <stdio.h>
#include <string.h>
#include <errno.h>
#include "api.h"

void file_allocate(WrenVM* vm)
{
  const char* filename = checkstring(vm, 1);
  const char* mode = checkstring(vm, 2);
  FILE** self = (FILE**)wrenSetSlotNewForeign(vm, 0, 0, sizeof(FILE*));
  *self = fopen(filename, mode);
  if (!*self)
  {
    throwerror(vm, "Failed to open file: %s", strerror(errno));
    return;
  }
}

#define checkfile(fpp, action)                        \
  do {                                                \
    if (!*(fpp)) {                                    \
      throwerror(vm, "Can't " action " closed file"); \
      return;                                         \
    }                                                 \
  } while(0)

void f_read(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  checkfile(self, "read from");

  size_t bytes = (size_t)checkdouble(vm, 1);
  char* buf = malloc(bytes);
  size_t bytesRead = fread(buf, 1, bytes, *self);
  if (bytes != bytesRead) {
    throwerror(vm, "Couldn't read all bytes from file: %s", strerror(errno));
    return;
  }
  wrenSetSlotBytes(vm, 0, buf, bytes);
  free(buf);
}

void f_read_line(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  checkfile(self, "read line from");

  char* line = NULL;
  size_t size = 0;
  if (getline(&line, &size, *self))
    wrenSetSlotBytes(vm, 0, line, size);
  else
    wrenSetSlotNull(vm, 0);

  free(line);
}

void f_write(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  checkfile(self, "write to");

  const char* string = checkstring(vm, 1);
  if (!string) return;
  size_t written = fwrite(string, sizeof(char), strlen(string), *self);
  wrenSetSlotDouble(vm, 0, written);
}

const char* seek_opts[] = { "cur", "set", "end" };
enum { S_CUR, S_SET, S_END };

void f_seek(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  checkfile(self, "seek through a");
  int opt = checkoption(vm, 1, "cur", seek_opts);
  size_t offset = (size_t)checkdouble(vm, 2);
  if (opt == -1) return;
  switch (opt)
  {
    case S_CUR: fseek(*self, offset, SEEK_CUR); break;
    case S_SET: fseek(*self, offset, SEEK_SET); break;
    case S_END: fseek(*self, offset, SEEK_END); break;
  }
  wrenSetSlotNull(vm, 0);
}

void f_tell(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  checkfile(self, "tell position of a");
  wrenSetSlotDouble(vm, 0, ftell(*self));
}

#undef checkfile

#define closefile(fpp) \
  do {                 \
    if (fpp != NULL) { \
      fclose(fpp);     \
      fpp = NULL;      \
    }                  \
  } while(0)

void f_close(WrenVM* vm)
{
  FILE** self = (FILE**)wrenGetSlotForeign(vm, 0);
  if (!*self) { throwerror(vm, "File is already closed"); return; }
  closefile(*self);
}

void file_finalize(void* data) { closefile(data); }

WrenForeignClassMethods file_foreign_class(WrenVM* vm)
{
  return (WrenForeignClassMethods) {
    .allocate = file_allocate,
    .finalize = file_finalize,
  };
}

APIRegistry file_api[] = {
  { "read(_)",     f_read      },
  { "read_line()", f_read_line },
  { "write(_)",    f_write     },
  { "seek(_,_)",   f_seek      },
  { "tell()",      f_tell      },
  { "close()",     f_close     },
  { NULL, NULL },
};

WrenForeignMethodFn file_foreign_method(WrenVM* vm, const char* signature)
{
  for (int i = 0; file_api[i].signature != NULL; i++)
  {
    APIRegistry* api = file_api + i;
    if (!strncmp(api->signature, signature, strlen(signature)))
      return api->func;
  }
  return NULL;
}
