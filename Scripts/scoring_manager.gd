extends Node

var scoring_values = {
	"six_of_a_kind": 3000,
	"five_of_a_kind": 2000,
	"four_of_a_kind": 1000,
	"three_pairs": 1500,
	"six_dice_straight": 1500,
	"four_and_a_pair": 1500,
	"two_triples": 2500,
	"three_of_a_kind_1": 1000,
	"three_of_a_kind": 100, 
	"single_1": 100,
	"single_5": 50,
}


func calculate_score(dice:Array)-> Dictionary:
	var counts: Dictionary = {}
	for d in dice:
		counts[d] = counts.get(d,0) +1
	var total_score =0
	var used_dice: Array = []
	#
	total_score += _six_of_a_kind(counts, used_dice)
	total_score += _six_dice_straight(counts, used_dice)
	total_score += _five_of_a_kind(counts, used_dice)
	total_score += _four_and_a_pair(counts, used_dice)
	total_score += _four_of_a_kind(counts, used_dice)
	total_score += _two_triples(counts, used_dice)
	total_score += _three_pairs(counts, used_dice)
	total_score += _three_of_a_kind(counts, used_dice)
	total_score += _individual_ones_and_fives(counts, used_dice)

	return {
		"score": total_score,
		"used_dice": used_dice,
	}
	
	
# === RULES ===
func _three_pairs(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	var pairs: Array = []
	for num in counts.keys():
		if counts[num] == 2:
			pairs.append(num)
	if pairs.size() == 3:
		score = scoring_values["three_pairs"]
		for num in pairs:
			for i in range(2):
				used_dice.append(num)
			counts[num] -= 2
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _two_triples(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	var triples: Array = []
	for num in counts.keys():
		if counts[num] == 3:
			triples.append(num)
	if triples.size() == 2:
		score = scoring_values["two_triples"]
		for num in triples:
			for i in range(3):
				used_dice.append(num)
			counts[num] -= 3
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _six_dice_straight(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	var straight = true
	for num in range(1, 7):
		if not counts.has(num) or counts[num] < 1:
			straight = false
			break
	if straight:
		score = scoring_values["six_dice_straight"]
		for num in range(1,7):
			used_dice.append(num)
			counts[num] -= 1
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _three_of_a_kind(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	for num in counts.keys():
		if counts[num] >= 3:
			if num == 1:
				score += scoring_values["three_of_a_kind_1"]
			else:
				score += num * scoring_values["three_of_a_kind"]
			for i in range(3):
				used_dice.append(num)
			counts[num] -= 3
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _four_of_a_kind(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	for num in counts.keys():
		if counts[num] >= 4:
			score = scoring_values["four_of_a_kind"]
			for i in range(4):
				used_dice.append(num)
			counts[num] -= 4
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _five_of_a_kind(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	for num in counts.keys():
		if counts[num] >= 5:
			score = scoring_values["five_of_a_kind"]
			for i in range(5):
				used_dice.append(num)
			counts[num] -= 5
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _six_of_a_kind(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	for num in counts.keys():
		if counts[num] == 6:
			score = scoring_values["six_of_a_kind"]
			for i in range(6):
				used_dice.append(num)
			counts[num] -= 6
			if counts[num] == 0:
				counts.erase(num)
	return score
	
	
func _four_and_a_pair(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	var four_of_a_kind: Array = []
	var pair: Array = []
	for num in counts.keys():
		if counts[num] == 4:
			four_of_a_kind.append(num)
		elif counts[num] == 2:
			pair.append(num)
	if four_of_a_kind.size() > 0 and pair.size() > 0:
		score = scoring_values["four_and_a_pair"]
		for i in range(4):
			used_dice.append(four_of_a_kind[0])
		counts[four_of_a_kind[0]] -= 4
		if counts[four_of_a_kind[0]] == 0:
			counts.erase(four_of_a_kind[0])

		for i in range(2):
			used_dice.append(pair[0])
		counts[pair[0]] -= 2
		if counts[pair[0]] == 0:
			counts.erase(pair[0])
	return score
	
	
func _individual_ones_and_fives(counts: Dictionary, used_dice: Array) -> int:
	var score = 0
	for num in [1, 5]:
		if counts.has(num):
			if num == 1:
				score += counts[num] * scoring_values["single_1"]
			else:
				score += counts[num] * scoring_values["single_5"]
			for i in range(counts[num]):
				used_dice.append(num)
			counts.erase(num)
	return score
