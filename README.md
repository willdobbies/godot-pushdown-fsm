# Godot Pushdown Fsm
A Godot 4 FSM addon which allows you to set, push and pop states.

# Installation
Clone or download the repo as a .zip, and copy the ```addons/``` directory to the root of your Godot project.

# Usage
- This addon provides two new global classes: StateMachine and State.

- The StateMachine object manages the State nodes below it, and can switch between them using the ```set_state```, ```push_state``` and ```pop_state``` methods.

- States contain a few core functions:
    1. _enter(msg)
        When a State is switched to, it's ```_enter(msg)``` function is called. The optional ```msg``` 
        parameter is a dictionary, which is passed along when switching to a new state. Use this to add 
        further complexity to your behaviors.

    2. _exit()
        Similarly, _exit() is called when the State is being switched away from. Use this to cleanup any
        lingering behaviors, signals, or variables you assigned during the State runtime.

    3. input(event)
        Hands off _input(event) calls down to the State. These only fire when the State is active.

    4. update(delta)
        Hands off _process(delta) calls down to the State. These only fire when the State is active.

    - Extend these functions to build behaviors in your FSM.

- Two references are passed down to States by the parent StateMachine
    1. machine
        A reference to the parent StateMachine. Use this to switch states from within a given State node.

    2. target
        The object utilizing the state machine. Set this to your Player, Enemy, or whatever the States will target.

# Examples
1. An Idle/Walk State
```gd
extends State

func enter(msg = {}):
    # Use asserts to confirm the target object fits with your code requirements
	assert(target is ActiveCharacter)
	target.strafe_changed.connect(update_anim)
	update_anim(target.strafe)

func exit():
	target.strafe_changed.disconnect(update_anim)

func get_strafe() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

func input(event) -> void:
	target.strafe = get_strafe()
	
    # If you want accessable methods for all your states, it's useful to put them
    # in the parent object itself.
    # You could also extend an existing State and leverage a previously written function.
	if(event.is_action_pressed("interact")):
		await target.interact_nearest()

func get_anim_dir(strafe):
	if(strafe.x == 0 and strafe.y > 0): return "_d"
	if(strafe.y < 0): return "_u"
	return ""

# This animation code is nice and contained within this single state.
func update_anim(strafe):
	var is_moving = strafe != Vector2.ZERO
	var anim = "walk" if is_moving else "idle"
	anim += get_anim_dir(target.look)
	
	target.sprite.play(anim)
```

2. A Special Interaction State
```gd
extends State

# Player movement and input is disabled, await completion of terminal input 
# before restoring control

func enter(msg={}):
	assert(target is Active)
	var terminal = msg.get("terminal",null)
	
	if(not terminal):
		machine.pop_state()
		return
	
	target.sprite.play("typing")
	await terminal.control_finished
	machine.pop_state()
```

# Notes
- This is my personal library that I use for my games, and is WIP. (Use at your own risk).
- If you find any major bugs or problems, let me know in the Github Issues and I'll try to fix them.
- There is a danger of things breaking if you don't keep track of how many states you've pushed or popped, and I'm pretty sure my implementation breaks some rules about how the 'pushdown automata' strategy should work. Therefore, if you want the most vanilla FSM experience, just stick with the 'set_state' function.
