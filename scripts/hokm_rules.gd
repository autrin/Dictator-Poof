extends RefCounted
## One partnership hand. Seats run anticlockwise; 0 and 2 are partners. Aces high.
var hands: Array[Array] = [[], [], [], []]
var trick: Array[Dictionary] = []
var scores := [0, 0]
var trump := -1
var leader := 0
var turn := 0
var deck: Array[int] = []

func deal(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	hands = [[], [], [], []]
	trick.clear()
	scores = [0, 0]
	trump = -1
	leader = 0
	turn = 0
	deck.clear()
	for card in range(52):
		deck.append(card)
	for i in range(51, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: int = deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	# The hakem selects trump from five cards before the remaining deal.
	for i in range(5):
		hands[0].append(deck.pop_back())
	hands[0].sort()

func choose_trump(suit: int) -> void:
	if trump >= 0 or suit < 0 or suit > 3:
		return
	trump = suit
	for seat in range(4):
		while hands[seat].size() < 13:
			hands[seat].append(deck.pop_back())
		hands[seat].sort()

func legal_cards(seat: int) -> Array:
	if trick.is_empty():
		return hands[seat].duplicate()
	var suit := int(trick[0].card) / 13
	var matching: Array = []
	for card: int in hands[seat]:
		if card / 13 == suit:
			matching.append(card)
	return matching if not matching.is_empty() else hands[seat].duplicate()

func play(seat: int, card: int) -> bool:
	if trump < 0 or finished() or trick.size() == 4 or seat != turn or not legal_cards(seat).has(card):
		return false
	hands[seat].erase(card)
	trick.append({"seat": seat, "card": card})
	turn = (turn + 1) % 4
	return true

func winner() -> int:
	var best: Dictionary = trick[0]
	for played in trick:
		var suit := int(played.card) / 13
		var best_suit := int(best.card) / 13
		if (suit == trump and best_suit != trump) or (suit == best_suit and int(played.card) % 13 > int(best.card) % 13):
			best = played
	return best.seat

func collect_trick() -> void:
	if trick.size() != 4:
		return
	leader = winner()
	scores[leader % 2] += 1
	turn = leader
	trick.clear()

func finished() -> bool:
	return scores[0] >= 7 or scores[1] >= 7

func computer_card() -> int:
	var legal := legal_cards(turn)
	legal.sort_custom(func(a: int, b: int): return strength(a) < strength(b))
	if trick.is_empty() or winner() % 2 == turn % 2:
		return legal[0]
	# Play the cheapest card that beats the current winner, otherwise discard low.
	var best: int = trick.filter(func(item: Dictionary): return item.seat == winner())[0].card
	for card: int in legal:
		if (card / 13 == trump and best / 13 != trump) or (card / 13 == best / 13 and card % 13 > best % 13):
			return card
	return legal[0]

func strength(card: int) -> int:
	return card % 13 + (20 if card / 13 == trump else 0)
