import "api" for Program

class Config {
  static fps                        { __fps }
  static fps=(v)                    { __fps = v }
  static message_timeout            { __message_timeout }
  static message_timeout=(v)        { __message_timeout = v }
  static mouse_wheel_scroll         { __mouse_wheel_scroll }
  static mouse_wheel_scroll=(v)     { __mouse_wheel_scroll = v }
  static file_size_limit            { __file_size_limit }
  static file_size_limit=(v)        { __file_size_limit = v }
  static undo_merge_timeout         { __undo_merge_timeout }
  static undo_merge_timeout=(v)     { __undo_merge_timeout = v }
  static max_undos                  { __max_undos }
  static max_undos=(v)              { __max_undos = v }
  static highlight_current_line     { __highlight_current_line }
  static highlight_current_line=(v) { __highlight_current_line = v }
  static line_height                { __line_height }
  static line_height=(v)            { __line_height = v }
  static indent_size                { __indent_size }
  static indent_size=(v)            { __indent_size = v }
  static tab_type                   { __tab_type }
  static tab_type=(v)               { __tab_type = v }
  static line_limit                 { __line_limit }
  static line_limit=(v)             { __line_limit = v }
}

Config.fps = 60
Config.message_timeout = 3
Config.mouse_wheel_scroll = 50 * Program.SCALE
Config.file_size_limit = 10
Config.undo_merge_timeout = 0.3
Config.max_undos = 10000
Config.highlight_current_line = true
Config.line_height = 1.2
Config.indent_size = 2
Config.tab_type = "soft"
Config.line_limit = 80
