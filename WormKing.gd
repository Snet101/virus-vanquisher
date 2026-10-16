extends Node2D
signal health_changed(current, max)
signal died()
signal split(pos, count)
var max_health = 500
var health = 500
var stunned = false
var has_custom_sprite = false
var attack_cooldown = 1.4
var attack_timer = 0.5
var attack_variance = 0.6
var hit_flash = 0.0
var splits_left = 5
var _move_t = 0.0
func _ready():
	health_changed.emit(health, max_health)
func _process(delta):
	if stunned:
		return
	# Lissajous path
	_move_t += delta
	position.x = clamp(144.0 + sin(_move_t * 2.0) * 78.0 + sin(_move_t * 3.5) * 25.0, 50.0, 258.0)
	position.y = clamp(68.0 + sin(_move_t * 1.5) * 38.0 + sin(_move_t * 2.7) * 16.0, 30.0, 120.0)
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown + randf() * attack_variance
		var lvl = get_parent()
		if lvl and lvl.has_node("Player"):
			var player = lvl.get_node("Player")
			var dir = (player.global_position - global_position).normalized()
			# Attack with spread
			var spread_angle = randf_range(-0.6, 0.6)  # ±0.6 rad
			dir = dir.rotated(spread_angle)
			if lvl.has_method("spawn_enemy_projectile"):
				lvl.spawn_enemy_projectile(global_position + Vector2(0, -10), dir)
	queue_redraw()
func take_damage(amount):
	if stunned:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_on_death()
	else:
		hit_flash = 0.25
		if splits_left > 0:
			splits_left -= 1
			split.emit(global_position, 2)
			# Grab audio
			var lvl = get_parent()
			if lvl and lvl.has_node("Audio"):
				var audio_node = lvl.get_node("Audio")
				if audio_node.has_node("SFX_Split"):
					var sfx = audio_node.get_node("SFX_Split")
					if sfx and sfx.stream:
						sfx.play()
func _on_death():
	stunned = true
	queue_redraw()  # update() → queue_redraw()
	died.emit()
func _draw():
	if has_custom_sprite:
		return
	if stunned:
		# Defeated
		draw_rect(Rect2(Vector2(-40, -25), Vector2(80, 50)), Color(0.5, 0.8, 0.2))
		draw_line(Vector2(-20, -18), Vector2(-32, -40), Color(0.95, 0.8, 0.6), 3)
		draw_line(Vector2(20, -18), Vector2(32, -40), Color(0.95, 0.8, 0.6), 3)
	else:
		var base_col = Color(0.5, 0.8, 0.2)
		if hit_flash > 0.0:
			base_col = base_col.lightened(0.4)
		# Body
		draw_rect(Rect2(Vector2(-40, -25), Vector2(80, 50)), base_col)
		# Segments
		for i in range(1, 4):
			var x = -40 + i * 20
			draw_line(Vector2(x, -25), Vector2(x, 25), Color(0.3, 0.6, 0.1, 0.5), 2)
		# Crown
		for i in range(5):
			var x = -24 + i * 12
			draw_rect(Rect2(Vector2(x, -38), Vector2(6, 13)), Color(0.7, 0.9, 0.4))
		# Eyes
		draw_circle(Vector2(-14, -8), 7, Color(0.9, 0.95, 0.2))
		draw_circle(Vector2(14, -8), 7, Color(0.9, 0.95, 0.2))
		draw_circle(Vector2(-14, -8), 3, Color(0.0, 0.0, 0.0))
		draw_circle(Vector2(14, -8), 3, Color(0.0, 0.0, 0.0))
