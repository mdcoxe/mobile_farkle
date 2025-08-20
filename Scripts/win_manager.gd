extends Node

var winning_score = 10000
var did_win = false


func check_win(total_score: int) -> bool:
	if total_score >= winning_score:
		did_win = true
	return did_win
