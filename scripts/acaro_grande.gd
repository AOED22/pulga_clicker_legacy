class_name AcaroGrande
extends Inimigo

enum Estado { PERSEGUINDO, PREPARANDO, GOLPEANDO, RECUPERANDO }

@export_group("Movimento")
@export var velocidade := 55.0
@export var alcance_visao := 420.0

@export_group("Porrada")
@export var alcance_porrada := 130.0
@export var distancia_golpe := 60.0
@export var raio_golpe := 85.0
@export var dano_golpe := 2
@export var tempo_preparo := 0.95
@export var tempo_recuperacao := 1.2
@export var altura_levantar := 20.0

@export_group("Furia")
@export var vida_furia := 4
@export var preparo_furia := 0.7
@export var raio_furia := 1.2

@export_group("Cenas")
@export var cena_anel: PackedScene
@export var fx_poeira: PackedScene
@export var fx_dano: PackedScene

var estado := Estado.PERSEGUINDO
var tempo_estado := 0.0
var duracao_preparo := 1.0
var centro_golpe := Vector2.ZERO
var tempo_passo := 0.0
var avisou_furia := false
var escala_sombra := Vector2.ONE

@onready var alerta: Node2D = $Alerta
@onready var alerta_area: Sprite2D = $Alerta/Area
@onready var alerta_preenche: Sprite2D = $Alerta/Preenchimento
@onready var sombra: Sprite2D = $Sombra


func _ready() -> void:
	super()
	escala_sombra = sombra.scale
	alerta.visible = false


func receber_dano(dano: int, empurrao: Vector2) -> bool:
	if estado == Estado.RECUPERANDO:
		dano += 1
	var morreu := super(dano, empurrao)
	if morreu:
		Efeitos.tremer(0.5)
		Efeitos.hit_stop(0.1, 0.05)
		Efeitos.criar(fx_morte, global_position + Vector2(-14, 8))
		Efeitos.criar(fx_morte, global_position + Vector2(14, -8))
		Efeitos.criar(fx_poeira, global_position)
	return morreu


func _ao_ser_atingido() -> void:
	Efeitos.criar(fx_dano, global_position)
	if estado == Estado.PREPARANDO or estado == Estado.GOLPEANDO:
		atordoado = 0.0
	if not avisou_furia and vida > 0 and vida <= vida_furia:
		avisou_furia = true
		_rugir()


func _furioso() -> bool:
	return vida <= vida_furia


func _raio_atual() -> float:
	return raio_golpe * (raio_furia if _furioso() else 1.0)


func _comportamento(delta: float) -> Vector2:
	var ate := jogador.global_position - global_position
	var direcao := ate.normalized()
	match estado:
		Estado.PERSEGUINDO:
			if ate.length() <= alcance_porrada:
				centro_golpe = global_position + direcao * distancia_golpe
				_mudar_estado(Estado.PREPARANDO)
			elif ate.length() < alcance_visao:
				_passos(delta)
				return direcao * velocidade + _separacao()
		Estado.PREPARANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.GOLPEANDO)
		Estado.GOLPEANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_impacto()
				_mudar_estado(Estado.RECUPERANDO)
		Estado.RECUPERANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.PERSEGUINDO)
	return Vector2.ZERO


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	match novo:
		Estado.PREPARANDO:
			duracao_preparo = tempo_preparo * (preparo_furia if _furioso() else 1.0)
			tempo_estado = duracao_preparo
			alerta.global_position = centro_golpe
			alerta.modulate.a = 1.0
			alerta.visible = true
			alerta_area.scale = Vector2.ONE * _raio_atual() * 2.0 / alerta_area.texture.get_size().x
			alerta_preenche.scale = Vector2.ZERO
		Estado.GOLPEANDO:
			tempo_estado = 0.07
		Estado.RECUPERANDO:
			tempo_estado = tempo_recuperacao


func _passos(delta: float) -> void:
	tempo_passo -= delta
	if tempo_passo > 0.0:
		return
	tempo_passo = 0.5
	visual.scale = Vector2(1.12, 0.88)
	Efeitos.criar(fx_poeira, global_position + Vector2(0, 14))
	if global_position.distance_to(jogador.global_position) < 260.0:
		Efeitos.tremer(0.05)


func _impacto() -> void:
	var raio := _raio_atual()
	var ate := jogador.global_position - centro_golpe
	if ate.length() <= raio and jogador.pode_ser_atingido():
		jogador.receber_dano(dano_golpe, ate.normalized())
	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		var distancia := objeto.global_position - centro_golpe
		if distancia.length() <= raio:
			objeto.atingido(distancia.normalized())
	Efeitos.criar_anel(cena_anel, centro_golpe, raio * 1.3, Color(1.0, 0.45, 0.4))
	Efeitos.criar(fx_poeira, centro_golpe)
	for i in 8:
		var angulo := TAU / 8.0 * i
		Efeitos.criar(fx_poeira, centro_golpe + Vector2.RIGHT.rotated(angulo) * raio * 0.85, angulo)
	Efeitos.tremer(0.55)
	Efeitos.hit_stop(0.05, 0.1)
	alerta_preenche.scale = alerta_area.scale
	alerta.modulate = Color(2.5, 2.5, 2.5, 1.0)
	var tween := create_tween()
	tween.tween_property(alerta, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(alerta.hide)


func _rugir() -> void:
	visual.scale = Vector2(1.5, 0.7)
	Efeitos.tremer(0.3)
	Efeitos.hit_stop(0.06, 0.1)
	Efeitos.criar_anel(cena_anel, global_position, 110.0, Color(1.0, 0.45, 0.4))


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-14.0 * delta)
	var escala_alvo := Vector2.ONE
	var altura_alvo := 0.0
	var cor := Color.WHITE
	var tremida := 0.0
	var inclinacao := 0.0

	match estado:
		Estado.PERSEGUINDO:
			if velocity.length() > 10.0:
				altura_alvo = absf(sin(tempo * 6.0)) * 3.0
		Estado.PREPARANDO:
			var progresso := 1.0 - tempo_estado / duracao_preparo
			if progresso < 0.2:
				escala_alvo = Vector2(1.25, 0.8)
			else:
				escala_alvo = Vector2(0.95, 1.18)
				altura_alvo = altura_levantar
			tremida = progresso * 2.5
			cor = Color.WHITE.lerp(Color(1.6, 0.7, 0.6), progresso)
			alerta_preenche.scale = alerta_area.scale * progresso
			alerta_preenche.modulate = Color(1, 1, 1, 1)
			if progresso > 0.75 and int(tempo * 24.0) % 2 == 0:
				alerta_preenche.modulate = Color(2.0, 1.5, 1.4, 1)
		Estado.GOLPEANDO:
			escala_alvo = Vector2(1.5, 0.55)
			suavizacao = 1.0 - exp(-45.0 * delta)
		Estado.RECUPERANDO:
			escala_alvo = Vector2(1.18, 0.82)
			inclinacao = sin(tempo * 9.0) * 0.06
			cor = Color(0.85, 0.85, 0.95)

	if _furioso() and estado != Estado.PREPARANDO:
		cor = cor * Color(1.25, 0.9, 0.9)
	cor = _cor_com_status(cor, estado == Estado.PREPARANDO)

	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)
	visual.position.y = lerpf(visual.position.y, -altura_alvo, suavizacao)
	visual.position.x = sin(tempo * 70.0) * tremida
	visual.rotation = lerpf(visual.rotation, inclinacao, suavizacao)
	visual.modulate = cor
	var folga := 1.0 - clampf(-visual.position.y / (altura_levantar * 3.0), 0.0, 0.4)
	sombra.scale = escala_sombra * folga * clampf(visual.scale.x, 0.0, 1.0)
