extends Node3D

const PLAYER_SCENE := "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const NATURE_ROOT := "res://assets/nature"
const MONSTER_ROOT := "res://assets/monsters"

var player: Node3D
var camera: Camera3D
var enemies: Array[Node3D] = []
var projectiles: Array[Node3D] = []
var nature_scenes: Array[String] = []
var monster_scenes: Array[String] = []
var move_input := Vector2.ZERO
var touch_origin := Vector2.ZERO
var active_touch := -1
var fire_timer := 0.0
var time_alive := 0.0

func _ready() -> void:
    nature_scenes = _collect_scenes(NATURE_ROOT)
    monster_scenes = _collect_scenes(MONSTER_ROOT)
    _build_world()
    _spawn_player()
    _spawn_nature()
    _spawn_enemies()
    _build_hud()

func _process(delta: float) -> void:
    time_alive += delta
    _update_player(delta)
    _update_enemies(delta)
    _update_projectiles(delta)
    _update_camera(delta)
    fire_timer -= delta
    if fire_timer <= 0.0:
        fire_timer = 0.75
        _cast_at_nearest_enemy()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1 and event.position.x < get_viewport().get_visible_rect().size.x * 0.72:
            active_touch = event.index
            touch_origin = event.position
            move_input = Vector2.ZERO
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == active_touch:
        move_input = (event.position - touch_origin) / 90.0
        move_input = move_input.limit_length(1.0)

func _build_world() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("7c8c86")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("b8c9be")
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 1.15
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58.0, -38.0, 0.0)
    sun.light_color = Color("ffe7c4")
    sun.light_energy = 1.65
    sun.shadow_enabled = true
    add_child(sun)

    var ground := MeshInstance3D.new()
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(54.0, 54.0)
    ground.mesh = ground_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("465f3f")
    mat.roughness = 0.94
    ground.material_override = mat
    add_child(ground)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 15.5, 13.5)
    camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
    camera.fov = 36.0
    camera.current = true
    add_child(camera)

func _spawn_player() -> void:
    var packed := load(PLAYER_SCENE) as PackedScene
    if packed == null:
        push_error("Runeborn: Mage asset not found at " + PLAYER_SCENE)
        return
    player = packed.instantiate() as Node3D
    player.name = "RunebornMage"
    player.position = Vector3(0.0, 0.0, 0.0)
    player.scale = Vector3.ONE * 1.3
    add_child(player)
    _play_first_animation(player, ["idle", "Idle"])

func _spawn_nature() -> void:
    if nature_scenes.is_empty():
        push_warning("Runeborn: no nature GLB/GLTF assets found")
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 68421
    var placed := 0
    for i in range(56):
        var angle := rng.randf_range(0.0, TAU)
        var radius := rng.randf_range(9.0, 25.0)
        var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        if pos.length() < 8.0:
            continue
        var path := nature_scenes[rng.randi_range(0, nature_scenes.size() - 1)]
        var packed := load(path) as PackedScene
        if packed == null:
            continue
        var item := packed.instantiate() as Node3D
        item.position = pos
        item.rotation.y = rng.randf_range(0.0, TAU)
        var size := rng.randf_range(0.8, 1.35)
        item.scale = Vector3.ONE * size
        add_child(item)
        placed += 1
        if placed >= 42:
            break

func _spawn_enemies() -> void:
    if monster_scenes.is_empty():
        push_warning("Runeborn: no monster GLB/GLTF assets found")
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 9911
    for i in range(12):
        var path := monster_scenes[i % monster_scenes.size()]
        var packed := load(path) as PackedScene
        if packed == null:
            continue
        var enemy := packed.instantiate() as Node3D
        var angle := TAU * float(i) / 12.0
        var radius := rng.randf_range(10.5, 16.5)
        enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        enemy.scale = Vector3.ONE * rng.randf_range(0.85, 1.2)
        enemy.set_meta("hp", 3)
        enemy.set_meta("speed", rng.randf_range(1.4, 2.15))
        add_child(enemy)
        enemies.append(enemy)
        _play_first_animation(enemy, ["walk", "Walk", "run", "Run", "idle", "Idle"])

func _update_player(delta: float) -> void:
    if player == null:
        return
    var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec := move_input if move_input.length() > 0.05 else keyboard
    var dir := Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 0.05:
        dir = dir.normalized()
        player.position += dir * 5.5 * delta
        player.position.x = clamp(player.position.x, -23.0, 23.0)
        player.position.z = clamp(player.position.z, -23.0, 23.0)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 12.0))

func _update_enemies(delta: float) -> void:
    if player == null:
        return
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var offset := player.position - enemy.position
        offset.y = 0.0
        if offset.length() > 1.4:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.6)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
        enemy.position.y = sin(time_alive * 3.0 + enemy.position.x) * 0.035

func _cast_at_nearest_enemy() -> void:
    if player == null or enemies.is_empty():
        return
    var target: Node3D
    var best := INF
    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue
        var d := player.position.distance_squared_to(enemy.position)
        if d < best:
            best = d
            target = enemy
    if target == null:
        return

    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.22
    sphere.height = 0.44
    orb.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("8e5cff")
    mat.emission_enabled = true
    mat.emission = Color("a875ff")
    mat.emission_energy_multiplier = 5.5
    orb.material_override = mat
    orb.position = player.position + Vector3(0.0, 1.1, 0.0)
    orb.set_meta("target", target)
    orb.set_meta("life", 2.2)
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
        var direction := target.global_position + Vector3(0.0, 0.75, 0.0) - orb.global_position
        if direction.length() < 0.75:
            _hit_enemy(target)
            projectiles.erase(orb)
            orb.queue_free()
            continue
        orb.global_position += direction.normalized() * 12.0 * delta
        orb.scale = Vector3.ONE * (1.0 + sin(time_alive * 14.0) * 0.12)

func _hit_enemy(enemy: Node3D) -> void:
    var hp := int(enemy.get_meta("hp", 1)) - 1
    enemy.set_meta("hp", hp)
    var tween := create_tween()
    tween.tween_property(enemy, "scale", enemy.scale * 1.35, 0.07)
    tween.tween_property(enemy, "scale", enemy.scale / 1.35, 0.12)
    if hp <= 0:
        enemies.erase(enemy)
        var death := create_tween()
        death.set_parallel(true)
        death.tween_property(enemy, "scale", Vector3.ZERO, 0.28)
        death.tween_property(enemy, "rotation:y", enemy.rotation.y + 2.4, 0.28)
        death.chain().tween_callback(enemy.queue_free)

func _update_camera(delta: float) -> void:
    if player == null or camera == null:
        return
    var desired := player.position + Vector3(0.0, 15.5, 13.5)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 5.5))

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var title := Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(38.0, 54.0)
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("efe8ff"))
    layer.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Drag left side to move • Arcane auto-cast"
    subtitle.position = Vector2(40.0, 100.0)
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("d4cede"))
    layer.add_child(subtitle)

func _collect_scenes(root: String) -> Array[String]:
    var result: Array[String] = []
    _scan_dir(root, result)
    result.sort()
    return result

func _scan_dir(path: String, result: Array[String]) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry != "." and entry != ".." and not entry.begins_with("__MACOSX") and not entry.begins_with("._"):
            var full := path.path_join(entry)
            if dir.current_is_dir():
                _scan_dir(full, result)
            else:
                var lower := entry.to_lower()
                if lower.ends_with(".glb") or lower.ends_with(".gltf"):
                    result.append(full)
        entry = dir.get_next()
    dir.list_dir_end()

func _play_first_animation(root: Node, candidates: Array[String]) -> void:
    var players := root.find_children("*", "AnimationPlayer", true, false)
    if players.is_empty():
        return
    var animation_player := players[0] as AnimationPlayer
    for candidate in candidates:
        if animation_player.has_animation(candidate):
            animation_player.play(candidate)
            return
    var names := animation_player.get_animation_list()
    if not names.is_empty():
        animation_player.play(names[0])
