tool
extends Position3D

class_name IKTarget

export(NodePath) var skel_nodepath setget set_skel_nodepath
export var ik_bone = ""
export var ik_bone_length = 1.0
export var ik_passes = 3
export var ik_limit = 2

var _debug_position_list = []
var skel : Skeleton
var skel_bone_tree : Tree
var bone_to_tree_item : Dictionary = {}

func set_skel_nodepath(v):
	skel_nodepath = v
	if (has_node(skel_nodepath)):
		for child in get_children(): child.queue_free()
		
		skel = get_node(skel_nodepath)
		setup_skel_tree()

func get_skeleton_tree() -> Tree:
	var new_tree = Tree.new()
	new_tree.create_item()
	new_tree.set_hide_root(true)
	bone_to_tree_item = {}
	
	for b in range(skel.get_bone_count()):
		var parent_item = new_tree.get_root()
		var parent_bone = skel.get_bone_parent(b)
		if (bone_to_tree_item.has(parent_bone)):
			parent_item = bone_to_tree_item[parent_bone]
		
		var new_item = new_tree.create_item(parent_item)
		new_item.set_text(0, skel.get_bone_name(b))
		bone_to_tree_item[b] = new_item
	
	return new_tree

func setup_skel_tree():
	skel_bone_tree = get_skeleton_tree()
	add_child(skel_bone_tree)
	skel_bone_tree.owner = owner

func _ready():
	for child in get_children():
		child.queue_free()
	
	if (has_node(skel_nodepath)):
		skel = get_node(skel_nodepath)
		setup_skel_tree()
	
	if (has_node(skel_nodepath)): skel = get_node(skel_nodepath)
	set_process(true)
	
	if (Engine.editor_hint):
		_reset_debug_positions()

func pass_chain():
	if (skel == null or not visible): return
	
	var b = skel.find_bone(ik_bone)
	if (b == -1): return
	
	var l = ik_limit
	var target = global_transform.origin
	
	var targets = [target]
	var bones = [b]
	
	while b >= 0 and l > 0:
		var p_gpose = skel.get_bone_global_pose(skel.get_bone_parent(b))
		var p_grest = skel.get_bone_rest(skel.get_bone_parent(b))
		var bone_transf_rest_obj = p_gpose * skel.get_bone_rest(b)
		var rest_length = skel.global_transform.xform(p_grest.origin).length()
		target = target + ((skel.global_transform*p_gpose).origin - target).normalized() * rest_length
		targets.append(target)
		b = skel.get_bone_parent(b)
		bones.append(b)
		l = l - 1
	
	bones.pop_back()
	targets.pop_back()
	targets.pop_back()
	_debug_positions(targets)
	
	while targets.size() > 0:
		_point_bone_to(bones[-1], targets[-1])
		bones.pop_back()
		targets.pop_back()
	_point_bone_to(bones[-1], global_transform.xform(Vector3.RIGHT), transform.xform(Vector3.UP))
	
	var bones_list = []
	bones_list.append(bone_to_tree_item[bones[-1]].get_children())
	
	while (bones_list.size() != 0):
		if (bones_list[0] == null): break
		var current_tree_item = bones_list[0]
		
		var t_item_children = current_tree_item.get_children()
		if (t_item_children != null): bones_list.append(t_item_children)
		
		var item_b = skel.find_bone(current_tree_item.get_text(0))
		var item_p_b = skel.get_bone_parent(item_b)
		var p_gpose = skel.get_bone_globral_pose(item_p_b)
		var p_grest = skel.get_bone_rest(item_p_b)
		var bone_transf_rest_obj = p_gpose * skel.get_bone_rest(item_b)
		var rest_length = skel.global_transform.xform(p_grest.origin).length()
		
		skel.set_bone_global_pose_override(item_b, bone_transf_rest_obj, 1, true) 
		bones_list.remove(0)


func _reset_bone_size():
	pass

func _reset_debug_positions():
	for child in get_children():
		if (child is Position3D): child.queue_free()
	_debug_position_list.clear()

func _debug_positions(array : Array):
	for el in _debug_position_list:
		el.hide()
	
	for i in range(array.size()):
		if i >= _debug_position_list.size():
			var new_pos = Position3D.new()
			add_child(new_pos)
			new_pos.owner = owner
			_debug_position_list.append(new_pos)
		var p = _debug_position_list[i]
		p.show()
		p.global_transform.origin = array[i]

func _point_bone_to(b : int, position : Vector3, normal : Vector3 = Vector3.ZERO):
	var bone_transf_obj = skel.get_bone_global_pose(b) # Object space bone pose
	var bone_transf_world = skel.global_transform * bone_transf_obj
	
	var bone_transf_rest_local = skel.get_bone_rest(b)
	var bone_transf_rest_obj = skel.get_bone_global_pose(skel.get_bone_parent(b)) * bone_transf_rest_local 

	var diff_vec_local = bone_transf_world.affine_inverse().xform(position).normalized() 
	var bone_forward_local = Vector3(0,1,0)
	
	var bone_rotate_axis = bone_forward_local.cross(diff_vec_local)
	var bone_rotate_angle = acos(bone_forward_local.dot(diff_vec_local))
	
	if bone_rotate_axis.length() < 1e-2:
		return  # Already aligned, no need to rotate
	
	bone_rotate_axis = bone_rotate_axis.normalized()

	# Bring the axis to object space, WITHOUT translation (so only the BASIS is used) since vectors shouldn't be translated
	var bone_rotate_axis_obj = bone_transf_obj.basis.xform(bone_rotate_axis).normalized()
	var bone_new_transf_obj = Transform(bone_transf_obj.basis.rotated(bone_rotate_axis_obj, bone_rotate_angle), bone_transf_obj.origin)  
	
	if normal != Vector3.ZERO:
		var u = bone_transf_world.affine_inverse().xform(normal)
		var n = Vector3(0,100,0)
		var nu = u - ((u.dot(n))*n)
		var diff_normal_vec_local = bone_transf_world.basis.inverse().xform(normal-translation)
#		_debug_positions([bone_transf_world.affine_inverse().xform(diff_normal_vec_local)])
		diff_normal_vec_local = diff_normal_vec_local.normalized()
		
#		var diff_normal_vec_local = bone_transf_world.affine_inverse().xform(normal).normalized()
		var normal_rotate_angle = acos(Vector3(1,0,0).dot(diff_normal_vec_local))
#		var positive_direction = Vector3(1,0,0).cross(diff_normal_vec_local).z
		var axis = Vector3(1,0,0).cross(diff_normal_vec_local)
		var normal_rotate_axis_obj = bone_transf_world.basis.xform(axis.normalized()).normalized()#bone_new_transf_obj.basis.xform(Vector3(0,1,0)).normalized()
		bone_new_transf_obj = Transform(bone_new_transf_obj.basis.rotated(normal_rotate_axis_obj, normal_rotate_angle), bone_new_transf_obj.origin)

	if is_nan(bone_new_transf_obj[0][0]):
		bone_new_transf_obj = Transform()  # Corrupted somehow
	
	# Set origin based on parent bone direction and rest position
	bone_new_transf_obj.origin = bone_transf_rest_obj.origin
	skel.set_bone_global_pose_override(b, bone_new_transf_obj, 1, true) 

func _process(delta):
	if (!visible): return
	
	for i in range(ik_passes):
		pass_chain()
