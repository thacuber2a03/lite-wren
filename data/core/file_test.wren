// WARNING: this test file is not actually a core part of the editor!
import "api" for File

var file = File.load("test.txt", "w+b")
file.write("Hello world!")

// previous open file is garbage-collected;
// you shouldn't rely on this though, not even I know whether to
file = File.load("test.txt", "rb")
System.print(file.read_line())
System.print("size: %(file.tell())")
file.seek(6, "set")
System.print(file.read(5))
file.close()
