extends "res://scripts/game.gd"
## Editor entry points into a fresh copy of the playable chapter.

enum Checkpoint { WAKE_UP = 0, BAKERY_ARRIVAL = 1, VISIT_GRANDMA = 2, FAMILY_LUNCH = 3 }
const FAMILY_ASSORTMENT: Array[int] = [1, 0, 2, 1]

## The moment to play when running this scene or restarting its story.
@export var start_at: Checkpoint = Checkpoint.VISIT_GRANDMA

func _ready() -> void:
	super()
	start_or_resume()
	enter_checkpoint(world)

func restart_mission() -> void:
	super()
	if story_mode:
		enter_checkpoint(world)

func enter_checkpoint(chapter: Nowruz) -> void:
	if start_at == Checkpoint.WAKE_UP:
		return
	chapter.blinds.hide()
	if start_at == Checkpoint.BAKERY_ARRIVAL:
		chapter.stage = Nowruz.STEPS.find("car")
		chapter.life.disembark("bakery")
	else:
		prepare_family_gift(chapter)
		if start_at == Checkpoint.VISIT_GRANDMA:
			chapter.life.disembark("grandma")
			notify("scene_wait", 4)
		else:
			join_lunch(chapter)
	chapter.apply_language()

func prepare_family_gift(chapter: Nowruz) -> void:
	chapter.scarf.show()
	chapter.life.dismiss_patrol(false)
	chapter.stage = Nowruz.STEPS.find("pastry")
	chapter.bakery.pack_assortment(FAMILY_ASSORTMENT)

func join_lunch(chapter: Nowruz) -> void:
	chapter.life.park_at("grandma")
	for i in range(chapter.family.size()):
		chapter.family[i].position = Nowruz.Life.family_room_spot(i, false)
	chapter.set_out_pastries()
	chapter.serving.show()
	var table: Vector3 = chapter.targets.cards.position
	chapter.teleport(table + Vector3(0, 0.05, 2), table)
	chapter.stage = Nowruz.STEPS.find("lunch")
	chapter.advance()
