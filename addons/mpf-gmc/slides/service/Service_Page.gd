# Copyright 2021 Paradigm Tilt

extends ScrollContainer
class_name ServicePage

var focused_index := 0
var is_focused := false
@onready var List = $MarginContainer/VBoxContainer

func focus():
	print("%s taking focus" % self)
	is_focused = true
	List.get_child(0).grab_focus()

func unfocus():
	is_focused = false
	focused_index = 0

func add_setting(item: SettingsItem) -> void:
	List.add_child(item)

func get_focused_setting() -> SettingsItem:
	return List.get_child(focused_index)

func _exit_tree() -> void:
	for child in List.get_children():
		List.remove_child(child)
		child.queue_free()

func focus_child(direction: int, wrap_around=false):
	var next = focused_index + direction
	if next >= 0:
		if next < List.get_child_count():
			focused_index = next
			List.get_child(focused_index).grab_focus()
		elif wrap_around:
			focused_index = 0
			List.get_child(focused_index).grab_focus()
	elif next == -1:
		if wrap_around:
			focused_index = List.get_child_count() - 1
			List.get_child(focused_index).grab_focus()
		else:
			is_focused = false
			# Moving the Settings into Base, the parent is now first child of scene
			get_tree().get_current_scene().get_node("Scene").get_child(0).focus()

func _unhandled_key_input(event):
	if not is_focused:
		return
	if event.key_label == -1 and List.get_child(focused_index).has_focus():
		if event.keycode == KEY_UP:
			self.focus_child(-1)
			get_window().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			self.focus_child(1)
			get_window().set_input_as_handled()

func _to_string() -> String:
	return "<ServicePage:%s>" % self.name
