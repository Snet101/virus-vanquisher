extends SceneTree
var checks = 0
var failures = 0
func check(value, message):
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)
func _initialize():
	call_deferred("run_campaign")
func settle():
	await process_frame
	await process_frame
func button_with_text(parent, text):
	for button in parent.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null
func run_campaign():
	change_scene_to_file("res://intro_scene.tscn")
	await settle()
	var intro = current_scene
	intro.get_node("StarterScreenLayer/StarterScreen/StartButton").pressed.emit()
	intro._on_start_pressed()
	check(intro.animation_started, "start button starts intro once")
	await create_timer(8.0).timeout
	check(current_scene.scene_file_path == "res://Level1.tscn", "timed intro reaches level one")
	for entry in [[1, "RansomwareRex"], [2, "TrojanTitan"], [3, "WormKing"]]:
		var level = current_scene
		check(level.scene_file_path == "res://Level%d.tscn" % entry[0], "correct campaign scene")
		var boss = level.get_node(entry[1])
		var timer_before = boss.attack_timer
		await create_timer(0.2).timeout
		check(not level.combat_active and boss.attack_timer == timer_before, "boss paused during instructions")
		var fight = button_with_text(level, "TAP TO FIGHT")
		check(fight != null, "fight button exists")
		var desc = level.find_children("Description", "Label", true, false)[0]
		check(desc.get_rect().end.x <= 288 and desc.get_rect().end.y <= fight.position.y, "instructions fit above fight button")
		fight.pressed.emit()
		fight.pressed.emit()
		await create_timer(0.6).timeout
		check(level.combat_active, "fight dismissal resumes combat once")
		var player = level.get_node("Player")
		player.invincible_timer = 9999
		await create_timer(1.5).timeout
		check(player.state == player.State.WALKING, "player lands and can move")
		if entry[0] == 2:
			var originals = level.get_node("Collectibles").get_children()
			for pickup in originals:
				pickup._on_collected(player, level)
			check(player.slow_timer > 0 and player.invert_timer > 0, "trap status pickups apply")
			check(player.invincible_timer > 0 and player.ammo > 5, "real ammo and shield pickups apply")
			level.clear_enemies()
			await process_frame
			check(level.get_node("Enemies").get_child_count() == 0, "floppy clearing uses real enemy container")
		# Controlled integration test: immobilize boss and replenish ammo.
		# This verifies real damage/signals/transitions, not human difficulty balance.
		boss.set_process(false)
		player.ammo = 9999
		for i in range(30):
			if boss.stunned:
				break
			player._try_fire()
			var bullet = level.get_node("Projectiles").get_children().back()
			bullet.global_position = boss.global_position
			bullet._process(0)
		check(boss.stunned and level.level_finished, "real projectiles defeat boss")
		if entry[0] == 3:
			check(level.get_node("Enemies").get_child_count() == 10, "worm splits limited to five pairs")
		await create_timer(1.5).timeout
	check(button_with_text(current_scene, "PLAY AGAIN") != null, "victory screen appears")
	check(not current_scene.combat_active, "combat stopped after victory")
	button_with_text(current_scene, "PLAY AGAIN").pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://intro_scene.tscn", "play again returns to intro")
	change_scene_to_file("res://Level2.tscn")
	await settle()
	var old_id = current_scene.get_instance_id()
	var victim = current_scene.get_node("Player")
	victim.take_damage(1000)
	victim.take_damage(1000)
	await create_timer(2.0).timeout
	check(current_scene.scene_file_path == "res://Level2.tscn" and current_scene.get_instance_id() != old_id, "death reloads current level once")
	# Free the final scene cleanly so shutdown diagnostics catch real leaks.
	current_scene.queue_free()
	await settle()
	print("PASS: ", checks-failures, "/", checks, " campaign checks")
	quit(1 if failures else 0)
