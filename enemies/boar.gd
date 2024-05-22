extends Enemy

enum State{
	IDLE,
	RUN,
	WALK,
	FALL,
	HITED,
}
var walk_speed: float = 100.0
@onready var wall_checker: RayCast2D = $Graphic/WallChecker#判断wall
@onready var foot_checker: RayCast2D = $Graphic/FootChecker#判断悬崖
@onready var player_checker: RayCast2D = $Graphic/PlayerChecker
@onready var calm_down_timer: Timer = $CalmDownTimer


func get_next_state(state: State)-> State:
	foot_checker.force_raycast_update()
	wall_checker.force_raycast_update()
	if not is_on_floor():
		return State.FALL
	if player_checker.is_colliding():
		return State.RUN
	match state:
		State.IDLE:
			if state_machine.state_time > 2:
				return State.WALK
		State.RUN:
			if calm_down_timer.is_stopped():
				return State.IDLE
		State.WALK:
			if wall_checker.is_colliding() or not foot_checker.is_colliding():
				return State.IDLE
		State.FALL:
			if is_on_floor():
				return State.IDLE
		State.HITED:
			pass
	return state

func transition_state(from: State, to: State)-> void:
	match to:
		State.IDLE:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				print("direction ", direction)
				direction = -direction
			
		State.RUN:
			animation_player.play("run")
			
		State.WALK:
			animation_player.play("walk")
			if not foot_checker.is_colliding():
				direction = -direction
		State.FALL:
			animation_player.play("idle")
		State.HITED:
			animation_player.play("hited")
			
	print(name, " ",Engine.get_physics_frames(), " << from %s to %s >> " % [
		State.keys()[from] if from >= 0 else "<START>" ,
		State.keys()[to]],
			"velocity ",velocity
		)


func tick_physics(state: State, delta: float)-> void:
	match state:
		State.IDLE:
			move(0, delta)
		State.RUN:
			if player_checker.is_colliding():
				calm_down_timer.start()
			if wall_checker.is_colliding() or not foot_checker.is_colliding():
				direction = -direction
			move(max_speed, delta)
		State.WALK:
			move(walk_speed, delta)
		State.FALL:
			move(0, delta)
		State.HITED:
			move(0, delta)

func move(speed: float, delta: float)-> void:
	velocity.x = move_toward(velocity.x, speed * direction, acceration * delta)
	velocity.y += default_gravity * delta
	move_and_slide()
