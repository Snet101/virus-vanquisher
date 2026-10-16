extends Node2D

# Tiny trap enemy from Gift Box

var health = 20
var speed = 55
var _direction = Vector2.RIGHT
var _attack_cooldown = 0.0
const CONTACT_DAMAGE = 8
const CONTACT_RADIUS = 12.0

func _process(delta):
	# Chase player
	var level = get_parent().get_parent()
	if level and level.has_node("Player"):
		var player = level.get_node("Player")
		_direction = (player.global_position - global_position).normalized()

		# Contact damage
		_attack_cooldown = max(0.0, _attack_cooldown - delta)
		if global_position.distance_to(player.global_position) < CONTACT_RADIUS and _attack_cooldown <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(CONTACT_DAMAGE)
			_attack_cooldown = 1.0

	global_position += _direction * speed * delta
	queue_redraw()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _draw():
	# Virus sprite
	draw_circle(Vector2.ZERO, 6, Color(0.85, 0.1, 0.1))
	draw_circle(Vector2.ZERO, 3, Color(0.6, 0.0, 0.0))
	# Spikes
	for i in range(6):
		var angle = i * TAU / 6
		var tip = Vector2(cos(angle), sin(angle)) * 10
		var base = Vector2(cos(angle), sin(angle)) * 6
		draw_line(base, tip, Color(0.9, 0.2, 0.1), 2)
	# Eyes
	draw_circle(Vector2(-2, -1), 1, Color(1, 1, 0))
	draw_circle(Vector2(2, -1), 1, Color(1, 1, 0))
