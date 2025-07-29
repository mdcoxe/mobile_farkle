extends Node

var winning_score = 10000

func check_win(total_score: int) -> bool:
	return total_score >= winning_score
