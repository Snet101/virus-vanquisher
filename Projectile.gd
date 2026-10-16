extends Node2D

var speed = 260
var direction = Vector2(1, 0)
var lifetime = 3.0
var age = 0.0
var damage = 16
var owner_is_player = true

# Engulf DoT
var is_engulf = false
var dot_timer = 0.0
var _engulf_entered = false   # true on first contact
const DOT_INTERVAL = 0.25    # damage tick rate
const ENGULF_RADIUS = 28.0

func _process(delta):
	# Enemy proj slower for dodging
	var proj_speed = speed
	global_position += direction.normalized() * proj_speed * delta
	age += delta
	if age >= lifetime:
		queue_free()
		return

	var root = get_parent().get_parent()
	if not root:
		return
	var level_position = root.to_local(global_position)
	if level_position.x < -30 or level_position.x > 320 or level_position.y < -30 or level_position.y > 200:
		queue_free()
		return

	if owner_is_player:
		_try_hit_bosses(root)
		if not is_queued_for_deletion():
			_try_hit_enemies(root)
	else:
		_try_hit_player(root, delta)

	queue_redraw()

func _try_hit_bosses(root):
	for boss_name in ["RansomwareRex", "TrojanTitan", "WormKing"]:
		var boss = root.get_node_or_null(boss_name)
		if not boss:
			continue
		if boss.get("stunned") == true:
			continue
		if global_position.distance_to(boss.global_position) < 50:
			if boss.has_method("take_damage"):
				boss.take_damage(damage)
			if boss.has_method("_on_hit_flash"):
				boss._on_hit_flash()
			queue_free()
			return

func _try_hit_enemies(root):
	var enemies = root.get_node_or_null("Enemies")
	if not enemies:
		return
	for enemy in enemies.get_children():
		if global_position.distance_to(enemy.global_position) < 18:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			queue_free()
			return

func _try_hit_player(root, delta):
	var player = root.get_node_or_null("Player")
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	var radius = ENGULF_RADIUS if is_engulf else 18.0

	if dist >= radius:
		dot_timer = 0.0
		_engulf_entered = false
		return
	if not is_engulf:
		player.take_damage(damage)
		queue_free()
		return
	if not _engulf_entered:
		_engulf_entered = true
		dot_timer = 0.0
		player.take_damage(damage)
	else:
		dot_timer += delta
		while dot_timer >= DOT_INTERVAL:
			dot_timer -= DOT_INTERVAL
			if not is_instance_valid(player) or player.is_queued_for_deletion():
				break
			player.take_damage(damage)

func _draw():
	if is_engulf:
		# Pulsing blob
		var pulse = 0.75 + 0.25 * sin(age * 7.0)
		var r = ENGULF_RADIUS * pulse
		draw_circle(Vector2.ZERO, r, Color(0.25, 0.75, 0.1, 0.55))
		draw_circle(Vector2.ZERO, r * 0.6, Color(0.4, 0.9, 0.15, 0.75))
		# Tentacles
		for i in range(5):
			var angle = i * TAU / 5.0 + age * 3.0
			var tip = Vector2(cos(angle), sin(angle)) * (r + 8.0 * pulse)
			draw_line(Vector2.ZERO, tip, Color(0.3, 0.85, 0.1, 0.5), 2)
		# Eyes
		draw_circle(Vector2(-3, -2), 3, Color(0.9, 0.95, 0.1))
		draw_circle(Vector2(3, -2), 3, Color(0.9, 0.95, 0.1))
		draw_circle(Vector2(-3, -2), 1.5, Color(0.0, 0.0, 0.0))
		draw_circle(Vector2(3, -2), 1.5, Color(0.0, 0.0, 0.0))
	elif owner_is_player:
		draw_circle(Vector2.ZERO, 4, Color(0.3, 0.7, 1.0))
		draw_circle(Vector2.ZERO, 2, Color(0.8, 0.95, 1.0))
	else:
		draw_circle(Vector2.ZERO, 3, Color(0.9, 0.2, 0.1))
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1.0, 0.5, 0.1), 1)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color(1.0, 0.5, 0.1), 1)
