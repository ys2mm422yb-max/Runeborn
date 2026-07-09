extends Node3D

const MAGE_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"

const FLOOR_DIRT = "res://assets/ruins/07_Ruins/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/floor_dirt_large.gltf"
const TREE_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_2_A_Color1.gltf"
const TREE_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_3_B_Color1.gltf"
const ROCK_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_2_A_Color1.gltf"
const ROCK_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_3_D_Color1.gltf"
const BUSH_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Bush_2_C_Color1.gltf"
const GRASS_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Grass_2_B_Color1.gltf"

const SKELETON_MINION = "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Minion.glb"
const SKELETON_ROGUE = "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Rogue.glb"
const SKELETON_WARRIOR = "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Warrior.glb"
const SKELETON_MAGE = "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Mage.glb"

const MONSTER_SCENES = [
    SKELETON_MINION,
    SKELETON_ROGUE,
    SKELETON_WARRIOR,
    SKELETON_MAGE
]

var player = null
var camera = null
var enemies = []
var move_input = Vector2.ZERO
var touch_origin = Vector2.ZERO
var active_touch = -1
var attack_timer = 0.0
var wave = 1
var score = 0
var hp = 100
var wave_delay = -1.0
var player_hit_pulse = 0.0
var camera_shake = 0.0
var player_hit_serial = 0
var player_attack_serial = 0
var cast_camera_pull = 0.0
var cast_target = null

func _ready():
    _build_environment()
    _build_package_floor()
    _build_fixed_forest()
    _spawn_player()
    _spawn_wave()

func _process(delta):
    _update_player(delta)
    _update_enemies(delta)
    _update_player_hit_state(delta)
    _update_camera(delta)

    attack_timer -= delta
    if attack_timer <= 0.0:
        attack_timer = 0.62
        _attack_nearest()

    if wave_delay >= 0.0:
        wave_delay -= delta
        if wave_delay <= 0.0:
            wave_delay = -1.0
            wave += 1
            _spawn_wave()

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
        move_input = ((event.position - touch_origin) / 105.0).limit_length(1.0)

func _build_environment():
    var world_environment = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("24342e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("bac8bb")
    environment.ambient_light_energy = 0.68
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50.0, -32.0, 0.0)
    sun.light_color = Color("ffdca7")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    add_child(sun)

    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-34.0, 145.0, 0.0)
    fill.light_color = Color("a6bed0")
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    add_child(fill)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 10.8, 8.2)
    camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
    camera.fov = 44.0
    camera.current = true
    add_child(camera)

func _build_package_floor():
    for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
        for z in [-12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0]:
            _spawn_asset(FLOOR_DIRT, Vector3(x, 0.0, z), 1.0, 0.0)

func _build_fixed_forest():
    var tree_layout = [
        [TREE_A, Vector3(-10.8, 0, -13.0), 1.35, 0.2], [TREE_B, Vector3(-6.8, 0, -14.2), 1.48, 1.1],
        [TREE_A, Vector3(-1.8, 0, -15.0), 1.30, 2.2], [TREE_B, Vector3(3.5, 0, -14.8), 1.52, 0.6],
        [TREE_A, Vector3(8.2, 0, -13.4), 1.38, 1.8], [TREE_B, Vector3(11.2, 0, -9.7), 1.50, 2.7],
        [TREE_A, Vector3(12.0, 0, -4.2), 1.34, 0.9], [TREE_B, Vector3(12.2, 0, 1.8), 1.48, 2.1],
        [TREE_A, Vector3(11.2, 0, 7.5), 1.38, 0.4], [TREE_B, Vector3(8.0, 0, 12.4), 1.50, 1.5],
        [TREE_A, Vector3(2.8, 0, 14.0), 1.34, 2.4], [TREE_B, Vector3(-3.2, 0, 14.2), 1.50, 0.8],
        [TREE_A, Vector3(-8.2, 0, 12.0), 1.38, 1.9], [TREE_B, Vector3(-11.2, 0, 7.2), 1.46, 2.8],
        [TREE_A, Vector3(-12.0, 0, 1.0), 1.32, 1.2], [TREE_B, Vector3(-11.8, 0, -5.0), 1.48, 2.3]
    ]
    for entry in tree_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var rock_layout = [
        [ROCK_A, Vector3(-8.0, 0, -8.5), 1.10, 0.4], [ROCK_B, Vector3(7.8, 0, -9.0), 0.95, 1.7],
        [ROCK_A, Vector3(8.8, 0, 6.8), 1.22, 2.6], [ROCK_B, Vector3(-8.8, 0, 7.5), 1.05, 0.9],
        [ROCK_A, Vector3(-5.8, 0, 11.0), 0.90, 2.2], [ROCK_B, Vector3(5.4, 0, 11.2), 1.00, 1.3]
    ]
    for entry in rock_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var bush_positions = [
        Vector3(-9.8, 0, -10.3), Vector3(-4.2, 0, -12.2), Vector3(5.0, 0, -12.0), Vector3(9.5, 0, -8.2),
        Vector3(10.0, 0, 3.0), Vector3(8.2, 0, 9.6), Vector3(0.8, 0, 12.0), Vector3(-7.2, 0, 10.0),
        Vector3(-10.0, 0, 3.8), Vector3(-9.4, 0, -2.8)
    ]
    var bush_index = 0
    for position in bush_positions:
        _spawn_asset(BUSH_A, position, 1.08 + float(bush_index % 3) * 0.12, float(bush_index) * 0.61)
        bush_index += 1

    var grass_layout = [
        Vector3(-7.0, 0.02, -10.0), Vector3(-3.5, 0.02, -11.0), Vector3(3.0, 0.02, -10.5), Vector3(6.5, 0.02, -9.5),
        Vector3(8.0, 0.02, -3.5), Vector3(8.2, 0.02, 3.5), Vector3(6.2, 0.02, 8.5), Vector3(2.5, 0.02, 10.0),
        Vector3(-2.5, 0.02, 10.0), Vector3(-6.5, 0.02, 8.5), Vector3(-8.0, 0.02, 3.2), Vector3(-8.0, 0.02, -3.5),
        Vector3(-5.2, 0.02, -6.8), Vector3(5.4, 0.02, -6.5), Vector3(5.8, 0.02, 6.0), Vector3(-5.8, 0.02, 6.2)
    ]
    var grass_index = 0
    for position in grass_layout:
        _spawn_asset(GRASS_A, position, 1.15 + float(grass_index % 4) * 0.08, float(grass_index) * 0.73)
        grass_index += 1

func _spawn_asset(path, position, scale_value, rotation_y):
    var packed = load(path)
    if packed == null:
        push_error("PACKAGE ASSET FAILED: " + path)
        return null
    var instance = packed.instantiate()
    if instance == null:
        push_error("PACKAGE INSTANCE FAILED: " + path)
        return null
    instance.position = position
    instance.scale = Vector3.ONE * scale_value
    instance.rotation.y = rotation_y
    add_child(instance)
    return instance

func _spawn_player():
    var packed = load(MAGE_SCENE)
    if packed == null:
        push_error("MAGE FAILED TO LOAD")
        return
    player = packed.instantiate()
    player.name = "RunebornMage"
    player.scale = Vector3.ONE
    player.position = Vector3.ZERO
    add_child(player)
    _play_animation(player, ["idle"])

func _spawn_wave():
    var count = min(10, 4 + wave)
    for index in range(count):
        var path = MONSTER_SCENES[index % MONSTER_SCENES.size()]
        var packed = load(path)
        if packed == null:
            push_error("MONSTER FAILED: " + path)
            continue
        var enemy = packed.instantiate()
        if enemy == null:
            push_error("MONSTER INSTANCE FAILED: " + path)
            continue

        var role = _role_for_index(index)
        var angle = TAU * float(index) / float(count)
        var radius = 8.2 + float(index % 2) * 1.1
        enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        enemy.rotation.y = angle + PI
        enemy.scale = Vector3.ONE * _role_scale(role)
        enemy.set_meta("role", role)
        enemy.set_meta("base_scale", enemy.scale)
        enemy.set_meta("hp", _role_hp(role))
        enemy.set_meta("speed", _role_speed(role))
        enemy.set_meta("cooldown", 0.25 + float(index % 4) * 0.12)
        enemy.set_meta("alive", true)
        enemy.set_meta("stagger", 0.0)
        enemy.set_meta("hit_punch", 0.0)
        enemy.set_meta("death_time", 0.0)
        enemy.set_meta("windup", 0.0)
        enemy.set_meta("knockback", Vector3.ZERO)
        enemy.set_meta("orbit_sign", -1.0 if index % 2 == 0 else 1.0)
        enemy.set_meta("attack_serial", 0)
        add_child(enemy)
        enemies.append(enemy)
        _play_animation(enemy, ["walk", "run", "idle"])

func _role_for_index(index):
    var slot = index % 4
    if slot == 1:
        return "rogue"
    if slot == 2:
        return "warrior"
    if slot == 3:
        return "mage"
    return "minion"

func _role_scale(role):
    if role == "warrior":
        return 1.08
    if role == "rogue":
        return 0.90
    if role == "mage":
        return 0.96
    return 0.94

func _role_hp(role):
    if role == "warrior":
        return 7 + wave * 2
    if role == "rogue":
        return 4 + wave
    if role == "mage":
        return 5 + wave
    return 3 + wave

func _role_speed(role):
    if role == "rogue":
        return 1.78 + float(wave) * 0.045
    if role == "warrior":
        return 0.95 + float(wave) * 0.035
    if role == "mage":
        return 1.18 + float(wave) * 0.04
    return 1.48 + float(wave) * 0.045

func _update_player(delta):
    if player == null:
        return
    var keyboard = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec = move_input if move_input.length() > 0.05 else keyboard
    var direction = Vector3(input_vec.x, 0.0, input_vec.y)
    if direction.length() > 0.05:
        direction = direction.normalized()
        player.position += direction * 4.7 * delta
        player.position.x = clamp(player.position.x, -7.5, 7.5)
        player.position.z = clamp(player.position.z, -10.5, 10.5)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(direction.x, direction.z), min(1.0, delta * 12.0))
        _play_animation(player, ["walk", "run"])
    else:
        _play_animation(player, ["idle"])

func _update_enemies(delta):
    if player == null:
        return
    var copy = enemies.duplicate()
    for enemy in copy:
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue

        var base_scale = enemy.get_meta("base_scale", enemy.scale)

        if not bool(enemy.get_meta("alive", true)):
            var death_time = max(0.0, float(enemy.get_meta("death_time", 0.0)) - delta)
            enemy.set_meta("death_time", death_time)
            var death_ratio = death_time / 0.72
            enemy.rotation.z += delta * 4.8
            enemy.scale = base_scale * max(0.05, death_ratio)
            if death_time <= 0.0:
                enemies.erase(enemy)
                enemy.queue_free()
            continue

        var windup = max(0.0, float(enemy.get_meta("windup", 0.0)) - delta)
        if windup > 0.0:
            enemy.set_meta("windup", windup)
            var windup_ratio = windup / 0.38
            enemy.scale = base_scale * (1.0 + (1.0 - windup_ratio) * 0.12)
            var face_offset = player.position - enemy.position
            face_offset.y = 0.0
            if face_offset.length() > 0.01:
                enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(face_offset.x, face_offset.z), min(1.0, delta * 14.0))
            if windup <= delta:
                enemy.scale = base_scale
                _apply_player_damage(_role_damage("warrior"), "warrior")
            continue
        enemy.set_meta("windup", 0.0)

        var hit_punch = max(0.0, float(enemy.get_meta("hit_punch", 0.0)) - delta * 6.8)
        enemy.set_meta("hit_punch", hit_punch)
        if hit_punch > 0.0:
            var punch = sin(hit_punch * PI)
            enemy.scale = base_scale * (1.0 + punch * 0.16)
            enemy.rotation.z = lerp(enemy.rotation.z, float(enemy.get_meta("orbit_sign", 1.0)) * punch * 0.16, min(1.0, delta * 20.0))
        else:
            enemy.scale = enemy.scale.lerp(base_scale, min(1.0, delta * 16.0))
            enemy.rotation.z = lerp(enemy.rotation.z, 0.0, min(1.0, delta * 14.0))

        var stagger = max(0.0, float(enemy.get_meta("stagger", 0.0)) - delta)
        enemy.set_meta("stagger", stagger)

        var knockback = enemy.get_meta("knockback", Vector3.ZERO)
        if knockback.length() > 0.02:
            enemy.position += knockback * delta
            enemy.set_meta("knockback", knockback.lerp(Vector3.ZERO, min(1.0, delta * 8.0)))

        if stagger > 0.0:
            continue

        var offset = player.position - enemy.position
        offset.y = 0.0
        var distance = offset.length()
        if distance <= 0.01:
            continue

        var role = str(enemy.get_meta("role", "minion"))
        var speed = float(enemy.get_meta("speed", 1.5))
        var cooldown = max(0.0, float(enemy.get_meta("cooldown", 0.0)) - delta)
        enemy.set_meta("cooldown", cooldown)

        var movement = _role_movement(enemy, role, offset, distance)
        var attack_range = _role_attack_range(role)

        if movement.length() > 0.05:
            enemy.position += movement.normalized() * speed * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
            _play_animation(enemy, ["walk", "run"])

        if distance <= attack_range and cooldown <= 0.0:
            enemy.set_meta("cooldown", _role_attack_cooldown(role))
            _play_animation(enemy, ["attack", "combat"])
            if role == "warrior":
                enemy.set_meta("windup", 0.38)
            elif role == "mage":
                enemy.set_meta("attack_serial", int(enemy.get_meta("attack_serial", 0)) + 1)
            else:
                _apply_player_damage(_role_damage(role), role)

func _role_movement(enemy, role, offset, distance):
    var toward = offset.normalized()
    var tangent = Vector3(-toward.z, 0.0, toward.x) * float(enemy.get_meta("orbit_sign", 1.0))

    if role == "rogue":
        if distance > 2.4:
            return (toward * 0.86 + tangent * 0.42).normalized()
        if distance < 1.45:
            return (-toward * 0.25 + tangent * 0.75).normalized()
        return (toward * 0.18 + tangent * 0.82).normalized()
    if role == "warrior":
        if distance > 1.35:
            return toward
        return Vector3.ZERO
    if role == "mage":
        if distance < 3.1:
            return (-toward * 0.82 + tangent * 0.42).normalized()
        if distance > 4.2:
            return (toward * 0.66 + tangent * 0.34).normalized()
        return tangent
    if distance > 1.08:
        return toward
    return Vector3.ZERO

func _role_attack_range(role):
    if role == "warrior":
        return 1.35
    if role == "rogue":
        return 1.25
    if role == "mage":
        return 4.35
    return 1.08

func _role_attack_cooldown(role):
    if role == "warrior":
        return 1.55
    if role == "rogue":
        return 0.78
    if role == "mage":
        return 1.35
    return 0.92

func _role_damage(role):
    if role == "warrior":
        return 9
    if role == "rogue":
        return 4
    if role == "mage":
        return 6
    return 5

func _apply_player_damage(amount, source_role = "minion"):
    hp = max(0, hp - int(amount))
    player_hit_pulse = 1.0
    player_hit_serial += 1
    if source_role == "warrior":
        camera_shake = max(camera_shake, 0.34)
    elif source_role == "mage":
        camera_shake = max(camera_shake, 0.26)
    else:
        camera_shake = max(camera_shake, 0.18)

func _apply_enemy_hit(target, amount = 1):
    if target == null or not is_instance_valid(target):
        return
    if not bool(target.get_meta("alive", true)):
        return

    var offset = target.position - player.position
    offset.y = 0.0
    var enemy_hp = int(target.get_meta("hp", 1)) - int(amount)
    target.set_meta("hp", enemy_hp)
    target.set_meta("stagger", 0.20)
    target.set_meta("hit_punch", 1.0)
    if offset.length() > 0.01:
        target.set_meta("knockback", offset.normalized() * 4.8)
    camera_shake = max(camera_shake, 0.09)

    if enemy_hp <= 0:
        target.set_meta("alive", false)
        target.set_meta("death_time", 0.72)
        target.set_meta("knockback", offset.normalized() * 2.8 if offset.length() > 0.01 else Vector3.ZERO)
        score += 5
        _play_animation(target, ["death", "die"])
        if _living_enemy_count() == 0:
            wave_delay = 1.15

func _update_player_hit_state(delta):
    if player == null:
        return
    player_hit_pulse = max(0.0, player_hit_pulse - delta * 5.8)
    var squash = sin(player_hit_pulse * PI)
    var target_scale = Vector3(1.0 + squash * 0.09, 1.0 - squash * 0.10, 1.0 + squash * 0.09)
    player.scale = player.scale.lerp(target_scale, min(1.0, delta * 18.0))
    if player_hit_pulse <= 0.01:
        player.scale = player.scale.lerp(Vector3.ONE, min(1.0, delta * 12.0))

func _attack_nearest():
    if player == null:
        return
    var target = null
    var best_distance = INF
    for enemy in enemies:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            var distance = player.position.distance_squared_to(enemy.position)
            if distance < best_distance:
                best_distance = distance
                target = enemy
    if target == null or best_distance > 42.25:
        return

    var offset = target.position - player.position
    offset.y = 0.0
    if offset.length() > 0.01:
        player.rotation.y = atan2(offset.x, offset.z)
    _play_animation(player, ["attack", "cast", "spell"])
    player_attack_serial += 1
    cast_camera_pull = 1.0
    cast_target = target

func _living_enemy_count():
    var count = 0
    for enemy in enemies:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            count += 1
    return count

func _update_camera(delta):
    if player == null or camera == null:
        return

    camera_shake = max(0.0, camera_shake - delta * 1.8)
    cast_camera_pull = max(0.0, cast_camera_pull - delta * 4.5)

    var shake = Vector3.ZERO
    if camera_shake > 0.0:
        var ticks = float(Time.get_ticks_msec()) * 0.001
        shake.x = sin(ticks * 63.0) * camera_shake * 0.42
        shake.y = sin(ticks * 79.0) * camera_shake * 0.24
        shake.z = cos(ticks * 57.0) * camera_shake * 0.30

    var focus_pull = Vector3.ZERO
    if cast_camera_pull > 0.0 and cast_target != null and is_instance_valid(cast_target):
        var target_offset = cast_target.position - player.position
        target_offset.y = 0.0
        focus_pull = target_offset.limit_length(1.4) * cast_camera_pull * 0.32

    var desired = player.position + Vector3(0.0, 10.8, 8.2) + focus_pull + shake
    camera.position = camera.position.lerp(desired, min(1.0, delta * 8.0))

func _play_animation(root, keywords):
    var players = root.find_children("*", "AnimationPlayer", true, false)
    if players.size() == 0:
        return false
    var animation_player = players[0]
    var names = animation_player.get_animation_list()
    for keyword in keywords:
        var wanted = str(keyword).to_lower()
        for animation_name in names:
            if str(animation_name).to_lower().contains(wanted):
                if animation_player.current_animation != animation_name:
                    animation_player.play(animation_name)
                return true
    if names.size() > 0 and animation_player.current_animation == "":
        animation_player.play(names[0])
    return names.size() > 0
