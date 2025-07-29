extends Node

@onready var roll_button: Button = $"../../VBoxContainer/RollButton"
@onready var end_roll_button: Button = $"../../VBoxContainer/EndRollButton"
@onready var dice_label: Label = $"../../VBoxContainer/DiceLabel"
@onready var score_label: Label = $"../../VBoxContainer/ScoreLabel"
@onready var round_label: Label = $"../../VBoxContainer/RoundLabel"
@onready var status_label: Label = $"../../VBoxContainer/StatusLabel"
@onready var scoring_manager: Node = $"../ScoringManager" 

var current_round_score = 0
var total_score = 0
var round = 1
var farkled = false
var has_opened = false

# Represents all 6 dice. Each element will be a dictionary:
# { "value": int, "is_held": bool }
var all_dice: Array = [] 

func _ready():
	for i in range(6):
		all_dice.append({"value": 0, "is_held": false}) 
	status_label.text = "Press Roll to start your turn!"

	_reset_round() 
	_update_display() 

func _reset_round():
	current_round_score = 0
	farkled = false
	for die_data in all_dice:
		die_data.value = 0
		die_data.is_held = false
	
	round_label.text = "Round: " + str(round)
	score_label.text = "Round Score: 0 | Total Score: %s" % total_score
	roll_button.disabled = false
	end_roll_button.disabled = false

func _update_display():
	var dice_display_text = "Your dice: ["
	var first = true
	for die_data in all_dice:
		if not first:
			dice_display_text += ", "
		dice_display_text += str(die_data.value)
		if die_data.is_held:
			dice_display_text += "(H)" 
		first = false
	dice_display_text += "]"
	dice_label.text = dice_display_text
	score_label.text = "Round Score: %s | Total Score: %s" % [current_round_score, total_score]

func _on_roll_button_pressed():
	status_label.text = "Rolling!!"
	farkled = false
	
	# Check for "Hot Dice" scenario *before* rolling, based on currently held dice
	# If all dice are currently held, it's a Hot Dice situation
	var current_held_dice_count = 0
	for die_data in all_dice:
		if die_data.is_held:
			current_held_dice_count += 1

	var is_hot_dice_situation = (current_held_dice_count == 6)

	if is_hot_dice_situation:
		status_label.text = "Hot Dice! Rolling all 6 again!"
		# Clear held status for all dice for the new roll
		for die_data in all_dice:
			die_data.is_held = false
		# Crucially, disable the end_roll_button temporarily
		# Player *must* roll again.
		end_roll_button.disabled = true
	else:
		end_roll_button.disabled = false
		
	# Roll only the unheld dice and update their values
	var current_roll_values_for_scoring: Array = []
	for die_data in all_dice:
		if not die_data.is_held:
			die_data.value = randi_range(1, 6)
		current_roll_values_for_scoring.append(die_data.value) 

	_update_display() 

	var result = scoring_manager.calculate_score(current_roll_values_for_scoring)
	var roll_score = result["score"]
	var used_dice_from_current_roll = result["used_dice"]

	if roll_score == 0:
		farkled = true
		status_label.text = "Farkle! No score this round."
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
	status_label.text = "Scored " + str(roll_score) + " points! Current round: " + str(current_round_score)
	
	# After scoring, re-check if *all* dice are now held.
	# This check needs to happen *after* marking dice as held.
	var all_dice_are_held_after_scoring = true
	for die_data in all_dice:
		if not die_data.is_held:
			all_dice_are_held_after_scoring = false
			break

	if all_dice_are_held_after_scoring:
		status_label.text += "\nHot Dice! You must roll all 6 again!" 
		end_roll_button.disabled = true 
		roll_button.disabled = false 
	else:
		# Not a hot dice, player can choose to roll or end.
		end_roll_button.disabled = false 
		roll_button.disabled = false 



func _on_end_button_pressed():
	if farkled:
		status_label.text = "Farkled! Your round score was lost."
		current_round_score = 0
		total_score += current_round_score
	else:
		if not has_opened and current_round_score < 500:
			status_label.text = "You need at least 500 points to get on the board!"
			
			_update_display()
			return
		else:
			if not has_opened:
				has_opened = true
				status_label.text = "You're on the board! " + str(current_round_score) + " points added to total!"
			else:
				status_label.text = "Taking points! " + str(current_round_score) + " points added to total."
			total_score += current_round_score
	
	if WinManager.check_win(total_score):
		status_label.text = "Congrats! You won!!"
		score_label.text = "Final Score: %s" % total_score
		roll_button.disabled = true
		end_roll_button.disabled = true
		return
	
	round += 1 
	_reset_round() 
	_update_display() 
