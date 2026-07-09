extends Node3D

const TREE_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_2_A_Color1.gltf"
const TREE_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_3_B_Color1.gltf"
const ROCK_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_2_A_Color1.gltf"
const ROCK_B = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Rock_3_D_Color1.gltf"
const BUSH_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Bush_2_C_Color1.gltf"
const GRASS_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Grass_2_B_Color1.gltf"

func _ready():
    call_deferred("_apply_polish")

func _apply_polish():
    _tune_camera_and_light()
    _build_outer_forest_depth()
    _soften_floor_edges()

func _tune_camera_and_light():
    var game = get_parent()
    var game_camera = game.get("camera")
    if game_camera != null and is_instance_valid(game_camera):
        game_camera.fov = 42.0
        game_camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)

    for child in game.get_children():
        if child is WorldEnvironment and child.environment != null:
            child.environment.background_color = Color("1f2f29")
            child.environment.ambient_light_color = Color("b4c2b5")
            child.environment.ambient_light_energy = 0.62
        elif child is DirectionalLight3D:
            if child.shadow_enabled:
                child.light_energy = 1.42
            else:
                child.light_energy = 0.24

func _build_outer_forest_depth():
    var outer_layout = [
        [TREE_B, Vector3(-14.6, 0, -13.8), 1.72, 0.4],
        [TREE_A, Vector3(-10.3, 0, -16.8), 1.58, 1.8],
        [TREE_B, Vector3(-5.5, 0, -17.6), 1.70, 2.6],
        [TREE_A, Vector3(0.0, 0, -18.2), 1.62, 0.9],
        [TREE_B, Vector3(5.5, 0, -17.3), 1.76, 2.0],
        [TREE_A, Vector3(10.8, 0, -16.1), 1.60, 1.2],
        [TREE_B, Vector3(14.8, 0, -12.6), 1.74, 2.9],
        [TREE_A, Vector3(15.5, 0, -6.7), 1.62, 0.7],
        [TREE_B, Vector3(15.8, 0, -0.8), 1.78, 1.9],
        [TREE_A, Vector3(15.2, 0, 5.6), 1.58, 2.5],
        [TREE_B, Vector3(13.8, 0, 11.5), 1.72, 0.3],
        [TREE_A, Vector3(9.8, 0, 15.7), 1.60, 1.5],
        [TREE_B, Vector3(4.8, 0, 17.2), 1.76, 2.4],
        [TREE_A, Vector3(-0.8, 0, 17.8), 1.64, 0.8],
        [TREE_B, Vector3(-6.4, 0, 16.7), 1.70, 1.7],
        [TREE_A, Vector3(-11.2, 0, 14.8), 1.58, 2.8],
        [TREE_B, Vector3(-14.5, 0, 10.6), 1.74, 0.5],
        [TREE_A, Vector3(-15.6, 0, 4.8), 1.62, 1.4],
        [TREE_B, Vector3(-15.8, 0, -1.4), 1.76, 2.2],
        [TREE_A, Vector3(-15.4, 0, -7.6), 1.60, 0.1]
    ]
    for entry in outer_layout:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

    var depth_bushes = [
        Vector3(-12.8, 0, -11.5), Vector3(-8.2, 0, -14.2), Vector3(-2.8, 0, -15.2),
        Vector3(3.2, 0, -15.0), Vector3(8.7, 0, -13.8), Vector3(12.7, 0, -10.1),
        Vector3(13.7, 0, -4.0), Vector3(13.8, 0, 2.2), Vector3(12.3, 0, 8.0),
        Vector3(8.5, 0, 12.6), Vector3(3.0, 0, 14.5), Vector3(-2.8, 0, 14.8),
        Vector3(-8.0, 0, 12.8), Vector3(-12.1, 0, 8.4), Vector3(-13.7, 0, 2.5),
        Vector3(-13.5, 0, -4.0)
    ]
    var index = 0
    for position in depth_bushes:
        _spawn_asset(BUSH_A, position, 1.20 + float(index % 4) * 0.09, float(index) * 0.57)
        index += 1

func _soften_floor_edges():
    var edge_grass = [
        Vector3(-9.0, 0.02, -11.5), Vector3(-6.5, 0.02, -12.5), Vector3(-1.8, 0.02, -12.8),
        Vector3(2.5, 0.02, -12.7), Vector3(6.8, 0.02, -12.0), Vector3(9.0, 0.02, -9.3),
        Vector3(9.5, 0.02, -5.5), Vector3(9.7, 0.02, -1.0), Vector3(9.4, 0.02, 4.0),
        Vector3(9.0, 0.02, 8.7), Vector3(6.5, 0.02, 11.8), Vector3(2.0, 0.02, 12.7),
        Vector3(-2.5, 0.02, 12.6), Vector3(-6.8, 0.02, 11.4), Vector3(-9.0, 0.02, 8.2),
        Vector3(-9.5, 0.02, 3.4), Vector3(-9.6, 0.02, -1.3), Vector3(-9.4, 0.02, -6.8)
    ]
    var index = 0
    for position in edge_grass:
        _spawn_asset(GRASS_A, position, 1.22 + float(index % 3) * 0.08, float(index) * 0.69)
        index += 1

    var edge_rocks = [
        [ROCK_A, Vector3(-8.9, 0, -11.0), 0.72, 0.8],
        [ROCK_B, Vector3(8.7, 0, -10.8), 0.70, 2.1],
        [ROCK_A, Vector3(9.1, 0, 10.0), 0.76, 1.4],
        [ROCK_B, Vector3(-8.8, 0, 10.2), 0.68, 2.7]
    ]
    for entry in edge_rocks:
        _spawn_asset(entry[0], entry[1], entry[2], entry[3])

func _spawn_asset(path, position, scale_value, rotation_y):
    var packed = load(path)
    if packed == null:
        push_error("POLISH ASSET FAILED: " + path)
        return null
    var instance = packed.instantiate()
    if instance == null:
        push_error("POLISH INSTANCE FAILED: " + path)
        return null
    instance.position = position
    instance.scale = Vector3.ONE * scale_value
    instance.rotation.y = rotation_y
    add_child(instance)
    return instance
