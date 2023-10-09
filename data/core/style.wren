import "api" for Program
import "core/common" for Common

class Style {
	static scrollbar_size { __scrollbar_size }
	static scrollbar_size=(v) { __scrollbar_size = v }

	static background { __background }
	static background=(v) { __background = v }
	static scrollbar { __scrollbar }
	static scrollbar=(v) { __scrollbar = v }
	static scrollbar2 { __scrollbar2 }
	static scrollbar2=(v) { __scrollbar2 = v }
}

Style.scrollbar_size = (4 * Program.SCALE).round

Style.background = Common.color("#2e2e32")
Style.scrollbar = Common.color("#414146")
Style.scrollbar2 = Common.color("#4b4b52")
