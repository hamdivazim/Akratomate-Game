extends Node2D

var slime_enemy = preload("res://Scenes/green_enemy.tscn")
var yellow_slime_enemy = preload("res://Scenes/yellow_enemy.tscn")
var shooter = preload("res://Scenes/enemy_shooter.tscn")
var boss = preload("res://Scenes/boss.tscn")

@onready var spawn_points = $Spawn.get_children()
@onready var music: AudioStreamPlayer2D = $Player/Music1

@onready var health_label: Label = $hud/Health
@onready var xp_label: Label = $hud/XP
@onready var wave_label: Label = $hud/Wave

@export var ROUND_GAP: float = 5
@export var MUSIC_FADE_TIME: float = 2.0
@export var MUSIC_VOLUME_DB: float = 0.0
@export var MUSIC_SILENT_DB: float = -40.0
@export var SPAWN_RANDOM_DELAY: float = 2.0

var current_wave: int = 1
var player: CharacterBody2D = null

var rounds = [
	{
		"spawns": [
			{"marker": 0, "enemy": slime_enemy, "count": 2},
			{"marker": 1, "enemy": slime_enemy, "count": 2},
			{"marker": 2, "enemy": slime_enemy, "count": 2},
			{"marker": 3, "enemy": slime_enemy, "count": 2},
			{"marker": 4, "enemy": slime_enemy, "count": 2},
		]
	},
	{
		"spawns": [
			{"marker": 0, "enemy": slime_enemy, "count": 1},
			{"marker": 1, "enemy": slime_enemy, "count": 1},
			{"marker": 2, "enemy": slime_enemy, "count": 1},
			{"marker": 3, "enemy": slime_enemy, "count": 1},
			{"marker": 4, "enemy": slime_enemy, "count": 1},

			{"marker": 0, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 1, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 2, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 3, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 4, "enemy": yellow_slime_enemy, "count": 1},
		]
	},
	{
		"spawns": [
			{"marker": 0, "enemy": slime_enemy, "count": 1},
			{"marker": 1, "enemy": slime_enemy, "count": 1},
			{"marker": 2, "enemy": slime_enemy, "count": 1},
			{"marker": 3, "enemy": slime_enemy, "count": 1},
			{"marker": 4, "enemy": slime_enemy, "count": 1},

			{"marker": 0, "enemy": shooter, "count": 1},
			{"marker": 2, "enemy": shooter, "count": 1},
			{"marker": 4, "enemy": shooter, "count": 1},
		]
	},
	{
		"spawns": [
			{"marker": 0, "enemy": slime_enemy, "count": 2},
			{"marker": 1, "enemy": slime_enemy, "count": 1},
			{"marker": 2, "enemy": slime_enemy, "count": 2},
			{"marker": 3, "enemy": slime_enemy, "count": 1},
			{"marker": 4, "enemy": slime_enemy, "count": 1},

			{"marker": 0, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 2, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 4, "enemy": yellow_slime_enemy, "count": 1},

			{"marker": 0, "enemy": shooter, "count": 1},
			{"marker": 1, "enemy": shooter, "count": 1},
			{"marker": 2, "enemy": shooter, "count": 1},
			{"marker": 3, "enemy": shooter, "count": 1},
			{"marker": 4, "enemy": shooter, "count": 1},
		]
	},
	{
		"spawns": [
			{"marker": 0, "enemy": yellow_slime_enemy, "count": 2},
			{"marker": 1, "enemy": yellow_slime_enemy, "count": 2},
			{"marker": 2, "enemy": yellow_slime_enemy, "count": 2},
			{"marker": 3, "enemy": yellow_slime_enemy, "count": 2},
			{"marker": 4, "enemy": yellow_slime_enemy, "count": 2},

			{"marker": 0, "enemy": shooter, "count": 1},
			{"marker": 1, "enemy": shooter, "count": 1},
			{"marker": 2, "enemy": shooter, "count": 1},
			{"marker": 3, "enemy": shooter, "count": 1},
			{"marker": 4, "enemy": shooter, "count": 1},
		]
	},
	{
		"spawns": [
			{"marker": 2, "enemy": boss, "count": 1},

			{"marker": 0, "enemy": slime_enemy, "count": 2},
			{"marker": 1, "enemy": slime_enemy, "count": 2},
			{"marker": 2, "enemy": slime_enemy, "count": 2},
			{"marker": 3, "enemy": slime_enemy, "count": 2},
			{"marker": 4, "enemy": slime_enemy, "count": 2},

			{"marker": 0, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 1, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 2, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 3, "enemy": yellow_slime_enemy, "count": 1},
			{"marker": 4, "enemy": yellow_slime_enemy, "count": 1},

			{"marker": 0, "enemy": shooter, "count": 1},
			{"marker": 1, "enemy": shooter, "count": 1},
			{"marker": 2, "enemy": shooter, "count": 1},
			{"marker": 3, "enemy": shooter, "count": 1},
			{"marker": 4, "enemy": shooter, "count": 1},
		]
	},
]

func _ready() -> void:
	randomize()
	player = find_child("Player", true, false)
	music.volume_db = MUSIC_SILENT_DB
	start_rounds()

func _process(_delta: float) -> void:
	if player:
		health_label.text = "HP: " + str(player.health)
	else:
		health_label.text = "HP: 0"
		
	xp_label.text = "LVL: " + str(Global.current_level) + " (" + str(Global.current_xp) + "/" + str(Global.xp_needed_for_level) + ")"
	wave_label.text = "WAVE: " + str(current_wave)

func start_rounds() -> void:
	current_wave = 1
	for round_data in rounds:
		fade_music_in()
		await spawn_round(round_data)
		
		while get_tree().get_nodes_in_group("enemy").size() > 0:
			await get_tree().create_timer(0.25).timeout
			
		await fade_music_out()
		await get_tree().create_timer(ROUND_GAP).timeout
		current_wave += 1

func fade_music_in() -> void:
	if not music.playing:
		music.play()
	var tween = create_tween()
	tween.tween_property(music, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE_TIME)

func fade_music_out() -> void:
	var tween = create_tween()
	tween.tween_property(music, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE_TIME)
	await tween.finished
	music.stop()

func spawn_round(round_data: Dictionary) -> void:
	for spawn_data in round_data["spawns"]:
		spawn_cluster(spawn_data)
	await get_tree().create_timer(SPAWN_RANDOM_DELAY + 0.1).timeout

func spawn_cluster(spawn_data: Dictionary) -> void:
	await get_tree().create_timer(randf_range(0.0, SPAWN_RANDOM_DELAY)).timeout

	var marker_index = spawn_data["marker"]
	var enemy_scene = spawn_data["enemy"]
	var count = spawn_data["count"]

	if marker_index < 0 or marker_index >= spawn_points.size():
		return

	var spawn_sound = spawn_points[marker_index].get_child(0)
	if spawn_sound is AudioStreamPlayer2D:
		spawn_sound.play()

	for i in range(count):
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_points[marker_index].global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		add_child(enemy)
