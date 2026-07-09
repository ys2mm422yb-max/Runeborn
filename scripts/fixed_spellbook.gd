extends Node3D

const SPELLBOOK_SCENE = "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Assets/gltf/spellbook_open.gltf"

var game = null
var mage = null
var book = null
var float_time = 0.0
var last_attack_timer = 0.0
var cast_push = 0.0

func _ready():
    game = get_parent()
    _spawn_book()
    set_process(true)

func _process(delta):
    float_time += delta
    if game == null:
        return
    if mage == null or not is_instance_valid(mage):
        mage = game.get_node_or_null("RunebornMage")
        return
    if book == null or not is_instance_valid(book):
        return

    var attack_timer = float(game.get("attack_timer"))
    if attack_timer > last_attack_timer + 0.30:
        cast_push = 1.0
    last_attack_timer = attack_timer
    cast_push = max(0.0, cast_push - delta * 5.0)

    var side = mage.global_transform.basis.x.normalized()
    var forward = -mage.global_transform.basis.z.normalized()
    var bob = sin(float_time * 3.0) * 0.06
    var desired = mage.global_position + side * 0.82 + Vector3(0.0, 0.92 + bob, 0.0)
    desired += forward * cast_push * 0.52

    global_position = global_position.lerp(desired, min(1.0, delta * 12.0))
    rotation.y = lerp_angle(rotation.y, mage.rotation.y + 0.35 + cast_push * 0.45, min(1.0, delta * 10.0))
    rotation.z = -0.18 + sin(float_time * 2.2) * 0.04

func _spawn_book():
    var packed = load(SPELLBOOK_SCENE)
    if packed == null:
        push_error("SPELLBOOK FAILED TO LOAD")
        return
    book = packed.instantiate()
    if book == null:
        push_error("SPELLBOOK INSTANCE FAILED")
        return
    book.scale = Vector3.ONE * 0.72
    book.rotation_degrees = Vector3(-12.0, 0.0, -8.0)
    add_child(book)
