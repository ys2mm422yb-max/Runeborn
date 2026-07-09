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
        var camera_shake = float(game.get("camera_shake"))
        var cast_pull = float(game.get("cast_camera_pull"))
        var cast_target = game.get("cast_target")
        var ticks = float(Time.get_ticks_msec()) * 0.001

        var shake = Vector3.ZERO
        if camera_shake > 0.0:
            shake = Vector3(
                sin(ticks * 63.0) * camera_shake * 0.34,
                sin(ticks * 79.0) * camera_shake * 0.18,
                cos(ticks * 57.0) * camera_shake * 0.24
            )

        var focus_pull = Vector3.ZERO
        if cast_pull > 0.0 and cast_target != null and is_instance_valid(cast_target):
            var target_offset = cast_target.position - mage.position
            target_offset.y = 0.0
            focus_pull = target_offset.limit_length(1.8) * cast_pull * 0.24

        if landscape:
            camera.fov = 52.0
            camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
            camera.position = mage.position + Vector3(0.0, 14.8, 11.8) + focus_pull + shake
        else:
            camera.fov = 42.0
            camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
            camera.position = mage.position + Vector3(0.0, 11.2, 8.6) + focus_pull + shake

        var hit_pulse = float(game.get("player_hit_pulse"))
        var squash = sin(hit_pulse * PI)
        var base_scale = 0.62 if landscape else 0.82
        mage.scale = Vector3(
            base_scale * (1.0 + squash * 0.09),
            base_scale * (1.0 - squash * 0.10),
            base_scale * (1.0 + squash * 0.09)
        )

    if spellbook != null and is_instance_valid(spellbook):
        spellbook.scale = Vector3.ONE * (0.62 if landscape else 0.88)
