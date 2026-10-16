extends SceneTree
func _initialize():
	call_deferred("capture")
func snap(name):
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	for label in current_scene.find_children("Description", "Label", true, false):
		if label.get_rect().end.x > 288 or label.get_rect().end.y > 132:
			push_error("Instructions exceed their reserved area")
			quit(1)
			return
	var image = root.get_texture().get_image()
	var result = image.save_png("res://.validation/" + name + ".png")
	if result != OK:
		push_error("Screenshot failed")
		quit(1)
func capture():
	DirAccess.make_dir_recursive_absolute("res://.validation")
	change_scene_to_file("res://intro_scene.tscn")
	await process_frame
	await snap("intro")
	for i in range(1, 4):
		change_scene_to_file("res://Level%d.tscn" % i)
		await process_frame
		await snap("level%d-instructions" % i)
		for b in current_scene.find_children("*", "Button", true, false):
			if b.text == "TAP TO FIGHT":
				b.pressed.emit()
		await create_timer(1.8).timeout
		await snap("level%d-combat" % i)
	current_scene._set_combat_active(false)
	current_scene._show_victory_screen()
	await snap("victory")
	current_scene.queue_free()
	await process_frame
	print("PASS: eight rendered scene captures")
	quit()
