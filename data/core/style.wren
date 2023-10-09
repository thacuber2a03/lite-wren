import "api" for Program, Font
import "core/shapes" for Vector
import "core/common" for Common

class Style {
	static padding            { __padding }
	static padding=(v)        { __padding = v }
	static divider_size       { __divider_size }
	static divider_size=(v)   { __divider_size = v}
	static scrollbar_size     { __scrollbar_size }
	static scrollbar_size=(v) { __scrollbar_size = v }
	static caret_width        { __caret_width }
	static caret_width=(v)    { __caret_width = v }
	static tab_width          { __tab_width }
	static tab_width=(v)      { __tab_width = v }

	static font          { __font }
	static font=(v)      { __font = v }
	static big_font      { __big_font }
	static big_font=(v)  { __big_font = v }
	static code_font     { __code_font }
	static code_font=(v) { __code_font = v }
	static icon_font     { __icon_font }
	static icon_font=(v) { __icon_font = v }

	static background         { __background }
	static background=(v)     { __background = v }
	static background2        { __background2 }
	static background2=(v)    { __background2 = v }
	static background3        { __background3 }
	static background3=(v)    { __background3 = v }
	static text               { __text }
	static text=(v)           { __text = v }
	static caret              { __caret }
	static caret =(v)         { __caret = v }
	static accent             { __accent }
	static accent=(v)         { __accent = v }
	static dim                { __dim }
	static dim=(v)            { __dim = v }
	static divider            { __divider }
	static divider=(v)        { __divider = v }
	static selection          { __selection }
	static selection=(v)      { __selection = v }
	static line_number        { __line_number }
	static line_number=(v)    { __line_number = v }
	static line_number2       { __line_number2 }
	static line_number2=(v)   { __line_number2 = v }
	static line_highlight     { __line_highlight }
	static line_highlight=(v) { __line_highlight = v }
	static scrollbar          { __scrollbar }
	static scrollbar=(v)      { __scrollbar = v }
	static scrollbar2         { __scrollbar2 }
	static scrollbar2=(v)     { __scrollbar2 = v }

	static syntax { __syntax }
	static syntax=(v) { __syntax = v }
}

Style.padding        = Vector.new((14 * Program.SCALE).round, (7 * Program.SCALE).round)
Style.divider_size   = (1 * Program.SCALE).round
Style.scrollbar_size = (4 * Program.SCALE).round
Style.caret_width    = (2 * Program.SCALE).round
Style.tab_width      = (170 * Program.SCALE).round

Style.font      = Font.load(Program.EXEDIR + "/data/fonts/font.ttf", 14 * Program.SCALE)
Style.big_font  = Font.load(Program.EXEDIR + "/data/fonts/font.ttf", 34 * Program.SCALE)
Style.icon_font = Font.load(Program.EXEDIR + "/data/fonts/icons.ttf", 14 * Program.SCALE)
Style.code_font = Font.load(Program.EXEDIR + "/data/fonts/monospace.ttf", 13.5 * Program.SCALE)

Style.background     = Common.color("#2e2e32")
Style.background2    = Common.color("#252529")
Style.background3    = Common.color("#252529")
Style.text           = Common.color("#97979c")
Style.caret          = Common.color("#93ddfa")
Style.accent         = Common.color("#e1e1e6")
Style.dim            = Common.color("#525257")
Style.divider        = Common.color("#202024")
Style.selection      = Common.color("#48484f")
Style.line_number    = Common.color("#525259")
Style.line_number2   = Common.color("#83838f")
Style.line_highlight = Common.color("#343438")
Style.scrollbar      = Common.color("#414146")
Style.scrollbar2     = Common.color("#4b4b52")

Style.syntax = {}
