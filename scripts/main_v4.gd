extends "res://scripts/main_v3.gd"

var xp := 0
var level := 1
var xp_to_level := 30
var xp_pickups: Array[Node3D] = []
var level_up_open := false
var level_layer: CanvasLayer
var xp_bar: ProgressBar
var level_label: Label
var upgrade_panel: PanelContainer
var bolt_damage := 1
var bolt_speed := 13.5
var bolt_rate_bonus := 0.0
var nova_damage := 2
var meteor_damage := 3
var player_speed_bonus := 0.0

func _process(delta: float) -> void:
    if level_up_open:
        _update_camera(delta)
        return
    super._process(delta)
    _update_xp_pickups(delta)

func _build_hud() -> void:
    super._build_hud()
    level_layer = CanvasLayer.new()
    level_layer.layer = 20
    add_child(level_layer)

    level_label = Label.new()
    level_label.position = Vector2(40.0, 312.0)
    level_label.add_theme_font_size_override("font_size", 18)
    level_label.add_theme_color_override("font_color", Color("d9ccff"))
    level_layer.add_child(level_label)

    xp_bar = ProgressBar.new()
    xp_bar.position = Vector2(40.0, 344.0)
    xp_bar.size = Vector2(310.0, 18.0)
    xp_bar.min_value = 0.0
    xp_bar.show_percentage = false
    level_layer.add_child(xp_bar)

    upgrade_panel = PanelContainer.new()
    upgrade_panel.position = Vector2(80.0, 560.0)
    upgrade_panel.size = Vector2(1010.0, 1240.0)
    upgrade_panel.visible = false
    level_layer.add_child(upgrade_panel)
    _refresh_level_hud()

func _spawn_enemy(index: int, total: int, elite: bool) -> void:
    if monster_scenes.is_empty():
        return
    var angle := TAU * float(index) / float(max(1, total))
    var radius := 13.0 + fmod(float(index) * 2.27, 8.0)
    var spawn_position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    _spawn_rune_rift(spawn_position, elite)
    var delay := 0.28 + float(index % 5) * 0.08
    get_tree().create_timer(delay).timeout.connect(_materialize_enemy.bind(index, spawn_position, elite))

func _materialize_enemy(index: int, spawn_position: Vector3, elite: bool) -> void:
    var path := monster_scenes[index % monster_scenes.size()]
    var packed := load(path) as PackedScene
    if packed == null:
        return
    var enemy := packed.instantiate() as Node3D
    enemy.position = spawn_position
    var difficulty := wave_director.difficulty_multiplier()
    var base_scale := Vector3.ONE * (1.0 + fmod(float(index) * 0.17, 0.28))
    enemy.scale = Vector3.ZERO
    enemy.set_meta("base_scale", base_scale)
    enemy.set_meta("max_hp", int(3.0 * difficulty))
    enemy.set_meta("hp", int(enemy.get_meta("max_hp")))
    enemy.set_meta("speed", 1.5 + difficulty * 0.28)
    enemy.set_meta("damage_cooldown", 0.0)
    enemy.set_meta("elite", elite)
    if elite:
        base_scale *= 1.7
        enemy.set_meta("base_scale", base_scale)
        enemy.set_meta("max_hp", int(20.0 * difficulty))
        enemy.set_meta("hp", int(enemy.get_meta("max_hp")))
        enemy.set_meta("speed", 1.15 + difficulty * 0.12)
        _attach_elite_aura(enemy)
        _attach_elite_hp(enemy)
    add_child(enemy)
    enemies.append(enemy)
    _play_animation(enemy, ["Walk", "walk", "Run", "run", "Idle", "idle"])
    var tween := create_tween()
    tween.tween_property(enemy, "scale", base_scale * 1.12, 0.16).set_trans(Tween.TRANS_BACK)
    tween.tween_property(enemy, "scale", base_scale, 0.12)

func _spawn_rune_rift(position: Vector3, elite: bool) -> void:
    var root := Node3D.new()
    root.position = position + Vector3(0.0, 0.04, 0.0)
    add_child(root)
    var ring_count := 3 if elite else 2
    for i in range(ring_count):
        var ring := RunebornFX.make_arcane_ring(0.3 + float(i) * 0.22)
        ring.scale = Vector3(0.15, 0.08, 0.15)
        ring.rotation.y = float(i) * 0.8
        root.add_child(ring)
        var target_scale := Vector3(2.2 + float(i) * 0.35, 0.08, 2.2 + float(i) * 0.35)
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(ring, "scale", target_scale, 0.34)
        tween.tween_property(ring, "rotation:y", ring.rotation.y + TAU, 0.34)
        tween.chain().tween_property(ring, "scale", Vector3.ZERO, 0.24)
    var burst_color := Color("d09bff") if elite else Color("8f6dff")
    var burst_size := 1.25 if elite else 0.8
    RunebornFX.burst(self, position + Vector3(0.0, 0.55, 0.0), burst_color, burst_size)
    get_tree().create_timer(0.72).timeout.connect(root.queue_free)

func _attach_elite_hp(enemy: Node3D) -> void:
    var holder := Node3D.new()
    holder.name = "EliteHealth"
    holder.position = Vector3(0.0, 2.35, 0.0)
    enemy.add_child(holder)

    var back := MeshInstance3D.new()
    var back_mesh := QuadMesh.new()
    back_mesh.size = Vector2(1.8, 0.16)
    back.mesh = back_mesh
    var back_mat := StandardMaterial3D.new()
    back_mat.albedo_color = Color("241d2f")
    back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    back_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    back.material_override = back_mat
    holder.add_child(back)

    var fill := MeshInstance3D.new()
    fill.name = "Fill"
    var fill_mesh := QuadMesh.new()
    fill_mesh.size = Vector2(1.72, 0.09)
    fill.mesh = fill_mesh
    fill.position.z = -0.01
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color("ba66ff")
    fill_mat.emission_enabled = true
    fill_mat.emission = Color("8d45d9")
    fill_mat.emission_energy_multiplier = 2.0
    fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    fill.material_override = fill_mat
    holder.add_child(fill)

func _hit_enemy(enemy: Node3D, damage: int) -> void:
    super._hit_enemy(enemy, damage)
    if is_instance_valid(enemy) and bool(enemy.get_meta("elite", false)):
        _refresh_elite_hp(enemy)

func _refresh_elite_hp(enemy: Node3D) -> void:
    var holder := enemy.get_node_or_null("EliteHealth")
    if holder == null:
        return
    var fill := holder.get_node_or_null("Fill") as MeshInstance3D
    if fill == null:
        return
    var max_hp := max(1, int(enemy.get_meta("max_hp", 1)))
    var ratio := clamp(float(enemy.get_meta("hp", 0)) / float(max_hp), 0.0, 1.0)
    fill.scale.x = ratio
    fill.position.x = -0.86 * (1.0 - ratio)

func _cast_at_nearest_enemy() -> void:
    var target := _nearest_enemy()
    if target == null or player == null:
        return
    var orb := RunebornFX.make_arcane_orb()
    orb.position = player.position + Vector3(0.0, 1.15, 0.0)
    orb.set_meta("target", target)
    orb.set_meta("life", 2.4)
    orb.set_meta("damage", bolt_damage)
    add_child(orb)
    projectiles.append(orb)

func _update_projectiles(delta: float) -> void:
    for orb in projectiles.duplicate():
        if not is_instance_valid(orb):
            projectiles.erase(orb)
            continue
        var life := float(orb.get_meta("life", 0.0)) - delta
        orb.set_meta("life", life)
        var target := orb.get_meta("target") as Node3D
        if life <= 0.0 or target == null or not is_instance_valid(target):
            projectiles.erase(orb)
            orb.queue_free()
            continue
        var direction := target.global_position + Vector3(0.0, 0.72, 0.0) - orb.global_position
        if direction.length() < 0.72:
            _hit_enemy(target, int(orb.get_meta("damage", bolt_damage)))
            projectiles.erase(orb)
            orb.queue_free()
            continue
        orb.global_position += direction.normalized() * bolt_speed * delta
        orb.scale = Vector3.ONE * (1.0 + sin(time_alive * 16.0) * 0.14)

func _cast_arcane_nova() -> void:
    if player == null:
        return
    var ring := RunebornFX.make_arcane_ring(0.35)
    ring.position = player.position + Vector3(0.0, 0.08, 0.0)
    ring.scale.y = 0.12
    add_child(ring)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring, "scale", Vector3(6.5, 0.12, 6.5), 0.42)
    tween.tween_property(ring, "rotation:y", PI, 0.42)
    tween.chain().tween_callback(ring.queue_free)
    for enemy in enemies.duplicate():
        if is_instance_valid(enemy) and player.position.distance_to(enemy.position) <= 6.5:
            _hit_enemy(enemy, nova_damage)

func _meteor_impact(position: Vector3) -> void:
    _kick_camera(0.24, 0.42)
    RunebornFX.burst(self, position + Vector3(0.0, 0.5, 0.0), Color("c493ff"), 2.0)
    for enemy in enemies.duplicate():
        if is_instance_valid(enemy) and enemy.global_position.distance_to(position) <= 3.6:
            _hit_enemy(enemy, meteor_damage)

func _update_player(delta: float) -> void:
    if player == null:
        return
    var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec := move_input if move_input.length() > 0.05 else keyboard
    var dir := Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 0.05:
        dir = dir.normalized()
        player.position += dir * (5.8 + player_speed_bonus) * delta
        player.position.x = clamp(player.position.x, -25.0, 25.0)
        player.position.z = clamp(player.position.z, -25.0, 25.0)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 13.0))

func _kill_enemy(enemy: Node3D) -> void:
    if is_instance_valid(enemy):
        var xp_amount := 12 if bool(enemy.get_meta("elite", false)) else 5
        _spawn_xp(enemy.global_position, xp_amount)
    super._kill_enemy(enemy)

func _spawn_xp(position: Vector3, amount: int) -> void:
    var shard := MeshInstance3D.new()
    shard.name = "RuneShard"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.22, 0.55, 0.22)
    shard.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("7fe5ff")
    mat.emission_enabled = true
    mat.emission = Color("66d5ff")
    mat.emission_energy_multiplier = 4.5
    mat.roughness = 0.22
    shard.material_override = mat
    shard.position = position + Vector3(0.0, 0.35, 0.0)
    shard.rotation.z = 0.5
    shard.set_meta("xp", amount)
    shard.set_meta("age", 0.0)
    add_child(shard)
    xp_pickups.append(shard)
    var tween := create_tween().set_loops()
    tween.tween_property(shard, "rotation:y", TAU, 1.5).from(0.0)

func _update_xp_pickups(delta: float) -> void:
    if player == null:
        return
    for shard in xp_pickups.duplicate():
        if not is_instance_valid(shard):
            xp_pickups.erase(shard)
            continue
        var age := float(shard.get_meta("age", 0.0)) + delta
        shard.set_meta("age", age)
        shard.position.y = 0.35 + sin(age * 4.5) * 0.12
        var distance := shard.global_position.distance_to(player.global_position)
        if distance < 4.2:
            var pull_speed := 4.0 + max(0.0, 4.2 - distance) * 4.0
            shard.global_position = shard.global_position.move_toward(player.global_position + Vector3(0.0, 0.7, 0.0), pull_speed * delta)
        if distance < 0.75:
            _gain_xp(int(shard.get_meta("xp", 1)))
            xp_pickups.erase(shard)
            shard.queue_free()

func _gain_xp(amount: int) -> void:
    xp += amount
    _refresh_level_hud()
    if xp >= xp_to_level:
        xp -= xp_to_level
        level += 1
        xp_to_level = int(round(float(xp_to_level) * 1.32 + 8.0))
        _open_level_up()

func _open_level_up() -> void:
    level_up_open = true
    upgrade_panel.visible = true
    for child in upgrade_panel.get_children():
        child.queue_free()

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 28)
    upgrade_panel.add_child(column)

    var header := Label.new()
    header.text = "RUNE AWAKENED\nLEVEL %d" % level
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header.add_theme_font_size_override("font_size", 44)
    header.add_theme_color_override("font_color", Color("efe6ff"))
    column.add_child(header)

    _add_upgrade_card(column, "ARCANE FANG", "+1 Bolt damage", "bolt_damage")
    _add_upgrade_card(column, "VOID CURRENT", "+18% projectile speed\n+0.06 attacks/sec", "bolt_speed")
    _add_upgrade_card(column, "RUNE HEART", "+25 HP and heal 25", "rune_heart")

func _add_upgrade_card(parent: VBoxContainer, title: String, description: String, upgrade_id: String) -> void:
    var button := Button.new()
    button.custom_minimum_size = Vector2(900.0, 230.0)
    button.text = title + "\n\n" + description
    button.add_theme_font_size_override("font_size", 30)
    button.pressed.connect(_choose_upgrade.bind(upgrade_id))
    parent.add_child(button)

func _choose_upgrade(upgrade_id: String) -> void:
    match upgrade_id:
        "bolt_damage":
            bolt_damage += 1
        "bolt_speed":
            bolt_speed *= 1.18
            bolt_rate_bonus += 0.06
        "rune_heart":
            player_hp = min(125, player_hp + 25)
    upgrade_panel.visible = false
    level_up_open = false
    fire_timer = max(0.15, fire_timer - bolt_rate_bonus)
    _refresh_hud()
    _refresh_level_hud()

func _refresh_level_hud() -> void:
    if level_label != null:
        level_label.text = "RUNE LEVEL  %02d" % level
    if xp_bar != null:
        xp_bar.max_value = xp_to_level
        xp_bar.value = xp
