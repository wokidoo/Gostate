@tool
@icon("uid://croparnxqnu4p")
extends Node
class_name State
## Represents a single state within a state machine, handling entry, exit,
## processing (both frame and physics), inputs, and custom events and all associated signals.

## Emitted when state is entered
signal entered()

## Emitted when state is exited
signal exited()

## Emitted when state is currently processing
## @param delta Time elapsed since last frame.
signal process(delta:float)

## Emitted when state is currently physics processing
## @param delta Time elapsed since last physics frame.
signal physics_process(delta:float)

## Emitted when an input event occurs and the state is active.
## @param event The InputEvent received.
signal input(event:InputEvent)

## Emitted when an unhandled input event occurs and the state is active.
## @param event The unhandled InputEvent.
signal state_unhandled_input(event:InputEvent)

## Returns `true` if this state is currently active.
var is_active: bool:
	get(): return _is_active

## Key/value pair representing transtions out of this state.
## Key represents the StringName event that triggers the transition.
@export var  transitions: Dictionary[StringName,State]

## Returns the associated StateMachine instance.
var state_machine: StateMachine:
	get(): return _state_machine

## Reference to the owning StateMachine. Internal use only.
var _state_machine: StateMachine

## Internal flag tracking whether the state is active.
## Use `active` to access this status.
var _is_active: bool:
	set(value):
		_is_active = value
		_update_processing()
func _ready():
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	_state_machine = _find_state_machine(get_parent())

## Called after ready method by the ancestor state machine.
## Sets all states to inactive by default
func _init_state():
	## Called by the StateMachine after ready. Initializes the state as inactive.
	_set_active(false)

## Recursively finds the nearest ancestor StateMachine.
func _find_state_machine(parent:Node) -> StateMachine:
	if parent == null:
		return null
	if parent is StateMachine:
		return parent
	return _find_state_machine(parent.get_parent())

func _state_enter():
	## Internal: Activates the state and emits `state_entered`.
	_set_active(true)
	entered.emit()

func _state_exit():
	## Internal: Deactivates the state and emits `state_exited`.
	_set_active(false)
	exited.emit()

func _process(delta):
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	## Called every frame when active; emits `state_processing`.
	process.emit(delta)

func _physics_process(delta):
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	## Called every physics frame when active; emits `state_physics_processing`.
	physics_process.emit(delta)

func _input(event):
	## Called on input; emits `state_input` when active.
	input.emit(event)

func _unhandled_input(event):
	## Called on unhandled input; emits `state_unhandled_input` when active.
	state_unhandled_input.emit(event)

func _set_active(status: bool = false):
	## Sets the internal active flag.
	_is_active = status

func _update_processing():
	## Enables or disables processing based on active status.
	set_process(is_active)
	set_physics_process(is_active)
	set_process_input(is_active)
	set_process_unhandled_input(is_active)

## Makes sure the parent node is a StateMachine.
## Displays a warning in editor if it isn't.
func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	var parent := get_parent()
	while parent and not (parent is StateMachine):
		parent = parent.get_parent()
	if parent == null:
		result.append("%s must be a child of a StateMachine." % name)
	return result
