// WARNING: this test file is not actually a core part of the editor!
import "api" for File

var file = File.load("test.txt", "w+b")
file.write("Hello world!")

// previous file is garbage-collected;
// you shouldn't rely on this though, not even I know whether to
file = File.load("test.txt", "rb")
var str = file.read_line()
System.print(str)
file.close()
