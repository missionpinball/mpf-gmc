# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License


class_name BCPServer
extends Node

signal bonus(payload)
signal mpf_timer(payload)
signal options(payload)
signal player_var(value, prev_value, change, player_num)
signal service(payload)

# A list of events that trigger their own automatic signals
var auto_signals = []
# A list of event names to register in MPF
var registered_events = []
# A logger instance and possible private instance
var logger
var _logger
# The port we will listen on
var port := 5052
# The polling frequency to poll the server for data
var poll_fps: int = 120
# The process ID for a spawned MPF
var mpf_pid: int

# A library of static methods for parsing the incoming BCP data
var _bcp_parse = preload("bcp_parse.gd")
# A connected MPF Client
var _client: StreamPeerTCP
# Our WebSocketServer instance
var _server: TCPServer = TCPServer.new()
# A separate thread for running the BCP Server
var _thread: Thread

# A mutex for managing threadsafe operations
@onready var _mutex := Mutex.new()

###
# Built-in virtual methods
###

func _ready() -> void:
  # Wait until a server is actively listening before polling for clients
  set_process(false)

func _exit_tree():
  self.stop(true)

func _input(ev: InputEvent) -> void:
  if not ev.is_class("InputEventKey"):
    return
  elif Input.is_action_pressed("ui_cancel"):
    # Cannot use quit() method because it won't cleanly shut down threads
    # Instead, send a notification to the main thread to shut down
    get_tree().notification(NOTIFICATION_WM_CLOSE_REQUEST)
    return

  for action in InputMap.get_actions():
    if ev.is_action(action):
      get_tree().get_root().set_input_as_handled()
      var ev_payload: PackedStringArray = action.split("?")
      if ev_payload.size() > 1:
        # Godot InputMap does not support the = and : characters,
        # which the BCP protocol requires. InputMap values must be
        # bound using % and $ as the respective substitutions.
        ev_payload[1] = ev_payload[1].replace("%","=").replace("$",":")

      match ev_payload[0]:
        "event":
          if ev.is_action_pressed(action):
            _send("trigger?name=%s" % ev_payload[1])
        "switch":
          var message: String
          # If the switch has no state, set one based on the key press state
          if not "state" in ev_payload[1]:
            if ev.is_action_pressed(action):
              message = "switch?name=%s&state=1" % ev_payload[1]
            elif ev.is_action_released(action):
              message = "switch?name=%s&state=0" % ev_payload[1]
            else:
              return
          elif ev.is_action_pressed(action):
              message = "switch?name=%s" % ev_payload[1]
          if message:
            _send(message)
      self.on_input(ev_payload)
      return


func _process(_delta: float) -> void:
  if not _client and _server.is_connection_available() == true:
    MPF.log.info("Client connection is available!")
    _client = _server.take_connection()
    var err = _thread.start(self._thread_poll, 0)
    if err != OK:
      MPF.log.error("Error spawning BCP poll thread: %s", err)
    else:
      MPF.log.info("Client connected!")
      # No need to run _process() while we have an active client connection
      set_process(false)

###
# Public Methods
###

func deferred_game(method: String, result=null) -> void:
  var callable = Callable(MPF.game, method)
  if result:
    callable.call(result)
  else:
    callable.call()

func deferred_mc(method: String, result=null) -> void:
  var callable = Callable(MPF.mc, method)
  if result:
    callable.call(result)
  else:
    callable.call()

func deferred_game_player(result) -> void:
  MPF.game.update_player(result)

func deferred_scene(scene_res: String) -> void:
  get_tree().change_scene_to_file(scene_res)


func deferred_scene_to(scene_pck: Resource) -> void:
  get_tree().change_scene_to_packed(scene_pck)

## Call this method from your main scene to open a port for MPF connections
func listen() -> void:
  _thread = Thread.new()
  var err = _server.listen(port)
  if err != OK:
    MPF.log.error("Unable to start GMC: %s", err)
    # The _process() method polls for client connections. If the server
    # isn't listening, there's no reason to poll for clients.
    set_process(false)
    return
  MPF.log.info("GMC listening on port %s", port)
  set_process(true)

## Post an event to MPF
func send_event(event_name: String) -> void:
  _send("trigger?name=%s" % event_name)

## Send a specialized Service Mode command to MPF
func send_service(subcommand: String, values: PackedStringArray = []) -> void:
  var suffix: String = "&values=%s" % ",".join(values) if values else ""
  self._send("service?subcommand=%s&sort=bool:false%s" % [subcommand, suffix])

## Set a machine variable in MPF
func set_machine_var(name: String, value) -> void:
  self._send("set_machine_var?name=%s&value=%s" % [name, self.wrap_value_type(value)])

## Disconnect the BCP server
func stop(is_exiting: bool = false) -> void:
  MPF.log.info("Shutting down BCP Server and %s", "will not restart" if is_exiting else "awaiting new connection")
  # Lock the mutex to prevent the BCP thread from polling
  _mutex.lock()
  _server.stop()
  if _client:
    # Say goodbye to MPF!
    _send("goodbye")
    _client.disconnect_from_host()
    _client = null
  _mutex.unlock()

  if _thread and _thread.is_started():
    _thread.wait_to_finish()

  if not is_exiting:
    self.on_disconnect()
    # Set an exit code so we know MPF is the cause of the exit
    get_tree().quit(6)
    # TODO: Add a configuration option to exit-on-disconnect and if false,
    # call self.deferred_scene("res://Main.tscn") instead of quit()

# Use the BCP syntax to define the type
func wrap_value_type(value) -> String:
  match typeof(value):
    TYPE_BOOL:
      value = "bool:%s" % value
    TYPE_INT:
      value = "int:%s" % value
    TYPE_FLOAT:
      value = "float:%s" % value
  return value

###
# The following public methods can be overridden in a subclass for game-specific behavior
###

func on_ball_start(ball, player_num) -> void:
  pass

func on_ball_end() -> void:
  pass

func on_connect() -> void:
  pass

func on_disconnect() -> void:
  pass

func on_input(event_payload: PackedStringArray) -> void:
  pass

func on_message(message: Dictionary) -> Dictionary:
  return message

func on_mode_start(mode_name: String) -> void:
  pass

func on_stop() -> void:
  pass

###
# Private Methods
###

func _send(message: String) -> void:
  if not _client:
    return
  MPF.log.debug("Sending BCP Message: %s" % message)
  _client.put_data(("%s\n" % message).to_ascii_buffer())


func _thread_poll(_userdata=null) -> void:
  # TBD: What is the optimal polling rate for the BCP client?
  var start = Time.get_ticks_msec()
  var delay = 1000/poll_fps
  while _client:
    # If the mutex is locked, the system is shutting down
    if not _mutex.try_lock():
      return
    var bytes = _client.get_available_bytes()
    if not bytes:
      OS.delay_msec(delay)
    else:
      var messages := _client.get_string(bytes).split("\n")
      for message_raw in messages:
        if message_raw.is_empty():
          continue
        MPF.log.verbose("Received BCP command: %s", message_raw)
        var message: Dictionary = _bcp_parse.parse(message_raw)
        MPF.log.info("Decoded BCP message: %s", message)
        # Log any errors
        if message.has("error"):
          MPF.log.error(message.error)

        # Known signals can be broadcast with arbitrary payloads
        if message.cmd in auto_signals:
          message.cmd = "signal"

        # If on_message() returns null, the message has been handled
        # and no further action is necessary.
        if self.on_message(message) == null:
          continue

        match message.cmd:
          "ball_end":
            call_deferred("on_ball_end")
          "ball_start":
            call_deferred("on_ball_start", message.ball, message.player_num)
          "goodbye":
            _send("goodbye")
            call_deferred("stop")
            # Resume polling for new client connections
            set_process(true)
          "hello":
            _send("hello")
            call_deferred("on_connect")
          "list_coils":
            call_deferred("emit_signal", "service", message)
          "list_lights":
            call_deferred("emit_signal", "service", message)
          "list_switches":
            call_deferred("emit_signal", "service", message)
          "machine_variable":
            call_deferred("deferred_game", "update_machine", message)
          "mode_list":
            call_deferred("deferred_game", "update_modes", message)
          "mode_start":
            if message.name == "game":
              call_deferred("deferred_game", "reset")
            call_deferred("on_mode_start", message.name)
          "mode_stop":
            pass
          "player_added":
            call_deferred("deferred_game", "add_player", message)
          "player_turn_start":
            call_deferred("deferred_game", "start_player_turn", message)
          "player_variable":
            call_deferred("deferred_game_player", message)
          "reset":
            MPF.log.info("Resetting connection with BCP client")
            _send("reset_complete")
            # Core MPF events
            _send("monitor_start?category=core_events")
            _send("monitor_start?category=service_events")
            _send("monitor_start?category=modes")
            _send("monitor_start?category=player_vars")
            _send("monitor_start?category=machine_vars")
            # Standard events
            _send("register_trigger?event=bonus")
            _send("register_trigger?event=high_score_enter_initials")
            _send("register_trigger?event=high_score_award_display")
            # Custom events
            for e in self.registered_events + self.auto_signals:
              _send("register_trigger?event=%s" % e)
          "service":
            call_deferred("emit_signal", "service", message)
          "service_mode_entered":
            call_deferred("deferred_scene", "res://modes/Service.tscn")
          "settings":
            call_deferred("deferred_game", "update_settings", message)
          "signal":
            call_deferred("emit_signal", message.name, message)
          "slides_play":
            call_deferred("deferred_mc", "play_slides", message)
          "sounds_clear":
            pass
          "sounds_play":
            call_deferred("deferred_mc", "play_sounds", message)
          "timer":
            call_deferred("emit_signal", "mpf_timer", message)
          "widgets_play":
            call_deferred("deferred_mc", "play_widgets", message)
          _:
            MPF.log.warn("No action defined for BCP message %s" % message_raw)
    # Free the mutex in case the main thread is trying to shut down
    _mutex.unlock()
