class_name RunebornFX
extends RefCounted

static func make_arcane_orb() -> MeshInstance3D:
    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.24
    sphere.height = 0.48
    orb.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("7a4cff")
    mat.emission_enabled = true
    mat.emission = Color("a86fff")
    mat.emission_energy_multiplier = 6.5
    mat.roughness = 0.18
    orb.material_override = mat
    return orb

static func make_arcane_ring(radius: float = 1.0) -> MeshInstance3D:
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = max(0.05, radius - 0.06)
    torus.outer_radius = radius
    ring.mesh = torus
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("7f53ff")
    mat.emission_enabled = true
    mat.emission = Color("a879ff")
    mat.emission_energy_multiplier = 4.8
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.78
    ring.material_override = mat
    return ring

static func burst(parent: Node, position: Vector3, color: Color = Color("a879ff"), size: float = 1.0) -> void:
    var root := Node3D.new()
    root.position = position
    parent.add_child(root)
    for i in range(7):
        var shard := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.08, 0.08, 0.28) * size
        shard.mesh = mesh
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 5.0
        shard.material_override = mat
        shard.rotation.y = TAU * float(i) / 7.0
        root.add_child(shard)
        var dir := Vector3(cos(shard.rotation.y), 0.25, sin(shard.rotation.y))
        var tween := root.create_tween()
        tween.set_parallel(true)
        tween.tween_property(shard, "position", dir * 1.15 * size, 0.24)
        tween.tween_property(shard, "scale", Vector3.ZERO, 0.24)
    var cleanup := root.create_tween()
    cleanup.tween_interval(0.28)
    cleanup.tween_callback(root.queue_free)
