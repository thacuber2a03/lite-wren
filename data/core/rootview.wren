import "core/style" for Style
import "core/view" for View

class RootView is View {
	construct new() {
		super()
	}

	draw() {
		draw_background(Style.background)
	}
}
