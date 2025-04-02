extends Character

var in_dir: Vector2

func _ready() -> void:
	super()

func hit(hitbox: Hitbox) -> void:
	super(hitbox)

func _physics_process(_delta: float) -> void:
	super(_delta)
