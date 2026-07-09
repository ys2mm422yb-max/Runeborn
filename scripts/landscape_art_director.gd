extends Node3D

const TREE_C = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_1_A_Color1.gltf"
const TREE_D = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Tree_4_A_Color1.gltf"
const BUSH_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Bush_2_C_Color1.gltf"
const GRASS_A = "res://assets/nature/01_Nature/KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/Grass_2_B_Color1.gltf"

var applied = false

func _ready():
    call_deferred("_apply_art_direction")

func _apply_art_direction():
    if applied:
        return
    applied = true

    var game = get_parent()
    var replacements = []

    for child in game.get_children():
        if child == self:
            continue
        if _contains_tree_token(child, "Tree_2_A_Color1") or _contains_tree_token(child, "Tree_3_B_Color1"):
            replacements.append({
                "node": child,
                "position": child.position,
                "rotation": child.rotation.y,
                "scale": child.scale.x
            })

    var index = 0
    for replacement in replacements:
        var old_node = replacement["node"]
        if is_instance_valid(old_node):
            old_node.visible = false
        var path = TREE_C if index % 2 == 0 else TREE_D
        var scale_value = float(replacement["scale"]) * (0.82 if index % 2 == 0 else 0.76)
        _spawn_asset(path, replacement["position"], scale_value, float(replacement["rotation"]) + float(index % 5) * 0.22)
        index += 1

    _add_midground_layers()

func _contains_tree_token(node, token):
    if str(node.name).contains(token):
        return true
    for child in node.get_children():
        if _contains_tree_token(child, token):
            return true
    return false

func _add_midground_layers():
    var bush_positions = [
        Vector3(-12.5, 0.0, -10.5), Vector3(-7.5, 0.0, -12.2), Vector3(-1.5, 0.0, -13.0),
        Vector3(5.5, 0.0, -12.4), Vector3(11.0, 0.0, -10.2), Vector3(13.2, 0.0, -5.0),
        Vector3(13.5, 0.0, 1.8), Vector3(12.0, 0.0, 8.2), Vector3(7.0, 0.0, 11.2),
        Vector3(0.0, 0.0, 12.3), Vector3(-7.0, 0.0, 11.4), Vector3(-12.0, 0.0, 8.0),
        Vector3(-13.5, 0.0, 1.5), Vector3(-13.0, 0.0, -5.0)
    ]
    var index = 0
    for position in bush_positions:
        _spawn_asset(BUSH_A, position, 0.68 + float(index % 3) * 0.07, float(index) * 0.63)
        index += 1

    var grass_positions = [
        Vector3(-10.5, 0.02, -8.5), Vector3(-6.0, 0.02, -10.0), Vector3(-1.0, 0.02, -10.5),
        Vector3(4.0, 0.02, -10.0), Vector3(9.0, 0.02, -8.0), Vector3(10.5, 0.02, -3.0),
        Vector3(10.5, 0.02, 3.0), Vector3(8.5, 0.02, 8.0), Vector3(3.5, 0.02, 10.0),
        Vector3(-2.0, 0.02, 10.5), Vector3(-7.5, 0.02, 8.5), Vector3(-10.0, 0.02, 4.0),
        Vector3(-10.5, 0.02, -2.0)
    ]
    index = 0
    for position in grass_positions:
        _spawn_asset(GRASS_A, position, 0.72 + float(index % 4) * 0.05, float(index) * 0.71)
        index += 1

func _spawn_asset(path, position, scale_value, rotation_y):
    var packed = load(path)
    if packed == null:
        push_error("LANDSCAPE ART ASSET FAILED: " + path)
        return null
    var instance = packed.instantiate()
    if instance == null:
        push_error("LANDSCAPE ART INSTANCE FAILED: " + path)
        return null
    instance.position = position
    instance.scale = Vector3.ONE * scale_value
    instance.rotation.y = rotation_y
    add_child(instance)
    return instance
