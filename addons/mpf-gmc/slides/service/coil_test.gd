extends Control

export (String) var device_type
onready var coil_map := []
# Don't instantiate the List ref until it's ready to populate
# because often the first test_start command arrives before the list
onready var List: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
  Server.connect("service", self, "_on_service")
  Server.send_service("list_%s" % device_type, ["name","label","number"])

func _on_service(payload):
  # COILS
  if payload.cmd == "list_coils":
    List = $ScrollContainer/coil_list
    var list_button = load("res://service/List_Button.tscn")
    for coil in payload.coils:
      var list_item = list_button.instance()
      list_item.name = coil[0]  # name
      list_item.text = coil[1]  # label
      list_item.hint_tooltip = coil[2]  # number
      List.add_child(list_item)
    select_option(List.get_child(0), "Coil")
  elif payload.cmd == "list_lights":
    List = $ScrollContainer/coil_list
    var list_button = load("res://service/List_Button.tscn")
    for light in payload.lights:
      var list_item = list_button.instance()
      list_item.name = light[0]  # name
      list_item.text = light[1]  # label
      list_item.hint_tooltip = light[2][0] # number
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
    get_parent().get_parent().deselect_child()
  elif payload.name == "service_light_test_start":
    if not List:
      return
    select_option(List.get_node(payload.light_name), "Light")
    $instructions.text = "Color: %s" % payload.test_color
  elif payload.name == "service_light_test_stop":
    get_parent().get_parent().deselect_child()

func select_option(target: Button, category: String) -> void:
  if target and target != get_focus_owner():
    target.grab_focus()
    $coil_label.text = "%s: %s" % [category, target.text]
    $coil_number.text = "Address: %s" % target.hint_tooltip
