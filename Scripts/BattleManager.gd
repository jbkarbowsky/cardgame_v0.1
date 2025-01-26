extends Node

var PLAYER_HEALTH = 100
var AI_HEALTH = 100

var shop_deck_reference
var card_manager_reference 
var ai_shop_reference
var player_hand_reference
var combined_hands = []
var MOVE_SPEED = 0.5

var skill_vars = {}
var card_id_counter = 0
var card_states = {}

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
	
	
	
	ai_shop_reference.fill_card_slots()
	ai_shop_reference.clear_shop()
	$"../Start".visible = true
	$"../EndTurnButton".visible = false
	$"../EndTurnButton".disabled = true
	$"../AICoins".visible = false
	
func _on_next_button_pressed() -> void:
	$"../AICoins".visible = true
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
	attack()
	
	
	

func update_skills():
	for card_id in skill_vars.keys():
		print("Przed aktualizacją:", skill_vars[card_id])

		if skill_vars[card_id]["current_cooldown"] > 0:
			skill_vars[card_id]["current_cooldown"] -= 1
			print("Decrementing cooldown for card_id:", card_id, "new cooldown:", skill_vars[card_id]["current_cooldown"])

		if skill_vars[card_id]["current_duration"] > 0:
			skill_vars[card_id]["current_duration"] -= 1
			print("Decrementing duration for card_id:", card_id, "new duration:", skill_vars[card_id]["current_duration"])

		if skill_vars[card_id]["current_duration"] == 0 and not skill_vars[card_id]["deactivated"]:
			print("Dezaktywacja umiejętności warunki spełnione dla card_id:", card_id, "z owner:", skill_vars[card_id]["owner"])

			if skill_vars[card_id]["owner"] == "AI":
				$"../Card_Special_Abilities".deactivate_skill(card_id, ai_shop_reference.AI_player_hand)
				print("Dezaktywacja umiejętności dla AI, card_id:", card_id)
			elif skill_vars[card_id]["owner"] == "player":
				$"../Card_Special_Abilities".deactivate_skill(card_id, player_hand_reference)
				print("Dezaktywacja umiejętności dla playera, card_id:", card_id)

			skill_vars[card_id]["deactivated"] = true

		for card in combined_hands:
			if card.card_id == card_id:
				card.get_node("AbilityCD").text = str(skill_vars[card_id]["current_cooldown"])

		print("Po aktualizacji:", skill_vars[card_id])

func attack():
	
	$"../Card_Special_Abilities".check_faction_bonus(player_hand_reference)
	$"../Card_Special_Abilities".check_faction_bonus(ai_shop_reference.AI_player_hand)
	
	
	var i = 0
	var last_card_attacked = false
	while i < combined_hands.size():
		var card = combined_hands[i]
		if not card.card_id:
			var owner = "player" if card in player_hand_reference else "AI"
			$"../Card_Special_Abilities".apply_ability(card, owner)  # Przypisanie umiejętności do karty
		if card.is_alive:
			$"../BattleManager".card_states[card.card_id]["is_alive"] = true  # Aktualizacja stanu karty
			if $"../BattleManager".skill_vars[card.card_id]["current_cooldown"] == 0:
				$"../BattleManager".skill_vars[card.card_id]["deactivated"] = false
				if card in ai_shop_reference.AI_player_hand:
					$"../Card_Special_Abilities".activate_skill(card, ai_shop_reference.AI_player_hand)
				elif card in player_hand_reference:
					$"../Card_Special_Abilities".activate_skill(card, player_hand_reference)
		
			attack_target(card)
			battle_timer.start()
			await battle_timer.timeout
			if i == combined_hands.size() - 1:
				last_card_attacked = true
				end_turn()
		else:
			$"../BattleManager".card_states[card.card_id]["is_alive"] = false 
		i += 1
	if not last_card_attacked:
		end_turn()

func attack_target(attacker):
	if attacker in player_hand_reference:
		var target = find_leftmost_card_AI()
		if target == null:
			
			direct_attack_on_AI(attacker)
		else:
			
			attack_card(attacker, target)
	else:
		var target = find_leftmost_card_player()
		if target == null:
			
			direct_attack_on_player(attacker)
		else:
			
			attack_card(attacker, target)

func attack_card(attacker, target):
	if target.card_id in $"../BattleManager".skill_vars:
		var dodge_chance = $"../BattleManager".skill_vars[target.card_id].get("crossbowman_dodge_chance", 0)
		if target.get_node("Name").text == "Crossbowman" and randf() < dodge_chance:
			print("Crossbowman uniknął ataku!")
			return  # Uniknięcie ataku
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
	var targetDEF = target.get_node("DEF").text.to_int()
	var actual_damage = max(1, int(attackerATK * (100 / (100 + targetDEF))))
	targetHP -= actual_damage
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
		card.what_card_slot.card_in_slot = false
		card.queue_free()
		
	elif card in ai_shop_reference.AI_player_hand:
		ai_shop_reference.AI_player_hand.erase(card)
		combined_hands.erase(card)
		$"../AI_Player/AI_PlayerShopDeck".remove_child(card)
		card.queue_free()

func end_turn():
	
	update_skills()
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
	
	ai_shop_reference.AI_shop_deck.clear()
	#fill AI shop
	ai_shop_reference.fill_shop(ai_shop_reference.card_scene)
	ai_shop_reference.card_limit = 0
	
	

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
		
	#remove card from shop:
	shop_deck_reference.shop_deck.clear()

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
