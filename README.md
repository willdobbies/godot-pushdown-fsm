# Godot Pushdown Fsm
A Finite State Machine (FSM) addon which allows for standard or pushdown-automata style state handling.

# Installation
Clone or download the repository as a .zip, and copy the contents of fsm/ directory to project addons/ folder. Enable the addon to access the global State/StateMachine classes.

This addon is tested and compatible with Godot 4.2, and should continue to work for future versions.

# Overview

## StateMachine
The StateMachine object manages the State nodes below it, and can switch between them using the set_state, push_state and pop_state methods.

- var default_state : State
	- The first State to enter when starting the machine.
	- If unset, the first child will be chosen instead.

- var target : Node
    - The target object that is controlled by the States (your player, enemy, etc.). 
	- This value is passed down to the child States
	- By default, this value is set to the container Scene's owner

- var blackboard : Dictionary
	- A simple dict object containing generic data.
	- Set/get data from here to pass data between States.

- func set_state(state : State)
	- Exit the current state, and overwrite it with a new one
	- Automatically triggers enter/exit signals on relevant States

- func push_state(state : State)
	- Exit the current state, push a new one onto the stack, then enter it
	- Note: These 'pushed' states should eventually be popped back out.
	- Automatically triggers enter/exit signals on relevant States

- func pop_state()
	- Exit and pop the current state, enter the previous State on the stack
	- Automatically triggers enter/exit signals on relevant States

## State
These are where your main behaviors get implemented. Extend from the base State class to add your own functionality.

- func enter()
    - Called when entering into the State. 
	- Use this to initialize the default settings for your State.
	- Fetch any relevant blackboard values which were set in previous States.

- func exit()
    - Called when exiting out from the State. 
    - Use this to cleanup any lingering behaviors, signals, or variables that were set during it's runtime.

- func input(event)
	- Delegated call of _input(event) from parent StateMachine.
	- Only called when State is active

- func process(delta)
	- Delegated call of _process(event) from parent StateMachine.
	- Only called when State is active

- var machine : StateMachine
    - A reference to the parent StateMachine. 
	- Use set/push/pop state functions from inside States to handle transitions

# Examples
1. An Idle/Walk State. Updates the target object's sprite direction and animation.

```gd
extends State

func enter():
	# Use asserts to confirm the target object fits with your code requirements
	assert(target is CharacterBody2D)
	assert(target.get("sprite") is AnimatedSprite2D)

func exit():
	target.velocity = Vector2.ZERO

func get_strafe() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

func input(event):
	target.strafe = get_strafe()

func is_moving():
	return strafe != Vector2.ZERO

func process(delta):
	var anim = "walk" if is_moving() else "idle"
	target.sprite.flip_h = strafe.x < 0
	target.sprite.play(anim)
```

2. An Interaction state with a "Terminal" object. Disable control until the Terminal emits it's "control_finished" signal. Push/pop state, utilizes blackboard values.

```gd
extends State

var _terminal_control_finished = false

func enter():
	assert(target is Active)
	var terminal = machine.blackboard.get("terminal", null)
	
	if(not terminal):
		machine.pop_state()
	else:
		terminal.control_finished.connect(func():
			_terminal_control_finished = true
		)
		
		target.sprite.play("typing")
		terminal.start_control()

func exit():
	target.sprite.stop()

func process(delta):
	if(finished):
		machine.pop_state()
```

3. A stunned state, where the character stays motionless for N seconds. Push/pop state, utilizes blackboard values.

```gd 
extends State

# Tracks total stun time before leaving state
var stun_time = 0

func enter():
	stun_time = machine.blackboard.get("stun_time", 3)
	machine.blackboard.erase("stun_time")
	target.sprite.play("stun")
	target.set_collisions(false)

func exit():
	stun_time = 0
	target.set_collisions(true)

func process(delta):
	stun_time -= delta
	if(stun_time < 0):
		pop_state()
```

4. A random selection state, where we immediately switch to a random option from the exported list. 
```gd
extends State

@export var states : Array[State]

func enter(args:={}):
	if(states.is_empty()):
		machine.pop_state()
	
	var rand_state = states.pick_random()
	
	if(not rand_state):
		machine.pop_state()
	else:
		machine.set_state(rand_state)
```