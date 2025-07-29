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

	var dice_to_score_this_roll: Array = [] 

	var all_dice_are_held = true
	for die_data in all_dice:
		if not die_data.is_held:
			all_dice_are_held = false
			break

	if all_dice_are_held:
		status_label.text = "Hot Dice! Rolling all 6 again!"
		for die_data in all_dice:
			die_data.is_held = false

	for die_data in all_dice:
		if not die_data.is_held:
			die_data.value = randi_range(1, 6)
		dice_to_score_this_roll.append(die_data.value) 

	_update_display() 


	var unheld_dice_values: Array = []
	for die_data in all_dice:
		if not die_data.is_held:
			unheld_dice_values.append(die_data.value)

	var result = scoring_manager.calculate_score(unheld_dice_values)
	var roll_score = result["score"]
	var used_dice_from_unheld = result["used_dice"] 

	if roll_score == 0:
		farkled = true
		status_label.text = "Farkle! No score this round."
		current_round_score = 0 
		_on_end_button_pressed()
		return

	current_round_score += roll_score
	
	var temp_used_dice = used_dice_from_unheld.duplicate()
	for die_data in all_dice:
		if not die_data.is_held: 
			if temp_used_dice.has(die_data.value):
				die_data.is_held = true
				var index_to_remove = temp_used_dice.find(die_data.value)
				if index_to_remove != -1:
					temp_used_dice.remove_at(index_to_remove)

	_update_display() 
	status_label.text = "Scored " + str(roll_score) + " points!"

func _on_end_button_pressed():
	total_score += current_round_score
	round += 1 

	
	if WinManager.check_win(total_score):
		status_label.text = "Congrats! You won!!"
		score_label.text = "Final Score: %s" % total_score
		roll_button.disabled = true
		end_roll_button.disabled = true
		return

	if farkled:
		status_label.text = "Farkled! Your round score was lost."
	else:
		status_label.text = "Taking points! Start next round."
	
	_reset_round() 
	_update_display() 
