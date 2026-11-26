class_name GlobuloAcido
extends Node2D

# glob de acido que a Rainha cospe: voa em parabola da boca ate o ponto de impacto
# (a mesma marca verde no chao). Ao chegar emite "aterrissou"; quem lancou cuida do dano e da poca.

signal aterrissou

var origem := Vector2.ZERO
var destino := Vector2.ZERO
var duracao := 0.8
var altura := 90.0
var tempo := 0.0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var sombra: Sprite2D = $Sombra


func _ready() -> void:
	add_to_group("globulos")
	global_position = origem
	# quanto mais longe o alvo, mais alto o arco
	altura = clampf(origem.distance_to(destino) * 0.35 + 50.0, 60.0, 190.0)


func _physics_process(delta: float) -> void:
	tempo += delta
	var t := clampf(tempo / maxf(duracao, 0.01), 0.0, 1.0)
	# o no anda em linha reta no chao; so o visual sobe e desce (parabola)
	var arco := 4.0 * altura * t * (1.0 - t)
	global_position = origem.lerp(destino, t)
	visual.position = Vector2(0.0, -arco)
	sombra.scale = Vector2.ONE * clampf(1.0 - arco / (altura * 2.5), 0.4, 1.0)
	sprite.frame = int(tempo * 12.0) % 2
	if t >= 1.0:
		aterrissou.emit()
		queue_free()
