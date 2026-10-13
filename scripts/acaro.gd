class_name Acaro
extends CharacterBody2D

enum Estado { PERSEGUINDO, PREPARANDO, INVESTINDO, RECUPERANDO }

@export_group("Atributos")
@export var vida := 3
@export var velocidade := 80.0
@export var alcance_visao := 380.0
@export var dano_contato := 1
@export var alcance_contato := 26.0
@export var recarga_contato := 1.0

@export_group("Investida")
@export var alcance_investida := 110.0
@export var tempo_preparo := 0.45
@export var tempo_investida := 0.22
@export var velocidade_investida := 380.0
@export var tempo_recuperacao := 0.6

@export_group("Reação ao dano")
@export var tempo_atordoamento := 0.18
@export var atrito_impulso := 900.0
@export var atordoamento_spawn := 0.6

@export_group("Separação")
@export var raio_separacao := 34.0
@export var forca_separacao := 120.0

@export_group("Cenas")
@export var fx_morte: PackedScene

var estado := Estado.PERSEGUINDO
var impulso := Vector2.ZERO
var direcao_investida := Vector2.ZERO
var tempo := 0.0
var tempo_estado := 0.0
var tempo_contato := 0.0
var atordoado := 0.0
var flash := 0.0
var jogador: Jogador

@onready var visual: Node2D = $Visual


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	# Nasce pequeno, cresce e fica parado por um instante
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


# Devolve true se o ácaro morreu
func receber_dano(dano: int, empurrao: Vector2) -> bool:
	vida -= dano
	impulso = empurrao
	atordoado = tempo_atordoamento
	flash = 0.1
	visual.scale = Vector2(1.4, 0.65)
	_mudar_estado(Estado.PERSEGUINDO)
	if vida <= 0:
		_morrer()
		return true
	return false


func enfraquecido() -> bool:
	return vida <= 1


func _morrer() -> void:
	remove_from_group("inimigos")
	Efeitos.criar(fx_morte, global_position)
	queue_free()


func _jogador_vivo() -> bool:
	return is_instance_valid(jogador) and not jogador.morto


# ---------- Comportamento ----------

# Persegue, prepara, investe e descansa. Devolve a velocidade desejada
func _comportamento(delta: float) -> Vector2:
	var ate := jogador.global_position - global_position
	var distancia := ate.length()
	var direcao := ate.normalized()
	match estado:
		Estado.PERSEGUINDO:
			if distancia <= alcance_investida:
				_mudar_estado(Estado.PREPARANDO)
			elif distancia < alcance_visao:
				return direcao * velocidade + _separacao()
		Estado.PREPARANDO:
			# Fica parado avisando o ataque (dá tempo de desviar)
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				direcao_investida = direcao
				_mudar_estado(Estado.INVESTINDO)
		Estado.INVESTINDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.RECUPERANDO)
			return direcao_investida * velocidade_investida
		Estado.RECUPERANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.PERSEGUINDO)
	return Vector2.ZERO


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	match novo:
		Estado.PREPARANDO:
			tempo_estado = tempo_preparo
		Estado.INVESTINDO:
			tempo_estado = tempo_investida
		Estado.RECUPERANDO:
			tempo_estado = tempo_recuperacao


# Afasta o ácaro dos outros para eles não ficarem empilhados
func _separacao() -> Vector2:
	var empurrao := Vector2.ZERO
	for outro: Acaro in get_tree().get_nodes_in_group("inimigos"):
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


# ---------- Visual ----------

func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-16.0 * delta)
	var escala_alvo := Vector2.ONE
	var cor := Color.WHITE
	var pulinho := 0.0

	match estado:
		Estado.PERSEGUINDO:
			if velocity.length() > 10.0:
				pulinho = absf(sin(tempo * 12.0)) * 2.0
		Estado.PREPARANDO:
			# Encolhe e pisca em vermelho antes de investir
			escala_alvo = Vector2(1.25, 0.75)
			if int(tempo * 20.0) % 2 == 0:
				cor = Color(1.8, 0.7, 0.7)
		Estado.INVESTINDO:
			escala_alvo = Vector2(0.8, 1.25)

	# Amarelo piscando = enfraquecido (pode ser executado)
	if enfraquecido() and estado != Estado.PREPARANDO:
		cor = Color.WHITE.lerp(Color(1.6, 1.4, 0.6), 0.5 + 0.5 * sin(tempo * 12.0))
	if flash > 0.0:
		cor = Color(3.0, 3.0, 3.0)

	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)
	visual.position.y = -pulinho
	visual.modulate = cor
