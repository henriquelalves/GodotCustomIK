tool
extends EditorPlugin

var custom_inspector_scene = preload("IKTargetCustomInspector.tscn")
var custom_inspector : IKTargetCustomInspector

func _enter_tree():
	add_custom_type("IKTarget", "Position3D", preload("IKTarget.gd"), preload("IKTargetIcon.png"))
	
	custom_inspector = custom_inspector_scene.instance()
	

func handles(object):
	if not custom_inspector: return
	
	var is_iktarget = object is IKTarget
	
	if is_iktarget:
		_add_inspector()
		custom_inspector.show()
		custom_inspector.iktarget = object
	elif custom_inspector.visible:
		_remove_inspector()
		custom_inspector.hide()
	
	return is_iktarget

func _add_inspector():
	if (custom_inspector.get_parent() == null):
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UR, custom_inspector)

func _remove_inspector():
	if (custom_inspector.get_parent() != null):
		remove_control_from_docks(custom_inspector)

func clear():
	_remove_inspector()
	custom_inspector.hide()

func make_visible(visible):
	custom_inspector.visible = visible

	if (visible): _add_inspector()
	else: _remove_inspector()

func _exit_tree():
	_remove_inspector()
	if (custom_inspector):
		custom_inspector.queue_free()
	remove_custom_type("IKTarget")
