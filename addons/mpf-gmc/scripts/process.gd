@tool
extends LoggingNode
class_name GMCProcess

var mpf_pid: int
var mpf_attempts := 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var args: PackedStringArray = OS.get_cmdline_args()
	if OS.has_feature("spawn_mpf") or "--spawn_mpf" in args or MPF.config.get_value("mpf", "spawn_mpf", false):
		self._spawn_mpf()

func launch_mpf():
	self._spawn_mpf()

func _spawn_mpf():
	self.log.info("Spawning MPF process...")
	MPF.server.set_status(MPF.server.ServerStatus.LAUNCHING)
	var launch_timer = Timer.new()
	launch_timer.connect("timeout", self._check_mpf)
	self.add_child(launch_timer)
	var exec: String = MPF.config.get_value("mpf", "executable_path", "")
	if not exec:
		self.log.error("No executable path defined, unable to spawn MPF.")
		MPF.server.set_status(MPF.server.ServerStatus.ERROR)
		return
	var args: PackedStringArray = OS.get_cmdline_args()
	var machine_path: String = MPF.config.get_value("mpf", "machine_path",
		ProjectSettings.globalize_path("res://") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir())

	var exec_args: PackedStringArray
	if MPF.config.get_value("mpf", "executable_args", ""):
		exec_args = PackedStringArray(MPF.config.get_value("mpf", "executable_args").split(" "))

	var mpf_args = PackedStringArray([machine_path, "-t"])
	if MPF.config.get_value("mpf", "mpf_args", ""):
		mpf_args.append_array(MPF.config.get_value("mpf", "mpf_args").split(" "))
	if MPF.config.get_value("mpf", "virtual", false):
		mpf_args.append("-x")

	# Generate a timestamped MPF log in the same place as the GMC log
	# mpf_YYYY-MM-DD_HH.mm.ss.log
	var log_path_base = "%s/logs" % OS.get_user_data_dir()
	var dt = Time.get_datetime_dict_from_system()
	var log_file_name = "mpf_%04d-%02d-%02d_%02d.%02d.%02d.log" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
	mpf_args.push_back("-l")
	mpf_args.push_back("%s/%s" % [log_path_base, log_file_name])

	if "--v" in args or "--V" in args:
		mpf_args.push_back("-v")

	# Empty values break the args list, so only add if necessary
	if exec_args:
		mpf_args = exec_args + mpf_args

	self.log.info("Executing %s with args [%s]", [exec, ", ".join(mpf_args)])
	mpf_pid = OS.create_process(exec, mpf_args, false)
	#var output = []
	#MPF.server.mpf_pid = OS.execute(exec, mpf_args, output, true, true)
	#print(output)
	launch_timer.start(5)

func _check_mpf():
	# Detect if the pid is still alive
	self.log.debug("Checking MPF PID %s..." % mpf_pid)
	var output = []
	OS.execute("ps", [mpf_pid, "-o", "state="], output, true, true)
	self.log.debug(" ".join(output))
	if output and output[0].strip_edges() == "Z":
		mpf_attempts += 1
		if mpf_attempts <= 5:
			self.log.info("MPF Failed to Start, Retrying (%s/5)" % mpf_attempts)
			self._spawn_mpf()
		else:
			MPF.server.set_status(MPF.server.ServerStatus.ERROR)
			self.log.error("ERROR: Unable to start MPF.")

func _exit_tree():
	if mpf_pid:
		OS.execute("kill", [mpf_pid])
