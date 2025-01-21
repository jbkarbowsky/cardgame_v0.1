extends Node2D

signal hovered
signal hovered_off

var card_being_collected_pos
var card_in_player_field = false
var is_alive = true
var what_card_slot



var skill_cooldown = 0
var skill_duration = 0 
var current_cooldown = 0
var current_duration = 0
var card_id



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
	
