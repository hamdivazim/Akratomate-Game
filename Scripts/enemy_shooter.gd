extends CharacterBody2D

@export var health: int = 10
@export var SPEED: float = 60.0
@export var GUN_TURN_SPEED: float = 3.0
@export var AIM_ERROR_DEGREES: float = 12.0
@export var AIM_ERROR_CHANGE_TIME: float = 0.6

var direction: Vector2
var aim_error: float = 0.0
var is_dying: bool = false

var bullet_scene = preload("res://Scenes/enemy_bullet.tscn")
var bullet_speed = 800.0

@onready var gun_pivot: Node2D = $GunPivot
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null 

func _ready():
	await get_tree().physics_frame
	player = get_tree().current_scene.find_child("Player", true, false)
	
	navigation_agent.path_desired_distance = 20.0
	navigation_agent.target_desired_distance = 20.0
	
	randomize()
	update_aim_error()
	var aim_error_timer = Timer.new()
	aim_error_timer.wait_time = AIM_ERROR_CHANGE_TIME
	aim_error_timer.autostart = true
	aim_error_timer.timeout.connect(update_aim_error)
	add_child(aim_error_timer)

func _physics_process(delta: float) -> void:
	if player == null or is_dying:
		return 
	
	var target_angle = global_position.direction_to(player.global_position).angle() + aim_error
	gun_pivot.global_rotation = lerp_angle(gun_pivot.global_rotation, target_angle, GUN_TURN_SPEED * delta)
	
	navigation_agent.target_position = player.global_position
	
	if not navigation_agent.is_navigation_finished():
		var next_path_position: Vector2 = navigation_agent.get_next_path_position()
		direction = global_position.direction_to(next_path_position)
		velocity = velocity.lerp(direction * SPEED, delta * 10.0)
		move_and_slide()
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 10.0)
		move_and_slide()

func update_aim_error() -> void:
	aim_error = deg_to_rad(randf_range(-AIM_ERROR_DEGREES, AIM_ERROR_DEGREES))

func _on_shoot_timer_timeout() -> void:
	if is_dying:
		return
	$EnemyShoot.play()
	if player == null:
		return
		
	var dir_to_player = Vector2.RIGHT.rotated(gun_pivot.global_rotation)
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	bullet.global_position = global_position
	bullet.global_rotation = dir_to_player.angle()
	
	bullet.velocity = dir_to_player * bullet_speed

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
