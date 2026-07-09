extends "res://scripts/main_v2.gd"

var dash_cooldown := 0.0
var dash_time := 0.0
var dash_direction := Vector3.ZERO
var meteor_timer := 4.5
var camera_shake := 0.0
var camera_shake_strength := 0.0
var last_touch_time := -10.0
var last_touch_position := Vector2.ZERO
var dash_label: Label
var spell_label: Label
var pending_meteor: Node3D
var pending_marker: Node3D
var pending_meteor_position := Vector3.ZERO

func _process(delta: float) -> void:
    dash_cooldown = max(0.0, dash_cooldown - delta)
    meteor_timer -= delta
    camera_shake = max(0.0, camera_shake - delta)

    if dash_time > 0.0:
        dash_time -= delta
        if player != null:
            player.position += dash_direction * 15.5 * delta
    else:
        super._process(delta)

    if meteor_timer <= 0.0:
        meteor_timer = 4.5
        _cast_rune_meteor()

    _refresh_combat_hud()

func _input(event: InputEvent) -> void:
    super._input(event)
    if event is InputEventScreenTouch and event.pressed:
        var now := Time.get_ticks_msec() / 1000.0
        if now - last_touch_time < 0.28 and event.position.distance_to(last_touch_position) < 90.0:
            _try_dash(event.position)
            last_touch_time = -10.0
        else:
            last_touch_time = now
            last_touch_position = event.position

func _try_dash(screen_position: Vector2) -> void:
    if dash_cooldown > 0.0 or player == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var screen_dir := (screen_position - viewport_size * 0.5).normalized()
    dash_direction = Vector3(screen_dir.x, 0.0, screen_dir.y)
    if move_input.length() > 0.1:
        dash_direction = Vector3(move_input.x, 0.0, move_input.y).normalized()
    if dash_direction.length() < 0.1:
        dash_direction = -player.global_transform.basis.z.normalized()
    dash_time = 0.18
    dash_cooldown = 2.2
    _spawn_dash_trail()
    _kick_camera(0.18, 0.24)

func _spawn_dash_trail() -> void:
    if player == null:
        return
    for i in range(5):
        var ghost := RunebornFX.make_arcane_ring(0.38 + float(i) * 0.05)
        ghost.position = player.position - dash_direction * float(i) * 0.45 + Vector3(0.0, 0.12, 0.0)
        ghost.scale.y = 0.08
        add_child(ghost)
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(ghost, "scale", Vector3(1.6, 0.08, 1.6), 0.24)
        tween.tween_property(ghost, "position:y", 0.02, 0.24)
        tween.chain().tween_callback(ghost.queue_free)

func _cast_rune_meteor() -> void:
    var target := _nearest_enemy()
    if target == null or not is_instance_valid(target):
        return

    var marker := RunebornFX.make_arcane_ring(0.45)
    marker.position = target.global_position + Vector3(0.0, 0.04, 0.0)
    marker.scale.y = 0.08
    add_child(marker)
    var marker_tween := create_tween()
    marker_tween.tween_property(marker, "scale", Vector3(2.4, 0.08, 2.4), 0.62)

    var meteor := RunebornFX.make_arcane_orb()
    meteor.position = target.global_position + Vector3(0.0, 10.0, 0.0)
    meteor.scale = Vector3.ONE * 2.1
    add_child(meteor)

    pending_meteor = meteor
    pending_marker = marker
    pending_meteor_position = target.global_position + Vector3(0.0, 0.35, 0.0)

    var tween := create_tween()
    tween.tween_property(meteor, "global_position", pending_meteor_position, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_callback(_finish_rune_meteor)

func _finish_rune_meteor() -> void:
    _meteor_impact(pending_meteor_position)
    if is_instance_valid(pending_meteor):
        pending_meteor.queue_free()
    if is_instance_valid(pending_marker):
        pending_marker.queue_free()
    pending_meteor = null
    pending_marker = null

func _meteor_impact(position: Vector3) -> void:
    _kick_camera(0.24, 0.42)
    RunebornFX.burst(self, position + Vector3(0.0, 0.5, 0.0), Color("c493ff"), 2.0)
    for enemy in enemies.duplicate():
        if is_instance_valid(enemy) and enemy.global_position.distance_to(position) <= 3.6:
            _hit_enemy(enemy, 3)

func _damage_player(amount: int) -> void:
    super._damage_player(amount)
    _kick_camera(0.14, 0.3)

func _kill_enemy(enemy: Node3D) -> void:
    super._kill_enemy(enemy)
    _kick_camera(0.08, 0.14)

func _update_camera(delta: float) -> void:
    super._update_camera(delta)
    if camera == null or camera_shake <= 0.0:
        return
    var strength := camera_shake_strength * (camera_shake / max(0.001, camera_shake + delta))
    camera.position += Vector3(randf_range(-strength, strength), randf_range(-strength, strength), 0.0)

func _kick_camera(duration: float, strength: float) -> void:
    camera_shake = max(camera_shake, duration)
    camera_shake_strength = max(camera_shake_strength, strength)

func _build_hud() -> void:
    super._build_hud()
    var layer := CanvasLayer.new()
    add_child(layer)

    dash_label = Label.new()
    dash_label.position = Vector2(40.0, 244.0)
    dash_label.add_theme_font_size_override("font_size", 18)
    dash_label.add_theme_color_override("font_color", Color("ccbaff"))
    layer.add_child(dash_label)

    spell_label = Label.new()
    spell_label.position = Vector2(40.0, 274.0)
    spell_label.add_theme_font_size_override("font_size", 18)
    spell_label.add_theme_color_override("font_color", Color("d8ccef"))
    layer.add_child(spell_label)
    _refresh_combat_hud()

func _refresh_combat_hud() -> void:
    if dash_label != null:
        if dash_cooldown <= 0.0:
            dash_label.text = "DASH  READY"
        else:
            dash_label.text = "DASH  %.1fs" % dash_cooldown
    if spell_label != null:
        spell_label.text = "RUNE METEOR  %.1fs" % max(0.0, meteor_timer)
