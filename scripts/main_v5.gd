extends "res://scripts/main_v4.gd"

var boot_label: Label
var boot_started := false

func _ready() -> void:
    set_process(false)
    _build_world()
    _spawn_player()
    _build_hud()

    wave_director = WaveDirector.new()
    add_child(wave_director)
    wave_director.wave_started.connect(_on_wave_started)
    wave_director.wave_cleared.connect(_on_wave_cleared)

    boot_label = Label.new()
    boot_label.text = "RUNES WERDEN GEWECKT ..."
    boot_label.position = Vector2(40.0, 390.0)
    boot_label.add_theme_font_size_override("font_size", 22)
    boot_label.add_theme_color_override("font_color", Color("d8ccef"))
    var boot_layer := CanvasLayer.new()
    boot_layer.layer = 30
    add_child(boot_layer)
    boot_layer.add_child(boot_label)

    var timer := get_tree().create_timer(0.15)
    timer.timeout.connect(_begin_boot)

func _begin_boot() -> void:
    if boot_started:
        return
    boot_started = true
    boot_label.text = "MONSTER WERDEN GELADEN ..."
    monster_scenes = AssetCatalog.collect_models_limited(
        MONSTER_ROOT,
        12,
        [],
        ["animation", "movement", "general", "combat", "simulation", "special", "tools", "mannequin"]
    )

    boot_label.text = "WALD WIRD ERSCHAFFEN ..."
    nature_scenes = AssetCatalog.collect_models_limited(
        NATURE_ROOT,
        28,
        ["tree", "rock", "grass", "bush", "flower", "plant", "stump"],
        ["animation", "mannequin"]
    )

    _spawn_nature_incremental()

func _spawn_nature_incremental() -> void:
    if nature_scenes.is_empty():
        push_warning("Runeborn: no filtered nature package assets found")
        _finish_boot()
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = 68421
    var placed := 0
    for i in range(36):
        var angle := rng.randf_range(0.0, TAU)
        var radius := rng.randf_range(10.5, 27.0)
        var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        var path := nature_scenes[rng.randi_range(0, nature_scenes.size() - 1)]
        var packed := load(path) as PackedScene
        if packed != null:
            var item := packed.instantiate() as Node3D
            item.position = pos
            item.rotation.y = rng.randf_range(0.0, TAU)
            var size := rng.randf_range(0.82, 1.38)
            item.scale = Vector3.ONE * size
            add_child(item)
            placed += 1
        if i % 4 == 3:
            await get_tree().process_frame

    _finish_boot()

func _finish_boot() -> void:
    boot_label.text = "DIE ERSTE WELLE KOMMT ..."
    await get_tree().process_frame
    _start_wave()
    set_process(true)
    boot_label.queue_free()
