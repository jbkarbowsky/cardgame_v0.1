extends Node2D

const shop_deck_count = 10
const PATH_TO_CARD_SCENE = "res://Scenes/EnemyCard.tscn"
var card_scene = preload(PATH_TO_CARD_SCENE)

const CARD_WIDTH = 188
const CARD_Y_POSITION = 130

var AI_shop_deck = []
var center_screen_x
var card_dbase_reference
var AI_starting_coins = 20

var AI_player_hand = []
var AI_shop_deck_reference
var card_limit = 5

func check_faction_bonus(hand):
	var faction_count = {
		"Royality": 0,
		"Archers": 0,
		"Knighthood": 0,
		"Clerics": 0
	}
	for card in hand:
		var faction = card.get_node("Faction").text
		if faction in faction_count:
			faction_count[faction] += 1

	var most_common_faction = ""
	var highest_count = 0
	for faction in faction_count.keys():
		if faction_count[faction] > highest_count:
			highest_count = faction_count[faction]
			most_common_faction = faction
			
		if faction_count.has(most_common_faction) and faction_count[most_common_faction] == 0:
			return ""
		else:
			return most_common_faction



func pick_card():
	var picked_card = null
	var faction_card = check_faction_bonus(AI_shop_deck)
	print(faction_card)
	if faction_card != "":
		for card in AI_shop_deck:
			var cost = int(card.get_node("Cost").text)
			if card.get_node("Faction").text == faction_card and cost <= AI_starting_coins:
				picked_card = card
			AI_player_hand.erase(picked_card)
	else:
		var temp_most_value = 0
		for card in AI_shop_deck:
			var SPD = card.get_node("SPD").text.to_int()
			var ATK = card.get_node("Attack").text.to_int()
			var combined_SPD_ATK = SPD+ATK
			if combined_SPD_ATK > temp_most_value:
				picked_card=card
			AI_player_hand.erase(picked_card)
	return picked_card

func add_card_to_hand():
	for i in range(5):
		var picked_card = pick_card()
		
		
		AI_starting_coins -= int(picked_card.get_node("Cost").text)
		$"../../AICoins".text = "AI coins: " + str(AI_starting_coins)
		
		if picked_card:
			var slot_found = false
			for j in range($"../AI_PlayerHand".get_child_count()):
				var card_slot = $"../AI_PlayerHand".get_child(j)
				if not card_slot.card_in_slot:  # Sprawdź, czy slot jest pusty
					var pos = card_slot.position
					animate_card_to_pos(picked_card, pos)
					picked_card.card_in_player_field = true
					picked_card.what_card_slot = card_slot
					card_slot.card_in_slot = true
					slot_found = true
					AI_player_hand.append(picked_card)
					break 
			if not slot_found:
				print("Nie znaleziono pustego slotu dla karty AI:", picked_card.name)

			


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	card_dbase_reference = preload("res://Scripts/CardDatabase.gd")
	fill_shop(card_scene)
	$"../../AICoins".text =  "Coins: " + str(AI_starting_coins)

func clear_shop():
	var parent = $"."
	for child in parent.get_children():
		if !child.card_in_player_field:
			print("Removing card:", child.name)
			if child in AI_shop_deck:
				AI_shop_deck.erase(child)
			parent.remove_child(child)
			child.queue_free()
	print("Shop cleared. Remaining children:", parent.get_child_count())

func fill_shop(card_scene):
	for i in range(shop_deck_count):
		var new_card = card_scene.instantiate()
		new_card = random_card_draw(new_card)
		$".".add_child(new_card)
		new_card.name = "AI_Card"
		AI_shop_deck.append(new_card)
		update_card_positions()

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
	card.get_node("Faction").text = str(card_dbase_reference.CARDS[name][6])
	card.get_node("DEF").text = "DEF: " + str(card_dbase_reference.CARDS[name][2])
	#health, attack, physical_defense, magical_defense, speed, cost, faction, damage_type
	return card

func calculate_card_position(index):
	var total_width = (AI_shop_deck.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func update_card_positions():
	for i in range(AI_shop_deck.size()):
		var card = AI_shop_deck[i]
		if card:  # Sprawdź, czy karta nadal istnieje
			var new_pos = Vector2(calculate_card_position(i), CARD_Y_POSITION)
			card.card_being_collected_pos = new_pos
			animate_card_to_pos(card, new_pos)
		else:
			print("Karta została usunięta:", i)

func animate_card_to_pos(card, pos):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", pos, 0.5)
