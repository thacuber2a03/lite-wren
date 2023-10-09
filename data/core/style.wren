import "api" for Program, Font
import "core/shapes" for Vector
import "core/common" for Common

class Style {
	static padding            { __padding }
	static padding=(v)        { __padding = v }
	static scrollbar_size     { __scrollbar_size }
	static scrollbar_size=(v) { __scrollbar_size = v }

	static font          { __font }
	static font=(v)      { __font = v }
	static big_font      { __big_font }
	static big_font=(v)  { __big_font = v }
	static code_font     { __code_font }
	static code_font=(v) { __code_font = v }
	static icon_font     { __icon_font }
	static icon_font=(v) { __icon_font = v }

	static background     { __background }
	static background=(v) { __background = v }
	static dim            { __dim }
	static dim=(v)        { __dim = v }
	static scrollbar      { __scrollbar }
	static scrollbar=(v)  { __scrollbar = v }
	static scrollbar2     { __scrollbar2 }
	static scrollbar2=(v) { __scrollbar2 = v }
}

Style.padding        = Vector.new((14 * Program.SCALE).round, (7 * Program.SCALE).round)
Style.scrollbar_size = (4 * Program.SCALE).round

Style.font      = Font.load(Program.EXEDIR + "/data/fonts/font.ttf", 14 * Program.SCALE)
Style.big_font  = Font.load(Program.EXEDIR + "/data/fonts/font.ttf", 34 * Program.SCALE)
Style.icon_font = Font.load(Program.EXEDIR + "/data/fonts/icons.ttf", 14 * Program.SCALE)
Style.code_font = Font.load(Program.EXEDIR + "/data/fonts/monospace.ttf", 13.5 * Program.SCALE)

Style.background = Common.color("#2e2e32")
Style.dim        = Common.color("#525257")
Style.scrollbar  = Common.color("#414146")
Style.scrollbar2 = Common.color("#4b4b52")
