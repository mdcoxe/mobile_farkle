extends Node

@onready var game: GameModel = $".."

@onready var status_label: Label = $"../../StatusLabel"
@onready var total_score_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/TotalScoreLabel"
@onready var round_score_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/RoundScoreLabel"
@onready var round_label: Label = $"../../VBoxContainer/Bottom/HBoxContainer/MarginContainer/StatsBox/RoundNumLabel"

@onready var roll_button: TextureButton = $"../../VBoxContainer/Bottom/HBoxContainer/ButtonBox/MarginContainer/RollButton"
@onready var bank_button: TextureButton = $"../../VBoxContainer/Bottom/HBoxContainer/ButtonBox/MarginContainer2/CollectButton"
@onready var farkle_container: HBoxContainer = $"../../VBoxContainer/FarkedBar/MarginContainer/FarkedBarHBox"
@onready var dice_container: GridContainer = $"../../VBoxContainer/DiceMat/MarginContainer/GridContainer"
@onready var scoring_manager: Node = $"../ScoringManager"

const DICE_ROLL := preload("res://Scene/animated_dice.tscn")
const DICE_TEXTURES: Array[PackedScene] = [
	preload("res://Assets/Dice/dice1.tscn"),
	preload("res://Assets/Dice/dice2.tscn"),
	preload("res://Assets/Dice/dice3.tscn"),
	preload("res://Assets/Dice/dice4.tscn"),
	preload("res://Assets/Dice/dice5.tscn"),
	preload("res://Assets/Dice/dice6.tscn"),
]
const F_ICON := preload("res://Assets/buttons/farkleicon.tscn")
const GAME_OVER_STATS = preload("res://Scene/GameOverStats.tscn")

var _rolling_anim_active: bool = false
var _roll_anim_started:bool = false
var _targets_by_index: Array = []

var _pending_roll_score: int = -1
var _pending_round_score: int = -1

func _ready():
	game.state_changed.connect(_on_state_changed)
	game.dice_changed.connect(_on_dice_changed)
	game.scored.connect(_on_scored)
	game.farkled.connect(_on_farkled)
	game.round_ended.connect(_on_round_ended)
	game.game_over.connect(_on_game_over)
	
	status_label.text = "\nPress Roll to start your turn!"
	_update_buttons_for_state(game.state)
	_update_totals()
	game.intent_new_round()

func _update_ui(comment: String, roll_b: bool, bank_b: bool):
	status_label.text = comment
	roll_button.disabled = roll_b
	bank_button.disabled = bank_b

func _on_state_changed(s: int) -> void:
	if s == GameModel.State.ROLLING:
		_rolling_anim_active = true
		_roll_anim_started = false
	_update_buttons_for_state(s)
	match s:
		GameModel.State.ROLLING:
			_update_ui("Rolling!!", true, true)
		GameModel.State.REVEALING:
			_update_ui("Rolling!!", true, true)
		GameModel.State.CHOOSING:
			if not _rolling_anim_active:
				_update_ui("Choose: Roll again or Bank", false, false)
		GameModel.State.FARKLED:
			if not _rolling_anim_active:
				_update_ui("Farkle!! Round over!", false, true)
		GameModel.State.FORCED_ROLL:
			if not _rolling_anim_active:
				_update_ui("Hot Dice!! You must roll all 6 again.", false, true)
		GameModel.State.IDLE:
			if not _rolling_anim_active:
				_update_ui("Press Roll to start your turn.",false, true)
		GameModel.State.GAME_END:
			_update_ui("", true, true)
#		Hold for special round endings - future use
		#GameModel.State.ROUND_END:
			#_update_ui("")
			
func _update_buttons_for_state(s: int) -> void:
	if _rolling_anim_active or s in [GameModel.State.ROLLING, GameModel.State.REVEALING]:
		roll_button.disabled = true
		bank_button.disabled = true
		return
	
	match s:
		GameModel.State.IDLE:
			roll_button.disabled = false
			bank_button.disabled = true
			#roll_button.tooltip_text = "Roll"
		#GameModel.State.ROLLING:
			#roll_button.disabled = true
			#bank_button.disabled = true
			#roll_button.tooltip_text = "Rolling…"
		GameModel.State.CHOOSING:
			roll_button.disabled = false
			bank_button.disabled = false
			#roll_button.tooltip_text = "Roll again"
		GameModel.State.FORCED_ROLL:
			roll_button.disabled = false
			bank_button.disabled = true
			#roll_button.tooltip_text = "Hot Dice: must roll"
		#Not currently used
		#GameModel.State.ROUND_END:
			#roll_button.disabled = false
			#bank_button.disabled = true
			#roll_button.tooltip_text = "Next round"
		GameModel.State.FARKLED:
			roll_button.disabled = false
			bank_button.disabled = true
			#roll_button.tooltip_text = "Next round"
		GameModel.State.GAME_END:
			roll_button.disabled = true
			bank_button.disabled = true
			#roll_button.tooltip_text = "Game over"
			
func _on_dice_changed(dice: Array) -> void:
	if not _rolling_anim_active:
		_draw_static_dice(dice)
		return
	if _roll_anim_started:
		return
	_roll_anim_started = true
	_targets_by_index = dice.duplicate(true)
	_start_staggered_roll_animation(_targets_by_index)
	
func _draw_static_dice(dice: Array) -> void:
	for c in dice_container.get_children():
		c.queue_free()	
			
	for d in dice:
		if d.value <= 0:
			var empty = Control.new()
			empty.custom_minimum_size = Vector2(64,64)
			dice_container.add_child(empty)
			continue
		var scene: PackedScene = DICE_TEXTURES[d.value - 1]
		var inst := scene.instantiate()
		if inst is CanvasItem:
			var canvas_item := inst as CanvasItem
			var held := bool(d.get("is_held", false))
			canvas_item.modulate = Color(0.6,0.6,0.6) if held else Color(1,1,1)
		dice_container.add_child(inst)
		
func _start_staggered_roll_animation(dice_after_roll: Array) -> void:
	for c in dice_container.get_children():
		c.queue_free()
	
	for i in dice_after_roll.size():
		var die = dice_after_roll[i]
		if bool(die.get("is_held", false)):
			var inst := _make_face_node(int(die.value))
			if inst is CanvasItem:
				(inst as CanvasItem).modulate = Color(0.6,0.6,0.6)
			dice_container.add_child(inst)
			continue
		
		var roller = DICE_ROLL.instantiate()
		roller.add_to_group("rolling_die")
		dice_container.add_child(roller)
		var animate: AnimationPlayer = roller.get_node_or_null("AnimateDice")
		if animate:
			animate.play("Roll", -1, 1.0, true)
		
		var delay := randf_range(0.5, 3.0)
		_reveal_die_later(i, die.value, delay)

func _apply_held_marker() -> void:
	var count: int = min(dice_container.get_child_count(), game.dice.size())
	for i in range(count):
		var child_node: Node = dice_container.get_child(i)
		if child_node.is_in_group("rolling_die"):
			continue
		var held: bool = bool(game.dice[i].get("is_held", false))
		if child_node is CanvasItem:
			var canvas_item := child_node as CanvasItem
			canvas_item.modulate = Color(0.6,0.6,0.6) if held else Color(1,1,1)

func _replace_child_at(index: int, with_node: Node) -> void:
	var old := dice_container.get_child(index)
	dice_container.remove_child(old)
	old.queue_free()
	dice_container.add_child(with_node)
	dice_container.move_child(with_node, index)

func _make_face_node(value: int) -> Node:
	var face: PackedScene = DICE_TEXTURES[value - 1]
	return face.instantiate()

func _reveal_die_later(index: int, value: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not _rolling_anim_active:
		return
	var face_node = _make_face_node(value)
	_replace_child_at(index, face_node)
	
	if _all_unheld_revealed():
		_on_roll_visuals_complete()
		
	
func _all_unheld_revealed() -> bool:
	for child in dice_container.get_children():
		if child.is_in_group("rolling_die"):
			return false
	return true
	
func _on_roll_visuals_complete() -> void:
	_rolling_anim_active = false
	_roll_anim_started = false
	_apply_pending_scores()
	_apply_held_marker()
	game.finish_reveal()
	_update_buttons_for_state(game.state)

func _apply_pending_scores()-> void:
	if _pending_round_score != -1:
		if _pending_roll_score > 0:
			status_label.text = "Scored %s points!" % _pending_roll_score
		round_score_label.text = str(_pending_round_score)
		_pending_roll_score = -1
		_pending_round_score = -1

func _on_scored(roll_score: int, round_score: int) -> void:
	_pending_roll_score = roll_score
	_pending_round_score = round_score
	if not _rolling_anim_active and not (game.state in [GameModel.State.ROLLING, GameModel.State.REVEALING]):
		_apply_pending_scores()
		
	
func _on_farkled(count: int) -> void:
	var icon := F_ICON.instantiate()
	status_label.text = "Farkled"
	farkle_container.add_child(icon)

func _on_round_ended(round_num: int, total: int) -> void:
	round_label.text = str(round_num)
	total_score_label.text = str(total)
	round_score_label.text = "0"
	
	_pending_roll_score = -1
	_pending_round_score = -1
	
	game.intent_new_round()

func _on_game_over(message: String, stats: Dictionary) -> void:
	status_label.text = message
	var game_over_scene = GAME_OVER_STATS.instantiate()
	add_child(game_over_scene)
	game_over_scene.show_stats(stats)

func _on_menu_press():
	print("Menu opened")
	
func _update_totals():
	total_score_label.text = str(game.total_score)
	round_label.text = str(game.round_count)

func _on_roll_button_pressed():
	if game.state in [GameModel.State.FARKLED, GameModel.State.ROUND_END]:
		game.intent_new_round()
	else:
		game.intent_roll()

func _on_end_button_pressed():
	game.intent_bank()
	
