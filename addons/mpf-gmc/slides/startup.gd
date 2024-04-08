extends Node
class_name MPFStartup

var loader: ResourceLoader
const time_max := 100  # ms to block thread


const preload_assets := []
var total_asset_size := preload_assets.size()
var error := false
var is_virtual_mpf := false
var mpf_attempts := 0

# For convenience, toggles that can be set in the editor
@export var mute_sounds: bool = false
@export var log_debug: bool = false
@export var log_verbose: bool = false
@export var spawn_mpf: bool = false

# Set the log levels on init so that subsequent LoggingNodes can inherit the
# default log level when they are instantiated.
func _init() -> void:
  # NOTE: All args must start with DOUBLE DASH for Godot to pass them through
  var args: PackedStringArray = OS.get_cmdline_args()
  if "--no-sound" in args or mute_sounds:
    AudioServer.set_bus_mute(0, true)
  if "--V" in args or log_verbose:
    MPF.log.setLevel(MPF.log.VERBOSE)
  elif "--v" in args or log_debug:
    MPF.log.setLevel(MPF.log.DEBUG)
  # Else here so that we can still verbose in prod
  elif "--prod" in args:
    MPF.log.setLevel(MPF.log.WARNING)
  if "--fs" in args or "--prod" in args:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _ready() -> void:
  # Attach the build version number to the launch screen
  var version: String
  if ResourceLoader.exists("res://version.gd"):
    var v = load("res://version.gd")
    version = "%s %s.%s.%s" % [v.PREFIX, v.MAJOR, v.MINOR, v.PATCH]
  else:
    version = "Developer Build"
  MPF.game.version = version
  $version.text = version
  MPF.log.info("Loading GMC: %s", $version.text)
  $error_main.visible = false
  $error_sub.visible = false
  $status_main.visible = false
  $status_sub.visible = false

  # NOTE: All args must start with DOUBLE DASH for Godot to pass them through
  var args: PackedStringArray = OS.get_cmdline_args()

  if OS.has_feature("spawn_mpf") or "--spawn-mpf" in args or spawn_mpf:
    $MPFSpawnTimer.connect("timeout", self._check_mpf)
    self._spawn_mpf()
  # Build engines aren't allowed to generate checksum, so this is an else-if
  elif "--checksum" in args:
    MPF.log.info("Generating checksum...")
    var checksum: String = self._checksum()
    print(checksum)
    return

  if error:
    return

  #$spinner.visible = true
  #$spinner.play()
  self.set_status("Loading Assets")
  # Store a process id
  var pid = OS.get_process_id()
  var pfile = FileAccess.open("user://pid", FileAccess.WRITE)
  if pfile:
    pfile.store_string("%s" % pid)
    pfile.close()
  else:
    printerr("Unable to write pid file")
  MPF.server.listen()
  self.queue_asset()
  # Use the "options" signal to get updates about MPF booting
  MPF.server.connect("options", self._on_server)

func queue_asset() -> void:
  if preload_assets.size() == 0:
    MPF.log.debug("Asset loading complete.")
    # Only clear the status if we're don't have a different status
    if "Loading Assets" in self.get_status():
      if MPF.server.mpf_pid:
        self.set_status("Starting MPF%s..." % " Virtual" if is_virtual_mpf else "")
      else:
        self.set_status("Waiting for MPF")
    loader = null
    return
  MPF.log.debug("Loading asset %s / %s", [total_asset_size + 1 - preload_assets.size(), total_asset_size])
  ResourceLoader.load_threaded_request("res://assets/%s" % preload_assets.pop_back())

func _checksum(is_build_file: bool = false) -> String:
  var path := "%s/mpf_config.bundle" % ("." if is_build_file else "../dist")
  var result = []
  var exit_code = OS.execute("openssl", ["dgst", "-sha256", path], result, true, true)
  if exit_code != 0:
    MPF.log.error("Unable to validate MPF Bundle at %s, exit code %s", [path, exit_code])
    return "ERROR-%s" % exit_code
  var checksum: String = result[0].get_slice(" ", 1)
  return checksum.strip_edges()

func set_error(main: String = "", sub: String = "") -> void:
  $error_main.text = main
  $error_sub.text = sub
  $error_main.visible = false
  $error_sub.visible = false
  error = true
  #$spinner.visible = false
  $status_main.visible = false
  $status_sub.visible = false

func set_status(value: String = "", sub_value: String = "") -> void:
  $status_main.visible = false
  $status_sub.visible = sub_value != ""
  $status_main.text = value
  $status_sub.text = sub_value
  $error_main.visible = false
  $error_sub.visible = false

func get_status() -> String:
  return $status_main.text

func _on_server(payload) -> void:
  var message
  match payload.cmd:
    "hello":
      message = "Connected to MPF"
    _:
      pass
  if message:
    set_status(message)

func _process(_delta) -> void:
  if loader == null or error == true:
    set_process(false)
    return

  var t = Time.get_ticks_msec()
  # Use "time_max" to control for how long we block this thread.
  while Time.get_ticks_msec() < t + time_max:
    # Poll the loader.
    var err = loader.poll()
    if err == ERR_FILE_EOF: # Finished loading.
      queue_asset()
      break
    # So far no asset requires so much time that it takes multiple polls. But
    # if more video/cutscenes come in, this may be useful.
    # elif err == OK:
      # Log.debug(" - progress %s / %s", [loader.get_stage(), loader.get_stage_count()])
    else: # Error during loading.
      MPF.log.error("Error loading asset: %s", err)
      break

func switch_scene(scene_name: String) -> void:
  get_tree().change_scene(scene_name)

func _notification(what):
  # In the event of an exit before MPF connects, kill MPF
  if what == NOTIFICATION_WM_CLOSE_REQUEST:
      if MPF.server.mpf_pid:
        OS.kill(MPF.server.mpf_pid)
      # The below line is the default behavior
      get_tree().quit()
  # In the event of a crash, also kill MPF
  elif what == MainLoop.NOTIFICATION_CRASH:
    MPF.log.error("GMC is about to crash!!")
    get_tree().quit(7)

func _spawn_mpf():
  var args: PackedStringArray = OS.get_cmdline_args()
  var machine_path := "/home/pi/sov"
  var production_flag := "-P"
  # Allow dev environment to simulate mpf spawning:
  if "--spawn-mpf" in args:
    machine_path = "/Users/Anthony/git/swords-of-vengeance/machine"
    production_flag = ""
  # Allow override of spawning mpf (but don't break the if/else block)
  if not "--no-mpf" in args:
    var mpf_args = ["-m", "mpf", machine_path, "-t", ""]
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
    MPF.server.mpf_pid = OS.execute("pypy", mpf_args, [], false)
    $MPFSpawnTimer.start()

func _check_mpf():
  # Detect if the pid is still alive
  var output = []
  OS.execute("ps", [MPF.server.mpf_pid, "-o", "state="], output, true, true)

  if output and output[0].strip_edges() == "Z":
    mpf_attempts += 1
    if mpf_attempts <= 5:
      set_status("MPF Failed to Start, Retrying (%s/5)" % mpf_attempts)
      self._spawn_mpf()
    else:
      set_error("ERROR: Unable to start MPF.")
