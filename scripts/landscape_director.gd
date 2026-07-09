extends Node

var game = null
var camera = null
var mage = null
var spellbook = null

func _ready():
    game = get_parent()
    set_process(true)

func _process(_delta):
    if game == null:
        return

    if camera == null or not is_instance_valid(camera):
        camera = game.get("camera")
    if mage == null or not is_instance_valid(mage):
        mage = game.get("player")
    if spellbook == null or not is_instance_valid(spellbook):
        spellbook = game.get_node_or_null("FixedSpellbook")

    var viewport_size = get_viewport().get_visible_rect().size
    if viewport_size.y <= 0.0:
        return
    var aspect = viewport_size.x / viewport_size.y
    var landscape = aspect >= 1.25

    if camera != null and is_instance_valid(camera) and mage != null and is_instance_valid(mage):
        if landscape:
            camera.fov = 50.0
            camera.rotation_degrees = Vector3(-47.0, 0.0, 0.0)
            camera.position = mage.position + Vector3(0.0, 13.6, 10.6)
        else:
            camera.fov = 42.0
            camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
            camera.position = mage.position + Vector3(0.0, 11.2, 8.6)

        var hit_pulse = float(game.get("player_hit_pulse"))
        var squash = sin(hit_pulse * PI)
        var base_scale = 0.72 if landscape else 0.82
        mage.scale = Vector3(
            base_scale * (1.0 + squash * 0.09),
            base_scale * (1.0 - squash * 0.10),
            base_scale * (1.0 + squash * 0.09)
        )

    if spellbook != null and is_instance_valid(spellbook):
        spellbook.scale = Vector3.ONE * (0.76 if landscape else 0.88)
