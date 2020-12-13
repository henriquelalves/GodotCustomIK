tool
extends VBoxContainer

class_name IKTargetCustomInspector

var iktarget : IKTarget
var set_bone_popup = preload("res://addons/IKTarget/IKTargetSetBonePopup.tscn")

func _ready():
	$SetBoneButton.connect("pressed", self, "_on_setbone_pressed")
	$ClearButton.connect("pressed", self, "_on_reset_pressed")
	$ResetDebugButton.connect("pressed", self, "_on_resetdebug_pressed")

func _on_setbone_pressed():
	var popup = set_bone_popup.instance()
	popup.connect("on_selected", self, "_on_bone_selected")
	get_tree().root.add_child(popup)
	print(iktarget.skel_bone_tree)
	popup.present_skeleton(iktarget)

func _on_bone_selected(bone_string):
	iktarget.ik_bone = bone_string
	iktarget.property_list_changed_notify()

func _on_reset_pressed():
	var b = iktarget.skel.find_bone(iktarget.ik_bone)
	for i in range(iktarget.skel.get_bone_count()):
		iktarget.skel.set_bone_global_pose_override(i, iktarget.skel.get_bone_rest(i), 0, false)

func _on_resetdebug_pressed():
	iktarget._reset_debug_positions()
