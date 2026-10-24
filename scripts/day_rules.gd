extends RefCounted
## Authored story time, not the computer clock. All venues share this policy.

var ramadan := false
var minute := 8 * 60
var dawn := 5 * 60
var iftar := 18 * 60 + 20
var citations := 0
var detained := false

func public_service_allowed() -> bool:
	return not ramadan or minute < dawn or minute >= iftar

func consume(in_public: bool, witnessed: bool) -> String:
	if not in_public or not witnessed or public_service_allowed():
		return "drink_safe"
	citations += 1
	if citations == 1:
		return "drink_fine"
	detained = true
	return "drink_detained"

func clock_text() -> String:
	return "%02d:%02d" % [minute / 60, minute % 60]
