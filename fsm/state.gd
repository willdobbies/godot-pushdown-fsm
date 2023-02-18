@icon("./state.png")
class_name State 
extends Node

# enable for additional debug messages checked this object
@export var editor_debug : bool

# A reference to the root StateMachine, passed down during initialization
# Often used to switch between states (using state_set, state_push, etc)
var machine : StateMachine

# A reference to the object that is making use of the state machine
# This reference is passed down by the root StateMachine
var target : Object

# Called when parent StateMachine enters this State
# Extend for state's initializer
func enter(msg = {}):
	pass

# Called when parent StateMachine exits this State
# Extend for state's cleanup 
func exit():
	pass

# All methods below are virtual and called by the state machine.
func input(event) -> void:
	pass

# When active, executed during parent machine's _update()
func process(delta) -> void:
	pass
