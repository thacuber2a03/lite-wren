import "renderer" for Font
import "system" for Program

import "core/common" for Common, Vector

class Style {
	static padding { __padding }
	static padding=(v) { __padding=v }

	static font { __font }
	static font=(v) { __font=v }
	static bigFont { __bigFont }
	static bigFont=(v) { __bigFont=v }

	static background { __background }
	static background=(v) { __background=v }
	static dim { __dim }
	static dim=(v) { __dim=v }
}

Style.padding = Vector.new((14 * Program.scale).round, (7 * Program.scale).round)

Style.font = Font.load("data/fonts/font.ttf", 14 * Program.scale)
Style.bigFont = Font.load("data/fonts/font.ttf", 34 * Program.scale)

Style.background = Common.color("#2e2e32")
Style.dim = Common.color("#525257")
