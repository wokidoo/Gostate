@tool
@icon("res://addons/gostate/icons/state_machine.svg")
extends State
class_name StateMachine
## Manages multiple State nodes as a parent. Handles initial entry, transitions,
## and event propagation across the active state hierarchy.

## Emitted when transitioning from one state to another.
## @param from The state being exited.
## @param to   The state being entered.
signal state_transition(from:State, to:State)

## The state to enter when the machine starts.
@export var initial_state: State:
	set(new_val):
		if new_val is StateTransition:
			push_error("Cannot set a StateTransition as an initial state")
			return
		if Engine.is_editor_hint():
			update_configuration_warnings()
		initial_state = new_val

## The currently active state.
var current_state: State

func _ready():
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	
	_state_machine = _find_state_machine(get_parent())
	current_state = initial_state
	## Initializes all child states.
	## By default all child states will be set to inactive.
	for child in get_children(true):
		if child is State:
			child._init_state()
	## If no parent state machine, set state machine to active and enter initial state.
	if _state_machine == null:
		_set_active(true)
		_enter_initial_state()

func _enter_initial_state():
	current_state = initial_state
	current_state._state_enter()

func send_event(event:StringName):
	## Propagates a state event down to all active child states.
	## Only propagate event if state machine is active.
	if self.active:
		state_event.emit(event)
	else:	
		return

func _execute_transition(to:State):
	## Internally handles exiting the current state and entering the new one.
	if active:
		current_state._state_exit()
		state_transition.emit(current_state,to)
		current_state = to
		# wait for next frame to clear current inputs and processes.
		await get_tree().process_frame
		to._state_enter()
	else:
		return

func _state_enter():
	## Internal: Activates the state and emits `state_entered`.
	_set_active(true)
	state_entered.emit()
	## Enter current state when state machine becomes active.
	current_state._state_enter()

func _state_exit():
	## Internal: Deactivates the current state and emits `state_exited`.
	_set_active(false)
	## Leave current state when state machine becomes inactive.
	current_state._state_exit()
	state_exited.emit()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []

	# No initial State was set.
	if initial_state == null:
		warnings.append("Select an initial State node.")
		request_ready()

	# Selected initial State is not a decedent of state machine.
	if not self.is_ancestor_of(initial_state):
		warnings.append("The chosen initial_state is not a child (or grand-child) of this StateMachine.")
		request_ready()

	# Selected initial State is not of type State.
	if not (initial_state is State):
		warnings.append("initial_state must inherit from the State script.")
		request_ready()

	return warnings
