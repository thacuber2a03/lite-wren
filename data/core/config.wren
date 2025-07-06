class Config {
	static fps { __fps }
	static fps=(v) { __fps = v }
	static messageTimeout { __messageTimeout }
	static messageTimeout=(v) { __messageTimeout = v }
}

Config.fps = 60
Config.messageTimeout = 60
