extends KinematicBody2D

onready var body: = $Body
onready var anim: = $AnimationPlayer

var velocity:				= Vector2.ZERO
var acc:					= 0.0
var is_skidding:			= false
var faster_air_limit:		= false		#Jump started at > max_walk
var faster_air_spd:			= false		#Jump started at > air_spd_treshold
var fast_jump:				= false		#Jump started at > fast_jump_treshold
var fastest_jump:			= false		#Jump started at > fastest_jump_treshold
var direction:				= 0.0		#Input horizontal direction
var is_grounded:			= true

var sprint_buffer:			= 0
var sprint_buffer_amount:	= 10

# Constants
const walk_acc:					= (9.0/256 + 8.0/(16*16*16)) 	#*60	*60
const run_acc:					= (14.0/256 + 4.0/(16*16*16))	#*60	*60
const min_walk:					= (1.0/16 + 3.0/256)			#*60
const max_walk:					= (1 + 9.0/16)					#*60
const max_run:					= (2 + 9.0/16)					#*60
const release_deacc:			= (13.0/256)					#*60	*60
const skid_deacc:				= (1.0/16 + 10.0/256)			#*60	*60
const turn_treshold:			= (9.0/16)						#*60

const air_spd_treshold:			= (1 + 13.0/16)					#*60
const air_slow_acc:				= (9.0/256 + 8.0/(16*16*16))	#*60	*60
const air_fast_acc:				= (14.0/256 + 4.0/(16*16*16))	#*60	*60
const air_fast_drag:			= (13.0/256)					#*60
const air_slow_drag:			= (9.0/256 + 8.0/(16*16*16))	#*60

const jump_spd:					= 4.0							#*60
const big_jump_spd:				= 5.0							#*60
const small_up_drag:			= (2.0/16)						#*60	*60
const medium_up_drag:			= (1.0/16 + 14.0/256)			#*60	*60
const big_up_drag:				= (2.0/16 + 8.0/256)			#*60	*60
const small_gravity:			= (7.0/16)						#*60	*60
const medium_gravity:			= (6.0/16)						#*60	*60
const big_gravity:				= (9.0/16)						#*60	*60
const fast_jump_treshold:		= 1.0							#*60
const fastest_jump_treshold:	= (2 + 5.0/16)					#*60
const max_fall:					= 4.0							#*60

#Inputs
var input_right:	= 0.0
var input_left:		= 0.0
var input_up:		= 0.0
var input_down:		= 0.0
var input_jump:		= false
var input_jump_p:	= false
var input_action:	= false

func _unhandled_input(event:InputEvent)->void:
	if event.is_action("input_right"):
		input_right		= Input.get_action_strength("input_right")
	elif event.is_action("input_left"):
		input_left		= Input.get_action_strength("input_left")
	elif event.is_action("input_up"):
		input_up		= Input.get_action_strength("input_up")
	elif event.is_action("input_down"):
		input_down		= Input.get_action_strength("input_down")
	elif event.is_action("input_jump"):
		input_jump		= Input.is_action_pressed("input_jump")
	elif event.is_action("input_action"):
		input_action	= Input.is_action_pressed("input_action")

func _physics_process(delta:float)->void:
	if is_equal_approx(delta, 0.0):		#catch divide by zero cases
		return
	
	direction = input_right - input_left
	var dir: = sign(direction)
	
	if is_grounded:
		velocity.y = small_gravity 						#*delta				#need to have a little gravity for ground detection

		if input_action:
			sprint_buffer = sprint_buffer_amount
			acc = run_acc
		else:
			if sprint_buffer > 0:
				sprint_buffer -= 1
			acc = walk_acc

		if abs(direction) > 0.01:
			is_skidding = sign(velocity.x) != dir && abs(velocity.x) > 0.00001
			if is_skidding:
				if abs(velocity.x) > turn_treshold:
					velocity.x += skid_deacc * dir 		#*delta
				else:
					velocity.x = 0.0
			else:
				if is_equal_approx(velocity.x, 0.0):	#no velocity.x
					velocity.x = min_walk * dir
				else:
					velocity.x += acc * dir 			#*delta
				if abs(velocity.x) > max_run:
					velocity.x = max_run * dir
				if abs(velocity.x) > max_walk && sprint_buffer == 0:
					velocity.x = max_walk * dir
		else:   															#no direction pressed
			var de_acc: = skid_deacc if is_skidding else release_deacc
			if abs(velocity.x) < de_acc:				#*delta:
				velocity.x = 0
			else:
				velocity.x -= de_acc * sign(velocity.x) #*delta

		var abs_spd:		= abs(velocity.x)
		fastest_jump		= abs_spd > fastest_jump_treshold
		fast_jump			= abs_spd > fast_jump_treshold
		faster_air_limit	= abs_spd > max_walk
		faster_air_spd		= abs_spd > air_spd_treshold
		if input_jump && !input_jump_p:					#just pressed
			velocity.y = -big_jump_spd if fastest_jump else -jump_spd
	
	else:	#MIDAIR
		if abs(direction) > 0.01:
			if abs(velocity.x) >= max_walk:
				velocity.x += air_fast_acc * dir 		#*delta
			else:
				if sign(velocity.x) == dir:									#pointing same direction
					velocity.x += air_slow_acc * dir 	#*delta
				else:														#pointing opposite direction
					velocity.x = (air_fast_drag if faster_air_spd else air_slow_drag) * dir

		if faster_air_limit:
			velocity.x = clamp(velocity.x, -max_run, max_run)
		else:
			velocity.x = clamp(velocity.x, -max_walk, max_walk)

		if velocity.y < 0.0 && input_jump:
			if fastest_jump:
				velocity.y += big_up_drag 				#*delta
			elif fast_jump:
				velocity.y += medium_up_drag 			#*delta
			else:
				velocity.y += small_up_drag 			#*delta
		else:
			if fastest_jump:
				velocity.y += big_gravity 				#*delta
			elif fast_jump:
				velocity.y += medium_gravity 			#*delta
			else:
				velocity.y += small_gravity 			#*delta
		if velocity.y > max_fall:
			velocity.y = max_fall
	
	input_jump_p = input_jump												#save old jump button state
	velocity = move_and_slide(velocity/delta, Vector2.UP) *delta
	slide_collision_check()
	

func slide_collision_check()->void:
	is_grounded = is_on_floor()
	for i in get_slide_count():
		var collision: = get_slide_collision(i)
#		if collision.normal.y < -0.5:        #hit up
#			print(collision.collider)
#		if abs(collision.normal.x) > 0.5:   #hit sides
#			print(collision.collider)

func _process(_delta:float)->void:				#Drawing
	if	!is_equal_approx(direction, 0.0):
		body.scale.x = sign(direction)
	
	if is_grounded:
		if is_equal_approx(velocity.x, 0.0):
			anim.play("Idle")
		else:
			if is_skidding:
				anim.play("Skid")
			else:
				anim.play("Walk")
				if faster_air_spd:
					anim.playback_speed = 1.96
				elif abs(velocity.x) >= max_walk:
					anim.playback_speed = 1.62
				else:
					anim.playback_speed = 1
	else:
		anim.play("Jump")










