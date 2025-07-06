import "renderer" for Font
import "system" for Program

import "core/common" for Common, Vector

class Style {
	static padding { __padding }
	static padding=(v) { __padding=v }
	static dividerSize { __dividerSize }
	static dividerSize=(v) { __dividerSize=v }

	static font { __font }
	static font=(v) { __font=v }
	static bigFont { __bigFont }
	static bigFont=(v) { __bigFont=v }
	static iconFont { __iconFont }
	static iconFont=(v) { __iconFont=v }
	static codeFont { __codeFont }
	static codeFont=(v) { __codeFont=v }

	static background { __background }
	static background=(v) { __background=v }
	static background2 { __background2 }
	static background2=(v) { __background2=v }
	static dim { __dim }
	static dim=(v) { __dim=v }
	static text { __text }
	static text=(v) { __text=v }
}

Style.padding = Vector.new((14 * Program.scale).round, (7 * Program.scale).round)
Style.dividerSize = Program.scale.round

Style.font = Font.load("%(Program.executableDirectory)/data/fonts/font.ttf", 14 * Program.scale)
Style.bigFont = Font.load("%(Program.executableDirectory)/data/fonts/font.ttf", 34 * Program.scale)
Style.iconFont = Font.load("%(Program.executableDirectory)/data/fonts/icons.ttf", 14 * Program.scale)

Style.background = Common.color("#2e2e32")
Style.background2 = Common.color("#252529")
Style.dim = Common.color("#525257")
Style.text = Common.color("#97979c")
