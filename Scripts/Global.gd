extends Node

var current_xp: int = 0
var current_level: int = 1
var xp_needed_for_level: int = 100

var damage_dealt_modifier: float = 1.0
var damage_taken_modifier: float = 1.0

func gain_xp(amount: int) -> void:
	current_xp += amount
	
	if current_xp >= xp_needed_for_level:
		level_up()

func level_up() -> void:
	current_xp -= xp_needed_for_level
	current_level += 1
	xp_needed_for_level = int(xp_needed_for_level * 1.5)
	
	damage_dealt_modifier += 0.2
	damage_taken_modifier -= 0.1
	damage_taken_modifier = clamp(damage_taken_modifier, 0.2, 1.0)
	
