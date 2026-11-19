extends "res://scripts/game.gd"
## F6 entry point at the grandparents' door, using the chapter's normal arrival.

func _ready() -> void:
	super()
	start_or_resume()
	world.blinds.hide()
	world.scarf.show()
	world.stage = world.STEPS.find("pastry")
	world.bakery.open()
	for kind in [1, 0, 2, 1]:
		world.bakery.add_piece(kind)
	world.bakery.wrap_box()
	world.life.trip = "grandma"
	world.life.board()
	world.car.position = Vector3(5.5, 0, -36)
	world.life.disembark()
