extends CharacterBody2D

@export var health: int = 25
@export var SPEED: float = 80
@export var SEPARATION_DISTANCE: float = 40.0
@export var SEPARATION_STRENGTH: float = 0.5
@export var contact_damage: int = 15

var direction: Vector2
var walk_anim_time: float = 0.0
var is_dying: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D = null

func _ready():
	await get_tree().physics_frame
	player = get_tree().current_scene.find_child("Player", true, false)
	add_to_group("enemy")
	if sprite:
		sprite.play("slime")

func _physics_process(delta: float) -> void:
	if player == null or is_dying:
		return
	
	direction = global_position.direction_to(player.global_position)
	var separation := Vector2.ZERO
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self:
			continue
		if enemy is CharacterBody2D:
			var distance = global_position.distance_to(enemy.global_position)
			if distance > 0 and distance < SEPARATION_DISTANCE:
				var away_direction = enemy.global_position.direction_to(global_position)
				separation += away_direction * (1.0 - distance / SEPARATION_DISTANCE)
	
	var final_direction = (direction + separation * SEPARATION_STRENGTH).normalized()
	velocity = velocity.lerp(final_direction * SPEED, delta * 10.0)
	move_and_slide()
	
	if global_position.distance_to(player.global_position) < 45.0:
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)
		
	walk_anim_time += delta * 10.0
	sprite.scale.y = 1.0 + sin(walk_anim_time) * 0.15
	update_sprite_direction(velocity)

func update_sprite_direction(move_velocity: Vector2) -> void:
	if sprite == null or is_dying:
		return
	if move_velocity.length() < 5.0:
		return
		
	var dir = move_velocity.normalized()
	if abs(dir.y) > 2.0 * abs(dir.x):
		if dir.y < 0:
			sprite.frame = 0
		else:
			sprite.frame = 4
		sprite.flip_h = false
		return

	if dir.x < 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

	if dir.y < -0.3:
		sprite.frame = 1
	elif dir.y > 0.3:
		sprite.frame = 3
	else:
		sprite.frame = 2

func take_damage(amount: int):
	if is_dying:
		return
	health -= amount
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	if health <= 0:
		die()

func die():
	is_dying = true
	velocity = Vector2.ZERO
	Global.gain_xp(25)
	
	var death_tween = create_tween().set_parallel(true)
	death_tween.tween_property(sprite, "rotation", 5.0, 0.25)
	death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25)
	death_tween.chain().tween_callback(queue_free)
