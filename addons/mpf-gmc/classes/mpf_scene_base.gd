@tool
class_name MPFSceneBase
extends Control

## The parent class of MPFSlide and MPFWidget that manages entry and exit behavior.
## Should not be used directly, implement MPFSlide or MPFWidget instead.

const CoreAnimation = { "CREATED": "created", "ACTIVE": "active", "INACTIVE": "inactive", "REMOVED": "removed" }

var priority: int = 0
var context: String
var key: String
@warning_ignore("shadowed_global_identifier")
var log: GMCLogger
var _expirations: Dictionary = {}
var _updaters: Array = []

var current_animation: String:
	get: return self.animation_player.current_animation if self.animation_player else ""
var animation_finished:
	get:
		@warning_ignore("incompatible_ternary")
		return self.animation_player.animation_finished if self.animation_player else null

## An AnimationPlayer node containing standard animations.
##
## Define animations with any of the following names for them to
## be automatically played at the corresponding time.
## [br][br]
## [code]created[/code] - When the node is instantiated and added to the display[br]
## [code]active[/code] - When the node is the highest-priority in the stack[br]
## [code]inactive[/code] - When the node is no longer highest-priority in the stack[br]
## [code]removed[/code] - When the node is removed from the display.[br]
## [br]
## If both 'created' and 'active' are defined and occur simultaneously,
## 'created' will be used. If both 'inactive' and 'removed' are defined
## and occur simultaneously, 'removed' will be used.
@export var animation_player: AnimationPlayer

func initialize(n: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	# The node name attribute is the name of the root node, which could be
	# anything or case-sensitive. Set an explicit key instead, using the name.
	self.key = settings["key"] if settings.get("key") else n
	self.priority = settings['priority'] + p if settings.get('priority') else p
	self.context = settings["custom_context"] if settings.get('custom_context') else c
	# Wait for the child variables to initialize themselves
	await self.ready
	# Update any child variables with the initial state
	self.action_update(settings, kwargs)
	# Play a created animation, if applicable
	self._trigger_animation(CoreAnimation.CREATED)

func _enter_tree():
	# Create a log
	self.log = preload("res://addons/mpf-gmc/scripts/log.gd").new(self.name)

func _exit_tree() -> void:
	for timer in self._expirations.values():
		if is_instance_valid(timer):
			timer.stop()

func process_action(child_name: String, children: Array, action: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	self.log.debug("Action '%s' called with name '%s' and settings: %s", [action, child_name, settings])
	var child: MPFSceneBase
	var ckey = settings['key'] if settings.get('key') else child_name
	for ch in children:
		if ch.key == ckey:
			child = ch
			break
	match action:
		"play":
			if not child:
				child = self.action_play(child_name, settings, c, p, kwargs)
		"queue", "queue_first", "queue_immediate":
			self.action_queue(action, child_name, settings, c, p, kwargs)
			child = null
		"remove":
			if child:
				self.action_remove(child)
		"update":
			if child:
				child.action_update(settings, kwargs)
		"method":
			if child and child.has_method(settings.method):
				var callable = Callable(child, settings.method)
				callable.call(settings, kwargs)
	if child and settings.expire:
		self._create_expire(child, settings.expire)

func action_play(_child_name: String, _settings: Dictionary, _context: String, _priority: int = 0, _kwargs: Dictionary = {}):
	assert(false, "Method 'action_play' must be overridden in child classes of MPFSceneBase")

func action_remove(_widget: Node) -> void:
	assert(false, "Method 'action_remove' must be overridden in child classes of MPFSceneBase")

func action_queue(_action: String, _slide_name: String, _settings: Dictionary, _context: String, _priority: int = 0, _kwargs: Dictionary = {}):
	assert(false, "Method 'action_queue' must be overridden in child classes of MPFSceneBase")

func action_update(settings: Dictionary, kwargs: Dictionary = {}):
	for c in self._updaters:
		c.update(settings, kwargs)

func register_updater(node):
	if self._updaters.find(node) == -1:
		self._updaters.append(node)

func remove_updater(node):
	if node in self._updaters:
		self._updaters.erase(node)

func on_active():
	if self._trigger_animation(CoreAnimation.ACTIVE):
		return self.animation_player.animation_finished

func remove(with_animation=true):
	if with_animation:
		if self._trigger_animation(CoreAnimation.REMOVED):
			await self.animation_player.animation_finished
			self.log.info("Removal animation complete, removing now")
	# Immediately cancel any created/active animations
	if self.current_animation in [CoreAnimation.CREATED, CoreAnimation.ACTIVE]:
		self.animation_player.stop()
	self.get_parent().remove_child(self)
	self.queue_free()

func _trigger_animation(animation_name: String) -> bool:
	if not self.animation_player:
		return false
	# Created takes priority over active
	if self.animation_player.current_animation == CoreAnimation.CREATED and animation_name == CoreAnimation.ACTIVE:
		return true
	# Removed takes priority over inactive
	if self.animation_player.current_animation == CoreAnimation.REMOVED and animation_name == CoreAnimation.INACTIVE:
		return true
	if self.animation_player.has_animation(animation_name):
		self.animation_player.stop()
		self.log.info("Playing animation %s" % animation_name)
		self.animation_player.play(animation_name)
		return true
	return false

func _create_expire(child: MPFSceneBase, expiration_secs: float) -> void:
	# If there is already a timer for this child to expire, reset it
	if self._expirations.has(child.key):
		self._expirations[child.key].start(expiration_secs)
		return

	var timer = Timer.new()
	timer.wait_time = expiration_secs
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(self._on_expire.bind(child, timer))
	self.add_child(timer)
	self._expirations[child.key] = timer

func _on_expire(child, timer: Timer) -> void:
	# This expiration may come after the child was removed for other reasons
	if is_instance_valid(child):
		self._expirations.erase(child.key)
		self.action_remove(child)
	if is_instance_valid(timer):
		self.remove_child(timer)
		timer.queue_free()
