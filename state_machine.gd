@icon("./state_machine.png")
class_name StateMachine
extends Node

# enable for additional debug messages checked this object
@export var editor_debug := false

# Emitted when transitioning to a new current_state.
signal transitioned(state_name)
signal entered(state_name)
signal exitted(state_name)

# Pushdown automaton style stack of State objects
var stack : Array

# Map referencing State nodes to names
var states : Dictionary

# The target object that makes use of the States/StateMachine
# A reference is passed during _ready
var target : Object

func _ready() -> void:
	await owner.ready
	
	for child in get_children():
		if(not child is State):
			continue
		
		add_state(child)
		
		if(stack.is_empty()):
			set_state(child.name)

func add_state(state : State) -> void:
	state.machine = self
	state.target = target
	states[state.name] = state

# The current_state machine subscribes to node callbacks and 
# delegates them to the current_state objects.
func _input(event) -> void:
	if(stack.is_empty()): return
	stack.back().input(event)

func _process(delta) -> void:
	if(stack.is_empty()): return
	stack.back().process(delta)

func _enter_state(state : State, msg := {}) -> void:
	if(editor_debug): print("Machine enter -> ", state.name)
	state.enter(msg)
	entered.emit(state.name)

func _exit_state(state: State) -> void:
	if(editor_debug): print("Machine exit -> ", state.name)
	state.exit()
	exitted.emit(state.name)

func has_state(state_name : String) -> bool:
	return state_name in states

func get_state(state_name : String) -> State:
	if(not has_state(state_name)):
		if(editor_debug): print("No such state ", state_name)
	
	return states.get(state_name)

# Replace the top of the stack, exit current and enter new (replaced state)
# Fail if new state is null or invalid
func set_state(state_name : String, msg := {}) -> void:
	var state = get_state(state_name)
	if(not state): return
	
	if(stack.is_empty()):
		stack.append(state)
		_enter_state(stack.back(), msg)
	else:
		_exit_state(stack.back())
		stack[-1] = state
		_enter_state(stack.back(), msg)

# Add new state to top of stack, exit current and enter new (added state)
# Fail if new state is null or invalid
func push_state(state_name : String, msg := {}) -> void:
	var state = get_state(state_name)
	if(not state): return
	
	_exit_state(stack.back())
	stack.push_back(state)
	_enter_state(stack.back(), msg)

# Pop state from top of stack, exit current and enter new (stack top)
# Fail if stack is empty or sized 1
func pop_state() -> State:
	if(stack.is_empty()): 
		return null
	
	_exit_state(stack.back())
	var old_state = stack.pop_back()
	_enter_state(stack.back())

	return old_state
