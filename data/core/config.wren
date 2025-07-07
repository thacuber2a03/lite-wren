import "system" for Program

class Config {
	static projectScanRate { __projectScanRate }
	static projectScanRate=(v) { __projectScanRate=v }
	static fps { __fps }
	static fps=(v) { __fps=v }
	static maxLogItems { __maxLogItems }
	static maxLogItems=(v) { __maxLogItems=v }
	static messageTimeout { __messageTimeout }
	static messageTimeout=(v) { __messageTimeout=v }
	static mouseWheelScroll { __mouseWheelScroll }
	static mouseWheelScroll=(v) { __mouseWheelScroll=v }
	static fileSizeLimit { __fileSizeLimit }
	static fileSizeLimit=(v) { __fileSizeLimit=v }
	static ignoreFiles { __ignoreFiles }
	static ignoreFiles=(v) { __ignoreFiles=v }
	static symbolPattern { __symbolPattern }
	static symbolPattern=(v) { __symbolPattern=v }
	static nonWordChars { __nonWordChars }
	static nonWordChars=(v) { __nonWordChars=v }
	static undoMergeTimeout { __undoMergeTimeout }
	static undoMergeTimeout=(v) { __undoMergeTimeout=v }
	static maxUndos { __maxUndos }
	static maxUndos=(v) { __maxUndos=v }
	static highlightCurrentLine { __highlightCurrentLine }
	static highlightCurrentLine=(v) { __highlightCurrentLine=v }
	static lineHeight { __lineHeight }
	static lineHeight=(v) { __lineHeight=v }
	static indentSize { __indentSize }
	static indentSize=(v) { __indentSize=v }
	static tabType { __tabType }
	static tabType=(v) { __tabType=v }
	static lineLimit { __lineLimit }
	static lineLimit=(v) { __lineLimit=v }
}

Config.projectScanRate = 5
Config.fps = 60
Config.maxLogItems = 80
Config.messageTimeout = 3
Config.mouseWheelScroll = 50 * Program.scale
Config.fileSizeLimit = 10

// TODO(thacuber2a03): what do I do regarding the patterns...
Config.ignoreFiles = "^\%."
Config.symbolPattern = "[\%a_][\%w_]*"
Config.nonWordChars = " \t\n/\\()\"':,.;<>~!@#$\%^&*|+=[]{}`?-"

Config.undoMergeTimeout = 0.3
Config.maxUndos = 10000
Config.highlightCurrentLine = true
Config.lineHeight = 1.2
Config.indentSize = 2
Config.tabType = "soft"
Config.lineLimit = 80
