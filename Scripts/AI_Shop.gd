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

var preffered_faction = ""

func find_key_with_max_value(dictionary):
	var max_key = ""
	var max_value = 0
	for key in dictionary.keys():
		var value = dictionary[key]
		if value > max_value:
			max_value = value
			max_key = key
	return max_key


func count_factions_in_hand(hand, dict):
	if hand:
		for card in hand:
			var faction_node = card.get_node("Faction")
			if faction_node != null:
				var faction = faction_node.text
				if faction in dict:
					dict[faction] += 1
	return dict

func fill_card_slots():
	while AI_player_hand.size() < 5 and AI_starting_coins > 0:
		var picked_card = pick_card()
		if picked_card == null:
			print("Nie znaleziono odpowiedniej karty.")
			break
		print("Karta dodana: ", picked_card.name)



func pick_card():
	var best_card = null
	var best_card_score = 0

	# Aktualizacja faction_count na początku każdej tury
	var faction_count = {
		"Royalty": 0,
		"Archers": 0,
		"Knighthood": 0,
		"Clerics": 0
	}
	count_factions_in_hand(AI_player_hand,faction_count)
	preffered_faction = find_key_with_max_value(faction_count)

	print("Preferred faction: ", preffered_faction)

	for card in AI_shop_deck:
		var card_faction = card.get_node("Faction").text
		var card_cost = card.get_node("Cost").text.to_int()

		if AI_player_hand.size() < 5:
			if preffered_faction == card_faction and card_cost <= AI_starting_coins:
				AI_shop_deck.erase(card)
				AI_starting_coins -= card_cost
				$"../../AICoins".text =  "AI Coins: " + str(AI_starting_coins)
				add_card_to_hand(card)
				card.card_in_player_field = true
				print("Karta dodana do slotu: ", card.name)
				return card

	# Jeśli nie znaleziono karty zgodnej z preferowaną frakcją, wybierz najlepszą kartę według SPD i ATK
	for card in AI_shop_deck:
		var card_cost = card.get_node("Cost").text.to_int()
		var actual_card_score = card.get_node("Attack").text.to_int() + card.get_node("SPD").text.to_int()

		if actual_card_score > best_card_score and card_cost <= AI_starting_coins:
			best_card = card
			best_card_score = actual_card_score

	if best_card != null:
		AI_shop_deck.erase(best_card)
		AI_starting_coins -= best_card.get_node("Cost").text.to_int()
		$"../../AICoins".text = "AI Coins: " + str(AI_starting_coins)
		add_card_to_hand(best_card)
		best_card.card_in_player_field = true
		print("Karta dodana do slotu: ", best_card.name)
		return best_card  # Wyjdź z funkcji po znalezieniu i dodaniu karty

	return null  # Zwróć null, jeśli nie znaleziono odpowiedniej karty



func add_card_to_hand(card: Node2D):
	var slot_found = false
	for j in range($"../AI_PlayerHand".get_child_count()):
		var card_slot = $"../AI_PlayerHand".get_child(j)
		if card_slot.card_in_slot == false:  # Sprawdź, czy slot jest pusty
			var pos = card_slot.position
			animate_card_to_pos(card, pos)
			card.card_in_player_field = true
			card.what_card_slot = card_slot
			card_slot.card_in_slot = true
			slot_found = true
			AI_player_hand.append(card)
			print("Karta dodana do slotu: ", card_slot.name)
			break  # Przerwij pętlę, gdy znajdziesz pusty slot

	if not slot_found:
		print("Nie znaleziono pustego slotu dla karty AI:", card.name)


			


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	card_dbase_reference = preload("res://Scripts/CardDatabase.gd")
	fill_shop(card_scene)
	$"../../AICoins".text =  "AI Coins: " + str(AI_starting_coins)

func clear_shop():
	var parent = $"."
	for child in parent.get_children():
		if child.has_method("is_card") and child.is_card() and !child.card_in_player_field:
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
	return card

func calculate_card_position(index):
	var total_width = (AI_shop_deck.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func update_card_positions():
	for i in range(AI_shop_deck.size()):
		var card = AI_shop_deck[i]
		if card:  
			var new_pos = Vector2(calculate_card_position(i), CARD_Y_POSITION)
			card.card_being_collected_pos = new_pos
			animate_card_to_pos(card, new_pos)
		else:
			print("Karta została usunięta:", i)

func animate_card_to_pos(card, pos):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", pos, 0.5)
