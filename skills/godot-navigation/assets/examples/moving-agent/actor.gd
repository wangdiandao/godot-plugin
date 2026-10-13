extends CharacterBody3D
var agent: NavigationAgent3D
var moving := false
var goal := Vector3.ZERO
var safe_callbacks := 0
var last_move_tick := -1
var double_move := false
func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 0.8
	collision.shape = capsule
	collision.position.y = 0.4
	add_child(collision)
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.15
	agent.target_desired_distance = 0.15
	agent.radius = 0.2
	agent.max_speed = 3
	add_child(agent)
	agent.velocity_computed.connect(_safe_velocity)
func set_goal(value: Vector3) -> void:
	goal = value
	agent.target_position = value
	moving = true
func _physics_process(_delta: float) -> void:
	if not moving or NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	var next := agent.get_next_path_position()
	if agent.is_navigation_finished() or not agent.is_target_reachable():
		moving = false
		agent.velocity = Vector3.ZERO
		return
	var desired := global_position.direction_to(next) * 3.0
	if agent.avoidance_enabled:
		agent.velocity = desired
	else:
		_move(desired)
func _safe_velocity(value: Vector3) -> void:
	safe_callbacks += 1
	if moving:
		_move(value)
func _move(value: Vector3) -> void:
	var tick := Engine.get_physics_frames()
	double_move = double_move or tick == last_move_tick
	last_move_tick = tick
	velocity = value
	move_and_slide()
