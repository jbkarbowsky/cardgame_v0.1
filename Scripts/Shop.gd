extends Node2D

#How many card we want to instantiate 
const shop_deck_count = 10
#Path to card scene for instantiate
const PATH_TO_CARD_SCENE = "res://Scenes/Card.tscn"
var card_scene = preload(PATH_TO_CARD_SCENE)

const CARD_WIDTH = 188
const CARD_Y_POSITION = 910

var battle_timer
#Shop matrix
var shop_deck = []
#Variable for centering card placement
var center_screen_x
#Reference to card database
var card_dbase_reference
#Starting coins
var starting_coins = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#COINS:
	$"../Coins".text = "Coins:" + str(starting_coins)
	#center of screen in x
	center_screen_x = get_viewport().size.x / 2
	card_dbase_reference = preload("res://Scripts/CardDatabase.gd")
	fill_shop(card_scene)
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1
	

func _on_refresh_shop_pressed() -> void:
	#-1 coin
	if starting_coins <= 0:
		$"../NotEnoughCoins".visible = true
		battle_timer.start()
		await battle_timer.timeout
		$"../NotEnoughCoins".visible = false
	else:
		clear_shop()
		starting_coins = starting_coins - 1
		#Delete existing cards
		shop_deck.clear()
		fill_shop(card_scene) 
		$"../Coins".text = "Coins:" + str(starting_coins)
		
func clear_shop():
	var parent = $"../CardManager"
	for child in parent.get_children():
		if !child.card_in_player_field:
			parent.remove_child(child)
			child.queue_free()
	

			
	
func fill_shop(card_scene):
	for i in range(shop_deck_count):
		var new_card = card_scene.instantiate()
		new_card = random_card_draw(new_card)
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		add_card_to_shop(new_card)
	
func update_coins(card):
	var cost = card.get_node("Cost").text
	cost = int(cost)
	print(cost)
	if (cost > starting_coins):
		
		$"../NotEnoughCoins".visible = true
		battle_timer.start()
		await battle_timer.timeout
		$"../NotEnoughCoins".visible = false
		return 1
	else:
		starting_coins = starting_coins - cost
		$"../Coins".text = "Coins:" + str(starting_coins)
		return 0

#random card pick
func random_card_draw(card):
	var name = card.get_node("Name").text
	name = card_dbase_reference.CARDS.keys()[randi() % card_dbase_reference.CARDS.size()]
	var path_card_img = str("res://Assets/"+name+"Card.png")
	card.get_node("CardImage").texture = load(path_card_img)
	card.get_node("Name").text = name
	card.get_node("HP").text = str(card_dbase_reference.CARDS[name][0])
	card.get_node("Attack").text = str(card_dbase_reference.CARDS[name][1])
	card.get_node("SPD").text = str(card_dbase_reference.CARDS[name][4])
	card.get_node("Cost").text = str(card_dbase_reference.CARDS[name][5])
	card.get_node("Fraction").text = str(card_dbase_reference.CARDS[name][6])
	card.get_node("DEF").text = "DEF: " + str(card_dbase_reference.CARDS[name][2])
	return card 
	
func add_card_to_shop(card):
	shop_deck.append(card)
	update_card_positions()
	
	
func calculate_card_position(index):
	#Width of player hand minus width of one card width
	var total_width = (shop_deck.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2 
	return x_offset
	
func update_card_positions():
	for i in range(shop_deck.size()):
		#Get new position based on card index
		var new_pos = Vector2(calculate_card_position(i),CARD_Y_POSITION)
		var card = shop_deck[i]
		card.card_being_collected_pos = new_pos
		animate_card_to_pos(card, new_pos)
		
func animate_card_to_pos(card, pos):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position", pos, 0.5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
