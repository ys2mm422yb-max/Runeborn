extends CanvasLayer

const PANEL_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Transparent center/panel-transparent-center-009.png"
const BORDER_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Border/panel-border-009.png"

var game = null
var hp_label = null
var score_label = null
var wave_label = null
var wave_frame = null
var last_wave = -1
var last_hit_serial = 0
var hit_pulse = 0.0

func _ready():
    layer = 20
    game = get_parent()
    _build_hud()
    set_process(true)

func _process(delta):
    if game == null:
        return

    var current_hp = int(game.get("hp"))
    var current_score = int(game.get("score"))
    var current_wave = int(game.get("wave"))
    var current_hit_serial = int(game.get("player_hit_serial"))

    if current_hit_serial > last_hit_serial:
        hit_pulse = 1.0
    last_hit_serial = current_hit_serial
    hit_pulse = max(0.0, hit_pulse - delta * 5.5)

    hp_label.text = "HP  %03d" % current_hp
    score_label.text = "RUNE  %05d" % current_score

    var hp_scale = 1.0 + sin(hit_pulse * PI) * 0.14
    hp_label.scale = hp_label.scale.lerp(Vector2(hp_scale, hp_scale), min(1.0, delta * 16.0))
    hp_label.modulate = Color(1.0, 0.72 + (1.0 - hit_pulse) * 0.28, 0.82 + (1.0 - hit_pulse) * 0.18, 1.0)

    if current_wave != last_wave:
        wave_label.text = "WAVE  %02d" % current_wave
        wave_frame.scale = Vector2(1.12, 1.12)
        last_wave = current_wave

    wave_frame.scale = wave_frame.scale.lerp(Vector2.ONE, min(1.0, delta * 8.0))

func _build_hud():
    var root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var info_panel = TextureRect.new()
    info_panel.anchor_left = 0.0
    info_panel.anchor_top = 0.0
    info_panel.anchor_right = 0.0
    info_panel.anchor_bottom = 0.0
    info_panel.offset_left = 24.0
    info_panel.offset_top = 28.0
    info_panel.offset_right = 326.0
    info_panel.offset_bottom = 154.0
    info_panel.texture = load(PANEL_TEX)
    info_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    info_panel.stretch_mode = TextureRect.STRETCH_SCALE
    info_panel.modulate = Color(0.70, 0.62, 0.88, 0.82)
    info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(info_panel)

    var title = Label.new()
    title.position = Vector2(25.0, 18.0)
    title.size = Vector2(250.0, 34.0)
    title.text = "RUNEBORN"
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Color("f7f1ff"))
    info_panel.add_child(title)

    hp_label = Label.new()
    hp_label.position = Vector2(25.0, 55.0)
    hp_label.size = Vector2(120.0, 30.0)
    hp_label.pivot_offset = Vector2(60.0, 15.0)
    hp_label.add_theme_font_size_override("font_size", 17)
    hp_label.add_theme_color_override("font_color", Color("f2e9ff"))
    info_panel.add_child(hp_label)

    score_label = Label.new()
    score_label.position = Vector2(145.0, 55.0)
    score_label.size = Vector2(132.0, 30.0)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    score_label.add_theme_font_size_override("font_size", 17)
    score_label.add_theme_color_override("font_color", Color("ded0ef"))
    info_panel.add_child(score_label)

    wave_frame = TextureRect.new()
    wave_frame.anchor_left = 0.5
    wave_frame.anchor_top = 0.0
    wave_frame.anchor_right = 0.5
    wave_frame.anchor_bottom = 0.0
    wave_frame.offset_left = -116.0
    wave_frame.offset_top = 28.0
    wave_frame.offset_right = 116.0
    wave_frame.offset_bottom = 104.0
    wave_frame.pivot_offset = Vector2(116.0, 38.0)
    wave_frame.texture = load(BORDER_TEX)
    wave_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    wave_frame.stretch_mode = TextureRect.STRETCH_SCALE
    wave_frame.modulate = Color(0.70, 0.58, 0.92, 0.88)
    wave_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(wave_frame)

    wave_label = Label.new()
    wave_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wave_label.add_theme_font_size_override("font_size", 21)
    wave_label.add_theme_color_override("font_color", Color("f7f1ff"))
    wave_frame.add_child(wave_label)
