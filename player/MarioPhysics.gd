extends KinematicBody2D

onready var body: = $Body
onready var anim: = $AnimationPlayer

var speed:			= Vector2.ZERO
var acceleration:	= 0.0
var skidding:		= false
var fastjump:		= false		#Jump started at > maxWalkSpeed
var fasterjump:		= false		#Jump started at > airspeedCutoff
var fastVjump:		= false		#Jump started at > jumpCutoff1
var fasterVjump:	= false		#Jump started at > jumpCutoff2
var direction:		= 0.0		#Input horizontal direction
var is_grounded:	= true

var sprint_buffer: = 0
var sprint_buffer_amount: = 10

# Constants
const minWalkSpeed:    = (1.0/16 + 3.0/256)				*60.0
const walkAccel:       = (9.0/256 + 8.0/(16*16*16)) 	*60.0	*60.0
const runAccel:        = (14.0/256 + 4.0/(16*16*16))	*60.0	*60.0
const maxWalkSpeed:    = (1 + 9.0/16)					*60.0
const maxRunSpeed:     = (2 + 9.0/16)					*60.0
const releaseDecel:    = (13.0/256)						*60.0	*60.0
const skidDecel:       = (1.0/16 + 10.0/256)			*60.0	*60.0
const turnSpeed:       = (9.0/16)						*60.0

const airspeedCutoff:  = (1 + 13.0/16)					*60.0
const airSlowGain:     = (9.0/256 + 8.0/(16*16*16))		*60.0	*60.0
const airFastGain:     = (14.0/256 + 4.0/(16*16*16))	*60.0	*60.0
const airFastDrag:     = (13.0/256)						*60.0
const airSlowDrag:     = (9.0/256 + 8.0/(16*16*16))		*60.0

const jumpSpeed:       = 4.0							*60.0
const bigJumpSpeed:    = 5.0							*60.0
const smallUpDrag:     = (2.0/16)						*60.0	*60.0
const mediumUpDrag:    = (1.0/16 + 14.0/256)			*60.0	*60.0
const bigUpDrag:       = (2.0/16 + 8.0/256)				*60.0	*60.0
const smallGravity:    = (7.0/16)						*60.0	*60.0
const medGravity:      = (6.0/16)						*60.0	*60.0
const bigGravity:      = (9.0/16)						*60.0	*60.0
const jumpCutoff1:     = 1.0							*60.0
const jumpCutoff2:     = (2 + 5.0/16)					*60.0
const maxVspeed:       = 4.0							*60.0

#Inputs
var input_right:    = 0.0
var input_left:     = 0.0
var input_up:       = 0.0
var input_down:     = 0.0
var input_jump:     = false
var input_jump_p:   = false
var input_action:   = false

func _unhandled_input(event:InputEvent)->void:
	if event.is_action("input_right"):
		input_right = Input.get_action_strength("input_right")
	elif event.is_action("input_left"):
		input_left = Input.get_action_strength("input_left")
	elif event.is_action("input_up"):
		input_up = Input.get_action_strength("input_up")
	elif event.is_action("input_down"):
		input_down = Input.get_action_strength("input_down")
	elif event.is_action("input_jump"):
		input_jump_p = Input.is_action_just_pressed("input_jump")
		input_jump = Input.is_action_pressed("input_jump")
	elif event.is_action("input_action"):
		input_action = Input.is_action_pressed("input_action")

func _physics_process(delta:float)->void:
	direction = input_right - input_left
	var dir: = sign(direction)
	
	if is_grounded:
		speed.y = smallGravity*delta				#need to have a little gravity for ground detection

		if input_action:
			sprint_buffer = sprint_buffer_amount
			acceleration = runAccel
		else:
			if sprint_buffer > 0:
				sprint_buffer -= 1
			acceleration = walkAccel

		if abs(direction) > 0.01:
			skidding = sign(speed.x) != dir && abs(speed.x) > 0.00001
			if skidding:
				if abs(speed.x) > turnSpeed:
					speed.x += skidDecel * dir      * delta
				else:
					speed.x = 0.0
			else:
				if is_equal_approx(speed.x, 0.0):   #no speed.x
					speed.x = minWalkSpeed * dir
				else:
					speed.x += acceleration * dir   * delta
				if abs(speed.x) > maxRunSpeed:
					speed.x = maxRunSpeed * dir
				if abs(speed.x) > maxWalkSpeed && sprint_buffer == 0:
					speed.x = maxWalkSpeed * dir
		else:   #no direction pressed
			var decel: = skidDecel if skidding else releaseDecel
			if abs(speed.x) < decel * delta:
				speed.x = 0
			else:
				speed.x -= decel * sign(speed.x) * delta

		var absxspeed:  = abs(speed.x)
		fasterVjump     = absxspeed > jumpCutoff2
		fastVjump       = absxspeed > jumpCutoff1
		fastjump        = absxspeed > maxWalkSpeed
		fasterjump      = absxspeed > airspeedCutoff
		if Input.is_action_just_pressed("input_jump"):    #just pressed
			speed.y = -bigJumpSpeed if fasterVjump else -jumpSpeed

		
	else:   #in midair
		if abs(direction) > 0.01:
			if abs(speed.x) >= maxWalkSpeed:
				speed.x += airFastGain * dir            * delta
			else:
				if sign(speed.x) == dir:
					speed.x += airSlowGain * dir        * delta
				else:
					speed.x = (airFastDrag if fasterjump else airSlowDrag) * dir

		if fastjump:
			speed.x = clamp(speed.x, -maxRunSpeed, maxRunSpeed)
		else:
			speed.x = clamp(speed.x, -maxWalkSpeed, maxWalkSpeed)

		if speed.y < 0.0 && input_jump:
			if fasterVjump:
				speed.y += bigUpDrag    * delta
			elif fastVjump:
				speed.y += mediumUpDrag * delta
			else:
				speed.y += smallUpDrag  * delta
		else:
			if fasterVjump:
				speed.y += bigGravity   * delta
			elif fastVjump:
				speed.y += medGravity   * delta
			else:
				speed.y += smallGravity * delta
		if speed.y > maxVspeed:
			speed.y = maxVspeed
	
	speed = move_and_slide(speed, Vector2.UP)
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
		if is_equal_approx(speed.x, 0.0):
			anim.play("Idle")
		else:
			if skidding:
				anim.play("Skid")
			else:
				anim.play("Walk")
				if fasterjump:
					anim.playback_speed = 1.96
				elif abs(speed.x) >= maxWalkSpeed:
					anim.playback_speed = 1.62
				else:
					anim.playback_speed = 1
	else:
		anim.play("Jump")










