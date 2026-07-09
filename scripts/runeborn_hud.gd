extends CanvasLayer

const HUD_PANEL = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Transparent center/panel-transparent-center-009.png"
const HUD_BORDER = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Border/panel-border-009.png"
const HUD_DIVIDER = "res://assets/ui/09_UI/kenney_fantasy-ui-borders/PNG/Double/Divider Fade/divider-fade-003.png"

var game = null
var hp_fill = null
var hp_text = null
var wave_text = null
var score_text = null
var state_text = null
var spell_text = null
var spell_frame = null
var pulse_time = 0.0
var last_wave = -1
var last_score = -1
var last_hp = -1

func _ready():
    layer = 50
    game = get_parent()
    _hide_debug_hud()
    _build_hud()

func _process(delta):
    if game == null:
        return
    pulse_time += delta
    _refresh_values(delta)

func _hide_debug_hud():
    for child in game.get_children():
        if child is CanvasLayer and child != self:
            child.visible = false

func _build_hud():
    var panel_texture = load(HUD_PANEL)
    var border_texture = load(HUD_BORDER)
    var divider_texture = load(HUD_DIVIDER)

    var top_panel = TextureRect.new()
    top_panel.position = Vector2(28.0, 36.0)
    top_panel.size = Vector2(410.0, 190.0)
    top_panel.texture = panel_texture
    top_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    top_panel.stretch_mode = TextureRect.STRETCH_SCALE
    top_panel.modulate = Color(0.72, 0.66, 0.84, 0.92)
    add_child(top_panel)

    var crest = TextureRect.new()
    crest.position = Vector2(424.0, 34.0)
    crest.size = Vector2(322.0, 124.0)
    crest.texture = border_texture
    crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    crest.stretch_mode = TextureRect.STRETCH_SCALE
    crest.modulate = Color(0.82, 0.74, 0.98, 1.0)
    add_child(crest)

    var divider = TextureRect.new()
    divider.position = Vector2(72.0, 103.0)
    divider.size = Vector2(320.0, 28.0)
    divider.texture = divider_texture
    divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    divider.stretch_mode = TextureRect.STRETCH_SCALE
    divider.modulate = Color(0.75, 0.66, 0.96, 0.82)
    add_child(divider)

    var title = Label.new()
    title.text = "RUNEBORN"
    title.position = Vector2(64.0, 57.0)
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("f5efff"))
    add_child(title)

    score_text = Label.new()
    score_text.position = Vector2(68.0, 130.0)
    score_text.add_theme_font_size_override("font_size", 17)
    score_text.add_theme_color_override("font_color", Color("d8cdea"))
    add_child(score_text)

    hp_fill = ProgressBar.new()
    hp_fill.position = Vector2(68.0, 170.0)
    hp_fill.size = Vector2(314.0, 20.0)
    hp_fill.min_value = 0.0
    hp_fill.max_value = 100.0
    hp_fill.show_percentage = false
    add_child(hp_fill)

    hp_text = Label.new()
    hp_text.position = Vector2(274.0, 166.0)
    hp_text.size = Vector2(104.0, 28.0)
    hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hp_text.add_theme_font_size_override("font_size", 15)
    hp_text.add_theme_color_override("font_color", Color("f4edf9"))
    add_child(hp_text)

    wave_text = Label.new()
    wave_text.position = Vector2(450.0, 62.0)
    wave_text.size = Vector2(270.0, 58.0)
    wave_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wave_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wave_text.add_theme_font_size_override("font_size", 28)
    wave_text.add_theme_color_override("font_color", Color("f6efff"))
    add_child(wave_text)

    spell_frame = TextureRect.new()
    spell_frame.position = Vector2(806.0, 2260.0)
    spell_frame.size = Vector2(300.0, 178.0)
    spell_frame.texture = border_texture
    spell_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    spell_frame.stretch_mode = TextureRect.STRETCH_SCALE
    spell_frame.modulate = Color(0.72, 0.57, 0.96, 0.92)
    add_child(spell_frame)

    spell_text = Label.new()
    spell_text.position = Vector2(830.0, 2294.0)
    spell_text.size = Vector2(252.0, 92.0)
    spell_text.text = "ARCANE FOCUS\nAUTO CAST"
    spell_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    spell_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    spell_text.add_theme_font_size_override("font_size", 21)
    spell_text.add_theme_color_override("font_color", Color("f2e8ff"))
    add_child(spell_text)

    state_text = Label.new()
    state_text.position = Vector2(66.0, 2130.0)
    state_text.size = Vector2(1030.0, 54.0)
    state_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    state_text.add_theme_font_size_override("font_size", 18)
    state_text.add_theme_color_override("font_color", Color("e4d6f7"))
    add_child(state_text)

func _refresh_values(delta):
    var current_wave = int(game.get("wave"))
    var current_score = int(game.get("score"))
    var current_hp = int(game.get("hp"))
    var boot_state = int(game.get("boot_state"))
    var attack_time = float(game.get("player_attack_time"))

    if current_wave != last_wave:
        wave_text.text = "WAVE  %02d" % current_wave
        wave_text.scale = Vector2(1.12, 1.12)
        last_wave = current_wave
    wave_text.scale = wave_text.scale.lerp(Vector2.ONE, min(1.0, delta * 7.0))

    if current_score != last_score:
        score_text.text = "RUNE SCORE   %05d" % current_score
        last_score = current_score

    if current_hp != last_hp:
        hp_fill.value = current_hp
        hp_text.text = "%d / 100" % current_hp
        last_hp = current_hp

    if boot_state > 0:
        state_text.text = "DIE RUNENWELT WIRD GEFORMT"
    else:
        state_text.text = "THE WILD RUNE GROVE"

    var pulse = 0.94 + sin(pulse_time * 3.6) * 0.04
    if attack_time > 0.0:
        pulse = 1.10
    spell_frame.scale = spell_frame.scale.lerp(Vector2(pulse, pulse), min(1.0, delta * 10.0))
