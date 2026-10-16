extends Node2D

var health = 50
var speed = 80
var direction = Vector2(1, 0)
var attack_cooldown = 0.0

func _ready():
	set_process(true)

func _process(delta):
	global_position += direction * speed * delta
	# AI: chase player
	var lvl = get_parent().get_parent()
	if lvl and lvl.has_node("Player"):
		var player = lvl.get_node("Player")
		direction = (player.global_position - global_position).normalized()
		attack_cooldown = max(0.0, attack_cooldown - delta)
		if global_position.distance_to(player.global_position) < 12.0 and attack_cooldown <= 0.0:
			player.take_damage(8)
			attack_cooldown = 1.0

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _draw():
	draw_rect(Rect2(Vector2(-5, -4), Vector2(10, 8)), Color(0.5, 0.8, 0.2))
	draw_circle(Vector2(-2, -1), 1, Color(0.9, 0.95, 0.2))
	draw_circle(Vector2(2, -1), 1, Color(0.9, 0.95, 0.2))
