import "system" for Program
import "renderer" for Font

import "core/common" for Common, Vector

class Style {
	static padding { __padding }
	static padding=(v) { __padding=v }
	static dividerSize { __dividerSize }
	static dividerSize=(v) { __dividerSize=v }
	static scrollbarSize { __scrollbarSize }
	static scrollbarSize=(v) { __scrollbarSize=v }
	static caretWidth { __caretWidth }
	static caretWidth=(v) { __caretWidth=v }
	static tabWidth { __tabWidth }
	static tabWidth=(v) { __tabWidth=v }
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
	static background3 { __background3 }
	static background3=(v) { __background3=v }
	static text { __text }
	static text=(v) { __text=v }
	static caret { __caret }
	static caret=(v) { __caret=v }
	static accent { __accent }
	static accent=(v) { __accent=v }
	static dim { __dim }
	static dim=(v) { __dim=v }
	static divider { __divider }
	static divider=(v) { __divider=v }
	static selection { __selection }
	static selection=(v) { __selection=v }
	static lineNumber { __lineNumber }
	static lineNumber=(v) { __lineNumber=v }
	static lineNumber2 { __lineNumber2 }
	static lineNumber2=(v) { __lineNumber2=v }
	static lineHighlight { __lineHighlight }
	static lineHighlight=(v) { __lineHighlight=v }
	static scrollbar { __scrollbar }
	static scrollbar=(v) { __scrollbar=v }
	static scrollbar2 { __scrollbar2 }
	static scrollbar2=(v) { __scrollbar2=v }
	static syntax { __syntax }
	static syntax=(v) { __syntax=v }
}


Style.padding = (Vector.new(14, 7) * Program.scale).round
Style.dividerSize = (1 * Program.scale).round
Style.scrollbarSize = (4 * Program.scale).round
Style.caretWidth = (2 * Program.scale).round
Style.tabWidth = (170 * Program.scale).round

Style.font = Font.load("%(Program.exeDir)/data/fonts/font.ttf", 14 * Program.scale)
Style.bigFont = Font.load("%(Program.exeDir)/data/fonts/font.ttf", 34 * Program.scale)
Style.iconFont = Font.load("%(Program.exeDir)/data/fonts/icons.ttf", 14 * Program.scale)
Style.codeFont = Font.load("%(Program.exeDir)/data/fonts/monospace.ttf", 13.5 * Program.scale)

Style.background = Common.color("#2e2e32")
Style.background2 = Common.color("#252529")
Style.background3 = Common.color("#252529")
Style.text = Common.color("#97979c")
Style.caret = Common.color("#93DDFA")
Style.accent = Common.color("#e1e1e6")
Style.dim = Common.color("#525257")
Style.divider = Common.color("#202024")
Style.selection = Common.color("#48484f")
Style.lineNumber = Common.color("#525259")
Style.lineNumber2 = Common.color("#83838f")
Style.lineHighlight = Common.color("#343438")
Style.scrollbar = Common.color("#414146")
Style.scrollbar2 = Common.color("#4b4b52")

Style.syntax = {}
