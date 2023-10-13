import "api" for Program

class Config {
  static fps                    { __fps }
  static fps=(v)                { __fps = v }
  static message_timeout        { __message_timeout }
  static message_timeout=(v)    { __message_timeout = v }
  static mouse_wheel_scroll     { __mouse_wheel_scroll }
  static mouse_wheel_scroll=(v) { __mouse_wheel_scroll = v }
  static line_height            { __line_height }
  static line_height=(v)        { __line_height = v }
  static indent_size            { __indent_size }
  static indent_size=(v)        { __indent_size = v }
  static line_limit             { __line_limit }
  static line_limit=(v)         { __line_limit = v }
}

Config.fps = 60
Config.message_timeout = 3
Config.mouse_wheel_scroll = 50 * Program.SCALE
Config.line_height = 1.2
Config.indent_size = 2
Config.line_limit = 80
