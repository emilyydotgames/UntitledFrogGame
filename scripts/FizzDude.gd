extends KinematicBody2D

onready var global = get_node("/root/Global")

export var pace_distance = 20
export var speed = 10
export var knockback = 80
export var point_value = 250

var velocity = Vector2.ZERO
var initial_position
var point_a
var point_b
var moving_to = "a"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationTree.set("parameters/state", 0)
	initial_position = position
	point_a = Vector2(initial_position.x - pace_distance, initial_position.y)
	point_b = Vector2(initial_position.x + pace_distance, initial_position.y)

func _physics_process(delta):
	if not global.paused:
		if $AnimationTree.process_mode == AnimationTree.ANIMATION_PROCESS_MANUAL:
			$AnimationTree.process_mode = AnimationTree.ANIMATION_PROCESS_IDLE
		# Switch directions depending on the target
		match(moving_to):
			"a":
				$Sprite.flip_h = false
				if position.x > point_a.x:
					velocity.x = -speed
				else:
					velocity.x = 0
					moving_to = "b"
			"b":
				$Sprite.flip_h = true
				if position.x < point_b.x:
					velocity.x = speed
				else:
					velocity.x = 0
					moving_to = "a"
		# Keep fizz dude from floating away
		if position.y > initial_position.y:
			velocity.y = -5
		elif position.y < initial_position.y:
			velocity.y = 5
			
		velocity = move_and_slide(velocity)
	else:
		$AnimationTree.process_mode = AnimationTree.ANIMATION_PROCESS_MANUAL
	
func hit(knockback):
	velocity.x = 0
	position.y -= knockback.y
	position.x += knockback.x
	$AnimationTree.set("parameters/state/current", 1)
	$DeathTimer.start()

func _on_Hitbox_body_entered(body):
	if "Player" in body.name:
		body.hurt()



func _on_DeathTimer_timeout():
	global.update_score(point_value)
	var i = global.death_explosion.instance()
	i.position = position
	get_parent().add_child(i)
	queue_free()