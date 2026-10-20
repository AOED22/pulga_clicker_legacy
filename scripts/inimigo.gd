class_name Inimigo
extends CharacterBody2D

signal morreu

@export_group("Atributos")
@export var vida := 3
@export var dano_contato := 1
@export var alcance_contato := 26.0
@export var recarga_contato := 1.0

@export_group("Reacao ao dano")
@export var tempo_atordoamento := 0.18
@export var atrito_impulso := 900.0
@export var resistencia_empurrao := 1.0
@export var atordoamento_spawn := 0.6

@export_group("Separacao")
@export var raio_separacao := 34.0
@export var forca_separacao := 120.0

@export_group("Cenas")
@export var fx_morte: PackedScene

var impulso := Vector2.ZERO
var tempo := 0.0
var tempo_contato := 0.0
var atordoado := 0.0
var flash := 0.0
var jogador: Jogador

@onready var visual: Node2D = $Visual


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	visual.scale = Vector2.ZERO
	atordoado = atordoamento_spawn


func _physics_process(delta: float) -> void:
	tempo += delta
	tempo_contato = maxf(tempo_contato - delta, 0.0)
	atordoado = maxf(atordoado - delta, 0.0)
	flash = maxf(flash - delta, 0.0)
	impulso = impulso.move_toward(Vector2.ZERO, atrito_impulso * delta)

	var mover := Vector2.ZERO
	if atordoado <= 0.0 and _jogador_vivo():
		mover = _comportamento(delta)
	velocity = mover + impulso
	move_and_slide()
	_checar_contato()
	_atualizar_visual(delta)


func receber_dano(dano: int, empurrao: Vector2) -> bool:
	vida -= dano
	impulso = empurrao * resistencia_empurrao
	atordoado = tempo_atordoamento
	flash = 0.1
	visual.scale = Vector2(1.4, 0.65)
	_ao_ser_atingido()
	if vida <= 0:
		remove_from_group("inimigos")
		Efeitos.criar(fx_morte, global_position)
		morreu.emit()
		queue_free()
		return true
	return false


func enfraquecido() -> bool:
	return vida <= 1


func bloqueia(_direcao_golpe: Vector2) -> bool:
	return false


func receber_bloqueio(_empurrao: Vector2) -> void:
	pass


func _jogador_vivo() -> bool:
	return is_instance_valid(jogador) and not jogador.morto


func _comportamento(_delta: float) -> Vector2:
	return Vector2.ZERO


func _ao_ser_atingido() -> void:
	pass


func _atualizar_visual(_delta: float) -> void:
	pass


func _cor_com_status(cor: Color, ignorar_fraco := false) -> Color:
	if enfraquecido() and not ignorar_fraco:
		cor = Color.WHITE.lerp(Color(1.6, 1.4, 0.6), 0.5 + 0.5 * sin(tempo * 12.0))
	if flash > 0.0:
		cor = Color(3.0, 3.0, 3.0)
	return cor


func _separacao() -> Vector2:
	var empurrao := Vector2.ZERO
	for outro: Inimigo in get_tree().get_nodes_in_group("inimigos"):
		if outro == self:
			continue
		var ate := global_position - outro.global_position
		var distancia := ate.length()
		if distancia > 0.0 and distancia < raio_separacao:
			empurrao += ate / distancia * (1.0 - distancia / raio_separacao)
	return empurrao * forca_separacao


func _checar_contato() -> void:
	if tempo_contato > 0.0 or not _jogador_vivo():
		return
	var ate := jogador.global_position - global_position
	if ate.length() <= alcance_contato and jogador.pode_ser_atingido():
		jogador.receber_dano(dano_contato, ate.normalized())
		tempo_contato = recarga_contato
