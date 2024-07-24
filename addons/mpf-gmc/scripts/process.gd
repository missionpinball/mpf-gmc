extends LoggingNode
class_name GMCProcess

signal mpf_spawned(result)
signal mpf_log_created(log_file_path)

const MAX_MPF_ATTEMPTS = 3
const ATTEMPT_WAIT_TIME_SECS = 3

var mpf_pid: int
var mpf_attempts := 0

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	if OS.has_feature("spawn_mpf") or "--spawn_mpf" in args or MPF.get_config_value("mpf", "spawn_mpf", false):
		self._spawn_mpf()

func launch_mpf():
	self._spawn_mpf()

func _spawn_mpf():
	self.log.info("Spawning MPF process...")
	MPF.server.set_status(MPF.server.ServerStatus.LAUNCHING)
	var launch_timer = Timer.new()
	launch_timer.name = "SpawnMpfLaunchTimer"
	launch_timer.one_shot = true
	launch_timer.connect("timeout", self._check_mpf)
	self.add_child(launch_timer)
	var exec: String = MPF.get_config_value("mpf", "executable_path", "")
	if not exec:
		self.log.error("No executable path defined, unable to spawn MPF.")
		MPF.server.set_status(MPF.server.ServerStatus.ERROR)
		return
	var args: PackedStringArray = OS.get_cmdline_args()
	var machine_path: String = MPF.get_config_value("mpf", "machine_path",
		ProjectSettings.globalize_path("res://") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir())

	var exec_args: PackedStringArray
	if MPF.get_config_value("mpf", "executable_args", ""):
		exec_args = PackedStringArray(MPF.get_config_value("mpf", "executable_args").split(" "))

	var mpf_args = PackedStringArray([machine_path, "-t"])
	if MPF.get_config_value("mpf", "mpf_args", ""):
		mpf_args.append_array(MPF.get_config_value("mpf", "mpf_args").split(" "))
	if MPF.get_config_value("mpf", "virtual", false):
		mpf_args.append("-x")
	if MPF.get_config_value("mpf", "verbose", false):
		mpf_args.append("-vV")

	# Generate a timestamped MPF log in the same place as the GMC log
	# mpf_YYYY-MM-DD_HH.mm.ss.log, unless one is specified
	var log_file_path
	if "-l" in mpf_args:
		log_file_path = mpf_args[mpf_args.find("-l") + 1]
	else:
		var log_path_base = "%s/logs" % OS.get_user_data_dir()
		var dt = Time.get_datetime_dict_from_system()
		var log_file_name = "mpf_%04d-%02d-%02d_%02d.%02d.%02d.log" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
		log_file_path = "%s/%s" % [log_path_base, log_file_name]
		mpf_args.push_back("-l")
		mpf_args.push_back(log_file_path)

	if "--v" in args or "--V" in args:
		mpf_args.push_back("-v")

	# Empty values break the args list, so only add if necessary
	if exec_args:
		mpf_args = exec_args + mpf_args

	self.log.info("Executing %s with args [%s]", [exec, ", ".join(mpf_args)])
	mpf_pid = OS.create_process(exec, mpf_args, false)
	if mpf_pid == -1:
		MPF.server.set_status(MPF.server.ServerStatus.ERROR)
		self._debug_mpf(exec, mpf_args)
		return

	EngineDebugger.send_message("mpf_log_created:process", [log_file_path])
	launch_timer.start(ATTEMPT_WAIT_TIME_SECS)

	# Only subscribe on the first loop through
	if mpf_attempts > 0:
		return

	var result = await self.mpf_spawned
	self.log.debug("MPF spawn returned result %s" % result)
	if result == -1:
		MPF.server.set_status(MPF.server.ServerStatus.ERROR)
		self._debug_mpf(exec, mpf_args)

func _check_mpf():
	# Detect if the pid is still alive
	self.log.debug("Checking MPF PID %s...", mpf_pid)
	var output = []
	OS.execute("ps", [mpf_pid, "-o", "state="], output, true, true)
	if not output:
		return
	var result = output[0].strip_edges()
	if result  == "Z":
		mpf_attempts += 1
		if mpf_attempts <= MAX_MPF_ATTEMPTS:
			self.log.info("MPF Failed to Start, Retrying (%d/%d)", [mpf_attempts, MAX_MPF_ATTEMPTS])
			self._spawn_mpf()
		else:
			MPF.server.set_status(MPF.server.ServerStatus.ERROR)
			self.mpf_spawned.emit(-1)
	elif result == "Ss":
		self.mpf_spawned.emit(1)
	else:
		self.log.warning("Unknown process status '%s'", result)
		self.mpf_spawned.emit(0)

## Run the mpf spawn synchronously and capture the output to
## assist in debugging why it failed to start.
func _debug_mpf(exec: String, args: Array):
	var output = []
	OS.execute(exec, args, output, true)
	self.log.error("Unable to start MPF:\n%s" % "\n".join(output))

func _exit_tree():
	if mpf_pid:
		OS.execute("kill", [mpf_pid])
