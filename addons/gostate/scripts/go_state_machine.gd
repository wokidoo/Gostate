@tool
@icon("res://addons/gostate/icons/state_machine.svg")
extends GoState
class_name GoStateMachine
## Manages multiple GoState nodes as a parent. Handles initial entry, transitions,
## and event propagation across the active GoState hierarchy.

## Defines the different reentry behaviour for renetering the state machine
enum ReentryMode {
	## Will enter the last active state before the state machine became inactive.
	PERSISTENT,
	## Will enter the [member initial_state]. 
	INITIAL_STATE
}

## Emitted when transitioning from one GoState to another.
## [param from] The GoState being exited.
## [param to] The GoState being entered.
signal state_transition(from:GoState, to:GoState)

## Emitted when a custom event is processed.
## [param event] The StringName of the event.
signal state_event(event: StringName)

## The GoState to enter when the machine starts.
@export var initial_state: GoState:
	set(val):
		if not val is GoState:
			push_error("Initial GoState must be of type GoState")
			return
		if Engine.is_editor_hint():
			update_configuration_warnings()
		initial_state = val

## Decides which state will be entered when the state machine is rentered.
@export var reentry_mode:ReentryMode = ReentryMode.INITIAL_STATE

# Internal reference to current GoState.
var _current_state:GoState:
	set(val):
		if not get_children().has(val):
			push_error("current_state must be a child of GoStateMachine")
			return
		_current_state = val

func _ready():
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	_current_state = initial_state
	## Initializes all child states.
	## By default all child states will be set to inactive.
	for child in get_children(true):
		if child is GoState:
			child._init_state()
	## If no parent GoState machine, set GoState machine to active and enter initial GoState.
	## This is done because having no parent GoStateMachine means this instance is a root GoStateMachine.
	if _state_machine == null:
		_set_active(true)
		_enter_initial_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		var parent = get_parent()
		if parent and parent is GoStateMachine:
			_state_machine = parent

func _enter_initial_state():
	_current_state = initial_state
	_current_state._state_enter()

## Trigger a GoState event.
func trigger_state_event(event:StringName):
	if _is_active:
		if _state_machine != null:
			_state_machine._handle_state_event(event)
		else:
			_handle_state_event(event)

func _handle_state_event(event:StringName)->bool:
	if _is_active:
		for c in get_children():
			if c.has_method('_handle_state_event'):
				if c._handle_state_event(event):
					return true
		return false
	else:
		return false

func _execute_transition(to:GoState):
	## Internally handles exiting the current GoState and entering the new one.
	if _is_active:
		await _current_state._state_exit()
		state_transition.emit(_current_state,to)
		_current_state = to
		to._state_enter()

func _state_enter():
	## Internal: Activates the GoState and emits `state_entered`.
	_set_active(true)
	state_entering.emit()
	if reentry_mode == ReentryMode.INITIAL_STATE:
		_current_state = initial_state
	state_entering.emit()
	await state_enter()
	state_entered.emit()
	## Only trigger state entry method after state machine has finished it's own entry methods
	await _current_state._state_enter()

func _state_exit():
	## Internal: Deactivates the current GoState and emits `state_exited`.
	_set_active(false)
	## Leave current GoState when GoState machine becomes inactive.
	await _current_state._state_exit()
	state_exiting.emit()
	await state_exit()
	state_exited.emit()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []

	# No initial GoState was set.
	if initial_state == null:
		warnings.append("Select an initial GoState node.")
		request_ready()

	# Selected initial GoState is not a decedent of GoState machine.
	if not self.is_ancestor_of(initial_state):
		warnings.append("The chosen initial_state is not a child (or grand-child) of this GoStateMachine.")
		request_ready()

	# Selected initial GoState is not of type GoState.
	if not (initial_state is GoState):
		warnings.append("initial_state must inherit from the GoState script.")
		request_ready()

	return warnings
