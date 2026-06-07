extends Node2D

var velocity = Vector2.ZERO
@export var damage = 25

@onready var shapecast: ShapeCast2D = $RayCast2D

func _physics_process(delta):
	shapecast.target_position = velocity * delta
	shapecast.force_shapecast_update()
	
	if shapecast.is_colliding():
		var collider = shapecast.get_collider(0)
		
		if collider:
			var final_damage = int(damage * Global.damage_dealt_modifier)
			
			if collider.has_method("take_damage"):
				collider.take_damage(final_damage)
			elif collider.get_parent() and collider.get_parent().has_method("take_damage"):
				collider.get_parent().take_damage(final_damage)
			
		queue_free()
		return

	global_position += velocity * delta
