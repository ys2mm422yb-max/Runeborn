extends Node3D

const MAGIC_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/magic_03.png"
const TRACE_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/trace_04.png"
const CIRCLE_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/circle_03.png"
const SPARK_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/spark_05.png"

var game = null
var spellbook = null
var last_attack_timer = 0.0
var effects = []

func _ready():
    game = get_parent()
    set_process(true)

func _process(delta):
    if game == null:
        return
    if spellbook == null or not is_instance_valid(spellbook):
        spellbook = game.get_node_or_null("FixedSpellbook")

    var attack_timer = float(game.get("attack_timer"))
    if attack_timer > last_attack_timer + 0.30:
        _spawn_player_cast()
    last_attack_timer = attack_timer
    _update_effects(delta)

func _spawn_player_cast():
    var target = _nearest_living_enemy()
    if target == null:
        return

    var origin = target.global_position
    if spellbook != null and is_instance_valid(spellbook):
        origin = spellbook.global_position

    var magic = _make_sprite(MAGIC_TEX, Color(0.76, 0.50, 1.0, 1.0), 0.0055)
    magic.global_position = origin + Vector3(0.0, 0.08, 0.0)
    add_child(magic)
    effects.append({"node": magic, "kind": "cast", "life": 0.34, "max_life": 0.34})

    var trace = _make_sprite(TRACE_TEX, Color(0.68, 0.40, 1.0, 1.0), 0.0038)
    trace.global_position = origin + Vector3(0.0, 0.08, 0.0)
    add_child(trace)
    effects.append({"node": trace, "kind": "trace", "life": 0.85, "max_life": 0.85, "target": target})

func _nearest_living_enemy():
    var player = game.get("player")
    if player == null or not is_instance_valid(player):
        return null
    var best_enemy = null
    var best_distance = INF
    var enemy_list = game.get("enemies")
    for enemy in enemy_list:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            var distance = player.global_position.distance_squared_to(enemy.global_position)
            if distance < best_distance and distance <= 42.25:
                best_distance = distance
                best_enemy = enemy
    return best_enemy

func _make_sprite(texture_path, color, pixel_size):
    var sprite = Sprite3D.new()
    sprite.texture = load(texture_path)
    sprite.pixel_size = pixel_size
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.modulate = color
    sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return sprite

func _update_effects(delta):
    var index = effects.size() - 1
    while index >= 0:
        var effect = effects[index]
        var node = effect["node"]
        if node == null or not is_instance_valid(node):
            effects.remove_at(index)
            index -= 1
            continue

        effect["life"] = float(effect["life"]) - delta
        var kind = str(effect["kind"])
        var ratio = clamp(float(effect["life"]) / float(effect["max_life"]), 0.0, 1.0)

        if kind == "cast":
            node.scale = Vector3.ONE * (0.55 + (1.0 - ratio) * 0.82)
            node.rotation.z += delta * 6.0
            _set_alpha(node, ratio)

        elif kind == "trace":
            var target = effect["target"]
            if target == null or not is_instance_valid(target) or not bool(target.get_meta("alive", true)):
                _remove_effect(index)
                index -= 1
                continue
            var destination = target.global_position + Vector3(0.0, 0.82, 0.0)
            var previous = node.global_position
            node.global_position = node.global_position.move_toward(destination, delta * 16.5)
            var travel = node.global_position - previous
            if travel.length() > 0.001:
                node.rotation.z = atan2(travel.y, travel.x)
            node.scale = Vector3.ONE * (0.62 + sin(Time.get_ticks_msec() * 0.018) * 0.08)
            if node.global_position.distance_to(destination) < 0.42:
                _spawn_impact(destination)
                _remove_effect(index)
                index -= 1
                continue

        elif kind == "impact":
            node.scale = Vector3.ONE * (0.42 + (1.0 - ratio) * 1.25)
            node.rotation.z += delta * 4.5
            _set_alpha(node, ratio)

        elif kind == "spark":
            node.scale = Vector3.ONE * (0.72 + (1.0 - ratio) * 0.58)
            node.position.y += delta * 0.48
            _set_alpha(node, ratio)

        if float(effect["life"]) <= 0.0:
            _remove_effect(index)
        index -= 1

func _spawn_impact(position):
    var circle = _make_sprite(CIRCLE_TEX, Color(0.60, 0.34, 1.0, 1.0), 0.0046)
    circle.global_position = position
    add_child(circle)
    effects.append({"node": circle, "kind": "impact", "life": 0.32, "max_life": 0.32})

    var spark = _make_sprite(SPARK_TEX, Color(0.94, 0.82, 1.0, 1.0), 0.0040)
    spark.global_position = position + Vector3(0.0, 0.08, 0.0)
    add_child(spark)
    effects.append({"node": spark, "kind": "spark", "life": 0.26, "max_life": 0.26})

func _set_alpha(node, alpha):
    var color = node.modulate
    color.a = alpha
    node.modulate = color

func _remove_effect(index):
    if index < 0 or index >= effects.size():
        return
    var node = effects[index]["node"]
    if node != null and is_instance_valid(node):
        node.queue_free()
    effects.remove_at(index)
