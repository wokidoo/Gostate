@tool
@icon("res://addons/gostate/icons/state.svg")
extends Node
class_name GoState
## Represents a single GoState within a GoStateMachine, handling entry, exit,
## processing (both frame and physics), inputs, and custom events and all associated signals.

## Emitted right before state_entered is called
signal state_entering()

## Emitted right after state_entered is called
signal state_entered()

## Emitted right before state_exit is called
signal state_exiting()

## Emitted right after state_exit is called
signal state_exited()

## Emitted when GoState is currently processing
## [param delta] Time elapsed since last frame.
signal state_processing(delta:float)

## Emitted when GoState is currently physics processing
## [param delta] delta Time elapsed since last physics frame.
signal state_physics_processing(delta:float)

## Emitted when an input event occurs and the GoState is active.
## [param event] The InputEvent received.
signal state_inputing(event:InputEvent)

## Emitted when an unhandled input event occurs and the GoState is active.
## [param event] The unhandled InputEvent.
signal state_unhandled_inputing(event:InputEvent)

## Returns `true` if this GoState is currently active.
var is_active: bool:
	get(): return _is_active

## Returns the associated StateMachine instance.
var state_machine: GoStateMachine:
	get(): return _state_machine
	set(val): state_machine = _state_machine

# Reference to the owning StateMachine. Internal use only.
var _state_machine: GoStateMachine

# Internal flag tracking whether the GoState is active.
# Use `active` to access this status.
var _is_active: bool:
	set(value):
		_is_active = value
		_update_processing()

func _ready():
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return

# Called after ready method by the ancestor GoState machine.
# Sets all states to inactive by default
func _init_state():
	## Called by the StateMachine after ready. Initializes the GoState as inactive.
	_set_active(false)

func _state_enter():
	## Internal: Activates the GoState and emits `state_entered`.
	_set_active(true)
	state_entering.emit()
	await state_enter()
	state_entered.emit()
	
func _state_exit():
	## Internal: Deactivates the GoState and emits `state_exited`.
	_set_active(false)
	state_exiting.emit()
	await state_exit()
	state_exited.emit()

func _process(delta):
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	## Called every frame when active; emits `state_processing`.
	state_processing.emit(delta)
	state_process(delta)

func _physics_process(delta):
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	## Called every physics frame when active; emits `state_physics_processing`.
	state_physics_processing.emit(delta)
	state_physics_process(delta)

func _input(event):
	## Called on input; emits `state_input` when active.
	state_inputing.emit(event)
	state_input(event)

func _unhandled_input(event):
	## Called on unhandled input; emits `state_unhandled_input` when active.
	state_unhandled_inputing.emit(event)
	state_unhandled_input(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		var parent = get_parent()
		if parent and parent is GoStateMachine:
			_state_machine = parent

# Makes sure the parent node is a StateMachine.
# Displays a warning in editor if it isn't.
func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	var parent := get_parent()
	while parent and not (parent is GoStateMachine):
		parent = parent.get_parent()
	if parent == null:
		result.append("%s must be a child of a StateMachine." % name)
	return result

func _set_active(status: bool = false):
	## Sets the internal active flag.
	_is_active = status

func _update_processing():
	## Enables or disables processing based on active status.
	set_process(is_active)
	set_physics_process(is_active)
	set_process_input(is_active)
	set_process_unhandled_input(is_active)

## Trigger a GoState event.
func trigger_state_event(event:StringName):
	if _is_active:
		_state_machine.trigger_state_event(event)

func _handle_state_event(event:StringName)->bool:
	if _is_active:
		for c in get_children():
			if c.has_method('_handle_state_event'):
				if c._handle_state_event(event):
					return true
		return false
	else:
		return false

#region Overridable GoState functions

## Overridable method.
## Called once upon GoState being entered.
func state_enter():
	pass

## Overridable method.
## Called once upon GoState being exited.
func state_exit():
	pass

## Overridable method.
## Called every process frame while GoState is active.
func state_process(_delta):
	pass

## Overridable method.
## Called every physics_process frame while GoState is active.
func state_physics_process(_delta):
	pass

## Overridable method.
## Called when input is detected while GoState is active.
func state_input(_event):
	pass

## Overridable method.
## Called when unhandled_input is detected while GoState is active.
func state_unhandled_input(_event):
	pass

#endregion
