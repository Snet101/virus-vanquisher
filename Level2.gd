extends Node2D
# Level 2: Trojan Horse

@onready var player            = $Player
@onready var titan             = $TrojanTitan
@onready var collectibles_node = $Collectibles
@onready var health_bg         = $UI/BossHealthBG
@onready var health_bar        = $UI/BossHealthBG/BossHealthBar
@onready var player_health_bg  = $UI/PlayerHealthBG
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var ammo_bg           = $UI/AmmoBG
@onready var ammo_bar          = $UI/AmmoBG/AmmoBar
@onready var audio_node        = $Audio
@onready var projectiles       = $Projectiles

var enemies_node: Node2D   # Mini viruses

var combat_active = false
var level_finished = false

const AMMO_BAR_MAX_W = 118.0

func _ready():
	_ensure_placeholders()

	# Create enemies node
	enemies_node = Node2D.new()
	enemies_node.name = "Enemies"
	add_child(enemies_node)

	titan.health_changed.connect(_on_titan_health_changed)
	titan.died.connect(_on_titan_died)
	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.ammo_changed.connect(_on_ammo_changed)
	player.died.connect(_on_player_died)
	# Start with 5 ammo
	player.max_ammo = 10
	player.ammo = 5
	_on_ammo_changed(player.ammo, player.max_ammo)

	_set_combat_active(false)
	_show_level_intro(
		"TROJAN HORSE",
		Color(0.85, 0.45, 0.0),
		"Disguised as legitimate, useful software (such as fake app updates or games), Trojans trick users into installing them.",
		func(): player.set_process(true); player.start_falling()
	)

	_spawn_collectibles()

func _on_titan_health_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	health_bar.size.x = (health_bg.size.x - 4) * pct

func _on_player_damaged(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	player_health_bar.size.x = (player_health_bg.size.x - 4) * pct

func _on_ammo_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	ammo_bar.size.x = AMMO_BAR_MAX_W * pct
	if pct > 0.5:
		ammo_bar.color = Color(0.2, 0.6, 1.0)
	elif pct > 0.2:
		ammo_bar.color = Color(1.0, 0.7, 0.1)
	else:
		ammo_bar.color = Color(0.9, 0.1, 0.1)

func _show_level_intro(virus_name: String, accent: Color, description: String, callback: Callable):
	var overlay = preload("res://LevelIntro.gd").new()
	add_child(overlay)
	overlay.show_intro(virus_name, accent, description, func():
		_set_combat_active(true)
		callback.call()
	)

func _set_combat_active(active: bool):
	combat_active = active
	player.set_process(active)
	titan.set_process(active)
	for container_name in ["Projectiles", "Enemies", "Collectibles"]:
		var container = get_node_or_null(container_name)
		if container:
			container.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _on_player_died():
	if level_finished:
		return
	level_finished = true
	_set_combat_active(false)
	_show_death_screen()

func _show_death_screen():
	var cl = CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var overlay = ColorRect.new()
	overlay.anchors_preset = 15
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.5, 0.0, 0.0, 0.0)
	cl.add_child(overlay)
	var lbl = Label.new()
	lbl.text = "YOU DIED"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = 15
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	cl.add_child(lbl)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.75, 0.4)
	tween.tween_interval(1.2)
	tween.tween_callback(func(): get_tree().reload_current_scene())

func _on_titan_died():
	if level_finished:
		return
	level_finished = true
	_set_combat_active(false)
	health_bar.color = Color(0.2, 0.9, 0.3)
	call_deferred("_go_to_level_three")

func _on_player_fired(from_pos, direction):
	spawn_player_projectile(from_pos, direction)
	_play_sfx("SFX_Shoot")

func _on_player_landed():
	_play_sfx("SFX_Land")

func spawn_mini_virus(pos: Vector2):
	var v = Node2D.new()
	v.set_script(load("res://MiniVirus.gd"))
	enemies_node.add_child(v)
	v.global_position = pos

func clear_enemies():
	for e in enemies_node.get_children():
		e.queue_free()

# Fixed collectible layout: mix of fakes and real power-ups
const COLLECTIBLE_LAYOUT = [
	# [type, x, y]
	[0, 80,  100],   # GIFT_BOX    (fake)
	[1, 130, 80],    # GREEN_SHIELD (fake)
	[2, 160, 130],   # SPAM_EMAIL  (fake)
	[3, 70,  60],    # WATER_BOTTLE (real)
	[4, 200, 70],    # ORANGE_SHIELD (real)
	[5, 110, 140],   # FLOPPY_DISK  (real)
	[0, 240, 110],   # GIFT_BOX    (fake)
	[1, 50,  130],   # GREEN_SHIELD (fake)
	[3, 190, 50],    # WATER_BOTTLE (real)
]

func _spawn_collectibles():
	for entry in COLLECTIBLE_LAYOUT:
		var c = Node2D.new()
		c.set_script(load("res://Collectible.gd"))
		c.position = Vector2(entry[1], entry[2])
		c.collectible_type = entry[0]
		collectibles_node.add_child(c)

func spawn_player_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.direction = direction
	p.owner_is_player = true
	p.damage = 25
	projectiles.add_child(p)
	p.global_position = from_pos

func spawn_enemy_projectile(from_pos, direction):
	if not combat_active:
		return
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.direction = direction
	p.owner_is_player = false
	p.speed = 200
	projectiles.add_child(p)
	p.global_position = from_pos

func _go_to_level_three():
	get_tree().change_scene_to_file("res://Level3.tscn")

func _play_sfx(sfx_name: String):
	if audio_node and audio_node.has_node(sfx_name):
		var sfx = audio_node.get_node(sfx_name)
		if sfx and sfx.stream:
			sfx.play()

func _make_tex(col: Color, w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)

func _make_silence() -> AudioStreamWAV:
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 22050
	s.stereo = false
	s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	s.data = PackedByteArray()
	return s

func _ensure_placeholders():
	var bg = get_node_or_null("Background")
	if bg:
		if ResourceLoader.exists("res://assets/background2.png"):
			bg.texture = load("res://assets/background2.png")
		else:
			bg.texture = _make_tex(Color(0.05, 0.05, 0.12), 288, 162)

	# Player sprite
	var psprite: Sprite2D
	if player.has_node("Sprite2D"):
		psprite = player.get_node("Sprite2D")
	else:
		psprite = Sprite2D.new()
		psprite.name = "Sprite2D"
		player.add_child(psprite)
	if ResourceLoader.exists("res://assets/TSA.MC.WaterGunPNG.png"):
		psprite.texture = load("res://assets/TSA.MC.WaterGunPNG.png")
		var sf_p = 40.0 / psprite.texture.get_height()
		psprite.scale = Vector2(sf_p, sf_p)
		player.has_custom_sprite = true

	# Titan sprite
	var tsprite: Sprite2D
	if titan.has_node("Sprite2D"):
		tsprite = titan.get_node("Sprite2D")
	else:
		tsprite = Sprite2D.new()
		tsprite.name = "Sprite2D"
		titan.add_child(tsprite)
	if ResourceLoader.exists("res://assets/titan.png"):
		tsprite.texture = load("res://assets/titan.png")
		var sf_t = 50.0 / tsprite.texture.get_height()
		tsprite.scale = Vector2(sf_t, sf_t)
		titan.has_custom_sprite = true

	for sfx_name in ["SFX_Shoot", "SFX_Land", "SFX_Collect", "SFX_Hurt"]:
		if audio_node and audio_node.has_node(sfx_name):
			var n = audio_node.get_node(sfx_name)
			if n and not n.stream:
				n.stream = _make_silence()
