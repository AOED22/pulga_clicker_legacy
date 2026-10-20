class_name Jogador
extends CharacterBody2D

signal vida_mudou(valor: int, maximo: int)
signal poder_mudou(valor: float)
signal acao_feita(nome: StringName)

enum Estado { LIVRE, DASH, CARGA, PULO }

var camada_obstaculo := 8

@export_group("Movimento")
@export var velocidade := 230.0
@export var velocidade_carga := 70.0
@export var aceleracao := 2200.0
@export var atrito := 2600.0

@export_group("Dash")
@export var dash_velocidade := 720.0
@export var dash_duracao := 0.18
@export var dash_recarga := 0.8
@export var dash_graca := 0.06
@export var fantasma_intervalo := 0.03
@export var buffer_tempo := 0.12

@export_group("Super Pulo")
@export var carga_min := 0.25
@export var carga_max := 0.9
@export var pulo_duracao := 0.55
@export var pulo_altura := 80.0
@export var pulo_distancia_min := 150.0
@export var pulo_distancia_max := 400.0
@export var altura_imune := 12.0
@export var pouso_raio := 100.0
@export var pouso_dano := 3
@export var pouso_forca := 480.0

@export_group("Combate")
@export var vida_max := 10
@export var poder_max := 100.0
@export var ataque_recarga := 0.5
@export var ataque_alcance := 72.0
@export var ataque_arco := 0.9
@export var ataque_forca := 320.0
@export var ataque_avanco := 150.0
@export var poder_por_golpe := 10.0
@export var poder_por_execucao := 15.0
@export var cura_execucao := 1
@export var custo_habilidade := 50.0
@export var onda_raio := 160.0
@export var onda_dano := 2
@export var onda_forca := 520.0

@export_group("Dano recebido")
@export var recuo_forca := 340.0
@export var atordoamento := 0.18
@export var invencibilidade_dano := 1.0

@export_group("Cenas")
@export var cena_anel: PackedScene
@export var fx_hit: PackedScene
@export var fx_sangue: PackedScene
@export var fx_poeira: PackedScene

@export_group("Visual")
@export var girar_sprite := true
@export var cor_carga := Color(1.0, 1.0, 0.4)
@export var cor_carga_cheia := Color(1.0, 1.0, 1.0)

var vida := 0:
	set(valor):
		vida = clampi(valor, 0, vida_max)
		vida_mudou.emit(vida, vida_max)

var poder := 0.0:
	set(valor):
		poder = clampf(valor, 0.0, poder_max)
		poder_mudou.emit(poder)

var estado := Estado.LIVRE
var morto := false
var altura := 0.0
var carga := 0.0
var olhando := Vector2.DOWN
var direcao_dash := Vector2.ZERO
var direcao_pulo := Vector2.ZERO
var direcao_ataque := Vector2.RIGHT
var distancia_pulo := 0.0
var tempo_estado := 0.0
var tempo_fantasma := 0.0
var tempo_andando := 0.0
var recarga_dash := 0.0
var recarga_ataque := 0.0
var invencibilidade := 0.0
var graca_dash := 0.0
var atordoado := 0.0
var flash := 0.0
var buffer_dash := 0.0
var mascara_base := 0
var bateu_parede := false
var tween_ataque: Tween
var luz_base := 0.3

@onready var colisao: CollisionShape2D = $Colisao
@onready var visual: Node2D = $Visual
@onready var sprite: Node2D = $Visual/Sprite
@onready var indicador_carga: Node2D = $Visual/IndicadorCarga
@onready var sombra: Node2D = $Sombra
@onready var efeito_ataque: Node2D = $EfeitoAtaque
@onready var poeira: CPUParticles2D = $Poeira
@onready var camera: CameraJogador = $Camera2D
@onready var luz: PointLight2D = $Luz
@onready var escala_sombra := sombra.scale


func _ready() -> void:
	mascara_base = collision_mask
	vida = vida_max


func definir_limites(limites: Rect2i) -> void:
	camera.definir_limites(limites)


func _physics_process(delta: float) -> void:
	if morto:
		return
	_atualizar_temporizadores(delta)
	var entrada := Input.get_vector("esquerda", "direita", "cima", "baixo")
	if entrada != Vector2.ZERO:
		olhando = entrada.normalized()
	if Input.is_action_just_pressed("dash"):
		buffer_dash = buffer_tempo
	match estado:
		Estado.LIVRE:
			_livre(entrada, delta)
		Estado.DASH:
			_dash(delta)
		Estado.CARGA:
			_carga(entrada, delta)
		Estado.PULO:
			_pulo(delta)
	_atualizar_visual(delta)


func _atualizar_temporizadores(delta: float) -> void:
	var tinha_recarga_dash := recarga_dash > 0.0
	recarga_dash = maxf(recarga_dash - delta, 0.0)
	if tinha_recarga_dash and recarga_dash <= 0.0 and not morto:
		visual.scale = Vector2(1.15, 0.9)
		luz.energy += 0.3
	recarga_ataque = maxf(recarga_ataque - delta, 0.0)
	invencibilidade = maxf(invencibilidade - delta, 0.0)
	graca_dash = maxf(graca_dash - delta, 0.0)
	atordoado = maxf(atordoado - delta, 0.0)
	flash = maxf(flash - delta, 0.0)
	buffer_dash = maxf(buffer_dash - delta, 0.0)


func em_dash() -> bool:
	return estado == Estado.DASH


func pode_ser_atingido() -> bool:
	return not morto and invencibilidade <= 0.0 and graca_dash <= 0.0 and estado != Estado.DASH and altura < altura_imune


func receber_dano(dano: int, direcao: Vector2) -> void:
	if not pode_ser_atingido():
		return
	vida -= dano
	invencibilidade = invencibilidade_dano
	atordoado = atordoamento
	flash = 0.1
	velocity = direcao * recuo_forca
	visual.scale = Vector2(1.35, 0.7)
	if estado == Estado.CARGA:
		estado = Estado.LIVRE
	Efeitos.criar(fx_sangue, global_position, direcao.angle())
	Efeitos.tremer(0.6)
	if vida <= 0:
		_morrer()
	else:
		Efeitos.hit_stop(0.08)


func _morrer() -> void:
	morto = true
	visual.visible = false
	sombra.visible = false
	luz.visible = false
	Efeitos.criar(fx_sangue, global_position)
	Efeitos.tremer(1.0)
	Efeitos.hit_stop(0.6, 0.15)
	await get_tree().create_timer(1.2, true, false, true).timeout
	get_tree().reload_current_scene()


func _livre(entrada: Vector2, delta: float) -> void:
	_mover(entrada * velocidade, delta)
	if atordoado > 0.0:
		return
	if buffer_dash > 0.0 and recarga_dash <= 0.0:
		_iniciar_dash(entrada)
	elif Input.is_action_just_pressed("super_pulo"):
		estado = Estado.CARGA
		carga = 0.0
	elif Input.is_action_pressed("atacar") and recarga_ataque <= 0.0:
		_atacar()
	if Input.is_action_just_pressed("habilidade"):
		_habilidade()


func _mover(alvo: Vector2, delta: float) -> void:
	if atordoado > 0.0:
		alvo = Vector2.ZERO
	var taxa := aceleracao if alvo != Vector2.ZERO else atrito
	velocity = velocity.move_toward(alvo, taxa * delta)
	move_and_slide()


func _iniciar_dash(entrada: Vector2) -> void:
	direcao_dash = entrada.normalized() if entrada != Vector2.ZERO else olhando
	estado = Estado.DASH
	tempo_estado = dash_duracao
	tempo_fantasma = 0.0
	recarga_dash = dash_recarga
	buffer_dash = 0.0
	Efeitos.criar(fx_poeira, global_position, direcao_dash.angle() + PI)
	Efeitos.tremer(0.12)
	acao_feita.emit(&"dash")


func _dash(delta: float) -> void:
	tempo_estado -= delta
	var progresso := 1.0 - tempo_estado / dash_duracao
	velocity = direcao_dash * dash_velocidade * lerpf(1.0, 0.3, progresso * progresso)
	move_and_slide()
	_criar_fantasma(delta)
	if tempo_estado <= 0.0:
		estado = Estado.LIVRE
		graca_dash = dash_graca


func _criar_fantasma(delta: float) -> void:
	tempo_fantasma -= delta
	if tempo_fantasma > 0.0:
		return
	tempo_fantasma = fantasma_intervalo
	var fantasma: Node2D = sprite.duplicate()
	get_parent().add_child(fantasma)
	get_parent().move_child(fantasma, get_index())
	fantasma.global_transform = sprite.global_transform
	fantasma.modulate = Color(1.0, 1.0, 1.0, 0.45)
	var tween := fantasma.create_tween()
	tween.tween_property(fantasma, "modulate:a", 0.0, 0.25)
	tween.tween_callback(fantasma.queue_free)


func _carga(entrada: Vector2, delta: float) -> void:
	carga = minf(carga + delta, carga_max)
	_mover(entrada * velocidade_carga, delta)
	if Input.is_action_just_released("super_pulo"):
		if carga >= carga_min:
			_iniciar_pulo(entrada)
		else:
			estado = Estado.LIVRE


func _iniciar_pulo(entrada: Vector2) -> void:
	direcao_pulo = entrada.normalized() if entrada != Vector2.ZERO else olhando
	distancia_pulo = lerpf(pulo_distancia_min, pulo_distancia_max, carga / carga_max)
	estado = Estado.PULO
	tempo_estado = 0.0
	collision_mask = mascara_base & ~camada_obstaculo
	visual.scale = Vector2(0.7, 1.35)
	Efeitos.criar(fx_poeira, global_position)
	bateu_parede = false
	acao_feita.emit(&"super_pulo")


func _pulo(delta: float) -> void:
	tempo_estado += delta
	var t := minf(tempo_estado / pulo_duracao, 1.0)
	altura = sin(t * PI) * pulo_altura
	velocity = direcao_pulo * (distancia_pulo / pulo_duracao)
	move_and_slide()
	if not bateu_parede and get_slide_collision_count() > 0:
		bateu_parede = true
		Efeitos.tremer(0.35)
		Efeitos.criar(fx_poeira, global_position)
		visual.scale = Vector2(1.4, 0.7)
		acao_feita.emit(&"bateu")
	if t >= 1.0:
		_aterrissar()


func _aterrissar() -> void:
	altura = 0.0
	estado = Estado.LIVRE
	velocity *= 0.3
	collision_mask = mascara_base
	_sair_de_obstaculo()
	visual.scale = Vector2(1.5, 0.55)
	Efeitos.criar(fx_poeira, global_position)
	Efeitos.tremer(0.55)
	Efeitos.criar_anel(cena_anel, global_position, pouso_raio)
	acao_feita.emit(&"pouso")
	if _atingir_inimigos(pouso_raio, pouso_dano, pouso_forca) > 0:
		Efeitos.hit_stop(0.07)
		acao_feita.emit(&"esmagou")


func _sair_de_obstaculo() -> void:
	var tentativas := 0
	while _preso_em_obstaculo() and tentativas < 80:
		global_position -= direcao_pulo * 4.0
		tentativas += 1


func _preso_em_obstaculo() -> bool:
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.transform = global_transform
	consulta.collision_mask = camada_obstaculo
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func _atacar() -> void:
	recarga_ataque = ataque_recarga
	direcao_ataque = (get_global_mouse_position() - global_position).normalized()
	if direcao_ataque == Vector2.ZERO:
		direcao_ataque = olhando
	olhando = direcao_ataque
	velocity += direcao_ataque * ataque_avanco
	_mostrar_efeito_ataque()
	acao_feita.emit(&"atacar")

	var acertou := false
	var matou := false
	var bloqueou := false
	for alvo: Inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not _no_arco(alvo):
			continue
		if alvo.bloqueia(direcao_ataque):
			alvo.receber_bloqueio(direcao_ataque * ataque_forca)
			velocity -= direcao_ataque * 200.0
			bloqueou = true
			continue
		var fraco := alvo.enfraquecido()
		var morreu := alvo.receber_dano(1, direcao_ataque * ataque_forca)
		Efeitos.criar(fx_hit, alvo.global_position, direcao_ataque.angle())
		if fraco:
			Efeitos.criar(fx_sangue, alvo.global_position, direcao_ataque.angle())
			acao_feita.emit(&"execucao")
		_sugar(fraco)
		acertou = true
		matou = matou or morreu
	if bloqueou and not acertou:
		acao_feita.emit(&"bloqueado")
	if acertou:
		acao_feita.emit(&"acertou")
		Efeitos.hit_stop(0.09 if matou else 0.045)
		Efeitos.tremer(0.4 if matou else 0.2)

	var bateu := false
	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		if not _no_arco(objeto):
			continue
		objeto.atingido(direcao_ataque)
		bateu = true
	if bateu and not acertou:
		Efeitos.tremer(0.08)

	var cortou := false
	for gota: GotaAcida in get_tree().get_nodes_in_group("projeteis"):
		if not _no_arco(gota):
			continue
		Efeitos.criar(fx_hit, gota.global_position, direcao_ataque.angle())
		gota.cortar()
		cortou = true
	if cortou:
		acao_feita.emit(&"cortou")
		if not acertou:
			Efeitos.hit_stop(0.03)
			Efeitos.tremer(0.15)


func _no_arco(alvo: Node2D) -> bool:
	var ate := alvo.global_position - global_position
	return ate.length() <= ataque_alcance and absf(direcao_ataque.angle_to(ate.normalized())) <= ataque_arco


func _sugar(executou: bool) -> void:
	poder += poder_por_golpe
	if executou:
		vida += cura_execucao
		poder += poder_por_execucao


func _habilidade() -> void:
	if poder < custo_habilidade:
		return
	poder -= custo_habilidade
	acao_feita.emit(&"habilidade")
	visual.scale = Vector2(1.3, 0.8)
	Efeitos.criar_anel(cena_anel, global_position, onda_raio)
	Efeitos.tremer(0.5)
	if _atingir_inimigos(onda_raio, onda_dano, onda_forca) > 0:
		Efeitos.hit_stop(0.06)


func _atingir_inimigos(raio: float, dano: int, forca: float) -> int:
	var acertos := 0
	for alvo: Inimigo in get_tree().get_nodes_in_group("inimigos"):
		var ate := alvo.global_position - global_position
		if ate.length() > raio:
			continue
		alvo.receber_dano(dano, ate.normalized() * forca)
		Efeitos.criar(fx_hit, alvo.global_position, ate.angle())
		acertos += 1
	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		var ate := objeto.global_position - global_position
		if ate.length() <= raio:
			objeto.atingido(ate.normalized())
	return acertos


func _mostrar_efeito_ataque() -> void:
	if tween_ataque and tween_ataque.is_valid():
		tween_ataque.kill()
	efeito_ataque.rotation = direcao_ataque.angle()
	efeito_ataque.visible = true
	efeito_ataque.modulate.a = 0.9
	efeito_ataque.scale = Vector2(0.5, 1.4)
	tween_ataque = create_tween().set_parallel()
	tween_ataque.tween_property(efeito_ataque, "scale", Vector2.ONE, 0.12)
	tween_ataque.tween_property(efeito_ataque, "modulate:a", 0.0, 0.12)
	tween_ataque.chain().tween_callback(efeito_ataque.hide)


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-18.0 * delta)

	visual.position.y = -altura - _balanco_andando(delta)
	sombra.scale = escala_sombra * maxf(1.0 - altura / (pulo_altura * 2.0), 0.5)

	var escala_alvo := Vector2.ONE
	if estado == Estado.CARGA:
		var forca := carga / carga_max
		escala_alvo = Vector2(1.0 + 0.2 * forca, 1.0 - 0.3 * forca)
	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)

	if girar_sprite:
		sprite.rotation = lerp_angle(sprite.rotation, olhando.angle(), suavizacao)

	var piscando := invencibilidade > 0.0 and int(invencibilidade * 20.0) % 2 == 0
	if flash > 0.0:
		visual.modulate = Color(3.0, 3.0, 3.0)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0, 0.4 if piscando else 1.0)

	indicador_carga.visible = estado == Estado.CARGA
	indicador_carga.scale.x = maxf(carga / carga_max, 0.01)
	indicador_carga.self_modulate = cor_carga_cheia if carga >= carga_max else cor_carga

	var luz_alvo := luz_base
	if estado == Estado.CARGA:
		luz_alvo = luz_base + 0.7 * carga / carga_max
	elif estado == Estado.DASH:
		luz_alvo = luz_base + 0.6
	luz.energy = lerpf(luz.energy, luz_alvo, suavizacao)

	poeira.emitting = estado == Estado.LIVRE and velocity.length() > velocidade * 0.5


func _balanco_andando(delta: float) -> float:
	if estado != Estado.LIVRE or altura > 0.0:
		return 0.0
	var ritmo := minf(velocity.length() / velocidade, 1.0)
	tempo_andando += delta * 14.0 * ritmo
	return absf(sin(tempo_andando)) * 2.0 * ritmo
