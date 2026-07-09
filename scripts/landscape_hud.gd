extends CanvasLayer

const PANEL_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Transparent center/panel-transparent-center-009.png"
const BORDER_TEX = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Border/panel-border-009.png"

var game = null
var hp_label = null
var score_label = null
var wave_label = null
var hp_bar = null
var left_panel = null
var wave_panel = null
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

    hp_label.text = "%03d / 100" % current_hp
    score_label.text = "RUNES   %05d" % current_score
    hp_bar.value = current_hp

    var pulse_scale = 1.0 + sin(hit_pulse * PI) * 0.06
    left_panel.scale = left_panel.scale.lerp(Vector2(pulse_scale, pulse_scale), min(1.0, delta * 14.0))

    if current_wave != last_wave:
        wave_label.text = "WAVE  %02d" % current_wave
        wave_panel.scale = Vector2(1.10, 1.10)
        last_wave = current_wave
    wave_panel.scale = wave_panel.scale.lerp(Vector2.ONE, min(1.0, delta * 8.0))

func _build_hud():
    var root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    left_panel = TextureRect.new()
    left_panel.anchor_left = 0.0
    left_panel.anchor_top = 0.0
    left_panel.offset_left = 46.0
    left_panel.offset_top = 38.0
    left_panel.offset_right = 566.0
    left_panel.offset_bottom = 220.0
    left_panel.pivot_offset = Vector2(260.0, 91.0)
    left_panel.texture = load(PANEL_TEX)
    left_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    left_panel.stretch_mode = TextureRect.STRETCH_SCALE
    left_panel.modulate = Color(0.42, 0.28, 0.64, 0.98)
    left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(left_panel)

    var title = Label.new()
    title.position = Vector2(48.0, 24.0)
    title.size = Vector2(420.0, 50.0)
    title.text = "RUNEBORN"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("fff8ff"))
    left_panel.add_child(title)

    var hp_title = Label.new()
    hp_title.position = Vector2(48.0, 82.0)
    hp_title.size = Vector2(70.0, 38.0)
    hp_title.text = "HP"
    hp_title.add_theme_font_size_override("font_size", 24)
    hp_title.add_theme_color_override("font_color", Color("eadcff"))
    left_panel.add_child(hp_title)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(112.0, 86.0)
    hp_bar.size = Vector2(230.0, 28.0)
    hp_bar.min_value = 0.0
    hp_bar.max_value = 100.0
    hp_bar.value = 100.0
    hp_bar.show_percentage = false
    left_panel.add_child(hp_bar)

    hp_label = Label.new()
    hp_label.position = Vector2(354.0, 80.0)
    hp_label.size = Vector2(124.0, 42.0)
    hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hp_label.add_theme_font_size_override("font_size", 23)
    hp_label.add_theme_color_override("font_color", Color("fff4ff"))
    left_panel.add_child(hp_label)

    score_label = Label.new()
    score_label.position = Vector2(48.0, 132.0)
    score_label.size = Vector2(430.0, 38.0)
    score_label.add_theme_font_size_override("font_size", 23)
    score_label.add_theme_color_override("font_color", Color("e8dcf7"))
    left_panel.add_child(score_label)

    wave_panel = TextureRect.new()
    wave_panel.anchor_left = 0.5
    wave_panel.anchor_top = 0.0
    wave_panel.anchor_right = 0.5
    wave_panel.offset_left = -190.0
    wave_panel.offset_top = 38.0
    wave_panel.offset_right = 190.0
    wave_panel.offset_bottom = 154.0
    wave_panel.pivot_offset = Vector2(190.0, 58.0)
    wave_panel.texture = load(BORDER_TEX)
    wave_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    wave_panel.stretch_mode = TextureRect.STRETCH_SCALE
    wave_panel.modulate = Color(0.54, 0.36, 0.80, 0.98)
    wave_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(wave_panel)

    wave_label = Label.new()
    wave_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wave_label.add_theme_font_size_override("font_size", 34)
    wave_label.add_theme_color_override("font_color", Color("fff8ff"))
    wave_panel.add_child(wave_label)
