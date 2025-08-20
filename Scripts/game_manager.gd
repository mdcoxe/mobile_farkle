extends Node

@onready var status_label: Label = $"../../StatusLabel"
@onready var total_score_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/TotalScoreLabel"
@onready var round_score_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/RoundScoreLabel"
@onready var round_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/RoundNumLabel"

@onready var roll_button: TextureButton = $"../../VBoxContainer/Bottom/HBoxContainer/ButtonBox/MarginContainer/RollButton"
@onready var end_roll_button: TextureButton = $"../../VBoxContainer/Bottom/HBoxContainer/ButtonBox/MarginContainer2/CollectButton"
@onready var farkle_container: HBoxContainer = $"../../VBoxContainer/FarkedBar/MarginContainer/FarkedBarHBox"
@onready var dice_container: GridContainer = $"../../VBoxContainer/DiceMat/MarginContainer/GridContainer"
@onready var scoring_manager: Node = $"../ScoringManager"

const F_ICON := preload("res://Assets/buttons/farkleicon.tscn")
const DICE_TEXTURES: Array[PackedScene] = [
	preload("res://Assets/Dice/dice1.tscn"),
	preload("res://Assets/Dice/dice2.tscn"),
	preload("res://Assets/Dice/dice3.tscn"),
	preload("res://Assets/Dice/dice4.tscn"),
	preload("res://Assets/Dice/dice5.tscn"),
	preload("res://Assets/Dice/dice6.tscn"),
]

var current_round_score := 0
var total_score := 0
var round_count := 1
var farkle_count := 0

var farkled := false
var has_opened := false
var game_over := false;

# Represents all 6 dice. Each element will be a dictionary:
# { "value": int, "is_held": bool }
var all_dice: Array = [] 


func _ready():
	for i in range(6):
		all_dice.append({"value": 0, "is_held": false}) 
	status_label.text = "\nPress Roll to start your turn!"

	_reset_round() 
	_update_display() 

func _reset_round():
	current_round_score = 0
	farkled = false
	for die_data in all_dice:
		die_data.value = 0
		die_data.is_held = false
	
	round_label.text = str(round_count)
	round_score_label.text = "0"
	total_score_label.text = "%s" % total_score
	roll_button.disabled = false
	end_roll_button.disabled = true

func _update_display():
	for child in dice_container.get_children():
		child.queue_free()
		
	for die_data in all_dice:
		var die_value = die_data["value"]
		if die_value > 0:
			var dice_scene = DICE_TEXTURES[die_value - 1]
			var new_dice_instance = dice_scene.instantiate()
			dice_container.add_child(new_dice_instance)

			if die_data["is_held"] and new_dice_instance is TextureRect:
				new_dice_instance.modulate = Color(0.6, 0.6, 0.6)
		
	round_score_label.text = "%s" % current_round_score
	total_score_label.text = "%s" % total_score


func _on_roll_button_pressed():
	if game_over:
		return
	status_label.text = "\nRolling!!"
	farkled = false

	# Check for "Hot Dice" scenario before rolling, based on currently held dice
	# If all dice are currently held, it's a Hot Dice situation
	var current_held_dice_count = 0
	for die_data in all_dice:
		if die_data.is_held:
			current_held_dice_count += 1

	var is_hot_dice_situation = (current_held_dice_count == 6)

	if is_hot_dice_situation:
		status_label.text = " Hot Dice! \nRolling all 6 again!"
		# Clear held status for all dice for the new roll
		for die_data in all_dice:
			die_data.is_held = false
		# Crucially, disable the end_roll_button temporarily
		# Player must roll again.
		end_roll_button.disabled = true
	else:
		end_roll_button.disabled = false
	
	var dice_values_for_this_roll: Array = [] 
	# Roll only the unheld dice and update their values
	#var current_roll_values_for_scoring: Array = []
	for die_data in all_dice:
		if not die_data.is_held:
			die_data.value = randi_range(1, 6)
		#current_roll_values_for_scoring.append(die_data.value) 
	for die_data in all_dice:
		if not die_data.is_held:
			dice_values_for_this_roll.append(die_data.value)
	_update_display() 
	
	var result = scoring_manager.calculate_score(dice_values_for_this_roll)
	#var result = scoring_manager.calculate_score(current_roll_values_for_scoring)
	var roll_score = result["score"]
	var used_dice_from_current_roll = result["used_dice"]

	if roll_score == 0:
		farkled = true
		_add_farkle_icon()
		farkle_count += 1
		if farkle_count >= 10:
			_end_game("Get Farked! You LOST!!")
			return
		status_label.text = "Farkle! \nNo score this round."
		current_round_score = 0
		# If farkled, player cannot roll again. End their turn.
		roll_button.disabled = true
		end_roll_button.disabled = false 
		_on_end_button_pressed()
		return
		
	current_round_score += roll_score
	
	# Mark the scored dice as held
	var temp_used_dice = used_dice_from_current_roll.duplicate()
	for die_data in all_dice:
		if not die_data.is_held: 
			if temp_used_dice.has(die_data.value):
				die_data.is_held = true
				var index_to_remove = temp_used_dice.find(die_data.value)
				if index_to_remove != -1:
					temp_used_dice.remove_at(index_to_remove)
					
	_update_display()
	round_score_label.text = str(current_round_score)
	status_label.text = "Scored " + str(roll_score) + " points!"
	
	# After scoring, re-check if all dice are now held.
	# This check needs to happen afgter marking dice as held.
	var all_dice_are_held_after_scoring = true
	for die_data in all_dice:
		if not die_data.is_held:
			all_dice_are_held_after_scoring = false
			break
			
	if all_dice_are_held_after_scoring:
		status_label.text += " Hot Dice! \nYou must roll all 6 again!" 
		end_roll_button.disabled = true 
		roll_button.disabled = false 
	else:
		# Not a hot dice, player can choose to roll or end.
		end_roll_button.disabled = false 
		roll_button.disabled = false 
		
		
func _on_end_button_pressed():
	if game_over:
		return
		
	if end_roll_button.disabled:
		return
		
	end_roll_button.disabled = true
	roll_button.disabled = true
	
	if farkled:
		status_label.text = "Farkled! \nYour round score was lost."
		current_round_score = 0
		total_score += current_round_score
	else:
		if not has_opened and current_round_score < 500:
			status_label.text = "You need at least 500 points to get on the board!"
			roll_button.disabled = false
			return
		else:
			if not has_opened:
				has_opened = true
				status_label.text = "You're on the board! " + str(current_round_score) + " points added to total!"
			else:
				status_label.text = "Taking points! " + str(current_round_score) + " points added to total."
			total_score += current_round_score
	
	if WinManager.check_win(total_score):
		_end_game("Congrats! You won!!")
		return
	
	round_count += 1 
	_reset_round() 
	_update_display() 
	
	
func _end_game(message: String):
	game_over = true
	status_label.text = message
	total_score_label.text = "%s" % total_score
	roll_button.disabled = true
	end_roll_button.disabled = true
	
	
func _add_farkle_icon():
		var inst := F_ICON.instantiate()
		farkle_container.add_child(inst)
