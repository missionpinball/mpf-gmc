# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License


# TODO: Define a type for the response dictionary
static func parse(message: String) -> Dictionary:
	var cmd: String
	var result = {}

	if "?" in message:
		var split_message := message.split("?", true, 1)
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

static func string_to_obj(message: String, _cmd: String) -> Dictionary:
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
			var type_hint = raw_value.get_slice(":", 0)
			var hint_value = raw_value.get_slice(":", 1)
			# Basic typesetting
			match type_hint:
				"int":
					result[pair[0]] = int(hint_value)
				"float":
					result[pair[0]] = float(hint_value)
				"bool":
					result[pair[0]] = hint_value == "True"
				"NoneType":
					result[pair[0]] = null
				"_":
					push_warning("Unknown type hint %s in message %s" % [raw_value, message])
					result[pair[0]] = hint_value
		else:
			result[pair[0]] = raw_value.uri_decode()
	return result

static func encode_event_args(event_name: String, args: Dictionary) -> String:
	# Always include the event name in the args
	args["name"] = event_name
	var params = []
	var needs_json = false
	for k in args.keys():
		var v = args[k]
		var arg_type = typeof(args[k])
		var prefix: String = ""
		match arg_type:
			TYPE_STRING:
				# Can't send back 'context' because it interferes with triggering players
				if k == "context":
					k = "original_context"
				elif k == "calling_context":
					k = "original_calling_context"
			# Some types need to be prefixed for MPF to type them appropriately
			TYPE_INT:
				prefix = "int:"
			TYPE_FLOAT:
				prefix = "float:"
			TYPE_BOOL:
				prefix = "bool:"
			TYPE_ARRAY, TYPE_DICTIONARY:
				needs_json = true
				break
		params.append("%s=%s%s" % [k,prefix,v])

	# If anything needs json, send the whole thing as json
	if needs_json:
		return "json=%s" % JSON.stringify(args)

	return "&".join(params)
