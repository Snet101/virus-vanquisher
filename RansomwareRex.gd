extends Node2D

signal health_changed(current, max)
signal died()

var max_health = 200
var health = 200
var stunned = false
var has_custom_sprite = false
var attack_cooldown = 1.6
var attack_timer = 0.5
var attack_variance = 0.9
var hit_flash = 0.0
var _base_pos = Vector2.ZERO
var _move_t = 0.0

func _ready():
	_base_pos = position
	health_changed.emit(health, max_health)

func _process(delta):
	if stunned:
		return
	# Lissajous path
	_move_t += delta
	position.x = clamp(144.0 + sin(_move_t * 2.2) * 85.0 + sin(_move_t * 3.7) * 28.0, 50.0, 258.0)
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
			var spread_angle = randf_range(-0.5, 0.5)  # ±0.5 rad
			dir = dir.rotated(spread_angle)
			if lvl.has_method("spawn_enemy_projectile"):
				lvl.spawn_enemy_projectile(global_position + Vector2(0, -10), dir)
	queue_redraw()

func _on_hit_flash():
	hit_flash = 0.25

func take_damage(amount):
	if stunned:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_on_death()

func _on_death():
	stunned = true
	queue_redraw()  # update() → queue_redraw()
	died.emit()

func _draw():
	if has_custom_sprite:
		return
	if stunned:
		# Defeated
		draw_rect(Rect2(Vector2(-40, -25), Vector2(80, 50)), Color(0.6, 0.1, 0.1))
		draw_line(Vector2(-20, -18), Vector2(-32, -40), Color(0.95, 0.8, 0.6), 3)
		draw_line(Vector2(20, -18), Vector2(32, -40), Color(0.95, 0.8, 0.6), 3)
	else:
		var base_col = Color(0.4, 0.0, 0.6)
		if hit_flash > 0.0:
			base_col = base_col.lightened(0.4)
		# Body
		draw_rect(Rect2(Vector2(-40, -25), Vector2(80, 50)), base_col)
		# Lock particles
		for i in range(5):
			var x = -24 + i * 12
			draw_rect(Rect2(Vector2(x, -36), Vector2(8, 8)), Color(0.9, 0.2, 0.2))
