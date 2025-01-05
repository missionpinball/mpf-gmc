# Copyright 2021 Paradigm Tilt

extends ScrollContainer
class_name ServicePage

var focused_index := 0
var is_focused := false
var List: Control

func focus():
	is_focused = true
	List.get_child(0).grab_focus()

func unfocus():
	is_focused = false
	focused_index = 0

func add_setting(item: SettingsItem) -> void:
	List.add_child(item)

func get_focused_setting() -> SettingsItem:
	return List.get_child(focused_index)

func has_settings() -> bool:
	return List.get_child_count() > 0

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
			# Find the main slide and restore focus to it
			var parent = self.get_parent()
			while parent:
				if parent is MPFSlide:
					parent.focus()
					return
				parent = parent.get_parent()

func _input(event):
	if not event.is_class("InputEventKey") or event.key_label != -1:
		return
	if not self.is_focused:
		return

	if List.get_child(focused_index).has_focus():
		if event.keycode == KEY_UP:
			self.focus_child(-1)
			get_window().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			self.focus_child(1)
			get_window().set_input_as_handled()

func _to_string() -> String:
	return "<ServicePage:%s>" % self.name
