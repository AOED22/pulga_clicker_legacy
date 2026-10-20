extends PointLight2D

@export var variacao := 0.25
@export var velocidade := 1.6

var energia_base := 0.0
var fase := 0.0


func _ready() -> void:
	energia_base = energy
	fase = randf() * TAU


func _process(delta: float) -> void:
	fase += velocidade * delta
	energy = energia_base * (1.0 + variacao * sin(fase) + variacao * 0.4 * sin(fase * 2.7))
