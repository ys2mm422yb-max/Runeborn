extends Node3D

const SPELLBOOK_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Assets/gltf/spellbook_open.gltf"

var mage = null
var book = null
var float_time = 0.0
var last_attack_time = 0.0
var attack_push = 0.0

func _ready():
    set_process(true)
    _spawn_book()

func _process(delta):
    float_time += delta
    if mage == null or not is_instance_valid(mage):
        mage = get_parent().get_node_or_null("RunebornMage")
        return
    if book == null or not is_instance_valid(book):
        return

    var parent_attack_time = float(get_parent().get("player_attack_time"))
    if parent_attack_time > last_attack_time:
        attack_push = 1.0
    last_attack_time = parent_attack_time
    attack_push = max(0.0, attack_push - delta * 5.8)

    var side = mage.global_transform.basis.x.normalized()
    var forward = -mage.global_transform.basis.z.normalized()
    var bob = sin(float_time * 3.2) * 0.10
    var desired = mage.global_position
    desired += side * 0.92
    desired += Vector3(0.0, 1.05 + bob, 0.0)
    desired += forward * attack_push * 0.85

    global_position = global_position.lerp(desired, min(1.0, delta * 11.0))
    rotation.y += delta * (0.55 + attack_push * 2.2)
    rotation.z = sin(float_time * 2.1) * 0.10

func _spawn_book():
    var packed = load(SPELLBOOK_SCENE)
    if packed == null:
        return
    book = packed.instantiate()
    if book == null:
        return
    add_child(book)

    var meshes = book.find_children("*", "MeshInstance3D", true, false)
    var max_height = 0.01
    for mesh_node in meshes:
        if mesh_node.mesh != null:
            max_height = max(max_height, mesh_node.mesh.get_aabb().size.y * abs(mesh_node.scale.y))
    var scale_value = 0.52 / max_height
    book.scale = Vector3.ONE * scale_value
    book.rotation_degrees = Vector3(-18.0, 0.0, -12.0)
