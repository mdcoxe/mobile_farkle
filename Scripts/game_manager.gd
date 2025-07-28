extends Node

@onready var roll_button: Button = $"../VBoxContainer/RollButton"
@onready var end_roll_button: Button = $"../VBoxContainer/EndRollButton"
@onready var dice_label: Label = $"../VBoxContainer/DiceLabel"
@onready var score_label: Label = $"../VBoxContainer/ScoreLabel"
@onready var round_label: Label = $"../VBoxContainer/RoundLabel"

var current_round_score = 0
var total_score = 0
var round = 1

func _ready():
	pass

func _on_roll_button_pressed():
	var dice = []
	for i in range(6):
		dice.append(randi_range(1,6))
	dice_label.text = "You rolled: " + str(dice)
	
#	Temp scoring
	var roll_score = 0
	for d in dice:
		if d ==1:
			roll_score += 100
		elif d ==5:
			roll_score += 50
	current_round_score += roll_score
	
	score_label.text = "Round Score: %s | Total Score: %s" % [current_round_score, total_score]

func _on_end_button_pressed():
	total_score += current_round_score
	round += 1
	current_round_score = 0
	dice_label.text = "Round ended!"
	round_label.text = "Round: "+ str(round)
	score_label.text = "Round Score: 0 | Total Score: %s" % total_score
