extends CharacterBody2D

@export var MAX_HEALTH = 100
@export var SPEED = 1500
@export var ACCEL = 2000
@export var DECEL = 1000
@export var IFRAME_DURATION: float = 1.0
@export var RELOAD_SPEED = 0.4

var pistol_bullet_speed = 1500
var weapons = ["pistol"]
var current_weapon = "pistol"
var walk_anim_time: float = 0.0
var health = 100
var spindir = 1
var is_invincible: bool = false
var can_shoot: bool = true

func _ready():
	add_to_group("player")
	$AnimatedSprite2D.animation = "default"
	$AnimatedSprite2D.play("default")

func _process(delta):
	$AnimatedSprite2D.speed_scale = 10.0 * spindir
	
	if is_invincible:
		var pulse = fmod(Time.get_ticks_msec() / 100.0, 2.0)
		$AnimatedSprite2D.modulate.a = 0.3 if pulse > 1.0 else 1.0
	else:
		$AnimatedSprite2D.modulate.a = 1.0
	
func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("Left", "Right")
	if direction_x != 0:
		velocity.x = move_toward(velocity.x, direction_x * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL * delta)
		
	var direction_y := Input.get_axis("Up", "Down")
	if direction_y != 0:
		velocity.y = move_toward(velocity.y, direction_y * SPEED, ACCEL * delta)
	else:
		velocity.y = move_toward(velocity.y, 0, DECEL * delta)
		
	if direction_y != 0 or direction_x != 0:
		walk_anim_time += delta * 10.0
		$AnimatedSprite2D.scale.y = 1.0 + sin(walk_anim_time) * 0.1
	else:
		walk_anim_time = 0.0
		$AnimatedSprite2D.scale.y = 1.0
		
	if Input.is_action_just_pressed("Shoot") and current_weapon == "pistol" and can_shoot:
		can_shoot = false
		spindir *= -1
		$Shoot.play()
		var bullet = preload("res://Scenes/pistol_bullet.tscn").instantiate()
		get_tree().current_scene.add_child(bullet)
		
		var angle_deg = $AnimatedSprite2D.frame * (356.0 / 88.0)
		var angle_rad = deg_to_rad(angle_deg)
		bullet.global_position = global_position
		var bullet_direction = Vector2(-sin(angle_rad), cos(angle_rad))

		bullet.global_rotation = bullet_direction.angle()
		bullet.velocity = bullet_direction * pistol_bullet_speed
		await get_tree().create_timer(RELOAD_SPEED).timeout
		can_shoot = true
	move_and_slide()

func take_damage(amount: int):
	if is_invincible:
		return

	var mitigated_damage = int(amount * Global.damage_taken_modifier)
	health -= mitigated_damage
	
	if health <= 0:
		get_tree().reload_current_scene()
		return
		
	is_invincible = true
	get_tree().create_timer(IFRAME_DURATION).timeout.connect(func(): is_invincible = false)
	
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.0)
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
