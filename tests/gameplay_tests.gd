extends SceneTree
var checks = 0
var failures = 0

func check(value, description):
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func _initialize():
	call_deferred("run_tests")

func make_player(parent):
	var player = preload("res://Player.gd").new()
	player.name = "Player"
	parent.add_child(player)
	player.set_process(false)
	return player

func run_tests():
	var world = Node2D.new()
	root.add_child(world)
	var player = make_player(world)
	player.start_falling()
	for i in range(100):
		player._process(1.0 / 60)
	check(player.state == player.State.WALKING, "initial fall/rub transitions to walking")
	check(player.position.y == player.ground_y, "landing clamps to ground")
	Input.action_press("ui_right")
	var before = player.position.x
	player._process(0.1)
	Input.action_release("ui_right")
	check(is_equal_approx(player.position.x - before, 15), "movement runs once per frame")
	await process_frame
	Input.action_press("ui_up")
	player._process(0.01)
	Input.action_release("ui_up")
	check(player.jumps_left == 1 and player.velocity.y < 0, "first jump")
	await process_frame
	Input.action_press("ui_up")
	player._process(0.01)
	Input.action_release("ui_up")
	check(player.jumps_left == 0 and player.velocity.y < 0, "second jump")
	await process_frame
	player.velocity.y = 10
	Input.action_press("ui_up")
	player._process(0.01)
	Input.action_release("ui_up")
	check(player.velocity.y > 0, "third jump rejected")
	await process_frame
	for i in range(100):
		player._process(1.0 / 60)
	check(player.state == player.State.WALKING and player.jumps_left == 2, "later landing restores jumps without intro rub")
	await process_frame
	var shots = [0]
	player.fired.connect(func(_pos, _direction): shots[0] += 1)
	Input.action_press("ui_accept")
	player._process(0.01)
	Input.action_release("ui_accept")
	check(shots[0] == 1 and player.ammo == 9, "one fire action consumes one ammo")
	player.ammo = 0
	player._try_fire()
	check(shots[0] == 1, "empty weapon cannot fire")
	await process_frame
	Input.action_press("reload")
	player._process(0.01)
	Input.action_release("reload")
	player._try_fire()
	check(shots[0] == 1 and player.reload_timer > 0, "reload blocks fire")
	player._process(0.8)
	check(player.ammo == player.max_ammo, "reload recovers empty ammo")
	player.apply_invincible(1)
	player.take_damage(20)
	check(player.health == 100, "invincibility blocks damage")
	player.invincible_timer = 0
	player.take_damage(20)
	check(player.health == 80, "normal damage")
	player.apply_slow(1)
	before = player.position.x
	Input.action_press("ui_right")
	player._process(0.1)
	Input.action_release("ui_right")
	check(is_equal_approx(player.position.x-before, 6), "slow movement multiplier")
	player.slow_timer = 0
	player.apply_invert(1)
	before = player.position.x
	Input.action_press("ui_right")
	player._process(0.1)
	Input.action_release("ui_right")
	check(player.position.x < before, "inverted horizontal movement")
	player.invert_timer = 0
	var projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	projectiles.position = Vector2(15, 0)
	world.add_child(projectiles)
	var enemies = Node2D.new()
	enemies.name = "Enemies"
	enemies.position = Vector2(-10, 0)
	world.add_child(enemies)
	var enemy = preload("res://tests/DamageTarget.gd").new()
	enemies.add_child(enemy)
	enemy.global_position = Vector2(100, 100)
	var bullet = preload("res://Projectile.gd").new()
	projectiles.add_child(bullet)
	bullet.set_process(false)
	bullet.global_position = enemy.global_position
	bullet._process(0)
	check(enemy.hits == 1 and bullet.is_queued_for_deletion(), "world-space enemy collision")
	await process_frame
	var boss = preload("res://tests/DamageTarget.gd").new()
	boss.name = "RansomwareRex"
	world.add_child(boss)
	boss.global_position = enemy.global_position
	bullet = preload("res://Projectile.gd").new()
	projectiles.add_child(bullet)
	bullet.set_process(false)
	bullet.global_position = boss.global_position
	bullet._process(0)
	check(boss.hits == 1 and enemy.hits == 1, "consumed projectile cannot hit boss and enemy")
	boss.queue_free()
	await process_frame
	var blob = preload("res://Projectile.gd").new()
	projectiles.add_child(blob)
	blob.set_process(false)
	blob.owner_is_player = false
	blob.is_engulf = true
	blob.speed = 48
	blob.direction = Vector2.RIGHT
	blob.position = Vector2(30, 30)
	before = blob.position.x
	blob._process(0.25)
	check(is_equal_approx(blob.position.x-before, 12), "enemy projectile honors configured speed")
	blob.speed = 0
	blob.global_position = player.global_position
	var health = player.health
	blob._process(0)
	check(player.health == health-16, "engulf immediate hit")
	blob._process(0.24)
	check(player.health == health-16, "no early engulf tick")
	blob._process(0.02)
	check(player.health == health-32, "engulf tick after interval")
	player.health = 1000
	blob._process(0.5)
	check(player.health == 968, "engulf preserves multiple elapsed ticks")
	blob.global_position += Vector2(100, 0)
	blob._process(0.1)
	check(not blob._engulf_entered and blob.dot_timer == 0, "engulf resets on exit")
	blob.global_position = player.global_position
	blob._process(0)
	check(player.health == 952, "engulf reentry hit")
	blob.queue_free()
	var pickup = preload("res://Collectible.gd").new()
	world.add_child(pickup)
	player.ammo = 0
	pickup.collectible_type = pickup.Type.WATER_BOTTLE
	pickup._on_collected(player, world)
	pickup._on_collected(player, world)
	check(player.ammo == 4, "pickup applied only once")
	var overlay = preload("res://LevelIntro.gd").new()
	world.add_child(overlay)
	var calls = [0]
	var callback = func(): calls[0] += 1
	overlay.show_intro("TEST", Color.RED, "Test", callback)
	overlay.dismiss(callback)
	overlay.dismiss(callback)
	await create_timer(0.4).timeout
	check(calls[0] == 1, "intro button/timeout race calls once")
	world.queue_free()
	await process_frame
	print("PASS: ", checks-failures, "/", checks, " gameplay checks")
	quit(1 if failures else 0)
