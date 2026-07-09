extends Node3D

const PLAYER_SCENE := "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf/Mage.glb"
const NATURE_ROOT := "res://assets/nature"
const MONSTER_ROOT := "res://assets/monsters"

var player: Node3D
var camera: Camera3D
var wave_director: WaveDirector
var enemies: Array[Node3D] = []
var projectiles: Array[Node3D] = []
var nature_scenes: Array[String] = []
var monster_scenes: Array[String] = []
var move_input := Vector2.ZERO
var touch_origin := Vector2.ZERO
var active_touch := -1
var fire_timer := 0.0
var nova_timer := 7.0
var time_alive := 0.0
var score := 0
var player_hp := 100
var wave_label: Label
var score_label: Label
var hp_bar: ProgressBar
var status_label: Label

func _ready() -> void:
    nature_scenes = AssetCatalog.collect_models(NATURE_ROOT, ["tree", "rock", "grass", "bush", "flower", "plant", "stump"], ["animation", "mannequin"])
    monster_scenes = AssetCatalog.collect_models(MONSTER_ROOT, [], ["animation", "movement", "general", "combat", "simulation", "special", "tools", "mannequin"])
    _build_world()
    _spawn_player()
    _spawn_nature()
    _build_hud()
    wave_director = WaveDirector.new()
    add_child(wave_director)
    wave_director.wave_started.connect(_on_wave_started)
    wave_director.wave_cleared.connect(_on_wave_cleared)
    _start_wave()

func _process(delta: float) -> void:
    time_alive += delta
    _update_player(delta)
    _update_enemies(delta)
    _update_projectiles(delta)
    _update_camera(delta)
    fire_timer -= delta
    nova_timer -= delta
    if fire_timer <= 0.0:
        fire_timer = max(0.34, 0.72 - float(wave_director.wave - 1) * 0.015)
        _cast_at_nearest_enemy()
    if nova_timer <= 0.0:
        nova_timer = 7.0
        _cast_arcane_nova()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1 and event.position.x < get_viewport().get_visible_rect().size.x * 0.75:
            active_touch = event.index
            touch_origin = event.position
            move_input = Vector2.ZERO
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == active_touch:
        move_input = ((event.position - touch_origin) / 100.0).limit_length(1.0)

func _build_world() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("697b76")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("becdc3")
    environment.ambient_light_energy = 0.66
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 1.28
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-56.0, -32.0, 0.0)
    sun.light_color = Color("ffe4b8")
    sun.light_energy = 1.8
    sun.shadow_enabled = true
    add_child(sun)

    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-35.0, 145.0, 0.0)
    fill.light_color = Color("8fa8d8")
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    add_child(fill)

    var ground := MeshInstance3D.new()
    ground.name = "ArenaGround"
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(58.0, 58.0)
    ground.mesh = ground_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("3f5940")
    mat.roughness = 0.96
    ground.material_override = mat
    add_child(ground)

    _build_rune_circle()

    camera = Camera3D.new()
    camera.name = "SpellBrigadeCamera"
    camera.position = Vector3(0.0, 15.7, 13.9)
    camera.rotation_degrees = Vector3(-49.0, 0.0, 0.0)
    camera.fov = 35.0
    camera.current = true
    add_child(camera)

func _build_rune_circle() -> void:
    var circle := RunebornFX.make_arcane_ring(4.3)
    circle.name = "ArenaRune"
    circle.position.y = 0.025
    circle.scale.y = 0.12
    add_child(circle)
    var tween := create_tween().set_loops()
    tween.tween_property(circle, "rotation:y", TAU, 18.0).from(0.0)

func _spawn_player() -> void:
    var packed := load(PLAYER_SCENE) as PackedScene
    if packed == null:
        push_error("Runeborn: Mage package asset missing")
        return
    player = packed.instantiate() as Node3D
    player.name = "RunebornMage"
    player.scale = Vector3.ONE * 1.34
    add_child(player)
    _play_animation(player, ["Idle", "idle", "General/Idle"])

func _spawn_nature() -> void:
    if nature_scenes.is_empty():
        push_warning("Runeborn: no filtered nature package assets found")
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 68421
    var placed := 0
    for i in range(120):
        var angle := rng.randf_range(0.0, TAU)
        var radius := rng.randf_range(10.5, 27.0)
        var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        var path := nature_scenes[rng.randi_range(0, nature_scenes.size() - 1)]
        var packed := load(path) as PackedScene
        if packed == null:
            continue
        var item := packed.instantiate() as Node3D
        item.position = pos
        item.rotation.y = rng.randf_range(0.0, TAU)
        var size := rng.randf_range(0.82, 1.38)
        item.scale = Vector3.ONE * size
        add_child(item)
        placed += 1
        if placed >= 64:
            break

func _start_wave() -> void:
    var count := wave_director.begin_wave()
    var elite := wave_director.is_elite_wave()
    for i in range(count):
        _spawn_enemy(i, count, elite and i == 0)

func _spawn_enemy(index: int, total: int, elite: bool) -> void:
    if monster_scenes.is_empty():
        return
    var path := monster_scenes[index % monster_scenes.size()]
    var packed := load(path) as PackedScene
    if packed == null:
        return
    var enemy := packed.instantiate() as Node3D
    var angle := TAU * float(index) / float(max(1, total))
    var radius := 13.0 + fmod(float(index) * 2.27, 8.0)
    enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    var difficulty := wave_director.difficulty_multiplier()
    var base_scale := 1.0 + fmod(float(index) * 0.17, 0.28)
    enemy.scale = Vector3.ONE * base_scale
    enemy.set_meta("base_scale", enemy.scale)
    enemy.set_meta("hp", int(3.0 * difficulty))
    enemy.set_meta("speed", 1.5 + difficulty * 0.28)
    enemy.set_meta("damage_cooldown", 0.0)
    enemy.set_meta("elite", elite)
    if elite:
        enemy.scale *= 1.7
        enemy.set_meta("base_scale", enemy.scale)
        enemy.set_meta("hp", int(20.0 * difficulty))
        enemy.set_meta("speed", 1.15 + difficulty * 0.12)
        _attach_elite_aura(enemy)
    add_child(enemy)
    enemies.append(enemy)
    _play_animation(enemy, ["Walk", "walk", "Run", "run", "Idle", "idle"])

func _attach_elite_aura(enemy: Node3D) -> void:
    var ring := RunebornFX.make_arcane_ring(1.25)
    ring.position.y = 0.08
    ring.scale.y = 0.1
    enemy.add_child(ring)
    var tween := create_tween().set_loops()
    tween.tween_property(ring, "rotation:y", -TAU, 2.8).from(0.0)

func _update_player(delta: float) -> void:
    if player == null:
        return
    var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_vec := move_input if move_input.length() > 0.05 else keyboard
    var dir := Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 0.05:
        dir = dir.normalized()
        player.position += dir * 5.8 * delta
        player.position.x = clamp(player.position.x, -25.0, 25.0)
        player.position.z = clamp(player.position.z, -25.0, 25.0)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 13.0))

func _update_enemies(delta: float) -> void:
    if player == null:
        return
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var cooldown := max(0.0, float(enemy.get_meta("damage_cooldown", 0.0)) - delta)
        enemy.set_meta("damage_cooldown", cooldown)
        var offset := player.position - enemy.position
        offset.y = 0.0
        if offset.length() > 1.25:
            enemy.position += offset.normalized() * float(enemy.get_meta("speed", 1.7)) * delta
            enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(offset.x, offset.z), min(1.0, delta * 9.5))
        elif cooldown <= 0.0:
            enemy.set_meta("damage_cooldown", 0.8)
            _damage_player(12 if bool(enemy.get_meta("elite", false)) else 5)
        enemy.position.y = sin(time_alive * 3.1 + enemy.position.x) * 0.028

func _cast_at_nearest_enemy() -> void:
    var target := _nearest_enemy()
    if target == null or player == null:
        return
    var orb := RunebornFX.make_arcane_orb()
    orb.position = player.position + Vector3(0.0, 1.15, 0.0)
    orb.set_meta("target", target)
    orb.set_meta("life", 2.4)
    orb.set_meta("damage", 1)
    add_child(orb)
    projectiles.append(orb)

func _cast_arcane_nova() -> void:
    if player == null:
        return
    var ring := RunebornFX.make_arcane_ring(0.35)
    ring.position = player.position + Vector3(0.0, 0.08, 0.0)
    ring.scale.y = 0.12
    add_child(ring)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring, "scale", Vector3(6.5, 0.12, 6.5), 0.42)
    tween.tween_property(ring, "rotation:y", PI, 0.42)
    tween.chain().tween_callback(ring.queue_free)
    for enemy in enemies.duplicate():
        if is_instance_valid(enemy) and player.position.distance_to(enemy.position) <= 6.5:
            _hit_enemy(enemy, 2)

func _nearest_enemy() -> Node3D:
    if player == null:
        return null
    var target: Node3D
    var best := INF
    for enemy in enemies:
        if is_instance_valid(enemy):
            var distance := player.position.distance_squared_to(enemy.position)
            if distance < best:
                best = distance
                target = enemy
    return target

func _update_projectiles(delta: float) -> void:
    for orb in projectiles.duplicate():
        if not is_instance_valid(orb):
            projectiles.erase(orb)
            continue
        var life := float(orb.get_meta("life", 0.0)) - delta
        orb.set_meta("life", life)
        var target := orb.get_meta("target") as Node3D
        if life <= 0.0 or target == null or not is_instance_valid(target):
            projectiles.erase(orb)
            orb.queue_free()
            continue
        var direction := target.global_position + Vector3(0.0, 0.72, 0.0) - orb.global_position
        if direction.length() < 0.72:
            _hit_enemy(target, int(orb.get_meta("damage", 1)))
            projectiles.erase(orb)
            orb.queue_free()
            continue
        orb.global_position += direction.normalized() * 13.5 * delta
        orb.scale = Vector3.ONE * (1.0 + sin(time_alive * 16.0) * 0.14)

func _hit_enemy(enemy: Node3D, damage: int) -> void:
    if not is_instance_valid(enemy):
        return
    var hp := int(enemy.get_meta("hp", 1)) - damage
    enemy.set_meta("hp", hp)
    RunebornFX.burst(self, enemy.global_position + Vector3(0.0, 0.65, 0.0), Color("a879ff"), 0.65)
    var base_scale := enemy.get_meta("base_scale", enemy.scale) as Vector3
    var tween := create_tween()
    tween.tween_property(enemy, "scale", base_scale * 1.23, 0.055)
    tween.tween_property(enemy, "scale", base_scale, 0.11)
    if hp <= 0:
        _kill_enemy(enemy)

func _kill_enemy(enemy: Node3D) -> void:
    enemies.erase(enemy)
    score += 25 if bool(enemy.get_meta("elite", false)) else 5
    _refresh_hud()
    RunebornFX.burst(self, enemy.global_position + Vector3(0.0, 0.7, 0.0), Color("d09bff"), 1.15)
    var death := create_tween()
    death.set_parallel(true)
    death.tween_property(enemy, "scale", Vector3.ZERO, 0.3)
    death.tween_property(enemy, "rotation:y", enemy.rotation.y + 2.8, 0.3)
    death.chain().tween_callback(enemy.queue_free)
    if wave_director.register_kill():
        get_tree().create_timer(1.25).timeout.connect(_start_wave)

func _damage_player(amount: int) -> void:
    player_hp = max(0, player_hp - amount)
    _refresh_hud()
    if player == null:
        return
    RunebornFX.burst(self, player.global_position + Vector3(0.0, 0.9, 0.0), Color("ff6b74"), 0.7)
    var base := Vector3.ONE * 1.34
    var tween := create_tween()
    tween.tween_property(player, "scale", base * 0.86, 0.07)
    tween.tween_property(player, "scale", base, 0.12)
    if player_hp <= 0:
        status_label.text = "RUNE SHATTERED"
        set_process(false)

func _update_camera(delta: float) -> void:
    if player == null or camera == null:
        return
    var desired := player.position + Vector3(0.0, 15.7, 13.9)
    camera.position = camera.position.lerp(desired, min(1.0, delta * 5.8))

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var title := Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(38.0, 48.0)
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("f1eaff"))
    layer.add_child(title)

    wave_label = Label.new()
    wave_label.position = Vector2(40.0, 94.0)
    wave_label.add_theme_font_size_override("font_size", 20)
    layer.add_child(wave_label)

    score_label = Label.new()
    score_label.position = Vector2(40.0, 124.0)
    score_label.add_theme_font_size_override("font_size", 18)
    score_label.add_theme_color_override("font_color", Color("d4cede"))
    layer.add_child(score_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(40.0, 162.0)
    hp_bar.size = Vector2(310.0, 24.0)
    hp_bar.min_value = 0.0
    hp_bar.max_value = 100.0
    hp_bar.show_percentage = false
    layer.add_child(hp_bar)

    status_label = Label.new()
    status_label.position = Vector2(40.0, 205.0)
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color("bfb4d6"))
    layer.add_child(status_label)
    _refresh_hud()

func _refresh_hud() -> void:
    if wave_label != null:
        wave_label.text = "WAVE %02d" % (wave_director.wave if wave_director != null else 1)
    if score_label != null:
        score_label.text = "RUNE SCORE  %05d" % score
    if hp_bar != null:
        hp_bar.value = player_hp
    if status_label != null and player_hp > 0:
        status_label.text = "ARCANE BOLT • NOVA  %.1fs" % max(0.0, nova_timer)

func _on_wave_started(_wave: int, _target_count: int) -> void:
    _refresh_hud()

func _on_wave_cleared(_wave: int) -> void:
    if status_label != null:
        status_label.text = "RUNE SURGE"

func _play_animation(root: Node, candidates: Array[String]) -> void:
    var players := root.find_children("*", "AnimationPlayer", true, false)
    if players.is_empty():
        return
    var animation_player := players[0] as AnimationPlayer
    for candidate in candidates:
        if animation_player.has_animation(candidate):
            animation_player.play(candidate)
            return
    var names := animation_player.get_animation_list()
    if not names.is_empty():
        animation_player.play(names[0])
