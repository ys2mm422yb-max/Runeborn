extends Node3D

const MAGE_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const FLOOR_DIRT = "res://assets/ruins/07_Ruins/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/floor_dirt_large.gltf"
const TREE_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_2_A_Color1.gltf"
const TREE_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_3_B_Color1.gltf"
const ROCK_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_2_A_Color1.gltf"
const ROCK_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_3_D_Color1.gltf"
const BUSH_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Bush_2_C_Color1.gltf"
const GRASS_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Grass_2_B_Color1.gltf"

const SKELETONS = [
    "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Minion.glb",
    "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Rogue.glb",
    "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Warrior.glb",
    "res://assets/monsters/02_Monsters/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Mage.glb"
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
var player_hit_serial = 0
var player_attack_serial = 0
var camera_shake = 0.0
var cast_camera_pull = 0.0
var cast_target = null

func _ready():
    _build_environment()
    _build_floor()
    _build_arena()
    _spawn_player()
    _spawn_wave()

func _process(delta):
    _update_player(delta)
    _update_enemies(delta)
    _update_player_hit(delta)
    _update_camera(delta)

    attack_timer -= delta
    if attack_timer <= 0.0:
        attack_timer = 0.62
        _start_player_cast()

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
        move_input = ((event.position - touch_origin) / 120.0).limit_length(1.0)

func _build_environment():
    var world_environment = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("1c2b25")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("b2c0b3")
    environment.ambient_light_energy = 0.58
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -36.0, 0.0)
    sun.light_color = Color("ffd49c")
    sun.light_energy = 1.28
    sun.shadow_enabled = true
    add_child(sun)

    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-30.0, 145.0, 0.0)
    fill.light_color = Color("a4bbcf")
    fill.light_energy = 0.20
    fill.shadow_enabled = false
    add_child(fill)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 9.2, 11.8)
    camera.rotation_degrees = Vector3(-38.0, 0.0, 0.0)
    camera.fov = 46.0
    camera.current = true
    add_child(camera)

func _build_floor():
    for x in [-16.0, -12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0]:
        for z in [-12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0]:
            _spawn_asset(FLOOR_DIRT, Vector3(x, 0.0, z), 1.0, 0.0)

func _build_arena():
    var tree_layout = [
        [TREE_A, Vector3(-19,0,-13),1.22,0.2], [TREE_B, Vector3(-14,0,-15),1.32,1.1],
        [TREE_A, Vector3(-8,0,-16),1.20,2.1], [TREE_B, Vector3(-2,0,-16.5),1.34,0.5],
        [TREE_A, Vector3(5,0,-16),1.24,1.7], [TREE_B, Vector3(11,0,-15.5),1.36,2.4],
        [TREE_A, Vector3(17,0,-13),1.22,0.8], [TREE_B, Vector3(20,0,-8),1.34,1.9],
        [TREE_A, Vector3(20,0,-1),1.20,2.7], [TREE_B, Vector3(20,0,6),1.34,0.4],
        [TREE_A, Vector3(17,0,12),1.24,1.3], [TREE_B, Vector3(11,0,15),1.32,2.2],
        [TREE_A, Vector3(5,0,16),1.20,0.7], [TREE_B, Vector3(-2,0,16.5),1.34,1.6],
        [TREE_A, Vector3(-9,0,16),1.22,2.5], [TREE_B, Vector3(-15,0,15),1.34,0.2],
        [TREE_A, Vector3(-19,0,12),1.24,1.1], [TREE_B, Vector3(-20,0,6),1.34,2.0],
        [TREE_A, Vector3(-20,0,-1),1.20,2.8], [TREE_B, Vector3(-20,0,-8),1.32,0.6]
    ]
    for entry in tree_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var rocks = [
        [ROCK_A, Vector3(-13,0,-9),0.82,0.5], [ROCK_B, Vector3(12,0,-10),0.72,1.6],
        [ROCK_A, Vector3(14,0,7),0.88,2.4], [ROCK_B, Vector3(-14,0,8),0.76,0.9],
        [ROCK_A, Vector3(-7,0,12),0.68,2.0], [ROCK_B, Vector3(7,0,12),0.72,1.1]
    ]
    for entry in rocks:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var bushes = [
        Vector3(-17,0,-11), Vector3(-11,0,-13), Vector3(-5,0,-14), Vector3(4,0,-14),
        Vector3(10,0,-13), Vector3(16,0,-10), Vector3(17,0,-4), Vector3(17,0,3),
        Vector3(15,0,9), Vector3(9,0,13), Vector3(2,0,14), Vector3(-5,0,14),
        Vector3(-11,0,13), Vector3(-16,0,9), Vector3(-17,0,3), Vector3(-17,0,-4)
    ]
    var bush_index = 0
    for position in bushes:
        _spawn_asset(BUSH_A, position, 0.92 + float(bush_index % 3) * 0.08, float(bush_index) * 0.55)
        bush_index += 1

    var grasses = [
        Vector3(-14,0.02,-11), Vector3(-9,0.02,-12), Vector3(-3,0.02,-12), Vector3(4,0.02,-12),
        Vector3(10,0.02,-11), Vector3(14,0.02,-8), Vector3(15,0.02,-2), Vector3(15,0.02,5),
        Vector3(12,0.02,10), Vector3(6,0.02,12), Vector3(0,0.02,12), Vector3(-6,0.02,12),
        Vector3(-12,0.02,10), Vector3(-15,0.02,5), Vector3(-15,0.02,-2), Vector3(-14,0.02,-7)
    ]
    var grass_index = 0
    for position in grasses:
        _spawn_asset(GRASS_A, position, 0.92 + float(grass_index % 4) * 0.07, float(grass_index) * 0.67)
        grass_index += 1

func _spawn_asset(path, position, scale_value, rotation_y):
    var packed = load(path)
    if packed == null:
        push_error("LANDSCAPE ASSET FAILED: " + path)
        return null
    var instance = packed.instantiate()
    if instance == null:
        push_error("LANDSCAPE INSTANCE FAILED: " + path)
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
    player.scale = Vector3.ONE * 0.72
    player.position = Vector3.ZERO
    add_child(player)
    _play_animation(player, ["idle"])

func _spawn_wave():
    var count = min(12, 5 + wave)
    for index in range(count):
        var path = SKELETONS[index % SKELETONS.size()]
        var packed = load(path)
        if packed == null:
            continue
        var enemy = packed.instantiate()
        if enemy == null:
            continue
        var role = _role_for_index(index)
        var angle = TAU * float(index) / float(count)
        var radius_x = 13.5 + float(index % 2) * 1.0
        var radius_z = 8.0 + float(index % 3) * 0.6
        enemy.position = Vector3(cos(angle) * radius_x, 0.0, sin(angle) * radius_z)
        enemy.rotation.y = angle + PI
        enemy.scale = Vector3.ONE * _role_scale(role)
        enemy.set_meta("role", role)
        enemy.set_meta("base_scale", enemy.scale)
        enemy.set_meta("hp", _role_hp(role))
        enemy.set_meta("speed", _role_speed(role))
        enemy.set_meta("cooldown", 0.3 + float(index % 4) * 0.12)
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
    return ["minion", "rogue", "warrior", "mage"][index % 4]

func _role_scale(role):
    if role == "warrior": return 0.82
    if role == "rogue": return 0.68
    if role == "mage": return 0.73
    return 0.70

func _role_hp(role):
    if role == "warrior": return 7 + wave * 2
    if role == "mage": return 5 + wave
    if role == "rogue": return 4 + wave
    return 3 + wave

func _role_speed(role):
    if role == "rogue": return 1.75 + float(wave) * 0.04
    if role == "warrior": return 0.92 + float(wave) * 0.03
    if role == "mage": return 1.15 + float(wave) * 0.04
    return 1.45 + float(wave) * 0.04

func _update_player(delta):
    if player == null:
        return
    var keyboard = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec = move_input if move_input.length() > 0.05 else keyboard
    var direction = Vector3(input_vec.x, 0.0, input_vec.y)
    if direction.length() > 0.05:
        direction = direction.normalized()
        player.position += direction * 4.9 * delta
        player.position.x = clamp(player.position.x, -15.0, 15.0)
        player.position.z = clamp(player.position.z, -9.5, 9.5)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(direction.x, direction.z), min(1.0, delta * 12.0))
        _play_animation(player, ["walk", "run"])
    else:
        _play_animation(player, ["idle"])

func _update_enemies(delta):
    if player == null:
        return
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var base_scale = enemy.get_meta("base_scale", enemy.scale)
        if not bool(enemy.get_meta("alive", true)):
            var death_time = max(0.0, float(enemy.get_meta("death_time", 0.0)) - delta)
            enemy.set_meta("death_time", death_time)
            enemy.rotation.z += delta * 4.5
            enemy.scale = base_scale * max(0.05, death_time / 0.72)
            if death_time <= 0.0:
                enemies.erase(enemy)
                enemy.queue_free()
            continue

        var previous_windup = float(enemy.get_meta("windup", 0.0))
        if previous_windup > 0.0:
            var windup = max(0.0, previous_windup - delta)
            enemy.set_meta("windup", windup)
            enemy.scale = base_scale * (1.0 + (1.0 - windup / 0.38) * 0.12)
            if windup <= 0.0:
                enemy.scale = base_scale
                _apply_player_damage(9, "warrior")
            continue

        var hit_punch = max(0.0, float(enemy.get_meta("hit_punch", 0.0)) - delta * 6.8)
        enemy.set_meta("hit_punch", hit_punch)
        if hit_punch > 0.0:
            var punch = sin(hit_punch * PI)
            enemy.scale = base_scale * (1.0 + punch * 0.16)
            enemy.rotation.z = float(enemy.get_meta("orbit_sign", 1.0)) * punch * 0.15
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
        var cooldown = max(0.0, float(enemy.get_meta("cooldown", 0.0)) - delta)
        enemy.set_meta("cooldown", cooldown)
        var movement = _role_movement(enemy, role, offset, distance)
        if movement.length() > 0.05:
            enemy.position += movement.normalized() * float(enemy.get_meta("speed", 1.4)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
            _play_animation(enemy, ["walk", "run"])

        if distance <= _role_attack_range(role) and cooldown <= 0.0:
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
        if distance > 2.5: return (toward * 0.86 + tangent * 0.40).normalized()
        if distance < 1.45: return (-toward * 0.22 + tangent * 0.78).normalized()
        return (toward * 0.18 + tangent * 0.82).normalized()
    if role == "warrior": return toward if distance > 1.3 else Vector3.ZERO
    if role == "mage":
        if distance < 3.2: return (-toward * 0.82 + tangent * 0.42).normalized()
        if distance > 5.0: return (toward * 0.68 + tangent * 0.32).normalized()
        return tangent
    return toward if distance > 1.05 else Vector3.ZERO

func _role_attack_range(role):
    if role == "warrior": return 1.3
    if role == "rogue": return 1.2
    if role == "mage": return 5.1
    return 1.05

func _role_attack_cooldown(role):
    if role == "warrior": return 1.55
    if role == "rogue": return 0.80
    if role == "mage": return 1.35
    return 0.92

func _role_damage(role):
    if role == "warrior": return 9
    if role == "rogue": return 4
    if role == "mage": return 6
    return 5

func _apply_player_damage(amount, source_role = "minion"):
    hp = max(0, hp - int(amount))
    player_hit_pulse = 1.0
    player_hit_serial += 1
    camera_shake = max(camera_shake, 0.34 if source_role == "warrior" else 0.24 if source_role == "mage" else 0.16)

func _apply_enemy_hit(target, amount = 1):
    if target == null or not is_instance_valid(target) or not bool(target.get_meta("alive", true)):
        return
    var offset = target.position - player.position
    offset.y = 0.0
    var enemy_hp = int(target.get_meta("hp", 1)) - int(amount)
    target.set_meta("hp", enemy_hp)
    target.set_meta("stagger", 0.20)
    target.set_meta("hit_punch", 1.0)
    if offset.length() > 0.01:
        target.set_meta("knockback", offset.normalized() * 4.3)
    camera_shake = max(camera_shake, 0.07)
    if enemy_hp <= 0:
        target.set_meta("alive", false)
        target.set_meta("death_time", 0.72)
        score += 5
        _play_animation(target, ["death", "die"])
        if _living_enemy_count() == 0:
            wave_delay = 1.15

func _update_player_hit(delta):
    if player == null:
        return
    player_hit_pulse = max(0.0, player_hit_pulse - delta * 5.8)
    var squash = sin(player_hit_pulse * PI)
    var base_scale = Vector3.ONE * 0.72
    var target_scale = base_scale * Vector3(1.0 + squash * 0.08, 1.0 - squash * 0.09, 1.0 + squash * 0.08)
    player.scale = player.scale.lerp(target_scale, min(1.0, delta * 18.0))

func _start_player_cast():
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
    if target == null or best_distance > 81.0:
        return
    var offset = target.position - player.position
    offset.y = 0.0
    if offset.length() > 0.01:
        player.rotation.y = atan2(offset.x, offset.z)
    _play_animation(player, ["attack", "cast", "spell"])
    cast_target = target
    player_attack_serial += 1
    cast_camera_pull = 1.0

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
    var ticks = float(Time.get_ticks_msec()) * 0.001
    var shake = Vector3.ZERO
    if camera_shake > 0.0:
        shake = Vector3(sin(ticks * 63.0) * camera_shake * 0.34, sin(ticks * 79.0) * camera_shake * 0.18, cos(ticks * 57.0) * camera_shake * 0.24)
    var focus_pull = Vector3.ZERO
    if cast_camera_pull > 0.0 and cast_target != null and is_instance_valid(cast_target):
        var target_offset = cast_target.position - player.position
        target_offset.y = 0.0
        focus_pull = target_offset.limit_length(1.8) * cast_camera_pull * 0.24
    var desired = player.position + Vector3(0.0, 9.2, 11.8) + focus_pull + shake
    camera.position = camera.position.lerp(desired, min(1.0, delta * 7.0))

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
