class_name Jogador
extends CharacterBody2D


signal vida_mudou(valor: int, maximo: int)
signal poder_mudou(valor: float)
signal acao_feita(nome: StringName)


enum Estado { LIVRE, DASH, CARGA, PULO }

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
@export var ataque_recarga := 0.38
@export var ataque_alcance := 72.0
@export var ataque_arco := 0.9
@export var ataque_duracao := 0.16
@export var ataque_alternar_sentido := true
@export var ataque_folga := 4.0
@export var ataque_buffer := 0.2
@export var combo_max := 3
@export var combo_janela := 0.35
@export var finalizador_escala := 1.3
@export var finalizador_forca := 1.6
@export var ataque_forca := 320.0
@export var agulha_recuo := 12.0
@export var corte_escala := 1.0
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
@export var fx_impacto: PackedScene
@export var fx_sangue: PackedScene
@export var fx_poeira: PackedScene

@export_group("Visual")
@export var girar_sprite := false
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
var olhando := Vector2.DOWN
var tempo_estado := 0.0

var camada_obstaculo := 8
var mascara_base := 0

var direcao_dash := Vector2.ZERO
var recarga_dash := 0.0
var graca_dash := 0.0
var buffer_dash := 0.0
var tempo_fantasma := 0.0

var carga := 0.0
var direcao_pulo := Vector2.ZERO
var distancia_pulo := 0.0
var bateu_parede := false

var direcao_ataque := Vector2.RIGHT
var recarga_ataque := 0.0
var buffer_ataque := 0.0
var combo := 0
var tempo_combo := 0.0

var swing_ativo := false
var swing_final := false
var swing_tempo := 0.0
var swing_sentido := -1.0
var swing_angulo_inicio := 0.0
var swing_arco := 0.9
var swing_alcance := 72.0
var swing_forca := 320.0
var swing_duracao := 0.16
var swing_impacto := 1.0
var swing_atingidos := {}
var swing_acertou := false
var swing_bloqueou := false
var swing_bateu := false
var swing_cortou := false
var formas_alvo := {}
var tween_ataque: Tween

var invencibilidade := 0.0
var atordoado := 0.0
var flash := 0.0

var tempo_andando := 0.0
var anim_acao: StringName = &""
var tempo_acao := 0.0
var luz_base := 0.3


@onready var colisao: CollisionShape2D = $Colisao
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var indicador_carga: Node2D = $Visual/IndicadorCarga
@onready var sombra: Node2D = $Sombra
@onready var agulha: Sprite2D = $Agulha
@onready var corte: AnimatedSprite2D = $Corte
@onready var poeira: CPUParticles2D = $Poeira
@onready var camera: CameraJogador = $Camera2D
@onready var luz: PointLight2D = $Luz
@onready var escala_sombra := sombra.scale


func _ready() -> void:
	mascara_base = collision_mask
	vida = vida_max
	agulha.offset = Vector2(-agulha_recuo, -agulha.texture.get_height() / 2.0)
	corte.animation_finished.connect(_esconder_corte)


func _physics_process(delta: float) -> void:
	if morto:
		return

	_atualizar_temporizadores(delta)

	var entrada := Input.get_vector("esquerda", "direita", "cima", "baixo")
	if entrada != Vector2.ZERO:
		olhando = entrada.normalized()

	if Input.is_action_just_pressed("dash"):
		buffer_dash = buffer_tempo
	if Input.is_action_just_pressed("atacar"):
		buffer_ataque = ataque_buffer

	match estado:
		Estado.LIVRE:
			_livre(entrada, delta)
		Estado.DASH:
			_dash(delta)
		Estado.CARGA:
			_carga(entrada, delta)
		Estado.PULO:
			_pulo(delta)

	_atualizar_swing(delta)
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
	buffer_ataque = maxf(buffer_ataque - delta, 0.0)
	tempo_combo = maxf(tempo_combo - delta, 0.0)


func definir_limites(limites: Rect2i) -> void:
	camera.definir_limites(limites)


func em_dash() -> bool:
	return estado == Estado.DASH


func pode_ser_atingido() -> bool:
	return (
		not morto
		and invencibilidade <= 0.0
		and graca_dash <= 0.0
		and estado != Estado.DASH
		and altura < altura_imune
	)


func receber_dano(dano: int, direcao: Vector2) -> void:
	if not pode_ser_atingido():
		return

	vida -= dano
	invencibilidade = invencibilidade_dano
	atordoado = atordoamento
	flash = 0.1
	velocity = direcao * recuo_forca
	visual.scale = Vector2(1.35, 0.7)
	_tocar_acao(&"dano")

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
	_cancelar_swing()
	luz.visible = false
	indicador_carga.visible = false
	visual.modulate = Color.WHITE
	visual.scale = Vector2.ONE
	visual.position.y = 0.0
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.play(&"morte")

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
	elif (buffer_ataque > 0.0 or Input.is_action_pressed("atacar")) and recarga_ataque <= 0.0:
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
	_cancelar_swing()
	tempo_acao = 0.0

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

	var fantasma := Sprite2D.new()
	fantasma.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	fantasma.flip_h = sprite.flip_h
	fantasma.offset = sprite.offset
	fantasma.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_parent().add_child(fantasma)
	get_parent().move_child(fantasma, get_index())
	fantasma.global_transform = sprite.global_transform
	fantasma.modulate = Color(1.0, 1.0, 1.0, 0.65)

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
	_cancelar_swing()
	tempo_acao = 0.0

	estado = Estado.PULO
	tempo_estado = 0.0
	collision_mask = mascara_base & ~camada_obstaculo
	visual.scale = Vector2(0.7, 1.35)
	bateu_parede = false

	Efeitos.criar(fx_poeira, global_position)
	acao_feita.emit(&"super_pulo")


func _pulo(delta: float) -> void:
	tempo_estado += delta
	var t := minf(tempo_estado / pulo_duracao, 1.0)
	altura = sin(t * PI) * pulo_altura
	velocity = direcao_pulo * (distancia_pulo / pulo_duracao)
	move_and_slide()

	if not bateu_parede and get_slide_collision_count() > 0:
		bateu_parede = true
		visual.scale = Vector2(1.4, 0.7)
		Efeitos.tremer(0.35)
		Efeitos.criar(fx_poeira, global_position)
		acao_feita.emit(&"bateu")

	if t >= 1.0:
		_aterrissar()


func _aterrissar() -> void:
	altura = 0.0
	estado = Estado.LIVRE
	velocity *= 0.3
	collision_mask = mascara_base
	_sair_de_obstaculo()
	visual.scale = Vector2(1.3, 0.7)
	_tocar_acao(&"pouso")

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
	buffer_ataque = 0.0

	if tempo_combo <= 0.0:
		combo = 0
	combo += 1
	swing_final = combo >= maxi(combo_max, 1)

	var escala := finalizador_escala if swing_final else 1.0
	swing_arco = ataque_arco * escala
	swing_alcance = ataque_alcance * escala
	swing_forca = ataque_forca * (finalizador_forca if swing_final else 1.0)
	swing_duracao = ataque_duracao * (1.25 if swing_final else 1.0)
	swing_impacto = 1.5 if swing_final else 1.0
	recarga_ataque = ataque_recarga + (0.12 if swing_final else 0.0)

	if swing_final:
		combo = 0
		tempo_combo = 0.0
	else:
		tempo_combo = ataque_recarga + combo_janela

	direcao_ataque = (get_global_mouse_position() - global_position).normalized()
	if direcao_ataque == Vector2.ZERO:
		direcao_ataque = olhando
	olhando = direcao_ataque
	velocity += direcao_ataque * ataque_avanco * (1.5 if swing_final else 1.0)
	visual.scale = Vector2(1.45, 0.7) if swing_final else Vector2(1.25, 0.8)

	if ataque_alternar_sentido:
		swing_sentido = -swing_sentido
	if swing_final:
		_tocar_acao(&"ataque_final")
	else:
		_tocar_acao(&"ataque_a" if combo % 2 == 1 else &"ataque_b")

	swing_ativo = true
	swing_tempo = 0.0
	swing_angulo_inicio = direcao_ataque.angle() - swing_arco * swing_sentido
	swing_atingidos.clear()
	swing_acertou = false
	swing_bloqueou = false
	swing_bateu = false
	swing_cortou = false
	_iniciar_efeito_swing()

	if swing_final:
		Efeitos.tremer(0.18)

	acao_feita.emit(&"atacar")


func _atualizar_swing(delta: float) -> void:
	if not swing_ativo:
		return

	swing_tempo += delta
	var t := minf(swing_tempo / maxf(swing_duracao, 0.01), 1.0)
	var progresso := 1.0 - pow(1.0 - t, 3.0)
	var inicio := -swing_arco * swing_sentido
	var offset := lerpf(inicio, swing_arco * swing_sentido, progresso)
	var angulo := direcao_ataque.angle() + offset

	agulha.rotation = angulo
	_golpear(minf(inicio, offset), maxf(inicio, offset))

	if t >= 1.0:
		_terminar_swing()


func _terminar_swing() -> void:
	swing_ativo = false
	if swing_bloqueou and not swing_acertou:
		acao_feita.emit(&"bloqueado")
	_terminar_efeito_swing(false)


func _cancelar_swing() -> void:
	if not swing_ativo:
		return
	swing_ativo = false
	_terminar_efeito_swing(true)


func _golpear(de: float, ate: float) -> void:
	for alvo: Inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not _novo_no_intervalo(alvo, de, ate):
			continue
		_golpear_inimigo(alvo)

	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		if not _novo_no_intervalo(objeto, de, ate):
			continue
		if not swing_bateu and not swing_acertou:
			Efeitos.tremer(0.08 * swing_impacto)
		swing_bateu = true
		objeto.atingido(_direcao_para(objeto))

	for gota: GotaAcida in get_tree().get_nodes_in_group("projeteis"):
		if not _novo_no_intervalo(gota, de, ate):
			continue
		var dir_gota := _direcao_para(gota)
		Efeitos.criar(fx_hit, gota.global_position, dir_gota.angle())
		_criar_impacto(gota.global_position, dir_gota, 0.6)
		gota.cortar()
		if not swing_cortou:
			acao_feita.emit(&"cortou")
			if not swing_acertou:
				Efeitos.hit_stop(0.03)
				Efeitos.tremer(0.15)
		swing_cortou = true


func _golpear_inimigo(alvo: Inimigo) -> void:
	var dir_golpe := _direcao_para(alvo)

	if alvo.bloqueia(dir_golpe):
		alvo.receber_bloqueio(dir_golpe * swing_forca)
		velocity -= dir_golpe * 200.0
		swing_bloqueou = true
		return

	var fraco := alvo.enfraquecido()
	var morreu := alvo.receber_dano(1, dir_golpe * swing_forca)

	Efeitos.criar(fx_hit, alvo.global_position, dir_golpe.angle())
	var forma := _forma_alvo(alvo)
	var contato: Vector2 = alvo.global_position + (forma["centro"] as Vector2) - dir_golpe * (forma["raio"] as float) * 0.5
	_criar_impacto(contato, dir_golpe, (1.0 + (swing_impacto - 1.0) * 0.8) * (1.25 if morreu else 1.0))
	if morreu and not swing_final:
		Efeitos.criar_anel(
			cena_anel,
			alvo.global_position,
			34.0 if morreu else 26.0,
			Color(1.0, 0.9, 0.5, 0.8)
		)
	if fraco:
		Efeitos.criar(fx_sangue, alvo.global_position, dir_golpe.angle())
		acao_feita.emit(&"execucao")

	_sugar(fraco)

	if not swing_acertou:
		acao_feita.emit(&"acertou")
	swing_acertou = true

	Efeitos.hit_stop((0.11 if morreu else 0.055) * swing_impacto)
	Efeitos.tremer((0.4 if morreu else 0.2) * swing_impacto)


func _direcao_para(alvo: Node2D) -> Vector2:
	var para := alvo.global_position - global_position
	return para.normalized() if para.length() > 1.0 else direcao_ataque


func _forma_alvo(alvo: Node2D) -> Dictionary:
	var id := alvo.get_instance_id()
	if formas_alvo.has(id):
		return formas_alvo[id]

	var caixa := Rect2()
	var achou := false

	for filho in alvo.get_children():
		var colisao_filho := filho as CollisionShape2D
		if colisao_filho == null or colisao_filho.shape == null:
			continue
		var rect_forma: Rect2 = colisao_filho.global_transform * colisao_filho.shape.get_rect()
		caixa = rect_forma if not achou else caixa.merge(rect_forma)
		achou = true

	if not achou:
		for no: Node in alvo.find_children("*", "Sprite2D", true, false):
			var sprite := no as Sprite2D
			if sprite == null or sprite.texture == null or not sprite.is_visible_in_tree():
				continue
			var rect_sprite: Rect2 = sprite.global_transform * sprite.get_rect()
			caixa = rect_sprite if not achou else caixa.merge(rect_sprite)
			achou = true

	var resultado := {"centro": Vector2.ZERO, "raio": 14.0}
	if achou:
		resultado["centro"] = caixa.get_center() - alvo.global_position
		resultado["raio"] = maxf(caixa.size.x, caixa.size.y) * 0.5

	formas_alvo[id] = resultado
	return resultado


func _novo_no_intervalo(alvo: Node2D, de: float, ate: float) -> bool:
	var id := alvo.get_instance_id()
	if swing_atingidos.has(id):
		return false
	if alvo.global_position.distance_to(global_position) > swing_alcance + 90.0:
		return false

	var forma := _forma_alvo(alvo)
	var raio: float = forma["raio"] + ataque_folga
	var para: Vector2 = alvo.global_position + (forma["centro"] as Vector2) - global_position
	var distancia := para.length()

	if distancia - raio > swing_alcance:
		return false
	if distancia > raio:
		var angulo := direcao_ataque.angle_to(para)
		var meia_largura := asin(minf(raio / distancia, 1.0))
		if angulo + meia_largura < de or angulo - meia_largura > ate:
			return false

	swing_atingidos[id] = true
	return true


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
	_tocar_acao(&"habilidade")
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


func _iniciar_efeito_swing() -> void:
	if tween_ataque and tween_ataque.is_valid():
		tween_ataque.kill()

	agulha.rotation = swing_angulo_inicio
	agulha.modulate.a = 1.0
	agulha.visible = true

	corte.stop()
	corte.rotation = direcao_ataque.angle()
	corte.scale = Vector2(corte_escala, corte_escala * swing_sentido)
	corte.modulate.a = 1.0
	corte.speed_scale = 1.0 / (swing_duracao * 1.3)
	corte.visible = true
	corte.play(&"final" if swing_final else &"normal")


func _terminar_efeito_swing(cancelado: bool) -> void:
	if tween_ataque and tween_ataque.is_valid():
		tween_ataque.kill()

	tween_ataque = create_tween().set_parallel()
	tween_ataque.tween_property(agulha, "modulate:a", 0.0, 0.08).set_delay(0.03)
	if cancelado:
		tween_ataque.tween_property(corte, "modulate:a", 0.0, 0.08)
	tween_ataque.chain().tween_callback(_esconder_efeito_ataque)


func _esconder_efeito_ataque() -> void:
	agulha.hide()
	if corte.modulate.a < 0.1:
		_esconder_corte()


func _esconder_corte() -> void:
	corte.stop()
	corte.hide()


func _criar_impacto(posicao: Vector2, direcao: Vector2, escala: float) -> void:
	var impacto := Efeitos.criar(fx_impacto, posicao, direcao.angle() + randf_range(-0.25, 0.25))
	if impacto:
		impacto.scale = Vector2.ONE * escala


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-18.0 * delta)

	_atualizar_animacao(delta)

	visual.position.y = -altura - _balanco_andando(delta)
	sombra.scale = escala_sombra * maxf(1.0 - altura / (pulo_altura * 2.0), 0.5)

	var escala_alvo := Vector2.ONE
	if estado == Estado.CARGA:
		var forca := carga / carga_max
		escala_alvo = Vector2(1.0 + 0.08 * forca, 1.0 - 0.1 * forca)
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


func _tocar_acao(nome: StringName) -> void:
	var frames := sprite.sprite_frames
	anim_acao = nome
	tempo_acao = frames.get_frame_count(nome) / frames.get_animation_speed(nome)
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.play(nome)


func _atualizar_animacao(delta: float) -> void:
	if absf(olhando.x) > 0.1:
		sprite.flip_h = olhando.x < 0.0

	tempo_acao = maxf(tempo_acao - delta, 0.0)

	if estado == Estado.PULO:
		var t := clampf(tempo_estado / pulo_duracao, 0.0, 0.999)
		var quadro := 0 if t < 0.15 else (1 if t < 0.45 else (2 if t < 0.8 else 3))
		if sprite.animation != &"pulo":
			sprite.animation = &"pulo"
		sprite.pause()
		sprite.frame = quadro
		return

	var nome: StringName = &"idle"
	var velocidade_anim := 1.0
	match estado:
		Estado.DASH:
			nome = &"dash"
		Estado.CARGA:
			nome = &"carga"
		_:
			if tempo_acao > 0.0:
				nome = anim_acao
			elif velocity.length() > velocidade * 0.15 and atordoado <= 0.0:
				nome = &"andar"
				velocidade_anim = clampf(velocity.length() / velocidade, 0.6, 1.25)

	sprite.speed_scale = velocidade_anim
	var ciclica := nome != anim_acao or tempo_acao <= 0.0
	if sprite.animation != nome or (ciclica and not sprite.is_playing()):
		sprite.play(nome)


func _balanco_andando(delta: float) -> float:
	if estado != Estado.LIVRE or altura > 0.0:
		return 0.0

	var ritmo := minf(velocity.length() / velocidade, 1.0)
	tempo_andando += delta * 14.0 * ritmo
	return absf(sin(tempo_andando)) * 0.5 * ritmo
