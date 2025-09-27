extends Node
class_name GameModel

signal state_changed(new_state: int)
signal dice_changed(dice: Array)
signal scored(roll_score: int, round_score: int)
signal farkled(farkle_count: int)
signal round_ended(round_num: int, total_score: int)
signal game_over(message: String, stats: Dictionary)


enum State{ IDLE, ROLLING, REVEALING, CHOOSING, FORCED_ROLL, FARKLED, ROUND_END, GAME_END }

@onready var scoring_manager: Node = $ScoringManager

var state: int = State.IDLE
var dice: Array = []
var current_round_score := 0
var total_score := 0
var round_count := 1
var farkle_count := 0
var has_opened := false
var _post_roll_state := State.CHOOSING
var highest_roll :=0

func _ready():
	dice.resize(6)
	for i in dice.size():
		dice[i] = {"value": 0, "is_held": false}
	_emit_all()
	
func _emit_all():
	emit_signal("state_changed", state)
	emit_signal("dice_changed", dice)
	emit_signal("scored", 0, current_round_score)

func _set_state(s: int):
	state = s
	emit_signal("state_changed", state)
	
func _reset_round():
	current_round_score = 0
	for d in dice:
		d.value = 0
		d.is_held = false
	emit_signal("dice_changed", dice)
	
func _game_end(message: String):
	_set_state(State.GAME_END)
	var stats := {
		"message": message,
		"total_score": total_score,
		"highest_roll": highest_roll,
		"farkle_count": farkle_count,
		"round_count": round_count,
		"win": message.find("won") != -1
	}
	emit_signal("game_over", message, stats)

func _process_roll():
	var current_roll: Array = []
	for d in dice:
		if not d.is_held:
			current_roll.append(d.value)
	
	var result = scoring_manager.calculate_score(current_roll)
	var roll_score: int = result["score"]
	var used: Array = result["used_dice"]
	
#	Farkle check
	if roll_score == 0:
		farkle_count += 1
		current_round_score = 0
		emit_signal("scored", 0,0)
		_post_roll_state = State.FARKLED
		_set_state(State.REVEALING)
		return
	
	current_round_score += roll_score
	_mark_used_as_held(used)
	emit_signal("scored", roll_score, current_round_score)
	record_highest_roll(current_round_score)

	_post_roll_state = State.FORCED_ROLL if _all_held() else State.CHOOSING
	_set_state(State.REVEALING) 
	
func _mark_used_as_held(used: Array):
	var temp = used.duplicate()
	for d in dice:
		if not d.is_held and temp.has(d.value):
			d.is_held = true
			temp.erase(d.value)
	emit_signal("dice_changed", dice)

func _all_held() -> bool:
	for d in dice:
		if not d.is_held: return false
	return true

func _roll_unheld():
	for d in dice:
		if not d.is_held:
			d.value = randi_range(1,6)
	emit_signal("dice_changed", dice)

func finish_reveal():
	if state == State.REVEALING:
		var next := _post_roll_state
		_set_state(next)
		
		if next == State.FARKLED:
			emit_signal("farkled", farkle_count)
			if farkle_count >= 10:
				_game_end("Get Farked!! You lost")
		
func intent_new_round():
	if state == State.GAME_END: return
	_reset_round()
	emit_signal("scored",0,0)
	_set_state(State.CHOOSING)

func intent_roll():
	if not (state in [State.CHOOSING, State.FORCED_ROLL, State.IDLE]): return
	if state == State.FORCED_ROLL:
		for d in dice: d.is_held =false
		emit_signal("dice_changed", dice)
	_set_state(State.ROLLING)
	_roll_unheld()
	_process_roll()

func intent_bank():
	if not (state in [State.CHOOSING]): return
	if current_round_score == 0:
		return
	if not has_opened and current_round_score < 500:
		return
	if not has_opened: has_opened = true
	total_score += current_round_score
	round_count += 1
	emit_signal("round_ended", round_count -1, total_score)
	if(WinManager.check_win(total_score)):
		_game_end("Congrats!! You WON!")
	else:
		_set_state(State.IDLE)
		
func intent_toggle_hold(index: int):
	if not (index >= 0 and index < dice.size()): return
	if state != State.CHOOSING: return
	dice[index].is_held = !dice[index].is_held
	emit_signal("dice_changed", dice)
	

#Store highest score to recall later
func record_highest_roll(score: int):
	if score > highest_roll:
		highest_roll = score

	
