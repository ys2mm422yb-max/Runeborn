class_name AssetCatalog
extends RefCounted

const CHARACTER_ROOT := "res://assets/characters/03_Characters/KayKit_Adventurers_2.0_FREE/Characters/gltf"
const MONSTER_ROOT := "res://assets/monsters"
const NATURE_ROOT := "res://assets/nature"
const RUINS_ROOT := "res://assets/ruins"
const VILLAGE_ROOT := "res://assets/village"
const PROPS_ROOT := "res://assets/props"
const GEAR_ROOT := "res://assets/gear"

static func character(name: String) -> String:
    return CHARACTER_ROOT.path_join(name + ".glb")

static func collect_models(root: String, include_terms: Array[String] = [], exclude_terms: Array[String] = []) -> Array[String]:
    var result: Array[String] = []
    _scan(root, result, include_terms, exclude_terms)
    result.sort()
    return result

static func _scan(path: String, result: Array[String], include_terms: Array[String], exclude_terms: Array[String]) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry != "." and entry != ".." and not entry.begins_with("__MACOSX") and not entry.begins_with("._"):
            var full := path.path_join(entry)
            if dir.current_is_dir():
                _scan(full, result, include_terms, exclude_terms)
            else:
                var lower := full.to_lower()
                if (lower.ends_with(".glb") or lower.ends_with(".gltf")) and _allowed(lower, include_terms, exclude_terms):
                    result.append(full)
        entry = dir.get_next()
    dir.list_dir_end()

static func _allowed(lower_path: String, include_terms: Array[String], exclude_terms: Array[String]) -> bool:
    for term in exclude_terms:
        if lower_path.contains(term.to_lower()):
            return false
    if include_terms.is_empty():
        return true
    for term in include_terms:
        if lower_path.contains(term.to_lower()):
            return true
    return false
