extends VBoxContainer

@export var device_type: String
@onready var coil_map := []
# Don't instantiate the List ref until it's ready to populate
# because often the first test_start command arrives before the list
@onready var List: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	MPF.server.service.connect(self._on_service)
	MPF.server.send_service("list_%s" % device_type, ["name","label","number"])

func _on_service(payload):
	# COILS
	if payload.cmd == "list_coils":
		List = $ScrollContainer/coil_list
		var list_button = load("res://addons/mpf-gmc/slides/service/List_Button.tscn")
		for coil in payload.coils:
			var list_item = list_button.instantiate()
			list_item.name = coil[0]  # name
			list_item.text = coil[1]  # label
			list_item.tooltip_text = "%s" % coil[2]  # number
			List.add_child(list_item)
		select_option(List.get_child(0), "Coil")
	elif payload.cmd == "list_lights":
		List = $ScrollContainer/coil_list
		var list_button = load("res://addons/mpf-gmc/slides/service/List_Button.tscn")
		for light in payload.lights:
			var list_item = list_button.instantiate()
			list_item.name = light[0]  # name
			list_item.text = light[1]  # label
			list_item.tooltip_text = "%s" % light[2][0] # number
			$instructions.text = "Color: white"
			List.add_child(list_item)
		select_option(List.get_child(0), "Light")
	elif not payload.has("name"):
		return
	elif payload.name == "service_coil_test_start":
		if not List:
			return
		select_option(List.get_node(payload.coil_name), "Coil")
	elif payload.name == "service_coil_test_stop":
		self._exit_test()
	elif payload.name == "service_light_test_start":
		if not List:
			return
		select_option(List.get_node(payload.light_name), "Light")
		$instructions.text = "Color: %s" % payload.test_color
	elif payload.name == "service_light_test_stop":
		self._exit_test()

func select_option(target: Button, category: String) -> void:
	if target and not target.has_focus():
		target.grab_focus()
		$coil_label.text = "%s: %s" % [category, target.text]
		$coil_number.text = "Address: %s" % target.tooltip_text

func _exit_test():
	var parent = self.get_parent()
	while parent:
		if parent is UtilitiesPage:
			parent.deselect_child()
			break
		parent = parent.get_parent()
	return
