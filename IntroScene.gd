extends Node2D

# Nodes
@onready var starter_screen = $StarterScreenLayer/StarterScreen
@onready var start_button    = $StarterScreenLayer/StarterScreen/StartButton
@onready var background      = $Background
@onready var character       = $Character
@onready var tv_glow         = $TVGlow
@onready var tv_flicker      = $TVFlicker
@onready var glitch_overlay  = $GlitchOverlay
@onready var fade_overlay    = $FadeOverlay
@onready var speech_bubble   = $SpeechBubble

# TV center
var tv_center = Vector2(120, 45)

var idle_time = 3.5
var elapsed = 0.0
var sequence_started = false
var flicker_timer = 0.0
var flicker_interval = 0.18
var flicker_on = false
var animation_started = false

func _ready():
	# Hide anims
	background.visible = false
	character.visible = false
	tv_glow.visible = false
	tv_flicker.visible = false
	glitch_overlay.visible = false
	speech_bubble.visible = false
	
	# Connect button
	print("Looking for StartButton...")
	print("Starter screen node path: ", starter_screen.get_path())
	
	if not start_button:
		print("ERROR: start_button is null!")
		# Find manually
		var btn = get_node_or_null("StarterScreenLayer/StarterScreen/StartButton")
		if btn:
			print("Found button manually")
			start_button = btn
		else:
			print("Could not find button at expected path")
			return
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.grab_focus()

func _process(delta):
	if not animation_started:
		return
		
	elapsed += delta

	if not sequence_started:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			flicker_on = !flicker_on
			var flicker_alpha = randf_range(0.03, 0.12) if flicker_on else 0.0
			tv_flicker.modulate.a = flicker_alpha
			var glow_alpha = randf_range(0.28, 0.45)
			tv_glow.modulate.a = glow_alpha

	if elapsed >= idle_time and not sequence_started:
		sequence_started = true
		start_suck_in()

func _input(event):
	# Keyboard fallback
	if not animation_started and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_start_pressed()
			get_tree().root.set_input_as_handled()

func _on_start_pressed():
	if animation_started:
		return
	print("START button pressed!")
	# Show anim elements
	starter_screen.visible = false
	background.visible = true
	character.visible = true
	tv_glow.visible = true
	tv_flicker.visible = true
	glitch_overlay.visible = true
	speech_bubble.visible = true
	
	# Start sequence
	animation_started = true
	_start_tv_pulse()
	elapsed = 0.0
	sequence_started = false

func _start_tv_pulse():
	var tween = create_tween().set_loops()
	tween.tween_property(tv_glow, "modulate:a", 0.6, 0.5)
	tween.tween_property(tv_glow, "modulate:a", 0.25, 0.5)

func start_suck_in():
	var tween = create_tween()

	# Hide bubble
	tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.3)

	# Flicker burst
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		tv_flicker.color = Color(0.24, 0.96, 1.0, 0.0)
	)

	for i in range(8):
		tween.tween_property(tv_flicker, "modulate:a", randf_range(0.5, 0.9), 0.04)
		tween.tween_property(tv_flicker, "modulate:a", 0.0, 0.04)

	# Shrink character
	tween.tween_interval(0.1)
	tween.parallel().tween_property(
		character, "position", tv_center, 0.75
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		character, "scale", Vector2(0.0, 0.0), 0.75
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		character, "rotation_degrees", 720.0, 0.75
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Flash
	tween.tween_property(glitch_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.85, 0.06)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.06)

	# Fade to level
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)
	tween.tween_callback(go_to_level_one)

func go_to_level_one():
	get_tree().change_scene_to_file("res://Level1.tscn")
