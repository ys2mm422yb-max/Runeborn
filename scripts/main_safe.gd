extends Node3D

const PLAYER_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const MONSTER_ROOT = "res://assets/monsters"
const NATURE_ROOT = "res://assets/nature"

var player = null
var camera = null
var enemies = []
var monster_paths = []
var nature_paths = []
var monster_records = []
var nature_records = []
var monster_roster = []
var ground_roster = []
var tall_roster = []
var decor_roster = []

var move_input = Vector2.ZERO
var touch_origin = Vector2.ZERO
var active_touch = -1
var attack_timer = 0.0
var player_attack_time = 0.0
var wave = 1
var score = 0
var hp = 100
var wave_pending = false
var wave_delay = 0.0
var camera_kick_time = 0.0
var camera_kick_strength = 0.0

var wave_label = null
var score_label = null
var hp_bar = null
var status_label = null

var boot_state = 0
var boot_index = 0
var build_index = 0
var boot_rng = RandomNumberGenerator.new()

func _ready():
    boot_rng.seed = 68421
    _build_environment()
    _build_hud()
    _spawn_player()
    boot_state = 1
    status_label.text = "PAKETDATEIEN WERDEN GEPRUEFT ..."

func _process(delta):
    if boot_state > 0:
        _boot_step()
        return

    player_attack_time = max(0.0, player_attack_time - delta)
    camera_kick_time = max(0.0, camera_kick_time - delta)
    _update_player(delta)
    _update_enemies(delta)
    _update_wave_transition(delta)
    _update_camera(delta)

    attack_timer -= delta
    if attack_timer <= 0.0 and not wave_pending:
        attack_timer = 0.68
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
        move_input = ((event.position - touch_origin) / 110.0).limit_length(1.0)

func _boot_step():
    if boot_state == 1:
        var all_monsters = _find_models_limited(MONSTER_ROOT, 500)
        var all_nature = _find_models_limited(NATURE_ROOT, 1400)
        monster_paths = _sample_paths(all_monsters, 32)
        nature_paths = _sample_paths(all_nature, 48)
        boot_index = 0
        boot_state = 2
        status_label.text = "NATURE-ASSETS WERDEN VALIDiert ..."
        return

    if boot_state == 2:
        if boot_index < nature_paths.size():
            var nature_record = _inspect_model(nature_paths[boot_index])
            if nature_record != null:
                nature_records.append(nature_record)
            boot_index += 1
            return
        boot_index = 0
        boot_state = 3
        status_label.text = "MONSTER-ASSETS WERDEN VALIDiert ..."
        return

    if boot_state == 3:
        if boot_index < monster_paths.size():
            var monster_record = _inspect_model(monster_paths[boot_index])
            if monster_record != null:
                monster_records.append(monster_record)
            boot_index += 1
            return
        boot_state = 4
        status_label.text = "PAKET-AUSWAHL WIRD FESTGELEGT ..."
        return

    if boot_state == 4:
        _build_package_rosters()
        build_index = 0
        boot_state = 5
        status_label.text = "BODEN AUS NATURE-PAKET ..."
        return

    if boot_state == 5:
        var ground_steps = 0
        while ground_steps < 2 and build_index < 36:
            _spawn_ground_tile(build_index)
            build_index += 1
            ground_steps += 1
        if build_index >= 36:
            build_index = 0
            boot_state = 6
            status_label.text = "WALDRAND AUS NATURE-PAKET ..."
        return

    if boot_state == 6:
        var scenery_steps = 0
        while scenery_steps < 2 and build_index < 32:
            _spawn_scenery_piece(build_index)
            build_index += 1
            scenery_steps += 1
        if build_index >= 32:
            boot_state = 7
            status_label.text = "ERSTE MONSTERWELLE ..."
        return

    if boot_state == 7:
        _start_wave()
        boot_state = 0
        status_label.text = "RUNENKAMPF AKTIV"

func _build_environment():
    var world_environment = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("596b65")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("c4cec8")
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -34.0, 0.0)
    sun.light_color = Color("ffe2b8")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    add_child(sun)

    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-40.0, 145.0, 0.0)
    fill.light_color = Color("98abc0")
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    add_child(fill)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 18.2, 15.8)
    camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
    camera.fov = 40.0
    camera.current = true
    add_child(camera)

func _build_hud():
    var layer = CanvasLayer.new()
    add_child(layer)

    var title = Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(38.0, 48.0)
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("f1ebf7"))
    layer.add_child(title)

    wave_label = Label.new()
    wave_label.position = Vector2(40.0, 88.0)
    wave_label.add_theme_font_size_override("font_size", 18)
    wave_label.add_theme_color_override("font_color", Color("e3dce9"))
    layer.add_child(wave_label)

    score_label = Label.new()
    score_label.position = Vector2(40.0, 116.0)
    score_label.add_theme_font_size_override("font_size", 16)
    score_label.add_theme_color_override("font_color", Color("cbc4d1"))
    layer.add_child(score_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(40.0, 148.0)
    hp_bar.size = Vector2(280.0, 18.0)
    hp_bar.min_value = 0.0
    hp_bar.max_value = 100.0
    hp_bar.show_percentage = false
    layer.add_child(hp_bar)

    status_label = Label.new()
    status_label.position = Vector2(40.0, 181.0)
    status_label.add_theme_font_size_override("font_size", 15)
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
    var player_size = _measure_instance(player)
    var player_height = max(0.01, player_size.y)
    var player_scale = 1.75 / player_height
    player.scale = Vector3.ONE * player_scale
    add_child(player)
    _play_matching_animation(player, ["idle", "general"])

func _find_models_limited(root, limit):
    var result = []
    _scan_dir(root, result, limit)
    return result

func _scan_dir(path, result, limit):
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
                if _scan_dir(full, result, limit):
                    dir.list_dir_end()
                    return true
            else:
                var lower = full.to_lower()
                if lower.ends_with(".glb") or lower.ends_with(".gltf"):
                    result.append(full)
                    if result.size() >= limit:
                        dir.list_dir_end()
                        return true
        entry = dir.get_next()
    dir.list_dir_end()
    return false

func _sample_paths(source, wanted):
    var sampled = []
    if source.size() == 0:
        return sampled
    var sample_count = min(wanted, source.size())
    var i = 0
    while i < sample_count:
        var sample_index = int(floor(float(i) * float(source.size()) / float(sample_count)))
        sample_index = clamp(sample_index, 0, source.size() - 1)
        var path = source[sample_index]
        if not sampled.has(path):
            sampled.append(path)
        i += 1
    return sampled

func _inspect_model(path):
    var packed = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
    if packed == null:
        return null
    var instance = packed.instantiate()
    if instance == null:
        return null
    var meshes = instance.find_children("*", "MeshInstance3D", true, false)
    if meshes.size() == 0:
        instance.free()
        return null
    var size = _measure_instance(instance)
    instance.free()
    packed = null
    if size.x <= 0.001 or size.y <= 0.001 or size.z <= 0.001:
        return null
    return {
        "path": path,
        "size": size,
        "height": size.y,
        "footprint": max(size.x, size.z),
        "ratio": size.y / max(0.001, max(size.x, size.z))
    }

func _measure_instance(root):
    var meshes = root.find_children("*", "MeshInstance3D", true, false)
    var max_x = 0.0
    var max_y = 0.0
    var max_z = 0.0
    for mesh_node in meshes:
        if mesh_node.mesh != null:
            var box = mesh_node.mesh.get_aabb()
            var local_size = box.size
            var node_scale = mesh_node.scale.abs()
            max_x = max(max_x, local_size.x * node_scale.x)
            max_y = max(max_y, local_size.y * node_scale.y)
            max_z = max(max_z, local_size.z * node_scale.z)
    return Vector3(max_x, max_y, max_z)

func _build_package_rosters():
    ground_roster.clear()
    tall_roster.clear()
    decor_roster.clear()
    monster_roster.clear()

    var lowest_ratio = 999999.0
    var lowest_record = null
    for record in nature_records:
        var ratio = float(record["ratio"])
        var footprint = float(record["footprint"])
        var height = float(record["height"])
        if ratio < lowest_ratio:
            lowest_ratio = ratio
            lowest_record = record
        if ratio <= 0.32 and footprint > 0.15:
            ground_roster.append(record)
        elif ratio >= 0.85 and height > 0.3:
            tall_roster.append(record)
        else:
            decor_roster.append(record)

    if ground_roster.size() == 0 and lowest_record != null:
        ground_roster.append(lowest_record)

    if tall_roster.size() == 0:
        for record in nature_records:
            if not ground_roster.has(record):
                tall_roster.append(record)

    if decor_roster.size() == 0:
        for record in nature_records:
            if not ground_roster.has(record):
                decor_roster.append(record)

    var valid_monsters = []
    for record in monster_records:
        var height = float(record["height"])
        var footprint = float(record["footprint"])
        if height > 0.02 and footprint > 0.02:
            valid_monsters.append(record)

    if valid_monsters.size() > 0:
        var wanted = min(8, valid_monsters.size())
        var i = 0
        while i < wanted:
            var sample_index = int(floor(float(i) * float(valid_monsters.size()) / float(wanted)))
            sample_index = clamp(sample_index, 0, valid_monsters.size() - 1)
            var selected = valid_monsters[sample_index]
            if not monster_roster.has(selected):
                monster_roster.append(selected)
            i += 1

func _spawn_ground_tile(index):
    if ground_roster.size() == 0:
        return
    var record = ground_roster[index % ground_roster.size()]
    var packed = load(record["path"])
    if packed == null:
        return
    var item = packed.instantiate()
    if item == null:
        return
    var footprint = max(0.01, float(record["footprint"]))
    var target_footprint = 7.6
    var scale_value = target_footprint / footprint
    var column = index % 6
    var row = index / 6
    item.position = Vector3((float(column) - 2.5) * 7.0, -0.08, (float(row) - 2.5) * 7.0)
    item.rotation.y = float((index + row) % 4) * PI * 0.5
    item.scale = Vector3.ONE * scale_value
    add_child(item)

func _spawn_scenery_piece(index):
    var use_tall = index < 20
    var pool = decor_roster
    var ring_index = index - 20
    var divisor = 12
    var radius = boot_rng.randf_range(8.0, 12.0)
    var target_height = boot_rng.randf_range(0.8, 1.8)

    if use_tall:
        pool = tall_roster
        ring_index = index
        divisor = 20
        radius = boot_rng.randf_range(12.5, 16.5)
        target_height = boot_rng.randf_range(4.0, 6.0)

    if pool.size() == 0:
        return
    var record = pool[index % pool.size()]
    var packed = load(record["path"])
    if packed == null:
        return
    var item = packed.instantiate()
    if item == null:
        return

    var angle = TAU * float(ring_index) / float(divisor)
    angle += boot_rng.randf_range(-0.08, 0.08)
    item.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    item.rotation.y = boot_rng.randf_range(0.0, TAU)

    var source_height = max(0.01, float(record["height"]))
    item.scale = Vector3.ONE * (target_height / source_height)
    add_child(item)

func _start_wave():
    if monster_roster.size() == 0:
        status_label.text = "KEINE SICHTBAREN MONSTER-ASSETS"
        return
    wave_pending = false
    wave_delay = 0.0
    var count = min(15, 6 + wave * 2)
    var i = 0
    while i < count:
        _spawn_enemy(i, count)
        i += 1
    _refresh_hud()

func _spawn_enemy(index, total):
    if monster_roster.size() == 0:
        return
    var record = monster_roster[index % monster_roster.size()]
    var packed = load(record["path"])
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
    var radius = 10.0 + fmod(float(index) * 1.47, 4.2)
    enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    enemy.rotation.y = angle + PI

    var source_height = max(0.01, float(record["height"]))
    var target_height = 1.1 + float(index % 4) * 0.17
    var scale_value = target_height / source_height
    enemy.scale = Vector3.ONE * scale_value
    enemy.set_meta("base_scale", enemy.scale)
    enemy.set_meta("hp", 3 + wave)
    enemy.set_meta("speed", 1.35 + float(wave) * 0.07)
    enemy.set_meta("cooldown", 0.0)
    enemy.set_meta("hit_time", 0.0)
    enemy.set_meta("death_time", 0.0)
    enemy.set_meta("knockback", Vector3.ZERO)
    enemy.set_meta("alive", true)
    add_child(enemy)
    enemies.append(enemy)
    _play_matching_animation(enemy, ["walk", "run", "move", "idle"])

func _update_player(delta):
    if player == null:
        return

    var keyboard = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec = move_input
    if move_input.length() <= 0.05:
        input_vec = keyboard
    var dir = Vector3(input_vec.x, 0.0, input_vec.y)

    if player_attack_time > 0.0:
        return

    if dir.length() > 0.05:
        dir = dir.normalized()
        player.position += dir * 5.5 * delta
        player.position.x = clamp(player.position.x, -12.0, 12.0)
        player.position.z = clamp(player.position.z, -15.0, 15.0)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 12.0))
        _play_matching_animation(player, ["walk", "run", "move"])
    else:
        _play_matching_animation(player, ["idle", "general"])

func _update_enemies(delta):
    if player == null:
        return

    var copy = enemies.duplicate()
    for enemy in copy:
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue

        var death_time = float(enemy.get_meta("death_time", 0.0))
        if death_time > 0.0:
            death_time = max(0.0, death_time - delta)
            enemy.set_meta("death_time", death_time)
            var knockback_death = enemy.get_meta("knockback", Vector3.ZERO)
            enemy.position += knockback_death * delta
            enemy.rotation.z += delta * 5.2
            var death_ratio = death_time / 0.36
            var base_scale_death = enemy.get_meta("base_scale", enemy.scale)
            enemy.scale = base_scale_death * max(0.05, death_ratio)
            if death_time <= 0.0:
                enemies.erase(enemy)
                enemy.queue_free()
            continue

        if not bool(enemy.get_meta("alive", true)):
            continue

        var hit_time = float(enemy.get_meta("hit_time", 0.0))
        var knockback = enemy.get_meta("knockback", Vector3.ZERO)
        if hit_time > 0.0:
            hit_time = max(0.0, hit_time - delta)
            enemy.set_meta("hit_time", hit_time)
            enemy.position += knockback * delta
            knockback = knockback.lerp(Vector3.ZERO, min(1.0, delta * 10.0))
            enemy.set_meta("knockback", knockback)
            if hit_time <= 0.0:
                enemy.scale = enemy.get_meta("base_scale", enemy.scale)
                _play_matching_animation(enemy, ["walk", "run", "move", "idle"])
            continue

        var cooldown = max(0.0, float(enemy.get_meta("cooldown", 0.0)) - delta)
        enemy.set_meta("cooldown", cooldown)
        var offset = player.position - enemy.position
        offset.y = 0.0

        if offset.length() > 1.15:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.5)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
            _play_matching_animation(enemy, ["walk", "run", "move"])
        elif cooldown <= 0.0:
            enemy.set_meta("cooldown", 0.82)
            _play_matching_animation(enemy, ["attack", "bite", "combat", "hit"])
            hp = max(0, hp - 5)
            _kick_camera(0.10, 0.08)
            _refresh_hud()

func _attack_nearest_enemy():
    var target = _nearest_enemy()
    if target == null or player == null:
        return

    var offset = target.position - player.position
    offset.y = 0.0
    if offset.length() > 0.01:
        player.rotation.y = atan2(offset.x, offset.z)

    player_attack_time = 0.22
    _play_matching_animation(player, ["spell", "cast", "attack", "ranged", "combat"])
    _hit_enemy(target)

func _nearest_enemy():
    if player == null:
        return null
    var target = null
    var best = INF
    for enemy in enemies:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            var distance = player.position.distance_squared_to(enemy.position)
            if distance < best:
                best = distance
                target = enemy
    return target

func _hit_enemy(enemy):
    if not is_instance_valid(enemy):
        return
    if not bool(enemy.get_meta("alive", true)):
        return

    var enemy_hp = int(enemy.get_meta("hp", 1)) - 1
    enemy.set_meta("hp", enemy_hp)
    var base_scale = enemy.get_meta("base_scale", enemy.scale)
    enemy.scale = base_scale * 1.14

    var knock_direction = enemy.position - player.position
    knock_direction.y = 0.0
    if knock_direction.length() > 0.01:
        knock_direction = knock_direction.normalized()
    enemy.set_meta("knockback", knock_direction * 4.5)
    enemy.set_meta("hit_time", 0.13)
    _play_matching_animation(enemy, ["hit", "damage", "hurt"])
    _kick_camera(0.07, 0.045)

    if enemy_hp <= 0:
        enemy.set_meta("alive", false)
        enemy.set_meta("hit_time", 0.0)
        enemy.set_meta("death_time", 0.36)
        enemy.set_meta("knockback", knock_direction * 6.0)
        _play_matching_animation(enemy, ["death", "die", "dead"])
        score += 5
        _kick_camera(0.11, 0.075)
        _refresh_hud()

        if _living_enemy_count() == 0:
            wave_pending = true
            wave_delay = 0.8

func _living_enemy_count():
    var count = 0
    for enemy in enemies:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            count += 1
    return count

func _update_wave_transition(delta):
    if not wave_pending:
        return
    wave_delay -= delta
    if wave_delay <= 0.0:
        wave += 1
        _start_wave()

func _update_camera(delta):
    if player == null or camera == null:
        return

    var desired = player.position + Vector3(0.0, 18.2, 15.8)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 5.0))

    if camera_kick_time > 0.0:
        camera.position += Vector3(
            randf_range(-camera_kick_strength, camera_kick_strength),
            randf_range(-camera_kick_strength, camera_kick_strength),
            0.0
        )

func _kick_camera(duration, strength):
    camera_kick_time = max(camera_kick_time, duration)
    camera_kick_strength = strength

func _refresh_hud():
    if wave_label != null:
        wave_label.text = "WAVE %02d" % wave
    if score_label != null:
        score_label.text = "RUNE SCORE %05d" % score
    if hp_bar != null:
        hp_bar.value = hp

func _play_matching_animation(root, keywords):
    var players = root.find_children("*", "AnimationPlayer", true, false)
    if players.size() == 0:
        return false

    var animation_player = players[0]
    var names = animation_player.get_animation_list()
    for keyword in keywords:
        var wanted = str(keyword).to_lower()
        for animation_name in names:
            var animation_text = str(animation_name)
            if animation_text.to_lower().contains(wanted):
                if animation_player.current_animation != animation_name:
                    animation_player.play(animation_name)
                return true
    return false
