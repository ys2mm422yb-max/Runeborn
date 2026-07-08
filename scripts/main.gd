extends Node3D

func _ready() -> void:
    _build_bootstrap_scene()

func _build_bootstrap_scene() -> void:
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("9aa6a0")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("c8d4cb")
    environment.ambient_light_energy = 0.9
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
    sun.light_energy = 1.5
    sun.shadow_enabled = true
    add_child(sun)

    var ground := MeshInstance3D.new()
    ground.name = "GroundPlaceholder"
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(36.0, 36.0)
    ground.mesh = ground_mesh
    var ground_material := StandardMaterial3D.new()
    ground_material.albedo_color = Color("536f4d")
    ground_material.roughness = 0.95
    ground.material_override = ground_material
    add_child(ground)

    var player := MeshInstance3D.new()
    player.name = "PlayerPlaceholder"
    var player_mesh := CapsuleMesh.new()
    player_mesh.radius = 0.6
    player_mesh.height = 1.8
    player.mesh = player_mesh
    player.position = Vector3(0.0, 0.9, 0.0)
    var player_material := StandardMaterial3D.new()
    player_material.albedo_color = Color("8b4fe0")
    player_material.roughness = 0.45
    player.material_override = player_material
    add_child(player)

    var camera := Camera3D.new()
    camera.name = "TopDownCamera"
    camera.position = Vector3(0.0, 13.0, 12.0)
    camera.rotation_degrees = Vector3(-48.0, 0.0, 0.0)
    camera.fov = 40.0
    camera.current = true
    add_child(camera)

    var label := Label.new()
    label.name = "BootstrapLabel"
    label.text = "RUNEBORN\nBootstrap bereit – Assets als Nächstes"
    label.position = Vector2(42.0, 70.0)
    label.add_theme_font_size_override("font_size", 34)
    add_child(label)
