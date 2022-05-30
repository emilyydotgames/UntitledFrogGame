extends KinematicBody2D

onready var global = get_node("/root/Global")

var velocity = Vector2.ZERO
var is_jumping = false
var jump_strength = 0.0
var start_position = Vector2(50, -50)
var max_health = 6
var invulnerable = false
var score = 0

export(PackedScene) var attack_hitbox
export var attacking = false
export var can_move = true
export var is_dead = false
export var speed = 50
export var gravity = 200.0
export var jump_height = 200
export var death_height = 48
export var health = 6
export var lives = 3

func _ready():
	$InvulnTimer.stop()
	position = start_position

func _input(event):
	if not global.paused:
		# Jump when action is released
		if event.is_action_released("jump") and is_on_floor():
			jump()
			$JumpMeter.visible = false
		if event.is_action_pressed("attack"):
			attack()

func _physics_process(delta):
	if not global.paused:
		# Handle player input and physics if they are not dead
		if not is_dead:
			# Gravity
			velocity.y += delta * gravity
			# Player Movement
			if Input.is_action_pressed("move_right"):
				velocity.x = speed
				$Sprite.flip_h = false
				if not is_jumping:
					$AnimationTree.set("parameters/isWalking/current", 1)
			elif Input.is_action_pressed("move_left"):
				velocity.x = -speed
				$Sprite.flip_h = true
				if not is_jumping:
					$AnimationTree.set("parameters/isWalking/current", 1)
			else:
				velocity.x = 0
				# Change animation to idle if no horizontal movement and on ground
				if is_on_floor():
					$AnimationTree.set("parameters/isWalking/current", 0)
			
			if position.y > death_height:
				die()
				
			if is_jumping:
				if is_on_floor():
					is_jumping = false # Reset after player touches ground after jumping
				else:
					$AnimationTree.process_mode = AnimationTree.ANIMATION_PROCESS_MANUAL
					$Sprite.frame = 17
			elif is_on_floor():
				# Charge jump when held
				if Input.is_action_pressed("jump"):
					charge_jump(delta)
				$AnimationTree.process_mode = AnimationTree.ANIMATION_PROCESS_IDLE
			
			# Update health UI
			global.update_health(health)
			velocity = move_and_slide(velocity, Vector2(0, -1))
	else:
		# Change process mode to manual when game is paused
		$AnimationTree.process_mode = AnimationTree.ANIMATION_PROCESS_MANUAL

func charge_jump(delta):
	# Show and fill jump meter
	if jump_strength < jump_height:
		$AnimationTree.set("parameters/jumpPrep/current", 1)
		velocity.x /= 2
		jump_strength += delta * 200 # Speed that jump charges
		$AnimationTree.set("parameters/isWalking/current", 0)    
		$JumpMeter.visible = true
		$JumpMeter.value = round(jump_strength / 40)
	# Jump automatically when jump meter fills
	if jump_strength >= jump_height:
		jump()

func jump():
	if !is_jumping and !is_dead:
		velocity.y = -jump_strength
		is_jumping = true
		$AnimationTree.set("parameters/jumpPrep/current", 0)
		$AnimationTree.set("parameters/isJumping/active", true)
		jump_strength = 0.0
		$JumpMeter.visible = false

func attack():
	$AnimationTree.set("parameters/isAttacking/active", true)
	can_move = false
	
func spawn_attack_hitbox():
	var i = attack_hitbox.instance()
	i.position = Vector2($Sprite.position.x - 8, $Sprite.position.y) if $Sprite.flip_h else Vector2($Sprite.position.x + 8, $Sprite.position.y)
	add_child(i)
	
func hurt():
	if not invulnerable and not attacking:
		if health > 1:
			health -= 1
			global.update_health(health)
			$AnimationTree.set("parameters/isHit/active", true)
			invulnerable = true
		else:
			die()
		$InvulnTimer.start()
	
func die():
	is_jumping = false
	$JumpMeter.visible = false
	is_dead = true
	velocity = Vector2.ZERO
	position.y = death_height - 16
	$AnimationTree.set("parameters/isDead/active", true)
	
func death_reset():
	global.transition_out()
	yield(global.get_node("UI/CircleTransition/AnimationPlayer"), "animation_finished")
	position = start_position
	is_dead = false
	$AnimationTree.set("parameters/isDead/active", false)
	$Sprite.position.y = 0
	health = max_health
	global.update_health(health)
	# Update lives
	lives -= 1
	global.update_life(lives)
	global.transition_in()

func _on_InvulnTimer_timeout():
	invulnerable = false
	$Sprite.material.set_shader_param("active", false)
	$InvulnTimer.stop()
