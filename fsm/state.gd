@icon("./state.png")
class_name State
extends Node

## An individual FSM State node, to be processed by a StateMachine

## A reference to the root StateMachine, passed down during initialization.
var machine : StateMachine

## A reference to the object that is making use of the state machine.
## This reference is passed down by the root StateMachine
var target : Node

## Emitted when enter() function fully completes.
## This is automatically emitted by the root StateMachine
signal entered()

## Emitted when exit() function fully completes.
## This is automatically emitted by the root StateMachine
signal exited()

## Called when parent StateMachine enters this State.
## Extend to define the State's initializer.
func enter() -> void:
	pass

## Called when parent StateMachine exits this State.
## Extend to define the State's cleanup.
func exit() -> void:
	pass

## When State is active, executed during parent machine's _input() call.
func input(event) -> void:
	pass

## When State is active, executed during parent machine's _process() call.
func process(delta) -> void:
	pass

func set_state(state : State) -> void:
	machine.set_state(state)

func set_state_name(state : String) -> void:
	machine.set_state_name(state)

## Returns whether the state is currently seleted by the main machine
func _is_active() -> bool:
	return machine.cur_state == self
