extends Spatial

export(NodePath) var LeftHandIK
export(NodePath) var RightHandIK
export(NodePath) var LeftKneeIK
export(NodePath) var LeftFootIK
export(NodePath) var RightKneeIK
export(NodePath) var RightFootIK

var _left_hand_ik : IKTarget
var _right_hand_ik : IKTarget
var _left_knee_ik : IKTarget
var _left_foot_ik : IKTarget
var _right_knee_ik : IKTarget
var _right_foot_ik : IKTarget

var _left_angle_tick = .0
var _right_angle_tick = .0

var _left_foot_offset : Vector3
var _left_knee_offset : Vector3
var _right_foot_offset : Vector3
var _right_knee_offset : Vector3


func _ready():
	_left_hand_ik = get_node(LeftFootIK)
	_right_hand_ik = get_node(RightHandIK)
	_left_knee_ik = get_node(LeftKneeIK)
	_left_foot_ik = get_node(LeftFootIK)
	_right_knee_ik = get_node(RightKneeIK)
	_right_foot_ik = get_node(RightFootIK)
	
	_left_foot_offset = _left_foot_ik.translation
	_left_knee_offset = _left_knee_ik.translation
	_right_foot_offset = _right_foot_ik.translation
	_right_knee_offset = _right_knee_ik.translation

func _process(delta):
	var forward = transform.basis * Vector3.FORWARD
	
	var left_angle_value = sin(2*PI*_left_angle_tick)
	_left_foot_ik.translation = translation + (Vector3.UP * left_angle_value) + (forward * left_angle_value) + _left_foot_offset
	_left_knee_ik.translation = translation + (Vector3.UP * left_angle_value * 0.5) + (Vector3.UP * 0.5) + _left_knee_offset

	var right_angle_value = sin(2*PI*_right_angle_tick)
	_right_foot_ik.translation = translation + (Vector3.UP * right_angle_value) + (forward * right_angle_value) + _right_foot_offset
	_right_knee_ik.translation = translation + (Vector3.UP * right_angle_value * 0.5) + (Vector3.UP * 0.5) + _right_knee_offset
	
	if (Input.is_key_pressed(KEY_Q)):
		_left_angle_tick += 0.5 * delta
	
	if (Input.is_key_pressed(KEY_E)):
		_right_angle_tick += 0.5 * delta
