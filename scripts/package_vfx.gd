extends Node3D

const MAGIC_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/magic_03.png"
const TRACE_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/trace_04.png"
const CIRCLE_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/circle_03.png"
const SPARK_TEX = "res://assets/vfx/10_VFX/kenney_particle-pack/PNG (Transparent)/spark_05.png"

var game = null
var mage = null
var focus = null
var last_attack_time = 0.0
var effects = []
var known_enemy_ids = {}

func _ready():
    game = get_parent()
    set_process(true)

func _process(delta):
    if game == null:
        return
    if mage == null or not is_instance_valid(mage):
        mage = game.get_node_or_null("RunebornMage")
    if focus == null or not is_instance_valid(focus):
        focus = game.get_node_or_null("SpellbookFocus")

    _scan_new_enemies()

    var attack_time = float(game.get("player_attack_time"))
    if attack_time > 0.0 and last_attack_time <= 0.0:
        _spawn_cast()
    last_attack_time = attack_time
    _update_effects(delta)

func _scan_new_enemies():
    var enemy_list = game.get("enemies")
    for enemy in enemy_list:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            var enemy_id = enemy.get_instance_id()
            if not known_enemy_ids.has(enemy_id):
                known_enemy_ids[enemy_id] = true
                _spawn_enemy_arrival(enemy)

func _spawn_enemy_arrival(enemy):
    var position = enemy.global_position + Vector3(0.0, 0.6, 0.0)

    var arrival_magic = _make_sprite(MAGIC_TEX, Color(0.46, 0.31, 0.72, 0.88), 0.0044)
    arrival_magic.global_position = position
    add_child(arrival_magic)
    effects.append({"node": arrival_magic, "kind": "pulse", "life": 0.48, "max_life": 0.48})

    var arrival_circle = _make_sprite(CIRCLE_TEX, Color(0.36, 0.24, 0.62, 0.78), 0.0040)
    arrival_circle.global_position = position
    add_child(arrival_circle)
    effects.append({"node": arrival_circle, "kind": "impact", "life": 0.42, "max_life": 0.42})

func _spawn_cast():
    if mage == null:
        return
    var target = _nearest_living_enemy()
    if target == null:
        return

    var origin = mage.global_position + Vector3(0.0, 1.0, 0.0)
    if focus != null and is_instance_valid(focus):
        origin = focus.global_position

    var pulse = _make_sprite(MAGIC_TEX, Color(0.72, 0.48, 1.0, 0.96), 0.0054)
    pulse.global_position = origin
    add_child(pulse)
    effects.append({"node": pulse, "kind": "pulse", "life": 0.34, "max_life": 0.34})

    var trace = _make_sprite(TRACE_TEX, Color(0.68, 0.42, 1.0, 0.98), 0.0042)
    trace.global_position = origin
    add_child(trace)
    effects.append({"node": trace, "kind": "trace", "life": 0.62, "max_life": 0.62, "target": target})

func _nearest_living_enemy():
    if mage == null:
        return null
    var enemy_list = game.get("enemies")
    var best_enemy = null
    var best_distance = INF
    for enemy in enemy_list:
        if is_instance_valid(enemy) and bool(enemy.get_meta("alive", true)):
            var distance = mage.global_position.distance_squared_to(enemy.global_position)
            if distance < best_distance:
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

        if kind == "pulse":
            var pulse_ratio = clamp(float(effect["life"]) / float(effect["max_life"]), 0.0, 1.0)
            var pulse_scale = 0.62 + (1.0 - pulse_ratio) * 1.28
            node.scale = Vector3.ONE * pulse_scale
            var pulse_color = node.modulate
            pulse_color.a = pulse_ratio
            node.modulate = pulse_color
            node.rotation.z += delta * 5.5

        elif kind == "trace":
            var target = effect["target"]
            if target == null or not is_instance_valid(target):
                _remove_effect(index)
                index -= 1
                continue
            var destination = target.global_position + Vector3(0.0, 0.65, 0.0)
            node.global_position = node.global_position.move_toward(destination, delta * 22.0)
            node.rotation.z += delta * 8.0
            var distance = node.global_position.distance_to(destination)
            var trace_scale = 0.56 + sin(Time.get_ticks_msec() * 0.018) * 0.08
            node.scale = Vector3.ONE * trace_scale
            if distance < 0.48:
                _spawn_impact(destination)
                _remove_effect(index)
                index -= 1
                continue

        elif kind == "impact":
            var impact_ratio = clamp(float(effect["life"]) / float(effect["max_life"]), 0.0, 1.0)
            var impact_scale = 0.52 + (1.0 - impact_ratio) * 1.65
            node.scale = Vector3.ONE * impact_scale
            var impact_color = node.modulate
            impact_color.a = impact_ratio
            node.modulate = impact_color
            node.rotation.z += delta * 3.5

        elif kind == "spark":
            var spark_ratio = clamp(float(effect["life"]) / float(effect["max_life"]), 0.0, 1.0)
            node.scale = Vector3.ONE * (0.76 + (1.0 - spark_ratio) * 0.82)
            var spark_color = node.modulate
            spark_color.a = spark_ratio
            node.modulate = spark_color
            node.position.y += delta * 0.75

        if float(effect["life"]) <= 0.0:
            _remove_effect(index)

        index -= 1

func _spawn_impact(position):
    var circle = _make_sprite(CIRCLE_TEX, Color(0.58, 0.32, 1.0, 0.94), 0.0048)
    circle.global_position = position
    add_child(circle)
    effects.append({"node": circle, "kind": "impact", "life": 0.30, "max_life": 0.30})

    var spark = _make_sprite(SPARK_TEX, Color(0.90, 0.78, 1.0, 1.0), 0.0040)
    spark.global_position = position + Vector3(0.0, 0.12, 0.0)
    add_child(spark)
    effects.append({"node": spark, "kind": "spark", "life": 0.26, "max_life": 0.26})

func _remove_effect(index):
    if index < 0 or index >= effects.size():
        return
    var node = effects[index]["node"]
    if node != null and is_instance_valid(node):
        node.queue_free()
    effects.remove_at(index)
