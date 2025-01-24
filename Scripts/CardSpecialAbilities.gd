extends Node

func apply_ability(card, owner):
	if not card.card_id:
		$"../BattleManager".card_id_counter += 1
		card.card_id = $"../BattleManager".card_id_counter
		$"../BattleManager".skill_vars[card.card_id] = {
			"card_name": "", "current_cooldown": 0, "current_duration": 0, "skill_cooldown": 0,
			"skill_duration": 0, "owner": owner, "deactivated": false,
			"royal_guard_buffed_cards": [], "knight_buffed_cards": [], "kingwarlord_buffed_cards": [], "monk_debuffed_cards": [], "crossbowman_dodge_chance": 0.2
		}
		$"../BattleManager".card_states[card.card_id] = {"is_alive": card.is_alive}
		match card.get_node("Name").text:
			"RoyalGuard":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "RoyalGuard"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 3
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 2
			"Knight":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Knight"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 3
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 1
			"KingWarlord":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "KingWarlord"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 4
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 2
			"Healer":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Healer"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 3
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 0
			"Monk":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Monk"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 4
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 2
			"Paladin":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Paladin"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 0
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 1
			"Archer":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Archer"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 0
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 1
			"Crossbowman":
				$"../BattleManager".skill_vars[card.card_id]["card_name"] = "Crossbowman"
				$"../BattleManager".skill_vars[card.card_id]["skill_cooldown"] = 0
				$"../BattleManager".skill_vars[card.card_id]["skill_duration"] = 1
				$"../BattleManager".skill_vars[card.card_id]["crossbowman_dodge_chance"] = 0.2
				
		print("Przypisano umiejętność:", $"../BattleManager".skill_vars[card.card_id])


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

	for faction in faction_count.keys():
		if faction_count[faction] >= 3:
			apply_faction_bonus(hand, faction)
		else:
			remove_faction_bonus(hand, faction)

func apply_faction_bonus(hand, faction):
	for card in hand:
		if card.get_node("Faction").text == faction:
			var card_attack = int(card.get_node("Attack").text)
			var card_defense = int(card.get_node("DEF").text)
			card_attack += 1
			card_defense += 1
			card.get_node("Attack").text = str(card_attack)
			card.get_node("DEF").text = "DEF: " + str(card_defense)
			card.set_meta("faction_bonus", true)
			print(faction, " bonus applied to ", card.get_node("Name").text)

func remove_faction_bonus(hand, faction):
	for card in hand:
		if card.get_node("Faction").text == faction:
			var card_attack = int(card.get_node("Attack").text)
			var card_defense = int(card.get_node("DEF").text)
			if card_attack > 0 and card_defense > 0 and card.has_meta("fraction_bonus") == true:
				card_attack -= 1
				card_defense -= 1
				card.get_node("Attack").text = str(card_attack)
				card.get_node("DEF").text = "DEF: " + str(card_defense)
				card.set_meta("faction_bonus", false)
				print(faction, " bonus removed from ", card.get_node("Name").text)





func activate_skill(card, hand):
	match card.get_node("Name").text:
		"RoyalGuard":
			activate_royal_guard_ability(card.card_id, hand)
		"Knight":
			activate_knight_ability(card.card_id, hand)
		"Queen":
			activate_queen_ability(card.card_id, hand)
		"Lancer":
			activate_lancer_ability(card.card_id, hand)
		"ShieldBearer":
			activate_shieldbearer_ability(card.card_id, hand)	
		"KingWarlord":
			activate_kingwarlord_ability(card.card_id, hand)
		"Healer":
			activate_healer_ability(card.card_id, hand)
		"Monk":
			activate_monk_ability(card.card_id, hand)
		"Paladin":
			activate_paladin_ability(card.card_id, hand)
		"Archer":
			activate_archer_ability(card.card_id, hand)
		"Crossbowman":
			activate_crossbowman_ability(card, hand)
		"Longbowman":
			activate_longbowman_ability(card.card_id, hand)

func deactivate_skill(card_id, hand):
	match $"../BattleManager".skill_vars[card_id]["card_name"]:
		"RoyalGuard":
			deactivate_royal_guard_ability(card_id, hand)
		"Knight":
			deactivate_knight_ability(card_id, hand)
		"Lancer":
			deactivate_lancer_ability(card_id, hand)
		"KingWarlord":
			deactivate_kingwarlord_ability(card_id, hand)
		"Monk":
			deactivate_monk_ability(card_id, hand)
		"Archer":
			deactivate_archer_ability(card_id, hand)
		"Longbowman":
			deactivate_longbowman_ability(card_id, hand)

func activate_longbowman_ability(card_id, hand):
	var rightmost_card = hand[0]
	for card in hand:
		if card.position.x > rightmost_card.position.x:
			rightmost_card = card
	if rightmost_card.card_id == card_id:
		for card in hand:
			if card.card_id == card_id:
				var card_attack = int(card.get_node("Attack").text)
				card_attack += 2  # Zwiększenie ataku o 2, gdy jest najbardziej po prawej
				card.get_node("Attack").text = str(card_attack)
				$"../BattleManager".skill_vars[card.card_id]["current_duration"] = 1  # Ustawienie czasu trwania na jedną turę
				print("Longbowman jest najbardziej po prawej: +2 do ataku")

func deactivate_longbowman_ability(card_id, hand):
	for card in hand:
		if card.card_id == card_id and card.get_node("Name").text == "Longbowman":
			var card_attack = int(card.get_node("Attack").text)
			card_attack -= 2  # Przywrócenie nominalnego ataku
			card.get_node("Attack").text = str(card_attack)
			print("Dezaktywowano umiejętność Longbowman, przywrócono nominalny atak")

func activate_crossbowman_ability(card, hand):
	var target = find_lowest_health_card($"../AI_Player/AI_PlayerShopDeck".AI_player_hand)
	if target != null:
		$"../BattleManager".attack_card(card,target)
		print("Crossbowman atakuje cel z najniższym HP")
 
func activate_archer_ability(card_id, hand):
	for card in hand:
		if card.card_id == card_id:
			var target = $"../BattleManager".find_leftmost_card_AI()
			if target != null:
				var target_def = int(target.get_node("DEF").text)
				if target_def < 6:
					var card_attack = int(card.get_node("Attack").text)
					card_attack += 3  # Zwiększenie ataku o 3 na jedną turę
					card.get_node("Attack").text = str(card_attack)
					$"../BattleManager".skill_vars[card_id]["current_duration"] = 1  # Ustawienie czasu trwania na jedną turę
					print("Archer atakuje cel z DEF < 6: +3 do ataku")

func deactivate_archer_ability(card_id, hand):
	for card in hand:
		if card.card_id == card_id:
			var card_attack = int(card.get_node("Attack").text)
			card_attack -= 3  # Przywrócenie nominalnego ataku
			card.get_node("Attack").text = str(card_attack)
			print("Dezaktywowano umiejętność Archera, przywrócono nominalny atak")

func activate_paladin_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		for card in hand:
			if card.card_id == card_id:
				var current_hp = int(card.get_node("HP").text)
				var max_hp = 21 
				var heal_amount = int(max_hp * 0.05)
				current_hp = min(current_hp + heal_amount, max_hp)
				card.get_node("HP").text = str(current_hp)
				print("Paladyn leczy się o 5%: current_hp =", current_hp)
		$"../BattleManager".skill_vars[card_id]["current_duration"] = $"../BattleManager".skill_vars[card_id]["skill_duration"]

func activate_monk_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		var target = $"../BattleManager".find_leftmost_card_AI()
		if target != null:
			var card_attack = int(target.get_node("Attack").text)
			card_attack -= 1  # Zmniejszenie ataku o 1
			target.get_node("Attack").text = str(card_attack)
			var debuffed_cards = [target.card_id]  # Używamy `target.card_id`
			$"../BattleManager".skill_vars[card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card_id]["skill_cooldown"]
			$"../BattleManager".skill_vars[card_id]["current_duration"] = $"../BattleManager".skill_vars[card_id]["skill_duration"]
			$"../BattleManager".skill_vars[card_id]["monk_debuffed_cards"] = debuffed_cards
			print("Aktywacja umiejętności Monk: current_cooldown =", $"../BattleManager".skill_vars[card_id]["current_cooldown"], "current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"])

func deactivate_monk_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_duration"] == 0 and not $"../BattleManager".skill_vars[card_id]["deactivated"]:
		var debuffed_cards = $"../BattleManager".skill_vars[card_id]["monk_debuffed_cards"]
		for target in hand:
			if target.is_alive and target.card_id in debuffed_cards:
				var card_attack = int(target.get_node("Attack").text)
				card_attack += 1  # Przywrócenie oryginalnego ataku
				target.get_node("Attack").text = str(card_attack)
		$"../BattleManager".skill_vars[card_id]["deactivated"] = true
		print("Dezaktywacja umiejętności dla Monk: current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"], "card_id =", card_id)

func activate_royal_guard_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		var buffed_cards = []
		for other_card in hand:
			if other_card.is_alive:
				var card_attack = int(other_card.get_node("Attack").text)
				card_attack += 1
				other_card.get_node("Attack").text = str(card_attack)
				buffed_cards.append(other_card.card_id)  # Dodanie ID buffowanej karty do listy
		$"../BattleManager".skill_vars[card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card_id]["skill_cooldown"]
		$"../BattleManager".skill_vars[card_id]["current_duration"] = $"../BattleManager".skill_vars[card_id]["skill_duration"]
		$"../BattleManager".skill_vars[card_id]["buffed_cards"] = buffed_cards  # Zapis listy buffowanych kart w skill_vars
		print("Aktywacja umiejętności: current_cooldown =", $"../BattleManager".skill_vars[card_id]["current_cooldown"], "current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"])

func deactivate_royal_guard_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_duration"] == 0 and not $"../BattleManager".skill_vars[card_id]["deactivated"]:
		if "buffed_cards" in $"../BattleManager".skill_vars[card_id]:
			var buffed_cards = $"../BattleManager".skill_vars[card_id]["buffed_cards"]
			for other_card in hand:
				if other_card.is_alive and other_card.card_id in buffed_cards:
					var card_attack = int(other_card.get_node("Attack").text)
					card_attack -= 1
					other_card.get_node("Attack").text = str(card_attack)
			$"../BattleManager".skill_vars[card_id]["deactivated"] = true
			print("Dezaktywacja umiejętności dla RoyalGuard: current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"], "card_id =", card_id)
		else:
			print("Brak właściwości 'buffed_cards' dla card_id =", card_id)

func activate_queen_ability(card_id, hand):
	var card = find_lowest_spd_card(hand)
	$"../BattleManager".attack_target(card)
	
func activate_knight_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		for card in hand:
			if card.card_id == card_id:
				var card_attack = int(card.get_node("Attack").text)
				card_attack = int(card_attack * 1.5)  # Zwiększenie ataku o 50%
				card.get_node("Attack").text = str(card_attack)
				$"../BattleManager".skill_vars[card.card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card.card_id]["skill_cooldown"]
				$"../BattleManager".skill_vars[card.card_id]["current_duration"] = $"../BattleManager".skill_vars[card.card_id]["skill_duration"]
				print("Aktywacja umiejętności Knight: current_cooldown =", $"../BattleManager".skill_vars[card.card_id]["current_cooldown"], "current_duration =", $"../BattleManager".skill_vars[card.card_id]["current_duration"])

func deactivate_knight_ability(card_id, hand):
	for card in hand:
		if card.card_id == card_id:
			var card_attack = int(card.get_node("Attack").text)
			card_attack = ceil(float(card_attack / 1.5))  # Przywrócenie oryginalnego ataku
			card.get_node("Attack").text = str(card_attack)
	print("Dezaktywacja umiejętności dla Knight: card_id =", card_id)

func activate_lancer_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		for card in hand:
			if card.card_id == card_id:
				var card_attack = int(card.get_node("Attack").text)
				card_attack = int(card_attack) + 3  # Zwiększenie ataku o 3
				card.get_node("Attack").text = str(card_attack)
				$"../BattleManager".skill_vars[card.card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card.card_id]["skill_cooldown"]
				$"../BattleManager".skill_vars[card.card_id]["current_duration"] = $"../BattleManager".skill_vars[card.card_id]["skill_duration"]
				print("Aktywacja umiejętności Lancer: current_cooldown =", $"../BattleManager".skill_vars[card.card_id]["current_cooldown"], "current_duration =", $"../BattleManager".skill_vars[card.card_id]["current_duration"])

func deactivate_lancer_ability(card_id, hand):
	for card in hand:
		if card.card_id == card_id:
			var card_attack = int(card.get_node("Attack").text)
			card_attack = int(card_attack) - 3  # Przywrócenie oryginalnego ataku
			card.get_node("Attack").text = str(card_attack)
	print("Dezaktywacja umiejętności dla Lancer: card_id =", card_id)

func activate_shieldbearer_ability(card_id, hand):
	for card in hand:	
		var card_defense = int(card.get_node("DEF").text)
		card_defense = int(card_defense) +1  
		card.get_node("DEF").text = "DEF: " + str(card_defense)
	print("Aktywacja umiejętności dla shieldberer: card_id =", card_id)

func activate_kingwarlord_ability(card_id, hand):
	var buffed_cards = []
	for other_card in hand:
		if other_card.is_alive:
			var card_defense = int(other_card.get_node("DEF").text)
			card_defense += 1
			other_card.get_node("DEF").text = "DEF: " + str(card_defense)
			buffed_cards.append(other_card.card_id)  # Dodanie ID buffowanej karty do listy
	$"../BattleManager".skill_vars[card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card_id]["skill_cooldown"]
	$"../BattleManager".skill_vars[card_id]["current_duration"] = $"../BattleManager".skill_vars[card_id]["skill_duration"]
	$"../BattleManager".skill_vars[card_id]["kingwarlord_buffed_cards"] = buffed_cards
	print("Aktywacja umiejętności: current_cooldown =", $"../BattleManager".skill_vars[card_id]["current_cooldown"], "current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"])

func deactivate_kingwarlord_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		if "buffed_cards" in $"../BattleManager".skill_vars[card_id]:
			var buffed_cards = $"../BattleManager".skill_vars[card_id]["kingwarlord_buffed_cards"]
			for other_card in hand:
				if other_card.is_alive and other_card.card_id in buffed_cards:
					var card_defense = int(other_card.get_node("Attack").text)
					card_defense -= 1
					other_card.get_node("DEF").text = "DEF: " + str(card_defense)
			$"../BattleManager".skill_vars[card_id]["deactivated"] = true
			print("Dezaktywacja umiejętności dla RoyalGuard: current_duration =", $"../BattleManager".skill_vars[card_id]["current_duration"], "card_id =", card_id)
		else:
			print("Brak właściwości 'buffed_cards' dla card_id =", card_id)

func activate_healer_ability(card_id, hand):
	if $"../BattleManager".skill_vars[card_id]["current_cooldown"] == 0 and $"../BattleManager".skill_vars[card_id]["current_duration"] == 0:
		var target = find_lowest_health_card(hand)
		if target != null:
			var targetHP = target.get_node("HP").text.to_int()
			var heal_amount = ceil(int(targetHP * 0.15))  # Leczenie o 15% HP
			targetHP += heal_amount
			target.get_node("HP").text = str(targetHP)
			$"../BattleManager".skill_vars[card_id]["current_cooldown"] = $"../BattleManager".skill_vars[card_id]["skill_cooldown"]
			$"../BattleManager".skill_vars[card_id]["current_duration"] = $"../BattleManager".skill_vars[card_id]["skill_duration"]
			$"../BattleManager".skill_vars[card_id]["healer_buffed_cards"] = [target.card_id]
			print("Healer leczy jednostkę o najniższym HP: current_cooldown =", $"../BattleManager".skill_vars[card_id]["current_cooldown"], "target HP po leczeniu =", targetHP)

func find_lowest_health_card(hand):
	var lowest_health_card = null
	var lowest_health = INF

	for card in hand:
		if card.is_alive:
			var hp = card.get_node("HP").text.to_int()
			if hp < lowest_health:
				lowest_health = hp
				lowest_health_card = card
	return lowest_health_card

func find_lowest_spd_card(hand):
	var lowest_spd_card = null
	var lowest_spd = INF

	for card in hand:
		if card.is_alive:
			var spd = card.get_node("SPD").text.to_int()
			if spd < lowest_spd:
				lowest_spd = spd
				lowest_spd_card = card

	return lowest_spd_card
