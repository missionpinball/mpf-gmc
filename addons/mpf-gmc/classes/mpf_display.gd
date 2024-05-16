@tool
class_name MPFDisplay
extends MPFSceneBase

## A container for slides and widgets. Each display is tracked separately and maintains its own stack of slides.

## If checked, slides played without a display target will be shown on this display.
@export var is_default: bool = false
## The scene to render on this display during startup
@export var initial_slide: PackedScene
## If not selected, this display will persist a removed slide until a new one arrives
@export var allow_empty: bool = false

# The slide stack is an array of slide nodes that are sorted by priority
var _slide_stack: Array = []
# The slides node is the parent container for the slide nodes rendered in the tree
var _slides: Control
var _current_slide: MPFSlide
# The queue of slides waiting to be played
var _queue: Array = []

func _ready() -> void:
	self._slides = Control.new()
	self._slides.set_anchors_preset(PRESET_FULL_RECT)
	self._slides.size_flags_horizontal = SIZE_EXPAND
	self._slides.size_flags_vertical = SIZE_EXPAND
	self.add_child(self._slides)
	if not self.initial_slide:
		return
	# The initial slide will be added as a child but not in the stack, so when
	# the stack is filled and calculated the initial will be removed
	self._slides.add_child(self.initial_slide.instantiate())
	MPF.server.connect("clear", self._on_clear)

func process_slide(slide_name: String, action: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	self.process_action(slide_name, self._slide_stack, action, settings, c, p, kwargs)

func process_widget(widget_name: String, action: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	var slide = self.get_slide(settings.get('slide'))
	# The requested slide may not exist
	if not slide:
		return
	slide.process_widget(widget_name, action, settings, c, p, kwargs)

func action_play(slide_name: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> MPFSlide:
	var slide = MPF.media.get_slide_instance(slide_name)
	assert(slide is MPFSlide, "Slide scenes must use (or extend) the MPFSlide script on the root node.")
	slide.initialize(slide_name, settings, c, p, kwargs)
	if settings.get("queue"):
		self._manage_queue(settings['queue'])
	self._slide_stack.append(slide)
	self._slides.add_child(slide)
	MPF.server.send_event("slide_%s_created" % slide.key)
	return slide

func action_queue(action: String, slide_name: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}):
	if settings.get("queue"):
		self._manage_queue(settings['queue'])
	var queue_entry = {
		"key": settings['key'] if settings.get('key') else slide_name,
		"slide_name": slide_name,
		"settings": settings,
		"context": c,
		"priority": p,
		"kwargs": kwargs,
		"expiration": 0
	}
	# Check for an expiration time
	if settings.get("max_queue_time"):
		queue_entry["expiration"] = Time.get_ticks_msec() + (1000 * settings['max_queue_time'])

	# Add this slide to the queue
	if not self._queue.size():
		self._queue.append(queue_entry)
	elif action == "queue":
		self._queue.push_back(queue_entry)
	else:
		self._queue.insert(1, queue_entry)
	# If there was no queue before or this in as immediate action, process the queue
	if self._queue.size() == 1 or action == "queue_immediate":
		return self._process_queue()

func update_stack(kwargs):
	self._update_stack(kwargs)

func action_remove(slide) -> void:
	self._slide_stack.erase(slide)
	self._update_stack()

func get_slide(slide_name):
	if not slide_name:
		return self._current_slide
	for s in self._slide_stack:
		if s.key == slide_name:
			return s

func _update_stack(kwargs: Dictionary = {}) -> void:
	# Sort the stack by priority
	self._slide_stack.sort_custom(
		func(a: MPFSlide, b: MPFSlide): return a.priority < b.priority
	)
	var persist_current = self.allow_empty == false and not self._slide_stack.size()
	# Update the children, rearranging and removing as necessary
	for s in self._slides.get_children():
		var idx = self._slide_stack.find(s)
		if idx == -1:
			# Don't remove the current slide if it needs to persist
			if persist_current and s == self._current_slide:
				s.set_meta("persisted", true)
				continue
			# Don't remove the current slide until we've handled the new one
			if s != self._current_slide:
				MPF.server.send_event("slide_%s_removed" % s.key)
				# Non-current slides don't get transitions out, remove immediately
				s.remove(false)
			# If this is in the queue, remove it as well
			if self._queue and s.key == self._queue[0].key:
				self._queue.pop_front()
				var new_queue = self._process_queue()
				# Restart this update with the new slide from the queue
				if new_queue:
					return self._update_stack(new_queue["kwargs"])
		else:
			self._slides.move_child(s, idx)

	if not self._slide_stack:
		if not persist_current:
			self._current_slide = null
		return

	var new_slide = self._slide_stack[-1]
	var old_slide = self._current_slide
	if new_slide != old_slide:
		new_slide.on_active()
		if old_slide:
			MPF.server.send_event("slide_%s_inactive" % old_slide.key)
		MPF.server.send_event_with_args("slide_%s_active" % new_slide.key, kwargs)
		self._current_slide = new_slide
		# If the old slide is removed, check for animations
		if old_slide and old_slide not in self._slide_stack:
			# Store the old slide key in case its removed
			var old_slide_key = old_slide.key
			# If the old slide is persisted, always put it at the bottom
			if old_slide.has_meta("persisted"):
				self._slides.move_child(old_slide, 0)
			# Let the outgoing slide wait for the incoming animation before removing
			if old_slide.priority < new_slide.priority and new_slide.current_animation:
				await new_slide.animation_finished
		   	# If the old slide is on top of the new one and has an outro, play it
			if is_instance_valid(old_slide):
				await old_slide.remove(old_slide.priority > new_slide.priority)
			MPF.server.send_event("slide_%s_removed" % old_slide_key)

func _manage_queue(action: String) -> void:
	if action == "clear":
		self._queue.resize(1)
	elif action == "clear_immediate":
		self._queue.clear()

func _process_queue():
	if not self._queue.size():
		return
	var now = Time.get_ticks_msec()
	while self._queue.size():
		var s = self._queue[0]
		if s["expiration"] and s["expiration"] < now:
			self._queue.pop_front()
		else:
			self.process_slide(s["slide_name"], "play", s["settings"], s["context"], s["priority"], s["kwargs"])
			return s

func _on_clear(context_name) -> void:
	# Track the top-most (i.e. currently active) queue item
	var top_queued = self._queue[0] if self._queue.size() else null
	self._queue = self._queue.filter(
		func(queue_entry): return queue_entry.context != context_name
	)
	# Filter all slides with the given context
	self._slide_stack = self._slide_stack.filter(
		func(slide): return slide.context != context_name
	)
	# If the queued item was removed, process the queue
	if top_queued and top_queued.context == context_name:
		self._process_queue()
	# Otherwise, just refresh the stack
	else:
		self._update_stack()

	# For the remaining slides, clear out any widgets from that context
	for s in self._slide_stack:
		s.clear(context_name)
