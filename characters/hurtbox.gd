class_name Hurtbox extends Area2D

signal got_hit(hitbox: Hitbox)

enum Faction {PLAYER, ENEMY}

@export var faction: Faction = Faction.PLAYER
@export var hit_particles: PackedScene = preload("res://vfx/blood_particles.tscn")

func hit(hitbox: Hitbox) -> void:
	got_hit.emit(hitbox)
	var particles: GPUParticles2D = hit_particles.instantiate()
	if particles:
		var ppos = (global_position + hitbox.global_position) * 0.5
		Events.vfx_spawned.emit(particles, ppos)
