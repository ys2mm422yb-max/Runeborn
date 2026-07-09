extends Node3D

const MAGE_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"

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

func _ready():
    _build_environment()
    _build_fixed_forest()
    _spawn_player()
    _spawn_wave()

func _process(delta):
    _update_player(delta)
    _update_enemies(delta)
    _update_camera(delta)

    attack_timer -= delta
    if attack_timer <= 0.0:
        attack_timer = 0.72
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
    environment.background_color = Color("31443c")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("b8c9bd")
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
    sun.light_color = Color("ffe1ad")
    sun.light_energy = 1.7
    sun.shadow_enabled = true
    add_child(sun)

    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-38.0, 150.0, 0.0)
    fill.light_color = Color("9db6cb")
    fill.light_energy = 0.32
    fill.shadow_enabled = false
    add_child(fill)

    camera = Camera3D.new()
    camera.position = Vector3(0.0, 13.8, 10.8)
    camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
    camera.fov = 48.0
    camera.current = true
    add_child(camera)

func _build_fixed_forest():
    var grass_positions = [
        Vector3(-8, 0, -12), Vector3(-4, 0, -12), Vector3(0, 0, -12), Vector3(4, 0, -12), Vector3(8, 0, -12),
        Vector3(-8, 0, -8), Vector3(-4, 0, -8), Vector3(0, 0, -8), Vector3(4, 0, -8), Vector3(8, 0, -8),
        Vector3(-8, 0, -4), Vector3(-4, 0, -4), Vector3(0, 0, -4), Vector3(4, 0, -4), Vector3(8, 0, -4),
        Vector3(-8, 0, 0), Vector3(-4, 0, 0), Vector3(0, 0, 0), Vector3(4, 0, 0), Vector3(8, 0, 0),
        Vector3(-8, 0, 4), Vector3(-4, 0, 4), Vector3(0, 0, 4), Vector3(4, 0, 4), Vector3(8, 0, 4),
        Vector3(-8, 0, 8), Vector3(-4, 0, 8), Vector3(0, 0, 8), Vector3(4, 0, 8), Vector3(8, 0, 8),
        Vector3(-8, 0, 12), Vector3(-4, 0, 12), Vector3(0, 0, 12), Vector3(4, 0, 12), Vector3(8, 0, 12)
    ]
    for position in grass_positions:
        _spawn_asset(GRASS_A, position, 2.6, 0.0)

    var tree_layout = [
        [TREE_A, Vector3(-11.5, 0, -12.5), 1.45, 0.2],
        [TREE_B, Vector3(-7.5, 0, -14.0), 1.55, 1.1],
        [TREE_A, Vector3(-2.5, 0, -15.2), 1.38, 2.2],
        [TREE_B, Vector3(3.2, 0, -15.0), 1.62, 0.6],
        [TREE_A, Vector3(8.0, 0, -13.7), 1.48, 1.8],
        [TREE_B, Vector3(11.5, 0, -10.5), 1.55, 2.7],
        [TREE_A, Vector3(12.5, 0, -5.0), 1.42, 0.9],
        [TREE_B, Vector3(12.8, 0, 1.0), 1.60, 2.1],
        [TREE_A, Vector3(11.8, 0, 7.0), 1.50, 0.4],
        [TREE_B, Vector3(8.5, 0, 12.7), 1.58, 1.5],
        [TREE_A, Vector3(3.0, 0, 14.5), 1.45, 2.4],
        [TREE_B, Vector3(-3.0, 0, 14.5), 1.62, 0.8],
        [TREE_A, Vector3(-8.5, 0, 12.5), 1.50, 1.9],
        [TREE_B, Vector3(-11.7, 0, 7.0), 1.55, 2.8],
        [TREE_A, Vector3(-12.8, 0, 1.0), 1.42, 1.2],
        [TREE_B, Vector3(-12.5, 0, -5.2), 1.60, 2.3]
    ]
    for entry in tree_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var rock_layout = [
        [ROCK_A, Vector3(-8.2, 0, -7.0), 1.2, 0.4],
        [ROCK_B, Vector3(7.5, 0, -8.0), 1.0, 1.7],
        [ROCK_A, Vector3(9.2, 0, 5.5), 1.35, 2.6],
        [ROCK_B, Vector3(-9.0, 0, 6.5), 1.15, 0.9],
        [ROCK_A, Vector3(-5.5, 0, 10.0), 0.95, 2.2],
        [ROCK_B, Vector3(5.0, 0, 10.5), 1.1, 1.3]
    ]
    for entry in rock_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var bush_positions = [
        Vector3(-10.5, 0, -9.0), Vector3(-5.0, 0, -12.0), Vector3(5.5, 0, -12.5), Vector3(10.0, 0, -8.0),
        Vector3(10.5, 0, 2.5), Vector3(8.5, 0, 9.5), Vector3(0.5, 0, 12.5), Vector3(-7.5, 0, 10.0),
        Vector3(-10.5, 0, 3.5), Vector3(-8.5, 0, -2.5)
    ]
    var index = 0
    for position in bush_positions:
        _spawn_asset(BUSH_A, position, 1.25 + float(index % 3) * 0.14, float(index) * 0.61)
        index += 1

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
    player.scale = Vector3.ONE * 0.82
    player.position = Vector3.ZERO
    add_child(player)
    _play_animation(player, ["idle"])

func _spawn_wave():
    var count = min(12, 5 + wave)
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
        var angle = TAU * float(index) / float(count)
        var radius = 8.5 + float(index % 3) * 1.25
        enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        enemy.rotation.y = angle + PI
        enemy.scale = Vector3.ONE * 0.88
        enemy.set_meta("hp", 3 + wave)
        enemy.set_meta("speed", 1.45 + float(wave) * 0.06)
        enemy.set_meta("cooldown", 0.0)
        enemy.set_meta("alive", true)
        add_child(enemy)
        enemies.append(enemy)
        _play_animation(enemy, ["walk", "run", "idle"])

func _update_player(delta):
    if player == null:
        return
    var keyboard = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec = move_input if move_input.length() > 0.05 else keyboard
    var direction = Vector3(input_vec.x, 0.0, input_vec.y)
    if direction.length() > 0.05:
        direction = direction.normalized()
        player.position += direction * 5.0 * delta
        player.position.x = clamp(player.position.x, -8.5, 8.5)
        player.position.z = clamp(player.position.z, -11.0, 11.0)
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
        if not bool(enemy.get_meta("alive", true)):
            continue
        var offset = player.position - enemy.position
        offset.y = 0.0
        var cooldown = max(0.0, float(enemy.get_meta("cooldown", 0.0)) - delta)
        enemy.set_meta("cooldown", cooldown)
        if offset.length() > 1.0:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.5)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.0))
            _play_animation(enemy, ["walk", "run"])
        elif cooldown <= 0.0:
            enemy.set_meta("cooldown", 0.9)
            hp = max(0, hp - 5)
            _play_animation(enemy, ["attack", "combat"])

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
    if target == null:
        return
    var offset = target.position - player.position
    offset.y = 0.0
    if offset.length() > 0.01:
        player.rotation.y = atan2(offset.x, offset.z)
    _play_animation(player, ["attack", "cast", "spell"])
    var enemy_hp = int(target.get_meta("hp", 1)) - 1
    target.set_meta("hp", enemy_hp)
    if enemy_hp <= 0:
        target.set_meta("alive", false)
        enemies.erase(target)
        score += 5
        _play_animation(target, ["death", "die"])
        target.queue_free()
        if _living_enemy_count() == 0:
            wave_delay = 0.9

func _living_enemy_count():
    var count = 0
    for enemy in enemies:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            count += 1
    return count

func _update_camera(delta):
    if player == null or camera == null:
        return
    var desired = player.position + Vector3(0.0, 13.8, 10.8)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 5.5))

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
