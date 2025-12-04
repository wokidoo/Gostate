@tool
@icon("uid://t3mnjf1o81d1")
extends State
class_name StateMachine
## Manages multiple State nodes as a parent. Handles initial entry, transitions,
## and event propagation across the active state hierarchy.

## Emitted when transitioning from one state to another.
## @param from The state being exited.
## @param to   The state being entered.
signal state_transition(from:State, to:State)

## Emitted when a custom event is processed.
## @param event The StringName of the event.
signal state_event(event: StringName)

## Traverses the StateMachine, printing all child States and their transitions.
@export_tool_button("Print StateMachine") var _print_state_machine_action = _print_state_machine

## The state to enter when the machine starts.
@export var initial_state: State:
	set(val):
		if not val is State:
			push_error("Initial State must be of type State")
			return
		if Engine.is_editor_hint():
			update_configuration_warnings()
		initial_state = val

## Public refrence to current_state. Protects external modifcation.
var current_state: State:
	get(): return _current_state

## Internal reference to current state.
var _current_state:State:
	set(val):
		if not get_children().has(val):
			push_error("current_state must be a child of StateMachine")
			return
		_current_state = val

func _ready():
	# Prevent running in editor.
	if Engine.is_editor_hint():
		return
	_state_machine = _find_state_machine(get_parent())
	_current_state = initial_state
	## Initializes all child states.
	## By default all child states will be set to inactive.
	for child in get_children(true):
		if child is State:
			child._init_state()
	## If no parent state machine, set state machine to active and enter initial state.
	## This is done because having no parent StateMachine means this instance is a root StateMachine.
	if _state_machine == null:
		_set_active(true)
		_enter_initial_state()

func _enter_initial_state():
	_current_state = initial_state
	_current_state._state_enter()

## Executes a State event to trigger a transition.
func execute_event(event:StringName):
	if _is_active:
		var next_state:State = _current_state.transitions.get(event)
		state_event.emit(event)
		if next_state != null:
			_execute_transition(next_state)
	else:
		return

func _execute_transition(to:State):
	## Internally handles exiting the current state and entering the new one.
	if _is_active:
		_current_state._state_exit()
		state_transition.emit(current_state,to)
		_current_state = to
		# wait for next frame to clear current inputs and processes.
		await get_tree().process_frame
		to._state_enter()
	else:
		return

func _state_enter():
	## Internal: Activates the state and emits `state_entered`.
	_set_active(true)
	entered.emit()
	## Enter current state when state machine becomes active.
	_current_state._state_enter()

func _state_exit():
	## Internal: Deactivates the current state and emits `state_exited`.
	_set_active(false)
	## Leave current state when state machine becomes inactive.
	_current_state._state_exit()
	exited.emit()

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

func _print_state_machine():
	print(name)
	var sms:Array[StateMachine] =[]
	for s in get_children():
		if s is StateMachine:
			for t in s.transitions:
				var transition_string:String = t+"->"+s.transitions[t].name
				print("\t",transition_string)
			sms.append(s)
		elif s is State:
			print("\t",s.name)
			for t in s.transitions:
				print("\t\t",t,"->",s.transitions[t])
	print()
	for s in sms:
		_print_state_machine_recursive(s)
func _print_state_machine_recursive(sm:StateMachine = self,iter:int = 1):
	var tabs:String ="\t"
	print(tabs.repeat(iter),sm.name)
	var sms:Array[StateMachine] =[]
	for s in sm.get_children():
		if s is StateMachine:
			for t in s.transitions:
				var transition_string:String = t+"->"+s.transitions[t].name
				print(tabs.repeat(iter+3),transition_string)
			sms.append(s)
		elif s is State:
			var name_string:String = s.name
			print(tabs.repeat(iter+1),name_string)
			for t in s.transitions:
				var transition_string:String = t+"->"+s.transitions[t].name
				print(tabs.repeat(iter+3),transition_string)
	print()
	for s in sms:
		_print_state_machine_recursive(s)
