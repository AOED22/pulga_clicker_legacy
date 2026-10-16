class_name FormigaAtiradora
extends Inimigo

# formiga atiradora: mantem distancia e cospe acido (o acaro e o corpo a corpo)
enum Estado { ANDANDO, MIRANDO, RECUPERANDO }

@export_group("Movimento")
@export var velocidade := 75.0
@export var velocidade_fuga := 115.0
@export var alcance_visao := 460.0
@export var distancia_min := 140.0
@export var distancia_max := 230.0

@export_group("Cuspe")
@export var alcance_cuspe := 340.0
@export var recarga_cuspe := 2.2
@export var tempo_mira := 0.7
@export var tempo_travar_mira := 0.18
@export var tempo_recuperacao := 0.55
@export var recuo_cuspe := 160.0
@export var cena_gota: PackedScene

var estado := Estado.ANDANDO
var tempo_estado := 0.0
var recarga := 1.0
var lado := 1.0
var olhando := Vector2.RIGHT

@onready var sprite: Node2D = $Visual/Sprite
@onready var mira: Sprite2D = $Mira


func _ready() -> void:
	super()
	# tempos diferentes para as formigas nao atirarem juntas
	recarga = randf_range(0.8, 1.6)
	lado = 1.0 if randf() < 0.5 else -1.0


# levar dano interrompe a mira e atrasa o proximo cuspe
func _ao_ser_atingido() -> void:
	recarga = maxf(recarga, 0.9)
	estado = Estado.ANDANDO


func _comportamento(delta: float) -> Vector2:
	var ate := jogador.global_position - global_position
	var distancia := ate.length()
	var direcao := ate.normalized()
	recarga = maxf(recarga - delta, 0.0)
	match estado:
		Estado.ANDANDO:
			olhando = direcao
			if distancia > alcance_visao:
				return Vector2.ZERO
			if recarga <= 0.0 and distancia <= alcance_cuspe:
				if _tem_visao():
					estado = Estado.MIRANDO
					tempo_estado = tempo_mira
					return Vector2.ZERO
				# sem visao: chega mais perto para achar um angulo
				return direcao * velocidade
			return _manter_distancia(direcao, distancia) + _separacao()
		Estado.MIRANDO:
			tempo_estado -= delta
			# a mira acompanha o jogador e trava no final (da tempo de desviar)
			if tempo_estado > tempo_travar_mira:
				olhando = direcao
			if tempo_estado <= 0.0:
				_cuspir()
				estado = Estado.RECUPERANDO
				tempo_estado = tempo_recuperacao
		Estado.RECUPERANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				estado = Estado.ANDANDO
	return Vector2.ZERO


# anda para ficar na distancia ideal, rodeando o jogador de lado
func _manter_distancia(direcao: Vector2, distancia: float) -> Vector2:
	var lateral := direcao.orthogonal() * lado
	if distancia < distancia_min:
		return (-direcao + lateral * 0.5).normalized() * velocidade_fuga
	if distancia > distancia_max:
		return (direcao + lateral * 0.3).normalized() * velocidade
	return lateral * velocidade * 0.6


# so atira se nao tiver parede ou obstaculo no caminho
func _tem_visao() -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(global_position, jogador.global_position, 9)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _cuspir() -> void:
	recarga = recarga_cuspe
	lado = -lado
	# recuo e amassadinho junto com o cuspe
	impulso = -olhando * recuo_cuspe
	visual.scale = Vector2(1.3, 0.7)
	Efeitos.tremer(0.1)
	var gota: GotaAcida = cena_gota.instantiate()
	gota.direcao = olhando
	get_tree().current_scene.add_child(gota)
	gota.global_position = global_position + olhando * 16.0


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-16.0 * delta)
	var escala_alvo := Vector2.ONE
	var cor := Color.WHITE
	var pulinho := 0.0

	match estado:
		Estado.ANDANDO:
			if velocity.length() > 10.0:
				pulinho = absf(sin(tempo * 14.0)) * 1.5
		Estado.MIRANDO:
			# levanta o corpo e pisca em verde antes de cuspir
			escala_alvo = Vector2(0.85, 1.3)
			if int(tempo * 20.0) % 2 == 0:
				cor = Color(0.8, 1.7, 0.7)
		Estado.RECUPERANDO:
			escala_alvo = Vector2(1.2, 0.8)

	# amarelo piscando = enfraquecido (pode ser executado)
	if enfraquecido() and estado != Estado.MIRANDO:
		cor = Color.WHITE.lerp(Color(1.6, 1.4, 0.6), 0.5 + 0.5 * sin(tempo * 12.0))
	if flash > 0.0:
		cor = Color(3.0, 3.0, 3.0)

	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)
	visual.position.y = -pulinho
	visual.modulate = cor
	sprite.rotation = lerp_angle(sprite.rotation, olhando.angle(), suavizacao)

	# linha que mostra para onde o cuspe vai (fica forte quando trava)
	mira.visible = estado == Estado.MIRANDO
	mira.rotation = olhando.angle()
	mira.modulate.a = 1.0 if tempo_estado <= tempo_travar_mira else 0.45
