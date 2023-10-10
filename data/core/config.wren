import "api" for Program

class Config {
  static fps { __fps }
  static fps=(v) { __fps = v }
  static message_timeout { __message_timeout }
  static message_timeout=(v) { __message_timeout = v }
  static mouse_wheel_scroll { __mouse_wheel_scroll }
  static mouse_wheel_scroll=(v) { __mouse_wheel_scroll = v }
}

Config.fps = 60
Config.message_timeout = 3
Config.mouse_wheel_scroll = 50 * Program.SCALE
