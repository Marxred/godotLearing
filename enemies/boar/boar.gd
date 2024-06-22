class_name Boar
extends Enemy

enum State{
	IDLE,
	RUN,
	WALK,
	FALL,
	HITED,
	DIE,
}
var walk_speed:float = 100.0
var KNOCKBACK:float = 512.0
var CHILL_TIME:float = 0.5
var STILL_TIME:float = 1.5

@onready var wall_checker: RayCast2D = $Graphic/WallChecker#判断wall
@onready var foot_checker: RayCast2D = $Graphic/FootChecker#判断悬崖
@onready var player_checker: RayCast2D = $Graphic/PlayerChecker
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var hit_box: HitBox = $HitBox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var stats: Stats = $Stats
var pending_damage: Damage


func _ready() -> void:
	pass


func get_next_state(state: State)-> State:
	state_machine.ENTER_CURRENT_STATE_AGAIN = false
	if stats.health <= 0:
		return State.DIE
	foot_checker.force_raycast_update()
	wall_checker.force_raycast_update()
	if pending_damage != null:
		state_machine.ENTER_CURRENT_STATE_AGAIN = true
		return State.HITED
	if not is_on_floor():
		return State.FALL
	if player_checker.is_colliding():
		return State.RUN
	
	match state:
		State.IDLE:
			if state_machine.state_time > STILL_TIME:
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
			if state_machine.state_time > CHILL_TIME:
				return State.WALK
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
			stats.health -= pending_damage.damage
			var dam_dir:Vector2 = self.global_position\
						.direction_to(pending_damage.source.global_position) 
			pending_damage = null
			#if dam_dir.x > 0:
				#direction = Direction.RIGHT
			#else:direction = Direction.LEFT
			direction = dam_dir.sign().x as int
			velocity = KNOCKBACK *-dam_dir
			
		State.DIE:
			animation_player.play("die")
			
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
		State.DIE:
			move(0, delta)
			if not animation_player.is_playing():
				queue_free()

func move(speed: float, delta: float)-> void:
	velocity.x = move_toward(velocity.x, speed * direction, acceration * delta)
	velocity.y += default_gravity * delta
	move_and_slide()


func _on_hurtbox_hurt(hitbox: HitBox) -> void:
	pending_damage = Damage.new()
	pending_damage.damage = 1
	pending_damage.source = hitbox
