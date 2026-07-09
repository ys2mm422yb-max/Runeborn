extends Node3D

const PLAYER_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const MONSTER_ROOT = "res://assets/monsters"
const NATURE_ROOT = "res://assets/nature"

var player = null
var camera = null
var enemies = []
var projectiles = []
var monster_paths = []
var nature_paths = []
var move_input = Vector2.ZERO
var touch_origin = Vector2.ZERO
var active_touch = -1
var fire_timer = 0.0
var wave = 1
var score = 0
var hp = 100
var wave_label = null
var score_label = null
var hp_bar = null
var status_label = null
var boot_state = 0
var boot_index = 0
var boot_label = null
var boot_rng = RandomNumberGenerator.new()

func _ready():
    set_process(true)
    boot_rng.seed = 68421
    _build_world()
    _build_hud()
    _spawn_player()
    boot_state = 1
    status_label.text = "MONSTER WERDEN GESUCHT ..."

func _process(delta):
    if boot_state > 0:
        _boot_step()
        return
    _update_player(delta)
    _update_enemies(delta)
    _update_projectiles(delta)
    _update_camera(delta)
    fire_timer -= delta
    if fire_timer <= 0.0:
        fire_timer = 0.65
        _cast_bolt()

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
        move_input = ((event.position - touch_origin) / 100.0).limit_length(1.0)

func _boot_step():
    if boot_state == 1:
        monster_paths = _find_models_limited(MONSTER_ROOT, 8, [])
        boot_state = 2
        status_label.text = "WALD WIRD ERSCHAFFEN ..."
        return
    if boot_state == 2:
        nature_paths = _find_models_limited(NATURE_ROOT, 16, ["tree", "rock", "grass", "bush", "flower", "plant", "stump"])
        boot_state = 3
        boot_index = 0
        return
    if boot_state == 3:
        var count = 0
        while count < 2 and boot_index < 24:
            _spawn_one_nature(boot_index)
            boot_index += 1
            count += 1
        if boot_index >= 24:
            boot_state = 4
            status_label.text = "DIE ERSTE WELLE KOMMT ..."
        return
    if boot_state == 4:
        _start_wave()
        boot_state = 0
        status_label.text = "ARCANE BOLT AKTIV"

func _build_world():
    var world_environment = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("697b76")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("becdc3")
    environment.ambient_light_energy = 0.66
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-56.0, -32.0, 0.0)
    sun.light_color = Color("ffe4b8")
    sun.light_energy = 1.8
    sun.shadow_enabled = true
    add_child(sun)

    var ground = MeshInstance3D.new()
    var ground_mesh = PlaneMesh.new()
    ground_mesh.size = Vector2(58.0, 58.0)
    ground.mesh = ground_mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("3f5940")
    mat.roughness = 0.96
    ground.material_override = mat
    add_child(ground)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 15.7, 13.9)
    camera.rotation_degrees = Vector3(-49.0, 0.0, 0.0)
    camera.fov = 35.0
    camera.current = true
    add_child(camera)

func _build_hud():
    var layer = CanvasLayer.new()
    add_child(layer)

    var title = Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(38.0, 48.0)
    title.add_theme_font_size_override("font_size", 34)
    layer.add_child(title)

    wave_label = Label.new()
    wave_label.position = Vector2(40.0, 94.0)
    wave_label.add_theme_font_size_override("font_size", 20)
    layer.add_child(wave_label)

    score_label = Label.new()
    score_label.position = Vector2(40.0, 124.0)
    score_label.add_theme_font_size_override("font_size", 18)
    layer.add_child(score_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(40.0, 162.0)
    hp_bar.size = Vector2(310.0, 24.0)
    hp_bar.min_value = 0.0
    hp_bar.max_value = 100.0
    hp_bar.show_percentage = false
    layer.add_child(hp_bar)

    status_label = Label.new()
    status_label.position = Vector2(40.0, 205.0)
    status_label.add_theme_font_size_override("font_size", 18)
    layer.add_child(status_label)
    _refresh_hud()

func _spawn_player():
    var packed = load(PLAYER_SCENE)
    if packed == null:
        status_label.text = "MAGE ASSET FEHLT"
        return
    player = packed.instantiate()
    player.scale = Vector3.ONE * 1.34
    add_child(player)
    _play_first_animation(player)

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

func _spawn_one_nature(index):
    if nature_paths.size() == 0:
        return
    var path = nature_paths[index % nature_paths.size()]
    var packed = load(path)
    if packed == null:
        return
    var item = packed.instantiate()
    var ring = index / 8
    var slot = index % 8
    var angle = TAU * float(slot) / 8.0 + float(ring) * 0.22
    var radius = 5.2 + float(ring) * 2.9
    item.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    item.rotation.y = angle + boot_rng.randf_range(-0.55, 0.55)
    item.scale = Vector3.ONE * boot_rng.randf_range(1.05, 1.55)
    add_child(item)

func _start_wave():
    var count = 6 + wave * 2
    var i = 0
    while i < count:
        _spawn_enemy(i, count)
        i += 1
    _refresh_hud()

func _spawn_enemy(index, total):
    var enemy = null
    if monster_paths.size() > 0:
        var path = monster_paths[index % monster_paths.size()]
        var packed = load(path)
        if packed != null:
            enemy = packed.instantiate()
    if enemy == null:
        enemy = MeshInstance3D.new()
        var mesh = SphereMesh.new()
        mesh.radius = 0.5
        mesh.height = 1.0
        enemy.mesh = mesh
    var angle = TAU * float(index) / float(max(1, total))
    var radius = 13.0 + fmod(float(index) * 2.27, 8.0)
    enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    enemy.set_meta("hp", 3 + wave)
    enemy.set_meta("speed", 1.5 + float(wave) * 0.08)
    enemy.set_meta("cooldown", 0.0)
    add_child(enemy)
    enemies.append(enemy)
    _play_first_animation(enemy)

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
        player.position += dir * 5.8 * delta
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 13.0))

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
        if offset.length() > 1.2:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.7)) * delta
        elif cooldown <= 0.0:
            enemy.set_meta("cooldown", 0.8)
            hp = max(0, hp - 5)
            _refresh_hud()

func _cast_bolt():
    var target = _nearest_enemy()
    if target == null or player == null:
        return
    var orb = MeshInstance3D.new()
    var mesh = SphereMesh.new()
    mesh.radius = 0.2
    mesh.height = 0.4
    orb.mesh = mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("7a4cff")
    mat.emission_enabled = true
    mat.emission = Color("a86fff")
    mat.emission_energy_multiplier = 5.0
    orb.material_override = mat
    orb.position = player.position + Vector3(0.0, 1.0, 0.0)
    orb.set_meta("target", target)
    orb.set_meta("life", 2.0)
    add_child(orb)
    projectiles.append(orb)

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

func _update_projectiles(delta):
    var copy = projectiles.duplicate()
    for orb in copy:
        if not is_instance_valid(orb):
            projectiles.erase(orb)
            continue
        var target = orb.get_meta("target")
        var life = float(orb.get_meta("life", 0.0)) - delta
        orb.set_meta("life", life)
        if life <= 0.0 or target == null or not is_instance_valid(target):
            projectiles.erase(orb)
            orb.queue_free()
            continue
        var direction = target.global_position + Vector3(0.0, 0.6, 0.0) - orb.global_position
        if direction.length() < 0.7:
            _hit_enemy(target)
            projectiles.erase(orb)
            orb.queue_free()
            continue
        orb.global_position += direction.normalized() * 13.0 * delta

func _hit_enemy(enemy):
    if not is_instance_valid(enemy):
        return
    var enemy_hp = int(enemy.get_meta("hp", 1)) - 1
    enemy.set_meta("hp", enemy_hp)
    if enemy_hp <= 0:
        enemies.erase(enemy)
        score += 5
        enemy.queue_free()
        _refresh_hud()
        if enemies.size() == 0:
            wave += 1
            _start_wave()

func _update_camera(delta):
    if player == null or camera == null:
        return
    var desired = player.position + Vector3(0.0, 15.7, 13.9)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 5.8))

func _refresh_hud():
    if wave_label != null:
        wave_label.text = "WAVE %02d" % wave
    if score_label != null:
        score_label.text = "RUNE SCORE %05d" % score
    if hp_bar != null:
        hp_bar.value = hp

func _play_first_animation(root):
    var players = root.find_children("*", "AnimationPlayer", true, false)
    if players.size() == 0:
        return
    var animation_player = players[0]
    var names = animation_player.get_animation_list()
    if names.size() > 0:
        animation_player.play(names[0])
