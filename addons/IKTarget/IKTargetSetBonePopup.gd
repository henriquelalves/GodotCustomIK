tool
extends PopupPanel

signal on_selected(selected_bone)

var tree : Tree

func _on_select_pressed():
	var selected = tree.get_selected()
	if (selected != null):
		emit_signal("on_selected", selected.get_text(0))
		queue_free()

func _on_hide():
	_on_select_pressed()
	queue_free()

func present_skeleton(skel_target : IKTarget):
	popup()
	connect("popup_hide", self, "_on_hide")
	
	tree = skel_target.get_skeleton_tree()
	
	$VBoxContainer.add_child(tree)
	tree.raise()
	tree.size_flags_vertical = SIZE_EXPAND_FILL
