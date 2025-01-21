extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var card_dragged_initial_position
var card_dragged
var is_dragging = false
var is_hovering_on_card
var shop_deck_reference
var player_hand = []

# Card slot counter to place cards
var counter = 0

# Signals from card (connection parent <- children)
func connect_card_signals(card):
	card.connect("hovered", hovered_on)
	card.connect("hovered_off", _hovered_off)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shop_deck_reference = $"../ShopDeck"

# Mouse handler
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card = raycast_for_card()
			if card and counter < 5 and card not in player_hand:
				if ! await shop_deck_reference.update_coins(card):
					pick_card(card)
			elif card in player_hand:
				start_drag(card)
		else:
			if card_dragged:
				finish_drag()
	elif event is InputEventMouseMotion and is_dragging:
		if card_dragged:
			card_dragged.position += event.relative
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false

# Click on card in shop - Buy unit
func pick_card(card):
	if card in shop_deck_reference.shop_deck:
		var node = $"../PlayerDeck"
		var pos = null
		var card_slot = null
		
		# Znajdź pierwszy wolny slot
		for i in range(node.get_child_count()):
			var temp_slot = node.get_child(i)
			if not temp_slot.card_in_slot:
				pos = temp_slot.position
				card_slot = temp_slot
				break
		
		if card_slot != null:
			card.get_node("Area2D/CollisionShape2D").disabled = true
			shop_deck_reference.animate_card_to_pos(card, pos)
			card.card_in_player_field = true
			card_slot.card_in_slot = true
			card.what_card_slot = card_slot
			player_hand.append(card)
			shop_deck_reference.shop_deck.erase(card)


# Card dragging
func start_drag(card):
	card.scale = Vector2(1, 1)
	is_dragging = true
	card_dragged = card
	card_dragged_initial_position = card.position
	card.get_node("Area2D/CollisionShape2D").disabled = true

func finish_drag():
	card_dragged.get_node("Area2D/CollisionShape2D").disabled = false
	is_dragging = false
	card_dragged.scale = Vector2(1.1, 1.1)
	var card_slot_found = raycast_for_card_slot()
	var card_found = raycast_for_card()
	if card_slot_found:
		if card_found and card_found != card_dragged:
			card_found.position = card_dragged_initial_position
			card_found.what_card_slot.card_in_slot = true 
			card_dragged.what_card_slot.card_in_slot = true
			card_dragged.position = card_slot_found.position
		else:
			card_dragged.what_card_slot.card_in_slot = false 
			card_dragged.position = card_slot_found.position
			card_slot_found.card_in_slot = true
	else:
		add_card_to_hand(card_dragged, card_dragged_initial_position)
	card_dragged = null

func add_card_to_hand(card, pos):
	shop_deck_reference.animate_card_to_pos(card, card_dragged_initial_position)

# Card hover effect
func highlight_card(card, hovered):
	if hovered and not card_dragged:
		card.scale = Vector2(1.5, 1.5)
		card.z_index = 2
	else:
		card.scale = Vector2(1.1, 1.1)
		card.z_index = 1

func hovered_on(card):
	highlight_card(card, true)

func _hovered_off(card):
	if !card_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_dragged:
		var mouse_pos = get_global_mouse_position()
		card_dragged.position = mouse_pos

# Raycast from Godot documentation
func raycast_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func raycast_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		if result[0].collider.get_parent().get_parent() != $"../AI_Player/AI_PlayerHand":
			return result[0].collider.get_parent()
	return null
