extends Node3D

const PLAYER_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const MONSTER_ROOT = "res://assets/monsters"
const NATURE_ROOT = "res://assets/nature"

var player = null
var camera = null
var enemies = []
var monster_paths = []
var nature_ground = []
var nature_trees = []
var nature_rocks = []
var nature_plants = []
var move_input = Vector2.ZERO
var touch_origin = Vector2.ZERO
var active_touch = -1
var attack_timer = 0.0
var wave = 1
var score = 0
var hp = 100
var wave_label = null
var score_label = null
var hp_bar = null
var status_label = null
var boot_state = 0
var boot_index = 0
var boot_rng = RandomNumberGenerator.new()

func _ready():
    boot_rng.seed = 68421
    _build_world()
    _build_hud()
    _spawn_player()
    boot_state = 1
    status_label.text = "PAKET-ASSETS WERDEN GELADEN ..."

func _process(delta):
    if boot_state > 0:
        _boot_step()
        return
    _update_player(delta)
    _update_enemies(delta)
    _update_camera(delta)
    attack_timer -= delta
    if attack_timer <= 0.0:
        attack_timer = 0.62
        _attack_nearest_enemy()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1:
            active_touch = event.index
            touch_origin = event.position
            move_input = Vector2.ZERO
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == active_touch:
        move_input = ((event.position - touch_origin) / 115.0).limit_length(1.0)

func _boot_step():
    if boot_state == 1:
        _collect_monster_roster()
        boot_state = 2
        status_label.text = "ARENA WIRD AUS NATURE-PAKET GEBAUT ..."
        return
    if boot_state == 2:
        nature_ground = _find_models_limited(NATURE_ROOT, 18, ["ground", "grass", "terrain", "floor", "dirt", "tile"])
        nature_trees = _find_models_limited(NATURE_ROOT, 18, ["tree", "trunk", "stump"])
        nature_rocks = _find_models_limited(NATURE_ROOT, 18, ["rock", "stone", "boulder"])
        nature_plants = _find_models_limited(NATURE_ROOT, 24, ["bush", "flower", "plant", "fern", "grass"])
        boot_state = 3
        boot_index = 0
        return
    if boot_state == 3:
        var count = 0
        while count < 3 and boot_index < 56:
            _spawn_arena_piece(boot_index)
            boot_index += 1
            count += 1
        if boot_index >= 56:
            boot_state = 4
            status_label.text = "MONSTER-WELLE WIRD GELADEN ..."
        return
    if boot_state == 4:
        _start_wave()
        boot_state = 0
        status_label.text = "RUNENANGRIFF AKTIV"

func _build_world():
    var world_environment = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("56645e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("c4d0c6")
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
    sun.light_color = Color("ffe0b0")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    add_child(sun)

    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-42.0, 142.0, 0.0)
    fill.light_color = Color("8da7c7")
    fill.light_energy = 0.34
    fill.shadow_enabled = false
    add_child(fill)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 22.5, 18.5)
    camera.rotation_degrees = Vector3(-54.0, 0.0, 0.0)
    camera.fov = 43.0
    camera.current = true
    add_child(camera)

func _build_hud():
    var layer = CanvasLayer.new()
    add_child(layer)

    var title = Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(38.0, 48.0)
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("f1eaff"))
    layer.add_child(title)

    wave_label = Label.new()
    wave_label.position = Vector2(40.0, 90.0)
    wave_label.add_theme_font_size_override("font_size", 18)
    wave_label.add_theme_color_override("font_color", Color("eee7f5"))
    layer.add_child(wave_label)

    score_label = Label.new()
    score_label.position = Vector2(40.0, 118.0)
    score_label.add_theme_font_size_override("font_size", 16)
    score_label.add_theme_color_override("font_color", Color("d4cede"))
    layer.add_child(score_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(40.0, 150.0)
    hp_bar.size = Vector2(280.0, 18.0)
    hp_bar.min_value = 0.0
    hp_bar.max_value = 100.0
    hp_bar.show_percentage = false
    layer.add_child(hp_bar)

    status_label = Label.new()
    status_label.position = Vector2(40.0, 184.0)
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color("d8ccef"))
    layer.add_child(status_label)
    _refresh_hud()

func _spawn_player():
    var packed = load(PLAYER_SCENE)
    if packed == null:
        status_label.text = "MAGE-ASSET FEHLT"
        return
    player = packed.instantiate()
    player.name = "RunebornMage"
    player.scale = Vector3.ONE * 0.62
    add_child(player)
    _play_animation(player, ["Idle", "idle", "General/Idle"])

func _collect_monster_roster():
    monster_paths.clear()
    _append_unique(monster_paths, _find_models_limited(MONSTER_ROOT, 4, ["/big/", "big/"]))
    _append_unique(monster_paths, _find_models_limited(MONSTER_ROOT, 4, ["/blob/", "blob/"]))
    _append_unique(monster_paths, _find_models_limited(MONSTER_ROOT, 4, ["/flying/", "flying/"]))
    if monster_paths.size() == 0:
        _append_unique(monster_paths, _find_models_limited(MONSTER_ROOT, 12, []))

func _append_unique(target, source):
    for path in source:
        if not target.has(path) and _scene_has_visual_mesh(path):
            target.append(path)

func _scene_has_visual_mesh(path):
    var packed = load(path)
    if packed == null:
        return false
    var instance = packed.instantiate()
    if instance == null:
        return false
    var meshes = instance.find_children("*", "MeshInstance3D", true, false)
    var valid = meshes.size() > 0
    instance.free()
    return valid

func _find_models_limited(root, limit, include_terms):
    var result = []
    _scan_dir(root, result, limit, include_terms)
    return result

func _scan_dir(path, result, limit, include_terms):
    if result.size() >= limit:
        return true
    var dir = DirAccess.open(path)
    if dir == null:
        return false
    dir.list_dir_begin()
    var entry = dir.get_next()
    while entry != "":
        if entry != "." and entry != ".." and not entry.begins_with("__MACOSX") and not entry.begins_with("._"):
            var full = path.path_join(entry)
            if dir.current_is_dir():
                if _scan_dir(full, result, limit, include_terms):
                    dir.list_dir_end()
                    return true
            else:
                var lower = full.to_lower()
                var valid_extension = lower.ends_with(".glb") or lower.ends_with(".gltf")
                if valid_extension and _matches_include(lower, include_terms):
                    result.append(full)
                    if result.size() >= limit:
                        dir.list_dir_end()
                        return true
        entry = dir.get_next()
    dir.list_dir_end()
    return false

func _matches_include(lower_path, include_terms):
    if include_terms.size() == 0:
        return true
    for term in include_terms:
        if lower_path.contains(str(term).to_lower()):
            return true
    return false

func _spawn_arena_piece(index):
    if index < 16:
        _spawn_ground_piece(index)
    elif index < 30:
        _spawn_boundary_piece(index, nature_rocks, 11.5, 17.0, 0.8, 1.35)
    elif index < 42:
        _spawn_boundary_piece(index, nature_trees, 14.0, 22.0, 0.85, 1.25)
    else:
        _spawn_boundary_piece(index, nature_plants, 8.5, 19.0, 0.7, 1.1)

func _spawn_ground_piece(index):
    if nature_ground.size() == 0:
        return
    var path = nature_ground[index % nature_ground.size()]
    var packed = load(path)
    if packed == null:
        return
    var item = packed.instantiate()
    var column = index % 4
    var row = index / 4
    item.position = Vector3((float(column) - 1.5) * 6.0, -0.02, (float(row) - 1.5) * 6.0)
    item.rotation.y = float((index * 3) % 4) * PI * 0.5
    item.scale = Vector3.ONE * 1.2
    add_child(item)

func _spawn_boundary_piece(index, pool, min_radius, max_radius, min_scale, max_scale):
    if pool.size() == 0:
        return
    var path = pool[index % pool.size()]
    var packed = load(path)
    if packed == null:
        return
    var item = packed.instantiate()
    var angle = boot_rng.randf_range(0.0, TAU)
    var radius = boot_rng.randf_range(min_radius, max_radius)
    item.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    item.rotation.y = boot_rng.randf_range(0.0, TAU)
    item.scale = Vector3.ONE * boot_rng.randf_range(min_scale, max_scale)
    add_child(item)

func _start_wave():
    if monster_paths.size() == 0:
        status_label.text = "KEINE LADBAREN MONSTER-ASSETS"
        return
    var count = min(14, 5 + wave * 2)
    var i = 0
    while i < count:
        _spawn_enemy(i, count)
        i += 1
    _refresh_hud()

func _spawn_enemy(index, total):
    if monster_paths.size() == 0:
        return
    var path = monster_paths[index % monster_paths.size()]
    var packed = load(path)
    if packed == null:
        return
    var enemy = packed.instantiate()
    if enemy == null:
        return
    var meshes = enemy.find_children("*", "MeshInstance3D", true, false)
    if meshes.size() == 0:
        enemy.free()
        return
    var angle = TAU * float(index) / float(max(1, total))
    var radius = 11.5 + fmod(float(index) * 1.7, 4.5)
    enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    enemy.scale = Vector3.ONE * 0.78
    enemy.set_meta("base_scale", enemy.scale)
    enemy.set_meta("hp", 3 + wave)
    enemy.set_meta("speed", 1.35 + float(wave) * 0.07)
    enemy.set_meta("cooldown", 0.0)
    add_child(enemy)
    enemies.append(enemy)
    _play_animation(enemy, ["Walk", "walk", "Run", "run", "Idle", "idle"])

func _update_player(delta):
    if player == null:
        return
    var keyboard = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec = move_input
    if move_input.length() <= 0.05:
        input_vec = keyboard
    var dir = Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 0.05:
        dir = dir.normalized()
        player.position += dir * 5.6 * delta
        player.position.x = clamp(player.position.x, -10.0, 10.0)
        player.position.z = clamp(player.position.z, -10.0, 10.0)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 12.0))
        _play_animation(player, ["Walk", "walk", "Run", "run"])
    else:
        _play_animation(player, ["Idle", "idle", "General/Idle"])

func _update_enemies(delta):
    if player == null:
        return
    var copy = enemies.duplicate()
    for enemy in copy:
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var cooldown = max(0.0, float(enemy.get_meta("cooldown", 0.0)) - delta)
        enemy.set_meta("cooldown", cooldown)
        var offset = player.position - enemy.position
        offset.y = 0.0
        if offset.length() > 1.15:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.5)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
        elif cooldown <= 0.0:
            enemy.set_meta("cooldown", 0.85)
            hp = max(0, hp - 5)
            _refresh_hud()

func _attack_nearest_enemy():
    var target = _nearest_enemy()
    if target == null or player == null:
        return
    _play_animation(player, ["Attack", "attack", "Spell", "spell", "Combat"])
    _hit_enemy(target)

func _nearest_enemy():
    if player == null:
        return null
    var target = null
    var best = INF
    for enemy in enemies:
        if is_instance_valid(enemy):
            var distance = player.position.distance_squared_to(enemy.position)
            if distance < best:
                best = distance
                target = enemy
    return target

func _hit_enemy(enemy):
    if not is_instance_valid(enemy):
        return
    var enemy_hp = int(enemy.get_meta("hp", 1)) - 1
    enemy.set_meta("hp", enemy_hp)
    var base_scale = enemy.get_meta("base_scale", enemy.scale)
    enemy.scale = base_scale * 1.12
    if enemy_hp <= 0:
        enemies.erase(enemy)
        score += 5
        enemy.queue_free()
        _refresh_hud()
        if enemies.size() == 0:
            wave += 1
            _start_wave()
    else:
        enemy.scale = base_scale

func _update_camera(delta):
    if player == null or camera == null:
        return
    var desired = player.position + Vector3(0.0, 22.5, 18.5)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 4.8))

func _refresh_hud():
    if wave_label != null:
        wave_label.text = "WAVE %02d" % wave
    if score_label != null:
        score_label.text = "RUNE SCORE %05d" % score
    if hp_bar != null:
        hp_bar.value = hp

func _play_animation(root, candidates):
    var players = root.find_children("*", "AnimationPlayer", true, false)
    if players.size() == 0:
        return
    var animation_player = players[0]
    var current = animation_player.current_animation
    for candidate in candidates:
        if animation_player.has_animation(candidate):
            if current != candidate:
                animation_player.play(candidate)
            return
