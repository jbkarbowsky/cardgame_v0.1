extends Node

var PLAYER_HEALTH = 20
var AI_HEALTH = 20

var shop_deck_reference
var card_manager_reference 
var ai_shop_reference
var player_hand_reference
var combined_hands = []
var MOVE_SPEED = 0.5

var battle_timer 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shop_deck_reference = $"../ShopDeck"
	card_manager_reference = $"../CardManager"
	ai_shop_reference = $"../AI_Player/AI_PlayerShopDeck"
	player_hand_reference = $"../CardManager".player_hand
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1
	$"../Try_again".process_mode = Node.PROCESS_MODE_ALWAYS
	

func _on_end_turn_button_pressed() -> void:
	for child in card_manager_reference.get_children():
		child.get_node("Area2D/CollisionShape2D").disabled = true
	ai_shop_reference.add_card_to_hand()
	ai_shop_reference.clear_shop()
	$"../Start".visible = true
	$"../EndTurnButton".visible = false
	$"../EndTurnButton".disabled = true
	
	
func _on_next_button_pressed() -> void:
	$"../Coins".visible = false
	$"../RefreshShopButton".visible = false
	$"../NextButton".visible = false
	$"../EndTurnButton".visible = true
	$"../EndTurnButton".disabled = false
	shop_deck_reference.clear_shop()
	for card in player_hand_reference:
		card.get_node("Area2D/CollisionShape2D").disabled = false

func _on_start_pressed() -> void:
	assign_turns()
	$"../AI_Health_Bar".value = AI_HEALTH
	$"../Player_Health_Bar".value = PLAYER_HEALTH
	$"../AI_Health_Bar".visible = true
	$"../Player_Health_Bar".visible = true 
	$"../Start".visible = false
	print("Początkowa tablica: ", combined_hands, " rozmiar: ", combined_hands.size())
	attack()

func attack():
	var i = 0
	var last_card_attacked = false
	while i < combined_hands.size():
		if combined_hands[i].is_alive:
			print("Atak karty:", combined_hands[i].name)
			attack_target(combined_hands[i])
			battle_timer.start()
			await battle_timer.timeout
			if i == combined_hands.size() - 1:
				last_card_attacked = true
				print("Ostatnia karta zaatakowała, wywołanie end_turn()")
				end_turn()
		else:
			print("Błąd: Indeks ", i, " przekracza rozmiar combined_hands")
		i += 1
	if not last_card_attacked:
		print("Wywołanie end_turn() po zakończeniu pętli")
		end_turn()
	print("Pozostałe karty: ", combined_hands)


func attack_target(attacker):
	if attacker in player_hand_reference:
		var target = find_leftmost_card_AI()
		if target == null:
			print("Bezpośredni atak na AI przez:", attacker.name)
			direct_attack_on_AI(attacker)
		else:
			print("Atak na kartę AI przez:", attacker.name)
			attack_card(attacker, target)
	else:
		var target = find_leftmost_card_player()
		if target == null:
			print("Bezpośredni atak na gracza przez:", attacker.name)
			direct_attack_on_player(attacker)
		else:
			print("Atak na kartę gracza przez:", attacker.name)
			attack_card(attacker, target)

func attack_card(attacker, target):
	var starting_pos = Vector2(attacker.position.x, attacker.position.y)
	var new_pos
	if attacker in ai_shop_reference.AI_player_hand:
		new_pos = Vector2(target.position.x, target.position.y - 50)
	else:
		new_pos = Vector2(target.position.x, target.position.y + 50)
	var tween = get_tree().create_tween()
	tween.tween_property(attacker, "position", new_pos, MOVE_SPEED)
	await tween.finished
	var targetHP = target.get_node("HP").text.to_int()
	var attackerATK = attacker.get_node("Attack").text.to_int()
	targetHP -= attackerATK
	if targetHP <= 0:
		target.is_alive = false
		target.what_card_slot.card_in_slot = false
		remove_card(target)
		
	else:
		target.get_node("HP").text = str(targetHP)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacker, "position", starting_pos, MOVE_SPEED)
	await tween2.finished

func remove_card(card):
	if card in player_hand_reference:
		player_hand_reference.erase(card)
		combined_hands.erase(card)
		$"../CardManager".remove_child(card)
		$"../ShopDeck".remove_child(card)
		card.queue_free()
		print("Usunięto kartę z ręki gracza:", card.name)
	elif card in ai_shop_reference.AI_player_hand:
		ai_shop_reference.AI_player_hand.erase(card)
		combined_hands.erase(card)
		$"../AI_Player/AI_PlayerShopDeck".remove_child(card)
		card.queue_free()
		print("Usunięto kartę z ręki AI:", card.name)




func end_turn():
	#Add coins:
	shop_deck_reference.starting_coins = shop_deck_reference.starting_coins + 10
	ai_shop_reference.AI_starting_coins = ai_shop_reference.AI_starting_coins + 10

	# Clear the shop deck
	for card in shop_deck_reference.get_children():
		card.queue_free()
	shop_deck_reference.shop_deck.clear()
	
	$"../AI_Health_Bar".visible = false
	$"../Player_Health_Bar".visible = false 
	$"../Coins".visible = true
	$"../Coins".text = "Coins:" + str(shop_deck_reference.starting_coins)
	$"../AICoins".text = "Coins: " + str(ai_shop_reference.AI_starting_coins)
	$"../RefreshShopButton".visible = true
	$"../NextButton".visible = true
	
	shop_deck_reference.fill_shop(shop_deck_reference.card_scene)
	$"../CardManager".counter = 0
	
	#fill AI shop
	ai_shop_reference.fill_shop(ai_shop_reference.card_scene)
	ai_shop_reference.card_limit = 0
	print("Stan shopa AI: ", ai_shop_reference.AI_starting_coins)
	
	



func direct_attack_on_AI(attacker):
	var starting_pos = Vector2(attacker.position.x, attacker.position.y) 
	var new_pos = Vector2($"../AI_Health_Bar".position.x + 350, $"../AI_Health_Bar".position.y + 20)
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacker, "position", new_pos, MOVE_SPEED)
	await tween.finished
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacker, "position", starting_pos, MOVE_SPEED)
	
	var attack = attacker.get_node("Attack").text.to_int()
	AI_HEALTH -= attack
	$"../AI_Health_Bar".value = AI_HEALTH
	
	if AI_HEALTH <= 0:
		print("Gracz wygrał!")
		end_game("player")

func end_game(winner):
	if winner == "player":
		end_game_status()
		print("Koniec gry: Gracz wygrał!")
		$"../AI_Player_Defeated".visible = true
	elif winner == "AI":
		end_game_status()
		print("Koniec gry: AI wygrał!")
		$"../Player_Defeated".visible = true
	
	# Dodaj tutaj dowolne inne czynności kończące grę, takie jak wyświetlenie ekranu końcowego, zresetowanie gry itp.
	
	
	# czyszczenie rąk graczy
	# info kto wygrał
func end_game_status():
	$"../ShopDeck".visible = false
	$"../PlayerDeck".visible = false
	$"../AI_Player".visible = false
	$"../Try_again".visible = true
	$"..".get_tree().paused = true
	
	
		#oprogramowanie zagraj ponownie buttona który będzie wracał do początku gry
		
		
		#czyli - losowanie shopa, reset stanu HP przeciwników, czyszczenie tablic z kart i dzieci, 
		#wlaczenie przyciskow Coins, Next, Refresh

func _on_try_again_pressed() -> void:
	$"..".get_tree().paused = false
	$"..".get_tree().reload_current_scene()
	try_again()
	



func try_again():
	$"../AI_Player_Defeated".visible = false
	$"../Player_Defeated".visible = false
	$"../Try_again".visible = false
	$"../ShopDeck".visible = true
	$"../PlayerDeck".visible = true
	$"../AI_Player".visible = true
	
	AI_HEALTH = 20
	PLAYER_HEALTH = 20
	$"../RefreshShopButton".visible = true
	$"../NextButton".visible = true
	$"../Coins".visible = true
	shop_deck_reference.starting_coins = 20
	ai_shop_reference.AI_starting_coins = 20
	

	#var player_slots = $"../PlayerDeck".get_children()
	#for card_slot in player_slots:
		#card_slot.card_in_slot = false
	#var AI_slots = $"../AI_Player/AI_PlayerHand".get_children()
	#for card_slot in AI_slots:
		#card_slot.card_in_slot = false
		
	#remove card from shop:
	shop_deck_reference.shop_deck.clear()	
		
	#shop_deck_reference.fill_shop(shop_deck_reference.card_scene)
	#ai_shop_reference.fill_shop(ai_shop_reference.card_scene)
	
	
	
	
	
	#REMOVING CARDS
	#var player_cards = $"../CardManager".get_children()
	#for card in player_cards:
		#$"../CardManager".remove_child(card)
		#card.queue_free()
	#var AI_cards = $"../AI_Player/AI_PlayerShopDeck".get_children()
	#for card in AI_cards:
		#$"../AI_Player/AI_PlayerShopDeck".remove_child(card)
		#card.queue_free()
		#
	#combined_hands.clear()
	#shop_deck_reference.player_hand.clear()
	#ai_shop_reference.AI_player_hand.clear()
		
	
	
	
	
func direct_attack_on_player(attacker):
	var starting_pos = Vector2(attacker.position.x, attacker.position.y) 
	var new_pos = Vector2($"../Player_Health_Bar".position.x + 350, $"../Player_Health_Bar".position.y - 20)
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacker, "position", new_pos, MOVE_SPEED)
	await tween.finished
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacker, "position", starting_pos, MOVE_SPEED)
	
	var attack = attacker.get_node("Attack").text.to_int()
	PLAYER_HEALTH -= attack
	$"../Player_Health_Bar".value = PLAYER_HEALTH
	
	if PLAYER_HEALTH <= 0:
		print("AI wygrał!")
		end_game("AI")


func assign_turns():
	combined_hands = player_hand_reference + ai_shop_reference.AI_player_hand
	for i in range(combined_hands.size()): 
		for j in range(i + 1, combined_hands.size()): 
			print("Player: ", player_hand_reference)
			print("AI: ", ai_shop_reference.AI_player_hand)
			print("Combined hands: ", combined_hands, "wartosc i: ", i, "rozmiar tablicy: ", combined_hands.size())
			if combined_hands[i].get_node("SPD").text.to_int() < combined_hands[j].get_node("SPD").text.to_int(): 
				var temp = combined_hands[i] 
				combined_hands[i] = combined_hands[j] 
				combined_hands[j] = temp
	for i in range(combined_hands.size()): 
		var card = combined_hands[i] 
		card.get_node("Turn").text = str(i + 1)

func find_leftmost_card_player():
	var leftmost_card = null
	var leftmost_position = INF
	for card in player_hand_reference:
		if card.get_node("HP").text.to_int() > 0:
			var card_position = card.position.x
			if card_position < leftmost_position:
				leftmost_position = card_position
				leftmost_card = card
	return leftmost_card

func find_leftmost_card_AI():
	var leftmost_card = null
	var leftmost_position = INF
	for card in ai_shop_reference.AI_player_hand:
		if card.get_node("HP").text.to_int() > 0:
			var card_position = card.position.x
			if card_position < leftmost_position:
				leftmost_position = card_position
				leftmost_card = card
	return leftmost_card
