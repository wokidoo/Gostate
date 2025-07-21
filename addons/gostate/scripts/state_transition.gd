@tool
@icon("res://addons/gostate/icons/state_transition.svg")
extends State
class_name StateTransition
## Defines a transition between two State nodes, triggered by a custom event.

## The target State to transition into.
@export var to: State
## The event name that triggers this transition.
@export var trigger_event: StringName

func _ready():
	super._ready()
	# If the immediate parent of the transition is a state machine,
	# Find the next ancestor state machine
	if get_parent() is StateMachine:
		_state_machine = _find_state_machine(_state_machine.get_parent())

## Called by associated ancestor state machine.
## Overrides original State implementation.
## Checks if received event should trigger transition
func _process_event(event: StringName):
	if event == trigger_event:
		state_event.emit(event)
		_state_machine._execute_transition(to)

## Makes sure the parent node is a StateMachine.
## Displays a warning in editor if it isn't.
func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	var parent := get_parent()
	while parent and not (parent is State):
		parent = parent.get_parent()
	if parent == null:
		result.append("%s must be a child of a State." % name)
	return result
