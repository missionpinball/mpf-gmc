@tool
extends LoggingNode
class_name GMCProcess

var mpf_pid
var is_virtual_mpf := true
var mpf_attempts := 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var args: PackedStringArray = OS.get_cmdline_args()
	if OS.has_feature("spawn_mpf") or "--spawn_mpf" in args or true:
		self._spawn_mpf()

func launch_mpf():
	self._spawn_mpf()

func _spawn_mpf():
	var launch_timer = Timer.new()
	launch_timer.connect("timeout", self._check_mpf)
	self.add_child(launch_timer)
	var exec: String = "/Users/Anthony/mpf080/bin/mpf"
	var args: PackedStringArray = OS.get_cmdline_args()
	var machine_path := "/Users/Anthony/Git/whitewater-harley"
	var production_flag := "" # "-P"
	# Allow dev environment to simulate mpf spawning:
	if "--spawn-mpf" in args:
		machine_path = "/Users/Anthony/Git/whitewater-harley"
		production_flag = ""
	# Allow override of spawning mpf (but don't break the if/else block)
	if not "--no-mpf" in args:
		var mpf_args = [machine_path, "-x", "-t"]
		# Doesn't like an empty string, so only include if present
		if production_flag:
			mpf_args.append(production_flag)

		# Generate a timestamped MPF log in the same place as the GMC log
		# mpf_YYYY-MM-DD_HH.mm.ss.log
		var log_path_base = "%s/logs" % OS.get_user_data_dir()
		var dt = Time.get_datetime_dict_from_system()
		var log_file_name = "mpf_%04d-%02d-%02d_%02d.%02d.%02d.log" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
		mpf_args.push_back("-l")
		mpf_args.push_back("%s/%s" % [log_path_base, log_file_name])

		if "--x" in args:
			mpf_args.push_back("-x")
			is_virtual_mpf = true
		if "--v" in args or "--V" in args:
			mpf_args.push_back("-v")
		print(mpf_args)
		MPF.server.mpf_pid = OS.create_process(exec, mpf_args, false)
		#var output = []
		#MPF.server.mpf_pid = OS.execute(exec, mpf_args, output, true, true)
		#print(output)
		launch_timer.start(5)

func _check_mpf():
	# Detect if the pid is still alive
	print("Checking MPF PID...")
	var output = []
	OS.execute("ps", [MPF.server.mpf_pid, "-o", "state="], output, true, true)
	print(output)
	if output and output[0].strip_edges() == "Z":
		mpf_attempts += 1
		if mpf_attempts <= 5:
			print("MPF Failed to Start, Retrying (%s/5)" % mpf_attempts)
			self._spawn_mpf()
		else:
			printerr("ERROR: Unable to start MPF.")
