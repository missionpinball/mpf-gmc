# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License


# TODO: Define a type for the response dictionary
static func parse(message: String) -> Dictionary:
  var cmd: String
  var result = {}

  if "?" in message:
    var split_message := message.split("?")
    cmd = split_message[0]
    result = string_to_obj(split_message[1], cmd)
  else:
    cmd = message
  if cmd == "trigger":
    # This creates a standard signal "mpf_timer" so any
    # timer event doesn't need an individual signal
    if result.name.substr(0,6) == "timer_":
      cmd = "timer"
    elif result.name.substr(0,8) == "service_" and result.name != "service_mode_entered":
      cmd = "service"
    else:
      cmd = result.name

  result.cmd = cmd
  return result

static func string_to_obj(message: String, cmd: String) -> Dictionary:
  var result := {}
  if message.substr(0, 5) == "json=":
    var json = JSON.parse_string(message.substr(5))
    if json == null:
      result.error = "Error %s parsing trigger: %s" % [json.error, message]
      return result
    else:
      return json

  var chunks = message.split("&")
  for chunk in chunks:
    # This algorithm looks verbose but it's the fastest. I tested.
    var pair = chunk.split("=")
    var raw_value: String = pair[1]
    if ":" in raw_value:
      # Basic typesetting
      if raw_value.substr(0,4) == "int:":
        result[pair[0]] = int(raw_value.substr(4))
      elif raw_value.substr(0,6) == "float:":
        result[pair[0]] = float(raw_value.substr(6))
      elif raw_value.substr(0,5) == "bool:":
        result[pair[0]] = raw_value.substr(5) == "True"
      else:
        result[pair[0]] = raw_value
    else:
      result[pair[0]] = raw_value.uri_decode()
  return result
