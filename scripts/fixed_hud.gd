extends CanvasLayer

const PANEL_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Transparent center/panel-transparent-center-009.png"
const BORDER_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Border/panel-border-009.png"

var game = null
var root = null
var info_panel = null
var hp_label = null
var score_label = null
var wave_label = null
var wave_frame = null
var last_wave = -1
var last_hit_serial = 0
var hit_pulse = 0.0
var last_layout_landscape = false

func _ready():
    layer = 20
    game = get_parent()
    _build_hud()
    _apply_layout()
    set_process(true)

func _process(delta):
    if game == null:
        return

    var viewport_size = get_viewport().get_visible_rect().size
    var landscape = viewport_size.y > 0.0 and viewport_size.x / viewport_size.y >= 1.25
    if landscape != last_layout_landscape:
        _apply_layout()

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

    var hp_scale = 1.0 + sin(hit_pulse * PI) * 0.12
    hp_label.scale = hp_label.scale.lerp(Vector2(hp_scale, hp_scale), min(1.0, delta * 16.0))
    hp_label.modulate = Color(1.0, 0.72 + (1.0 - hit_pulse) * 0.28, 0.82 + (1.0 - hit_pulse) * 0.18, 1.0)

    if current_wave != last_wave:
        wave_label.text = "WAVE  %02d" % current_wave
        wave_frame.scale = Vector2(1.10, 1.10)
        last_wave = current_wave

    wave_frame.scale = wave_frame.scale.lerp(Vector2.ONE, min(1.0, delta * 8.0))

func _apply_layout():
    if root == null:
        return
    var viewport_size = get_viewport().get_visible_rect().size
    var landscape = viewport_size.y > 0.0 and viewport_size.x / viewport_size.y >= 1.25
    last_layout_landscape = landscape

    if landscape:
        info_panel.offset_left = 42.0
        info_panel.offset_top = 34.0
        info_panel.offset_right = 512.0
        info_panel.offset_bottom = 198.0
        wave_frame.offset_left = -160.0
        wave_frame.offset_top = 34.0
        wave_frame.offset_right = 160.0
        wave_frame.offset_bottom = 132.0
        wave_frame.pivot_offset = Vector2(160.0, 49.0)
    else:
        info_panel.offset_left = 24.0
        info_panel.offset_top = 28.0
        info_panel.offset_right = 326.0
        info_panel.offset_bottom = 154.0
        wave_frame.offset_left = -116.0
        wave_frame.offset_top = 28.0
        wave_frame.offset_right = 116.0
        wave_frame.offset_bottom = 104.0
        wave_frame.pivot_offset = Vector2(116.0, 38.0)

func _build_hud():
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    info_panel = TextureRect.new()
    info_panel.anchor_left = 0.0
    info_panel.anchor_top = 0.0
    info_panel.anchor_right = 0.0
    info_panel.anchor_bottom = 0.0
    info_panel.texture = load(PANEL_TEX)
    info_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    info_panel.stretch_mode = TextureRect.STRETCH_SCALE
    info_panel.modulate = Color(0.62, 0.52, 0.82, 0.94)
    info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(info_panel)

    var title = Label.new()
    title.position = Vector2(38.0, 24.0)
    title.size = Vector2(360.0, 48.0)
    title.text = "RUNEBORN"
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", Color("fff8ff"))
    info_panel.add_child(title)

    hp_label = Label.new()
    hp_label.position = Vector2(38.0, 82.0)
    hp_label.size = Vector2(160.0, 42.0)
    hp_label.pivot_offset = Vector2(80.0, 21.0)
    hp_label.add_theme_font_size_override("font_size", 25)
    hp_label.add_theme_color_override("font_color", Color("fff2ff"))
    info_panel.add_child(hp_label)

    score_label = Label.new()
    score_label.position = Vector2(210.0, 82.0)
    score_label.size = Vector2(210.0, 42.0)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    score_label.add_theme_font_size_override("font_size", 25)
    score_label.add_theme_color_override("font_color", Color("eadcf7"))
    info_panel.add_child(score_label)

    wave_frame = TextureRect.new()
    wave_frame.anchor_left = 0.5
    wave_frame.anchor_top = 0.0
    wave_frame.anchor_right = 0.5
    wave_frame.anchor_bottom = 0.0
    wave_frame.texture = load(BORDER_TEX)
    wave_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    wave_frame.stretch_mode = TextureRect.STRETCH_SCALE
    wave_frame.modulate = Color(0.66, 0.50, 0.90, 0.96)
    wave_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(wave_frame)

    wave_label = Label.new()
    wave_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wave_label.add_theme_font_size_override("font_size", 29)
    wave_label.add_theme_color_override("font_color", Color("fff8ff"))
    wave_frame.add_child(wave_label)
