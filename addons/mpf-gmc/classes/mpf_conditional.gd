class_name MPFConditional
extends Node2D
## A node that conditionally appears or hides based on a condition.


enum ConditionType {
	EQUALS,
	NOT_EQUALS,
	LESS_THAN,
	LESS_THAN_OR_EQUAL_TO,
	GREATER_THAN,
	GREATER_THAN_OR_EQUAL_TO
}

const VariableType = preload("const.gd").VariableType

## The source of the variable value
@export var variable_type: VariableType = VariableType.CURRENT_PLAYER
## The name of the variable to compare to
@export var variable_name: String
## The comparison to make
@export var condition_type: ConditionType = ConditionType.EQUALS
## The value to compare to. Has no effect for MPFConditionalChildren
@export var condition_value: String
## If set, this node will only render if the number of players is greater than or equal to this value.
@export var min_players: int
## If set, this nod will only render if the number of players is less than or equal to this value.
@export var max_players: int

var initialized = false

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger
var operator
var true_variable_name: String
var target

func _enter_tree() -> void:
	self.log = preload("res://addons/mpf-gmc/scripts/log.gd").new("Conditional<%s>" % self.name)

func _ready() -> void:
	if not Engine.is_editor_hint():
		self._initialize()
	var parent_slide = MPF.util.find_parent_slide_or_widget(self)
	parent_slide.register_updater(self)

func _exit_tree() -> void:
	var parent_slide = MPF.util.find_parent_slide_or_widget(self)
	parent_slide.remove_updater(self)

@warning_ignore("native_method_override")
func show():
	if self.visible:
		return
	if not self.initialized:
		self._initialize()
	else:
		self._show_or_hide()

func update(settings: Dictionary, kwargs: Dictionary = {}):
	if self.variable_type == VariableType.EVENT_ARG:
		self.target = settings.duplicate()
		if settings.get("tokens") and not settings["tokens"].is_empty():
			self.target.merge(settings["tokens"])
		if not kwargs.is_empty():
			self.target.merge(kwargs)
	self.show_or_hide()

## Override this method to pass in the correct value and set visibility
func _show_or_hide():
	if self.min_players and MPF.game.num_players < self.min_players:
		self.log.info("Minimum players not met, hiding")
		self.visible = false
	elif self.max_players and MPF.game.num_players > self.max_players:
		self.log.info("Maximum players exceeded, hiding")
		self.visible = false
	elif self.target:
		self.show_or_hide()

func show_or_hide():
	self.visible = self.evaluate(self.condition_value)

func evaluate(value):
	var t = self.target.get(self.true_variable_name)
	self.log.debug("Evaluating value '%s' against current %s value '%s'", [value, self.true_variable_name, t])
	# If there is no target, evaluate false
	if not t:
		return false
	var v = type_convert(value, typeof(t))
	return self.operator.call(t, v)

func _initialize():
	# Look up the operator
	self.operator = self._find_operator()
	self.target = self._find_target()
	self._show_or_hide()

func _find_target():
	var base
	match self.variable_type:
		VariableType.CURRENT_PLAYER:
			base = MPF.game.player
		VariableType.MACHINE_VAR:
			base = MPF.game.machine
		VariableType.SETTING:
			base = MPF.game.settings
		VariableType.EVENT_ARG:
			base = null
		VariableType.PLAYER_1:
			base = MPF.game.players[0]
		VariableType.PLAYER_2:
			if MPF.game.players.size() > 1:
				base = MPF.game.players[1]
		VariableType.PLAYER_3:
			if MPF.game.players.size() > 2:
				base = MPF.game.players[2]
		VariableType.PLAYER_4:
			if MPF.game.players.size() > 4:
				base = MPF.game.players[4]
	if "." in self.variable_name and base != null:
		var nested = self.variable_name.split(".")
		while nested.size() > 1:
			var next_nest = nested.pop_front()
			base = base[next_nest]
		self.true_variable_name = nested[0]
	else:
		self.true_variable_name = self.variable_name
	return base

func _find_operator():
	match self.condition_type:
		ConditionType.EQUALS:
			return eq
		ConditionType.NOT_EQUALS:
			return not_eq
		ConditionType.LESS_THAN:
			return lt
		ConditionType.LESS_THAN_OR_EQUAL_TO:
			return lt_eq
		ConditionType.GREATER_THAN:
			return gt
		ConditionType.GREATER_THAN_OR_EQUAL_TO:
			return gt_eq

func eq(a, b):
	return a == b

func not_eq(a, b):
	return a != b

func lt(a, b):
	return a < b

func lt_eq(a, b):
	return a <= b

func gt(a, b):
	return a > b

func gt_eq(a, b):
	return a >= b
