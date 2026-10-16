extends CanvasLayer
# One dismiss path shared by the button and the timeout.
var dismissed = false
var panel: Control
var timer: Timer

func show_intro(virus_name: String, accent: Color, description: String, callback: Callable):
	layer = 20
	panel = Control.new()
	panel.size = Vector2(288, 162)
	add_child(panel)
	var bg = ColorRect.new()
	bg.size = Vector2(288, 162)
	bg.color = Color(0.02, 0.02, 0.08, 0.95)
	panel.add_child(bg)
	var title = Label.new()
	title.text = "VIRUS ALERT: " + virus_name
	title.position = Vector2(0, 6)
	title.size = Vector2(288, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", accent)
	panel.add_child(title)
	var desc = Label.new()
	desc.name = "Description"
	desc.text = description + "\n\nArrows: move/jump (double jump)\nSpace: fire | R: reload"
	desc.position = Vector2(12, 30)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 8)
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.size = Vector2(264, 94)
	panel.add_child(desc)
	desc.set_deferred("size", Vector2(264, 94))
	var button = Button.new()
	button.name = "FightButton"
	button.text = "TAP TO FIGHT"
	button.position = Vector2(84, 132)
	button.add_theme_font_size_override("font_size", 7)
	button.size = Vector2(120, 24)
	panel.add_child(button)
	button.set_deferred("size", Vector2(120, 24))
	button.pressed.connect(dismiss.bind(callback))
	button.grab_focus()
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 6.0
	add_child(timer)
	timer.timeout.connect(dismiss.bind(callback))
	timer.start()

func dismiss(callback: Callable):
	if dismissed:
		return
	dismissed = true
	timer.stop()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		callback.call()
		queue_free()
	)
