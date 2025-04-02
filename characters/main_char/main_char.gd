extends Character

func _ready() -> void:
	super()

func hit(hitbox: Hitbox) -> void:
	super(hitbox)

func _process(_delta: float) -> void:
	input_dir = Vector2(0, 0)
	if Input.is_action_pressed("ui_right"):
		input_dir.x = 1
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1
	if Input.is_action_pressed("ui_up"):
		input_dir.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_dir.y = 1

	input_dir = input_dir.normalized()

	input_attack_1 = false
	input_attack_2 = false
	if Input.is_key_pressed(KEY_Z):
		input_attack_1 = true
	elif Input.is_key_pressed(KEY_X):
		input_attack_2 = true

func _physics_process(_delta: float) -> void:
	super(_delta)
