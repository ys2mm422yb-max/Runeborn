class_name WaveDirector
extends Node

signal wave_started(wave: int, target_count: int)
signal wave_cleared(wave: int)
signal elite_wave_started(wave: int)

var wave := 1
var target_count := 10
var alive_count := 0
var kills_this_wave := 0
var elapsed := 0.0
var elite_every := 5

func _process(delta: float) -> void:
    elapsed += delta

func begin_wave() -> int:
    target_count = 8 + wave * 2
    kills_this_wave = 0
    alive_count = target_count
    wave_started.emit(wave, target_count)
    if wave % elite_every == 0:
        elite_wave_started.emit(wave)
    return target_count

func register_kill() -> bool:
    kills_this_wave += 1
    alive_count = max(0, alive_count - 1)
    if alive_count == 0:
        wave_cleared.emit(wave)
        wave += 1
        return true
    return false

func difficulty_multiplier() -> float:
    return 1.0 + float(wave - 1) * 0.12

func is_elite_wave() -> bool:
    return wave % elite_every == 0
