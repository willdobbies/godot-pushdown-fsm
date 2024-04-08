@icon("./state_machine.png")
class_name StateMachine
extends Node

## A FSM (finite state machine) which utilizes Nodes as States.
##
## StateMachine delagates _input() and _process() calls to the currently
## active State Node.
## Each individual State node has its enter()/exit() methods called during 
## state transitions.
## All child State Nodes are automatically added to the StateMachine, and 
## can be transitioned to using the set_state() method.
## Additional push_state() and pop_state() allow for pushdown-automata style 
## state management.

## The currently active State in the StateMachine.
## If unset, the first child of the StateMachine Node will be used by default.
@export var default_state : State

## Store history of states. Utilized during state selection in push/pop
var state_stack : Array[State]

## The target object that makes use of the States/StateMachine.
@export var target : Node = owner : set = set_target

## A collection of all the States in the StateMachine. 
## Maps [Node -> name] for each state
var state_map : Dictionary

## Generic data which is shared among all States
## Use this to keep persistant data between States
var blackboard : Dictionary

## Emitted when enterring into to the next State.
signal entered(state : State)

## Emitted after exitting from the previous State
signal exitted(state : State)

func _ready() -> void:
	await owner.ready
	
	add_state_children()

	if(default_state == null):
		default_state = state_map.values().front()
	
	assert(default_state != null)
	
	## Push our first state
	state_stack.append(default_state)
	_enter_state(state_stack.back())

## Search for all valid State objects in children and add them to the 
## StateMachine.
func add_state_children() -> void:
	for child in get_children():
		if(not child is State): continue
		add_state(child)

## Add a State to the state_map, pass down machine variables.
func add_state(state : State) -> void:
	state.machine = self
	state.target = target
	state_map[state.name] = state

## Sets the StateMachine target and updates all relevent states
func set_target(t : Node):
	target = t
	for state in state_map.values():
		state.target = t

## Delegate _input calls to the currently running State 
func _input(event) -> void:
	state_stack.back().input(event)

## Delegate _process calls to the currently running State 
func _process(delta) -> void:
	state_stack.back().process(delta)

## Returns a State node based on it's name
func get_state(state_name : String) -> State:
	return state_map.get(state_name, null)

## Check if we're in a given state right now
func is_in_state(state_name : String) -> bool:
	return state_stack.back().name == state_name

func _enter_state(state : State):
	await state.enter()
	state.entered.emit()
	entered.emit(state)

func _exit_state(state : State):
	await state.exit()
	state.exited.emit()
	exitted.emit(state)

func set_state(next_state : State) -> void:
	await _exit_state(state_stack.back())
	state_stack[-1] = next_state
	await _enter_state(state_stack.back())

func push_state(next_state : State) -> void:
	await _exit_state(state_stack.back())
	state_stack.push_back(next_state)
	await _enter_state(state_stack.back())

func pop_state() -> void:
	if(state_stack.is_empty()): return
	await _exit_state(state_stack.back())
	state_stack.pop_back()
	await _enter_state(state_stack.back())

func set_state_name(state_name : String) -> void:
	set_state(get_state(state_name))

func push_state_name(state_name : String) -> void:
	push_state(get_state(state_name))
