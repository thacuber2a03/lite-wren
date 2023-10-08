import "prelude" for Program

class Core {
	static init() {
	}

	static run() {
		Program.wait_event()
		System.print(Program.poll_event())
	}

	static on_error(err) {
		
	}
}
