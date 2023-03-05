extends Camera2D

@export var smooth_speed: = Vector2(5.0, 15.0)
@export var velocity_mult: = Vector2(50.0, 15.0)
@export var offset_position: = Vector2(0.0, -32.0)
@export var target:Node2D
@export var boundries:Rect2 = Rect2(-100, -100, 200, 200)
@export_group("Debug")
@export var debug:bool
@export var show_center: = true
@export var show_velocity: = true
@export var show_projected: = true
@export var show_smooth: = true
@export var show_round: = true
@export var show_boundries: = true

var target_pos:Vector2
var projected_pos:Vector2
var smooth_pos:Vector2
var round_pos:Vector2

func _ready()->void:
	smooth_pos = target.global_position

func _process(delta:float)->void:
	target_pos = target.body.global_position
	projected_pos = target_pos + offset_position + (target.velocity * velocity_mult)
	smooth_pos.x = lerp(smooth_pos.x, projected_pos.x, delta * smooth_speed.x)
	smooth_pos.y = lerp(smooth_pos.y, projected_pos.y, delta * smooth_speed.y)
	smooth_pos.x = clamp(smooth_pos.x, target_pos.x + boundries.position.x, target_pos.x + (boundries.size.x + boundries.position.x))
	smooth_pos.y = clamp(smooth_pos.y, target_pos.y + boundries.position.y, target_pos.y + (boundries.size.y + boundries.position.y))
	round_pos = smooth_pos.round()
	global_position = round_pos
	if debug:
		queue_redraw()

func _draw()->void:
	if show_velocity:
		draw_circle(target.global_position - global_position + (target.velocity) ,1, Color.DEEP_PINK)
	if show_projected:
		draw_circle(projected_pos - global_position,1, Color.DARK_KHAKI)
	if show_smooth:
		draw_circle(smooth_pos - global_position,1, Color.DARK_KHAKI)
	if show_round:
		draw_circle(smooth_pos - global_position,1, Color.GOLD)
	if show_center:
		draw_circle(Vector2.ZERO, 1, Color.GOLD)
	if show_boundries:
		draw_rect(boundries, Color.DARK_VIOLET, false)
