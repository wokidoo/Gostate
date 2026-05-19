@tool
@icon("res://addons/gostate/icons/state_transition.svg")
extends Node
class_name GoStateTransition
## Represents a transition from a source [class GoState] (parent) to a destination [class GoState].

## State event that will trigger this transition.
@export var trigger_event:StringName:
	set(val):
		trigger_event = val
		update_configuration_warnings()
## Destination [class GoState] if the transtion is triggered. 
@export var destination_state:GoState:
	set(val):
		destination_state = val
		update_configuration_warnings()


@export_group("Transtion Condition")
@export_tool_button("Print Condition Result") var test_condition_tool_button = Callable(func():
	print(_execute_condition()))

@export var condition_input_node:Node:
	set(value):
		condition_input_node = value
		_set_condtion_node_input_properties()
		update_configuration_warnings()

@export_custom(PROPERTY_HINT_EXPRESSION, "") var condition:String:
	set(value):
		condition = value
		update_configuration_warnings()

var _source_state:GoState
var _condition_expression:Expression
var _condition_inputs:Dictionary

func _init() -> void:
	_condition_expression = Expression.new()

func _handle_state_event(event:StringName)->bool:
	if _source_state.is_active and event == trigger_event:
		if not condition.is_empty():
			if _execute_condition():
				_source_state.state_machine._execute_transition(destination_state)
				return true
			else:
				return false
		else:
			_source_state.state_machine._execute_transition(destination_state)
			return true
	else:
		return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		var parent = get_parent()
		if parent and parent is GoState:
			_source_state = parent

func _execute_condition()->bool:
	if condition_input_node != null:
		_set_condtion_node_input_properties()
		return _condition_expression.execute(_condition_inputs.values(),condition_input_node)
	else:
		return _condition_expression.execute()

func _set_condtion_node_input_properties():
	_condition_inputs.clear()
	if condition_input_node == null:
		return
	for prop in condition_input_node.get_property_list():
		condition_input_node.set(prop.name,condition_input_node.get(prop.name))

func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	var parent := get_parent()
	if parent == null:
		result.append("%s must have a parent." % name)
		return result
	elif not parent is GoState:
		result.append("%s must be the child of a GoState node." % name)
		return result
	
	if destination_state == null:
		result.append("%s must have transition destination." % name)
	elif not _source_state.state_machine.get_children().has(destination_state):
		result.append("destination_state must be a sibling of the source state." % name)
	
	if not condition.is_empty():
		if condition_input_node != null:
			_set_condtion_node_input_properties()
			var condition_expression_error = _condition_expression.parse(condition,_condition_inputs.keys())
			if condition_expression_error != OK:
				result.append(_condition_expression.get_error_text())
		else:
			var condition_expression_error = _condition_expression.parse(condition)
			if condition_expression_error != OK:
				result.append(_condition_expression.get_error_text())

	return result
