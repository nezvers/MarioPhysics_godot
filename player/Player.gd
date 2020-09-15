extends Actor
class_name Player

onready var anim:AnimationPlayer = $AnimationPlayer

var scaler: = Vector2(1.0, 1.0)

var velocity_previous: = Vector2.ZERO

func unhandled_input(event)->void:
	if event.is_action("move_right"):
		move_right = Input.get_action_strength("move_right")
	elif event.is_action("move_left"):
		move_left = Input.get_action_strength("move_left")
	elif event.is_action("move_up"):
		move_up = Input.get_action_strength("move_up")
	elif event.is_action("move_down"):
		move_down = Input.get_action_strength("move_down")
	elif event.is_action_pressed("jump"):
		jump = true
	elif event.is_action_released("jump"):
		jump = false

func visual_process(delta:float):
	if abs(direction.x)>= 0.001:
		body.scale.x = sign(direction.x)
	
	if !is_grounded:	#Not on the ground
		scaler.y = range_lerp(abs(velocity.y), 0.0, abs(jump_impulse), 0.85, 1.15)
		scaler.x = range_lerp(abs(velocity.y), 0.0, abs(jump_impulse), 1.0, 0.85)
		
	scaler.x = lerp(scaler.x, 1.0, 1.0 - pow(0.01, delta))
	scaler.y = lerp(scaler.y, 1.0, 1.0 - pow(0.01, delta))
	
	body.scale = scaler * Vector2(sign(body.scale.x), 1.0)
	velocity_previous = velocity

func landed()->void:	#triggered in ground logic when just landed
	scaler.x = range_lerp(abs(velocity_previous.y), 0.0, abs(jump_impulse), 1.2, 1.25)
	scaler.y = range_lerp(abs(velocity_previous.y), 0.0, abs(jump_impulse), 0.8, 0.5)



















