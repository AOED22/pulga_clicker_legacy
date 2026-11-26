class_name RainhaFormiga
extends Inimigo

signal vida_mudou(valor: int, maximo: int)
signal fase_mudou(fase: int)
signal exposta_mudou(exposta: bool)
signal onda_iniciada(numero: int)

enum Estado {
	INATIVA,
	INVOCANDO, PROTEGIDA, EXPOSTA,
	TRANSICAO,
	PERSEGUINDO, PREPARANDO, INVESTINDO, SALTANDO, DISPARANDO, RECUPERANDO, ATORDOADA,
	MORRENDO,
}

enum Ataque {
	MORDIDA, PATAS, PANCADA, INVESTIDA, INVESTIDA_FURIOSA, CUSPE, CHUVA, INVOCACAO,
	BOMBARDEIO, SALTO, TERREMOTO,
}

const COR_ALERTA := Color(1.0, 0.25, 0.2)
const COR_ACIDO := Color(0.55, 1.0, 0.25)
const COR_TERREMOTO := Color(1.0, 0.5, 0.15)

@export_group("Fases")
@export_range(0.1, 0.9, 0.05) var fracao_transicao := 0.5
@export_range(0.05, 0.5, 0.05) var fracao_furia := 0.25

@export_group("Fase 1 - Colonia")
@export var tempo_chamado := 0.9
@export var intervalo_invocacao := 0.18
@export var tempo_exposta := 4.5
@export var giro_fase1 := 1.5
@export var intervalo_bombardeio_fase1 := 3.2

@export_group("Fase 2 - Movimento")
@export var velocidade := 105.0
@export var giro := 2.4
@export var giro_preparo := 3.2
@export var tempo_travar_mira := 0.15
@export var intervalo_ataque := 0.95
@export var velocidade_furia := 1.3
@export var ritmo_furia := 0.55
@export var preparo_furia := 0.75
@export_range(0.0, 1.0, 0.05) var chance_combo := 0.3

@export_group("Tempo de preparo (telegrafo)")
@export var preparo_mordida := 0.5
@export var preparo_patas := 0.6
@export var preparo_pancada := 0.85
@export var preparo_investida := 0.8
@export var preparo_cuspe := 0.65
@export var preparo_chuva := 0.9
@export var preparo_invocacao := 0.8
@export var preparo_bombardeio := 0.8
@export var preparo_salto := 0.75
@export var preparo_terremoto := 1.0

@export_group("Dano")
@export var dano_mordida := 2
@export var dano_patas := 2
@export var dano_pancada := 2
@export var dano_investida := 2
@export var dano_cuspe := 2
@export var dano_chuva := 1
@export var dano_bombardeio := 2
@export var dano_salto := 3
@export var dano_terremoto := 2

@export_group("Corpo a corpo")
@export var distancia_mordida := 80.0
@export var raio_mordida := 62.0
@export var raio_patas := 150.0
@export var arco_patas := 100.0
@export var raio_pancada := 165.0

@export_group("Investida")
@export var distancia_investida := 560.0
@export var largura_investida := 70.0
@export var velocidade_inicial := 200.0
@export var velocidade_maxima := 700.0
@export var tempo_tonta := 2.0

@export_group("Acido")
@export var gotas_chuva := 11
@export var arco_chuva := 90.0
@export var intervalo_chuva := 0.1
@export var velocidade_chuva := 290.0

@export_group("Salto / Bombardeio / Terremoto")
@export var duracao_salto := 0.75
@export var raio_salto := 135.0
@export var zonas_bombardeio := 3
@export var raio_cuspe := 60.0
@export var duracao_cuspe := 0.75
@export var raio_bombardeio := 70.0
@export var atraso_bombardeio := 0.9
@export var raio_terremoto_externo := 310.0
@export var atraso_terremoto := 0.55

@export_group("Invocacao na fase 2")
@export var recarga_invocacao_fase2 := 12.0
@export var max_minions_fase2 := 4

@export_group("Cenas")
@export var cena_acaro: PackedScene
@export var cena_acaro_grande: PackedScene
@export var cena_atiradora: PackedScene
@export var cena_operaria: PackedScene
@export var cena_gota: PackedScene
@export var cena_globulo: PackedScene
@export var cena_poca: PackedScene
@export var cena_anel: PackedScene
@export var fx_poeira: PackedScene
@export var fx_migalhas: PackedScene
@export var fx_acido: PackedScene

@export_group("Arte")
@export var frames_furia: SpriteFrames

var fase := 1
var estado := Estado.INATIVA
var ataque: int = Ataque.MORDIDA
var ultimo_ataque: int = -1

var vida_max := 1
var vida_transicao := 1
var vida_furia := 1
var furiosa := false
var dano_normal := 1

var onda := 0
var minions_vivos := 0
var fila_invocacao: Array = []
var contador_spawn := 0
var tempo_invocar := 0.0
var recarga_bombardeio := 0.0

var tempo_estado := 0.0
var duracao_estado := 1.0
var recarga_ataque := 0.0
var recarga_invocacao := 0.0
var recuperacao_vulneravel := false

var olhando := Vector2.LEFT
var direcao_travada := Vector2.LEFT
var direcao_investida := Vector2.LEFT
var percorrido := 0.0
var ultima_poca := 0.0
var investidas_restantes := 0
var alvo_salto := Vector2.ZERO

var disparos_restantes := 0
var tempo_disparo := 0.0
var angulo_varredura := 0.0
var passo_varredura := 0.0

var tempo_poeira := 0.0
var tempo_passo := 0.0
var lado := -1.0
var tempo_cuspe_visual := 0.0

var rugido := 0.0
var escudo_alfa := 0.0
var escudo_pulso := 0.0
var escala_escudo := Vector2.ONE
var escala_sombra := Vector2.ONE

@onready var colisao: CollisionShape2D = $Colisao
@onready var corpo: AnimatedSprite2D = $Visual/Corpo
@onready var aura: Sprite2D = $Visual/Aura
@onready var brilho: Sprite2D = $Visual/Brilho
@onready var escudo: Sprite2D = $Escudo
@onready var sombra: Sprite2D = $Sombra
@onready var aviso: AvisoAtaque = $Aviso


func _ready() -> void:
	super()
	visual.scale = Vector2.ONE
	vida_max = vida
	vida_transicao = int(ceil(vida_max * fracao_transicao))
	vida_furia = int(ceil(vida_max * fracao_furia))
	dano_normal = dano_contato
	escala_escudo = escudo.scale
	escala_sombra = sombra.scale
	escudo.visible = false
	brilho.modulate.a = 0.0
	aura.modulate.a = 0.0


func iniciar_luta() -> void:
	if estado != Estado.INATIVA:
		return
	vida_mudou.emit(vida, vida_max)
	fase_mudou.emit(1)
	_mudar_estado(Estado.INVOCANDO)



func receber_dano(dano: int, empurrao: Vector2) -> bool:
	if not _pode_receber_dano():
		_pulsar_escudo()
		return false

	if fase == 1:
		dano = mini(dano, vida - vida_transicao)
		if dano <= 0:
			return false
	elif estado == Estado.ATORDOADA or (estado == Estado.RECUPERANDO and recuperacao_vulneravel):
		dano += 1

	if vida - dano <= 0:
		_morrer()
		return true

	var resultado := super(dano, empurrao)
	visual.scale = Vector2.ONE
	return resultado


func _ao_ser_atingido() -> void:
	atordoado = 0.0
	vida_mudou.emit(vida, vida_max)
	if fase == 1:
		if vida <= vida_transicao and estado != Estado.TRANSICAO:
			_transicao()
	elif not furiosa and vida <= vida_furia:
		_enfurecer()


func _pode_receber_dano() -> bool:
	match estado:
		Estado.INATIVA, Estado.INVOCANDO, Estado.PROTEGIDA, Estado.TRANSICAO, Estado.SALTANDO, Estado.MORRENDO:
			return false
	return true


func bloqueia(_direcao_golpe: Vector2) -> bool:
	return not _pode_receber_dano()


func receber_bloqueio(empurrao: Vector2) -> void:
	var ponto := global_position - empurrao.normalized() * 60.0
	_pulsar_escudo()
	Efeitos.criar(fx_poeira, ponto, empurrao.angle() + PI)
	Efeitos.criar_anel(cena_anel, ponto, 30.0, Color(0.6, 0.9, 1.0))
	Efeitos.tremer(0.1)
	Efeitos.hit_stop(0.03)


func _pulsar_escudo() -> void:
	escudo_pulso = 1.0


func enfraquecido() -> bool:
	return vida <= 1 and fase == 2


func _checar_contato() -> void:
	if fase == 1 or estado == Estado.TRANSICAO or estado == Estado.ATORDOADA:
		return
	if estado == Estado.SALTANDO or estado == Estado.MORRENDO:
		return
	super()



func _comportamento(delta: float) -> Vector2:
	recarga_invocacao = maxf(recarga_invocacao - delta, 0.0)
	var ate := jogador.global_position - global_position
	var distancia := ate.length()
	var direcao := ate.normalized()

	match estado:
		Estado.INVOCANDO:
			olhando = _girar(olhando, direcao, giro_fase1 * delta)
			tempo_estado -= delta
			if tempo_estado > 0.0:
				return Vector2.ZERO
			tempo_invocar -= delta
			if tempo_invocar > 0.0:
				return Vector2.ZERO
			if fila_invocacao.is_empty():
				_mudar_estado(Estado.PROTEGIDA)
			else:
				_invocar_proximo()
				tempo_invocar = intervalo_invocacao

		Estado.PROTEGIDA:
			olhando = _girar(olhando, direcao, giro_fase1 * delta)
			recarga_bombardeio -= delta
			if recarga_bombardeio <= 0.0 and minions_vivos > 0:
				recarga_bombardeio = intervalo_bombardeio_fase1
				_bombardeio_fase1()
			if minions_vivos <= 0:
				_mudar_estado(Estado.EXPOSTA)

		Estado.EXPOSTA:
			olhando = _girar(olhando, direcao, giro_fase1 * delta)
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.INVOCANDO)

		Estado.PERSEGUINDO:
			olhando = _girar(olhando, direcao, giro * delta)
			recarga_ataque = maxf(recarga_ataque - delta, 0.0)
			if recarga_ataque <= 0.0:
				var escolhido := _escolher_ataque(distancia)
				if escolhido >= 0:
					_comecar_ataque(escolhido)
					return Vector2.ZERO
			if distancia < 90.0:
				return Vector2.ZERO
			_passos(delta)
			return olhando * velocidade * (velocidade_furia if furiosa else 1.0)

		Estado.PREPARANDO:
			tempo_estado -= delta
			var progresso := clampf(1.0 - tempo_estado / duracao_estado, 0.0, 1.0)
			if tempo_estado > tempo_travar_mira:
				olhando = _girar(olhando, direcao, giro_preparo * delta)
				direcao_travada = olhando
			_atualizar_aviso(progresso)
			if tempo_estado <= 0.0:
				_executar_ataque()
				return Vector2.ZERO
			if ataque == Ataque.INVESTIDA or ataque == Ataque.INVESTIDA_FURIOSA:
				return -direcao_travada * 30.0

		Estado.INVESTINDO:
			if percorrido > 20.0 and get_slide_collision_count() > 0:
				_bater()
				return Vector2.ZERO
			if tempo_contato > 0.0:
				_terminar_investida(false)
				return Vector2.ZERO
			var total := _distancia_da_investida()
			var progresso_dash := clampf(percorrido / total, 0.0, 1.0)
			var maxima := velocidade_maxima * (1.15 if furiosa else 1.0)
			var vel := lerpf(velocidade_inicial, maxima, progresso_dash * progresso_dash)
			percorrido += vel * delta
			tempo_poeira -= delta
			if tempo_poeira <= 0.0:
				tempo_poeira = 0.06
				Efeitos.criar(fx_poeira, global_position - direcao_investida * 40.0, direcao_investida.angle() + PI)
			if furiosa and percorrido - ultima_poca >= 120.0:
				ultima_poca = percorrido
				_criar_poca(global_position - direcao_investida * 40.0, 34.0)
			if percorrido >= total:
				_terminar_investida(true)
			return direcao_investida * vel

		Estado.SALTANDO:
			tempo_estado -= delta
			aviso.atualizar(1.0 - clampf(tempo_estado / duracao_salto, 0.0, 1.0))
			if tempo_estado <= 0.0:
				_aterrissar()
				return Vector2.ZERO
			return (alvo_salto - global_position) / maxf(tempo_estado, delta)

		Estado.DISPARANDO:
			tempo_disparo -= delta
			if tempo_disparo <= 0.0:
				tempo_disparo = intervalo_chuva
				var angulo := direcao_travada.rotated(angulo_varredura)
				_disparar_gota(angulo, dano_chuva, velocidade_chuva + randf_range(-30.0, 30.0))
				angulo_varredura += passo_varredura
				disparos_restantes -= 1
				Efeitos.tremer(0.06)
				if disparos_restantes <= 0:
					_mudar_estado(Estado.RECUPERANDO)

		Estado.RECUPERANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_fim_do_ataque(true)

		Estado.ATORDOADA:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_fim_do_ataque(false)

	return Vector2.ZERO


func _mudar_estado(novo: Estado) -> void:
	var anterior := estado
	estado = novo
	dano_contato = dano_normal

	match novo:
		Estado.INVOCANDO:
			onda += 1
			fila_invocacao = _montar_onda()
			tempo_estado = tempo_chamado
			tempo_invocar = 0.0
			Efeitos.criar_anel(cena_anel, global_position, 150.0, Color(0.9, 0.55, 0.25))
			onda_iniciada.emit(onda)
		Estado.PROTEGIDA:
			recarga_bombardeio = 2.0
		Estado.EXPOSTA:
			tempo_estado = tempo_exposta
			_quebrar_escudo()
		Estado.PREPARANDO:
			duracao_estado = _tempo_preparo()
			tempo_estado = duracao_estado
			_configurar_aviso()
		Estado.INVESTINDO:
			dano_contato = dano_investida
			tempo_contato = 0.0
			percorrido = 0.0
			ultima_poca = 0.0
			tempo_poeira = 0.0
			direcao_investida = direcao_travada
		Estado.SALTANDO:
			tempo_estado = duracao_salto
		Estado.RECUPERANDO:
			recuperacao_vulneravel = _ataque_pesado()
			tempo_estado = _tempo_recuperacao()
		Estado.ATORDOADA:
			tempo_estado = tempo_tonta

	if (anterior == Estado.EXPOSTA) != (novo == Estado.EXPOSTA):
		exposta_mudou.emit(novo == Estado.EXPOSTA)


func _fim_do_ataque(permite_combo: bool) -> void:
	recarga_ataque = intervalo_ataque * (ritmo_furia if furiosa else 1.0)
	var curto := ataque == Ataque.MORDIDA or ataque == Ataque.PATAS or ataque == Ataque.CUSPE or ataque == Ataque.BOMBARDEIO
	var chance := chance_combo + (0.2 if furiosa else 0.0)
	if permite_combo and curto and randf() < chance:
		recarga_ataque = 0.1
	_mudar_estado(Estado.PERSEGUINDO)



func _montar_onda() -> Array:
	match mini(onda, 4):
		1:
			return [cena_acaro, cena_acaro, cena_acaro, cena_acaro]
		2:
			return [cena_acaro, cena_atiradora, cena_acaro, cena_atiradora, cena_acaro]
		3:
			return [cena_operaria, cena_acaro, cena_operaria, cena_atiradora, cena_acaro]
	return [cena_acaro_grande, cena_operaria, cena_atiradora, cena_acaro, cena_atiradora, cena_acaro]


func _invocar_proximo() -> void:
	var cena: PackedScene = fila_invocacao.pop_front()
	contador_spawn += 1
	_invocar_um(cena, _posicao_spawn(contador_spawn))


func _invocar_um(cena: PackedScene, posicao: Vector2) -> void:
	if cena == null:
		return
	var inimigo: Inimigo = cena.instantiate()
	inimigo.position = posicao
	get_tree().current_scene.add_child(inimigo)
	inimigo.morreu.connect(_ao_minion_morrer)
	minions_vivos += 1
	Efeitos.criar(fx_poeira, posicao)
	Efeitos.criar_anel(cena_anel, posicao, 40.0, Color(0.9, 0.55, 0.25))


func _ao_minion_morrer() -> void:
	minions_vivos = maxi(minions_vivos - 1, 0)


func _posicao_spawn(indice: int) -> Vector2:
	var pontos := get_tree().get_nodes_in_group("spawn_boss")
	if pontos.is_empty():
		return global_position + Vector2.RIGHT.rotated(TAU / 5.0 * indice) * 200.0
	var ponto: Node2D = pontos[(indice + onda) % pontos.size()]
	return ponto.global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))


func _eliminar_minions() -> void:
	fila_invocacao.clear()
	for outro: Inimigo in get_tree().get_nodes_in_group("inimigos"):
		if outro != self:
			outro.receber_dano(999, Vector2.ZERO)


func _limpar_arena() -> void:
	get_tree().call_group("projeteis", "cortar")
	get_tree().call_group("zonas_boss", "queue_free")
	get_tree().call_group("globulos", "queue_free")
	get_tree().call_group("pocas", "queue_free")


func _quebrar_escudo() -> void:
	escudo_pulso = 1.0
	Efeitos.criar_anel(cena_anel, global_position, 170.0, Color(0.6, 0.9, 1.0))
	for angulo in [0.0, 2.1, -2.1]:
		Efeitos.criar(fx_migalhas, global_position, angulo)
	Efeitos.tremer(0.3)
	Efeitos.hit_stop(0.05, 0.1)


func _bombardeio_fase1() -> void:
	var quantidade := 1 if onda < 3 else 2
	for i in quantidade:
		var ponto := jogador.global_position
		if i > 0:
			ponto += jogador.velocity * 0.7
		_lancar_acido(ponto, 0.8 + i * 0.2, raio_bombardeio, dano_bombardeio)
	tempo_cuspe_visual = 0.5
	Efeitos.tremer(0.1)



func _transicao() -> void:
	_mudar_estado(Estado.TRANSICAO)
	aviso.esconder()
	_eliminar_minions()
	_limpar_arena()

	jogador.set_physics_process(false)
	jogador.invencibilidade = 5.0
	var camera := jogador.camera
	var zoom_base := camera.zoom

	await _esperar(0.4)

	camera.foco = self
	var tween := create_tween().set_parallel()
	tween.tween_property(camera, "foco_forca", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", zoom_base * 1.45, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	var tween_rugido := create_tween()
	tween_rugido.tween_property(self, "rugido", 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _esperar(0.6)
	Efeitos.criar_anel(cena_anel, global_position, 280.0, Color(1.0, 0.3, 0.2))
	Efeitos.criar_anel(cena_anel, global_position, 180.0, Color(1.0, 0.7, 0.3))
	Efeitos.criar(fx_poeira, global_position)
	for i in 8:
		var angulo := TAU / 8.0 * i
		Efeitos.criar(fx_poeira, global_position + Vector2.RIGHT.rotated(angulo) * 120.0, angulo)
	Efeitos.tremer(0.9)
	Efeitos.hit_stop(0.12, 0.05)
	await _esperar(0.9)

	fase = 2
	fase_mudou.emit(2)
	await _esperar(0.5)

	var tween_volta := create_tween().set_parallel()
	tween_volta.tween_property(camera, "foco_forca", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_volta.tween_property(camera, "zoom", zoom_base, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_volta.tween_property(self, "rugido", 0.0, 0.6)
	await tween_volta.finished
	camera.foco = null

	jogador.set_physics_process(true)
	jogador.invencibilidade = 1.0
	recarga_ataque = 0.9
	recarga_invocacao = 5.0
	olhando = (jogador.global_position - global_position).normalized()
	_mudar_estado(Estado.PERSEGUINDO)


func _enfurecer() -> void:
	furiosa = true
	if frames_furia != null:
		var atual := corpo.animation
		corpo.sprite_frames = frames_furia
		corpo.play(atual)
	Efeitos.tremer(0.45)
	Efeitos.hit_stop(0.07, 0.08)
	Efeitos.criar_anel(cena_anel, global_position, 190.0, Color(1.0, 0.3, 0.2))
	Efeitos.criar(fx_poeira, global_position)



func _escolher_ataque(distancia: float) -> int:
	var opcoes := {}
	if distancia <= 150.0:
		opcoes[Ataque.MORDIDA] = 5.0
	if distancia <= 200.0:
		opcoes[Ataque.PATAS] = 4.0
		opcoes[Ataque.PANCADA] = 3.0
	if distancia <= 260.0:
		opcoes[Ataque.TERREMOTO] = 3.0 if furiosa else 2.5
	if distancia >= 180.0:
		opcoes[Ataque.INVESTIDA] = 4.0 + (3.0 if distancia > 340.0 else 0.0)
		opcoes[Ataque.SALTO] = 4.0 if furiosa else 3.0
		if vida <= vida_max * 0.4:
			opcoes[Ataque.INVESTIDA_FURIOSA] = 3.0 if furiosa else 2.0
	if distancia >= 120.0:
		opcoes[Ataque.BOMBARDEIO] = 4.0 if furiosa else 3.0
	if distancia >= 150.0:
		opcoes[Ataque.CUSPE] = 3.0 + (2.0 if distancia > 300.0 else 0.0)
	if distancia >= 230.0:
		opcoes[Ataque.CHUVA] = 3.0 if furiosa else 2.0
	if recarga_invocacao <= 0.0 and minions_vivos < max_minions_fase2:
		opcoes[Ataque.INVOCACAO] = 6.0

	opcoes.erase(ultimo_ataque)
	if opcoes.is_empty():
		return -1

	var total := 0.0
	for peso in opcoes.values():
		total += peso
	var sorteio := randf() * total
	for chave in opcoes:
		sorteio -= opcoes[chave]
		if sorteio <= 0.0:
			return chave
	return opcoes.keys()[0]


func _comecar_ataque(escolhido: int) -> void:
	ataque = escolhido
	ultimo_ataque = escolhido
	direcao_travada = olhando
	match escolhido:
		Ataque.INVESTIDA:
			investidas_restantes = 1
		Ataque.INVESTIDA_FURIOSA:
			investidas_restantes = 2
	_mudar_estado(Estado.PREPARANDO)


func _executar_ataque() -> void:
	match ataque:
		Ataque.MORDIDA:
			_mordida()
		Ataque.PATAS:
			_patas()
		Ataque.PANCADA:
			_pancada()
		Ataque.TERREMOTO:
			_terremoto()
		Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA:
			_mudar_estado(Estado.INVESTINDO)
			aviso.disparar()
		Ataque.CUSPE:
			_cuspe()
		Ataque.CHUVA:
			_iniciar_chuva()
		Ataque.INVOCACAO:
			_invocar_fase2()
		Ataque.BOMBARDEIO:
			_bombardeio()
		Ataque.SALTO:
			_iniciar_salto()


func _tempo_preparo() -> float:
	var base := 0.8
	match ataque:
		Ataque.MORDIDA:
			base = preparo_mordida
		Ataque.PATAS:
			base = preparo_patas
		Ataque.PANCADA:
			base = preparo_pancada
		Ataque.TERREMOTO:
			base = preparo_terremoto
		Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA:
			base = preparo_investida
		Ataque.CUSPE:
			base = preparo_cuspe
		Ataque.CHUVA:
			base = preparo_chuva
		Ataque.INVOCACAO:
			base = preparo_invocacao
		Ataque.BOMBARDEIO:
			base = preparo_bombardeio
		Ataque.SALTO:
			base = preparo_salto
	if ataque == Ataque.INVESTIDA_FURIOSA and investidas_restantes == 1:
		base *= 0.5
	return base * (preparo_furia if furiosa else 1.0)


func _tempo_recuperacao() -> float:
	match ataque:
		Ataque.MORDIDA:
			return 0.55
		Ataque.PATAS:
			return 0.65
		Ataque.PANCADA:
			return 1.2
		Ataque.TERREMOTO:
			return 1.4
		Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA:
			return 0.9
		Ataque.CUSPE:
			return 0.5
		Ataque.CHUVA:
			return 0.7
		Ataque.BOMBARDEIO:
			return 0.8
		Ataque.SALTO:
			return 1.3
	return 0.9


func _ataque_pesado() -> bool:
	return ataque == Ataque.PANCADA or ataque == Ataque.TERREMOTO or ataque == Ataque.SALTO or ataque == Ataque.INVESTIDA or ataque == Ataque.INVESTIDA_FURIOSA


func _configurar_aviso() -> void:
	var rotacao_aviso := direcao_travada.angle()
	match ataque:
		Ataque.MORDIDA:
			aviso.circulo(global_position + direcao_travada * distancia_mordida, raio_mordida, COR_ALERTA)
		Ataque.PATAS:
			aviso.setor(global_position, rotacao_aviso, raio_patas, deg_to_rad(arco_patas), COR_ALERTA)
		Ataque.PANCADA:
			aviso.circulo(global_position, raio_pancada, COR_ALERTA)
		Ataque.TERREMOTO:
			aviso.circulo(global_position, raio_pancada, COR_TERREMOTO)
		Ataque.SALTO:
			aviso.circulo(jogador.global_position, raio_salto, COR_ALERTA)
		Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA:
			aviso.faixa(global_position, rotacao_aviso, _distancia_da_investida(), largura_investida, COR_ALERTA)
		Ataque.CUSPE:
			aviso.circulo(jogador.global_position, raio_cuspe, COR_ACIDO)
		Ataque.CHUVA:
			aviso.setor(global_position, rotacao_aviso, 460.0, deg_to_rad(arco_chuva), COR_ACIDO)
		_:
			aviso.esconder()


func _atualizar_aviso(progresso: float) -> void:
	match ataque:
		Ataque.MORDIDA:
			aviso.mirar(global_position + direcao_travada * distancia_mordida, 0.0)
		Ataque.PANCADA, Ataque.TERREMOTO:
			aviso.mirar(global_position, 0.0)
		Ataque.SALTO, Ataque.CUSPE:
			if tempo_estado > tempo_travar_mira + 0.15:
				aviso.mirar(jogador.global_position, 0.0)
		Ataque.INVOCACAO, Ataque.BOMBARDEIO:
			return
		_:
			aviso.mirar(global_position, direcao_travada.angle())
	aviso.atualizar(progresso)
	var piscando := progresso > 0.75 and int(tempo * 24.0) % 2 == 0
	aviso.modulate = Color(2.0, 1.6, 1.5, 1.0) if piscando else Color.WHITE


func _distancia_da_investida() -> float:
	return distancia_investida * (1.2 if ataque == Ataque.INVESTIDA_FURIOSA else 1.0)


func _nova_zona() -> AvisoAtaque:
	var zona := AvisoAtaque.new()
	zona.add_to_group("zonas_boss")
	get_tree().current_scene.add_child(zona)
	return zona


func _liberar_zona(zona: AvisoAtaque) -> void:
	get_tree().create_timer(0.5).timeout.connect(zona.queue_free)


func _criar_poca(ponto: Vector2, raio: float) -> void:
	if cena_poca == null:
		return
	var poca: PocaAcida = cena_poca.instantiate()
	poca.raio = raio
	poca.position = ponto
	get_tree().current_scene.add_child(poca)



func _mordida() -> void:
	var centro := global_position + direcao_travada * distancia_mordida
	_acertar_circulo(centro, raio_mordida, dano_mordida)
	impulso = direcao_travada * 260.0
	Efeitos.criar(fx_poeira, centro, direcao_travada.angle())
	Efeitos.tremer(0.3)
	Efeitos.hit_stop(0.04, 0.1)
	aviso.disparar()
	_mudar_estado(Estado.RECUPERANDO)


func _patas() -> void:
	var meio_arco := deg_to_rad(arco_patas) * 0.5
	var ate := jogador.global_position - global_position
	var dentro := ate.length() <= raio_patas and absf(direcao_travada.angle_to(ate)) <= meio_arco
	if dentro and jogador.pode_ser_atingido():
		jogador.receber_dano(dano_patas, ate.normalized())
	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		var distancia := objeto.global_position - global_position
		if distancia.length() <= raio_patas and absf(direcao_travada.angle_to(distancia)) <= meio_arco:
			objeto.atingido(distancia.normalized())
	for i in 3:
		var angulo := direcao_travada.angle() + lerpf(-meio_arco, meio_arco, i / 2.0)
		Efeitos.criar(fx_poeira, global_position + Vector2.RIGHT.rotated(angulo) * raio_patas * 0.8, angulo)
	Efeitos.criar_anel(cena_anel, global_position + direcao_travada * 70.0, 90.0, Color(1.0, 0.45, 0.4))
	Efeitos.tremer(0.35)
	Efeitos.hit_stop(0.04, 0.1)
	aviso.disparar()
	_mudar_estado(Estado.RECUPERANDO)


func _pancada() -> void:
	_acertar_circulo(global_position, raio_pancada, dano_pancada)
	_efeito_impacto_central(0.65)
	aviso.disparar()
	_mudar_estado(Estado.RECUPERANDO)


func _terremoto() -> void:
	_acertar_circulo(global_position, raio_pancada, dano_pancada)
	_efeito_impacto_central(0.8)
	aviso.disparar()
	var zona := _nova_zona()
	zona.anel(global_position, raio_pancada, raio_terremoto_externo, COR_TERREMOTO)
	var tween := zona.create_tween()
	tween.tween_method(zona.atualizar, 0.0, 1.0, atraso_terremoto)
	tween.tween_callback(_impacto_anel.bind(zona, global_position, raio_pancada, raio_terremoto_externo, dano_terremoto))
	_mudar_estado(Estado.RECUPERANDO)


func _impacto_anel(zona: AvisoAtaque, centro: Vector2, interno: float, externo: float, dano: int) -> void:
	if not is_instance_valid(zona):
		return
	zona.disparar()
	var ate := jogador.global_position - centro
	if ate.length() >= interno and ate.length() <= externo and jogador.pode_ser_atingido():
		jogador.receber_dano(dano, ate.normalized())
	Efeitos.criar_anel(cena_anel, centro, externo * 1.1, COR_TERREMOTO)
	Efeitos.tremer(0.5)
	Efeitos.hit_stop(0.04, 0.1)
	_liberar_zona(zona)


func _efeito_impacto_central(tremor: float) -> void:
	Efeitos.criar_anel(cena_anel, global_position, raio_pancada * 1.3, Color(1.0, 0.45, 0.4))
	Efeitos.criar(fx_poeira, global_position)
	for i in 8:
		var angulo := TAU / 8.0 * i
		Efeitos.criar(fx_poeira, global_position + Vector2.RIGHT.rotated(angulo) * raio_pancada * 0.85, angulo)
	Efeitos.tremer(tremor)
	Efeitos.hit_stop(0.05, 0.1)


func _acertar_circulo(centro: Vector2, raio: float, dano: int) -> void:
	var ate := jogador.global_position - centro
	if ate.length() <= raio and jogador.pode_ser_atingido():
		var direcao := ate.normalized() if ate.length() > 1.0 else direcao_travada
		jogador.receber_dano(dano, direcao)
	for objeto: ObjetoCenario in get_tree().get_nodes_in_group("objetos"):
		var distancia := objeto.global_position - centro
		if distancia.length() <= raio:
			objeto.atingido(distancia.normalized())


func _iniciar_salto() -> void:
	alvo_salto = _ponto_livre(aviso.global_position)
	aviso.mirar(alvo_salto, 0.0)
	impulso = Vector2.ZERO
	collision_mask = 0
	Efeitos.criar(fx_poeira, global_position)
	Efeitos.tremer(0.2)
	_mudar_estado(Estado.SALTANDO)


func _aterrissar() -> void:
	collision_mask = 9
	global_position = alvo_salto
	_acertar_circulo(alvo_salto, raio_salto, dano_salto)
	Efeitos.criar_anel(cena_anel, alvo_salto, raio_salto * 1.4, Color(1.0, 0.45, 0.4))
	Efeitos.criar(fx_poeira, alvo_salto)
	for i in 10:
		var angulo := TAU / 10.0 * i
		Efeitos.criar(fx_poeira, alvo_salto + Vector2.RIGHT.rotated(angulo) * raio_salto * 0.8, angulo)
	Efeitos.tremer(0.8)
	Efeitos.hit_stop(0.07, 0.08)
	aviso.disparar()
	_mudar_estado(Estado.RECUPERANDO)


func _ponto_livre(ponto: Vector2) -> Vector2:
	for distancia: float in [0.0, 70.0, 130.0, 190.0]:
		for i in 8:
			var candidato := ponto + Vector2.RIGHT.rotated(TAU / 8.0 * i) * distancia
			if _espaco_livre(candidato):
				return candidato
			if distancia == 0.0:
				break
	return ponto


func _espaco_livre(ponto: Vector2) -> bool:
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.transform = Transform2D(0.0, ponto)
	consulta.collision_mask = 9
	return get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func _bombardeio() -> void:
	var quantidade := zonas_bombardeio + (2 if furiosa else 0)
	var alvo := jogador.global_position
	for i in quantidade:
		var ponto := alvo
		if i % 2 == 1:
			ponto = alvo + jogador.velocity * 0.7
		elif i > 0:
			ponto = alvo + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(80.0, 170.0)
		_lancar_acido(ponto, 0.75 + i * 0.18, raio_bombardeio, dano_bombardeio)
	Efeitos.tremer(0.15)
	_mudar_estado(Estado.RECUPERANDO)


func _lancar_acido(destino: Vector2, duracao: float, raio: float, dano: int) -> void:
	var zona := _nova_zona()
	zona.circulo(destino, raio, COR_ACIDO)
	var tween := zona.create_tween()
	tween.tween_method(zona.atualizar, 0.0, 1.0, duracao)
	if cena_globulo == null:
		tween.tween_callback(_impacto_acido.bind(zona, destino, raio, dano))
		return
	var globulo: GlobuloAcido = cena_globulo.instantiate()
	globulo.origem = _boca()
	globulo.destino = destino
	globulo.duracao = duracao
	get_tree().current_scene.add_child(globulo)
	globulo.aterrissou.connect(_impacto_acido.bind(zona, destino, raio, dano))


func _impacto_acido(zona: AvisoAtaque, ponto: Vector2, raio: float, dano: int) -> void:
	if not is_instance_valid(zona):
		return
	zona.disparar()
	var ate := jogador.global_position - ponto
	if ate.length() <= raio and jogador.pode_ser_atingido():
		jogador.receber_dano(dano, ate.normalized() if ate.length() > 1.0 else Vector2.DOWN)
	_criar_poca(ponto, raio * 0.9)
	Efeitos.criar(fx_acido, ponto)
	for i in 4:
		var angulo := TAU / 4.0 * i + randf() * 0.8
		Efeitos.criar(fx_acido, ponto + Vector2.RIGHT.rotated(angulo) * raio * 0.6, angulo)
	Efeitos.criar_anel(cena_anel, ponto, raio * 1.2, Color(0.55, 1.0, 0.25))
	Efeitos.tremer(0.12)
	_liberar_zona(zona)


# boca da Rainha (ela so olha para a esquerda ou para a direita)
func _boca() -> Vector2:
	return global_position + Vector2(lado * 76.0, 8.0)


func _terminar_investida(completou: bool) -> void:
	dano_contato = dano_normal
	investidas_restantes -= 1
	if completou and investidas_restantes > 0:
		direcao_travada = (jogador.global_position - global_position).normalized()
		olhando = direcao_travada
		_mudar_estado(Estado.PREPARANDO)
	else:
		investidas_restantes = 0
		_mudar_estado(Estado.RECUPERANDO)


func _bater() -> void:
	var objeto := get_slide_collision(0).get_collider()
	if objeto is ObjetoCenario:
		objeto.atingido(direcao_investida)
	var ponto := global_position + direcao_investida * 55.0
	Efeitos.criar(fx_poeira, ponto, direcao_investida.angle() + PI)
	Efeitos.criar(fx_migalhas, ponto, direcao_investida.angle() + PI)
	Efeitos.criar_anel(cena_anel, ponto, 120.0, Color(1.0, 0.8, 0.4))
	Efeitos.tremer(0.7)
	Efeitos.hit_stop(0.08, 0.05)
	impulso = -direcao_investida * 200.0
	investidas_restantes = 0
	_mudar_estado(Estado.ATORDOADA)


func _cuspe() -> void:
	# o glob cai onde a marca travou: da tempo de sair de la
	var destino := aviso.global_position
	aviso.esconder()
	_lancar_acido(destino, duracao_cuspe, raio_cuspe, dano_cuspe)
	impulso = -direcao_travada * 100.0
	Efeitos.tremer(0.15)
	_mudar_estado(Estado.RECUPERANDO)


func _iniciar_chuva() -> void:
	disparos_restantes = gotas_chuva + (4 if furiosa else 0)
	tempo_disparo = 0.0
	var metade := deg_to_rad(arco_chuva) * 0.5
	var sentido := 1.0 if randf() < 0.5 else -1.0
	angulo_varredura = -metade * sentido
	passo_varredura = metade * 2.0 * sentido / float(maxi(disparos_restantes - 1, 1))
	aviso.disparar()
	_mudar_estado(Estado.DISPARANDO)


func _disparar_gota(direcao: Vector2, dano: int, vel: float) -> void:
	if cena_gota == null:
		return
	var gota: GotaRainha = cena_gota.instantiate()
	gota.direcao = direcao
	gota.dano = dano
	gota.velocidade = vel
	get_tree().current_scene.add_child(gota)
	gota.global_position = _boca() + direcao * 20.0


func _invocar_fase2() -> void:
	recarga_invocacao = recarga_invocacao_fase2
	var quantidade := 3 if furiosa else 2
	for i in quantidade:
		var sorteio := randf()
		var cena := cena_acaro
		if sorteio > 0.8:
			cena = cena_operaria
		elif sorteio > 0.5:
			cena = cena_atiradora
		contador_spawn += 1
		_invocar_um(cena, _posicao_spawn(contador_spawn))
	Efeitos.criar_anel(cena_anel, global_position, 160.0, Color(0.9, 0.55, 0.25))
	Efeitos.tremer(0.3)
	_mudar_estado(Estado.RECUPERANDO)



func _morrer() -> void:
	vida = 0
	vida_mudou.emit(0, vida_max)
	remove_from_group("inimigos")
	_eliminar_minions()
	_limpar_arena()
	collision_mask = 9
	aviso.esconder()
	_mudar_estado(Estado.MORRENDO)
	Efeitos.tremer(0.8)
	Efeitos.hit_stop(0.2, 0.03)
	_sequencia_morte()


func _sequencia_morte() -> void:
	for i in 9:
		var ponto := global_position + Vector2(randf_range(-70.0, 70.0), randf_range(-45.0, 45.0))
		Efeitos.criar(fx_morte, ponto)
		Efeitos.criar(fx_poeira, ponto)
		Efeitos.tremer(0.35)
		await _esperar(0.17)
	Efeitos.criar_anel(cena_anel, global_position, 320.0, Color(1.0, 0.9, 0.5))
	Efeitos.criar(fx_morte, global_position)
	Efeitos.tremer(1.0)
	morreu.emit()
	queue_free()



func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, false, true).timeout


func _girar(atual: Vector2, alvo: Vector2, passo: float) -> Vector2:
	return atual.rotated(clampf(atual.angle_to(alvo), -passo, passo))


func _passos(delta: float) -> void:
	tempo_passo -= delta
	if tempo_passo > 0.0:
		return
	tempo_passo = 0.4
	Efeitos.criar(fx_poeira, global_position + Vector2(0, 16))
	if global_position.distance_to(jogador.global_position) < 300.0:
		Efeitos.tremer(0.05)



func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-14.0 * delta)
	var altura_alvo := 0.0
	var cor := Color.WHITE
	var tremida := 0.0
	var recuo := 0.0
	var brilho_alvo := 0.0
	var escudo_alvo := 0.0

	tempo_cuspe_visual = maxf(tempo_cuspe_visual - delta, 0.0)

	match estado:
		Estado.INVOCANDO:
			# ergue o abdomen e chama a colonia
			var chamado := clampf(1.0 - tempo_estado / maxf(tempo_chamado, 0.01), 0.0, 1.0)
			altura_alvo = 10.0 * chamado
			tremida = chamado * 1.6
			cor = Color.WHITE.lerp(Color(1.5, 1.15, 0.75), chamado)
			escudo_alvo = 1.0
		Estado.PROTEGIDA:
			escudo_alvo = 1.0
		Estado.EXPOSTA:
			brilho_alvo = 1.0
			if tempo_estado < 1.2 and int(tempo * 14.0) % 2 == 0:
				brilho_alvo = 0.15
		Estado.TRANSICAO:
			tremida = rugido * 4.0
			cor = Color.WHITE.lerp(Color(1.8, 0.6, 0.5), rugido)
			escudo_alvo = 1.0 - rugido
		Estado.PERSEGUINDO:
			if velocity.length() > 10.0:
				altura_alvo = absf(sin(tempo * 7.0)) * 3.0
		Estado.PREPARANDO:
			var p := clampf(1.0 - tempo_estado / duracao_estado, 0.0, 1.0)
			cor = Color.WHITE.lerp(Color(1.6, 0.7, 0.6), p)
			tremida = p * 1.5
			match ataque:
				Ataque.PANCADA, Ataque.TERREMOTO:
					altura_alvo = 14.0 * p
					tremida = p * 2.5
				Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA:
					recuo = 20.0 * p
				Ataque.CUSPE, Ataque.CHUVA, Ataque.BOMBARDEIO:
					tremida = p * 1.2
					cor = Color.WHITE.lerp(Color(0.8, 1.5, 0.7), p)
				Ataque.INVOCACAO:
					altura_alvo = 10.0 * p
		Estado.SALTANDO:
			var voo := clampf(1.0 - tempo_estado / maxf(duracao_salto, 0.01), 0.0, 1.0)
			altura_alvo = sin(voo * PI) * 90.0
		Estado.DISPARANDO:
			tremida = 1.2
			cor = Color(0.85, 1.4, 0.8)
		Estado.RECUPERANDO:
			if recuperacao_vulneravel:
				cor = Color(0.85, 0.85, 0.95)
		Estado.ATORDOADA:
			tremida = 1.5
			cor = Color(0.85, 0.85, 1.0)
		Estado.MORRENDO:
			tremida = 5.0
			cor = Color.WHITE.lerp(Color(2.0, 2.0, 2.0), 0.5 + 0.5 * sin(tempo * 40.0))

	cor = _cor_com_status(cor, estado == Estado.PREPARANDO)

	var rapido := 1.0 - exp(-(30.0 if estado == Estado.SALTANDO else 14.0) * delta)
	visual.scale = Vector2.ONE
	visual.position = Vector2(sin(tempo * 70.0) * tremida, lerpf(visual.position.y, -altura_alvo, rapido))
	visual.modulate = cor

	if absf(olhando.x) > 0.2:
		lado = signf(olhando.x)
	var anim := _animacao()
	if corpo.animation != anim:
		corpo.play(anim)
	var rapida := 1.0
	if estado == Estado.INVESTINDO:
		rapida = 2.5
	elif furiosa and anim == "andar":
		rapida = 1.5
	elif anim == "cuspir_preparo":
		rapida = 0.5 / maxf(duracao_estado, 0.1)
	corpo.speed_scale = rapida
	corpo.flip_h = lado < 0.0
	corpo.position = corpo.position.lerp(Vector2(-lado * recuo, 0.0), suavizacao)
	brilho.position = Vector2(-lado * 44.0, -4.0)

	# brilho de exposta, aura de furia e escudo
	brilho.modulate.a = lerpf(brilho.modulate.a, brilho_alvo * (0.6 + 0.4 * sin(tempo * 8.0)), suavizacao)
	var aura_alvo := 0.6 if furiosa and estado != Estado.MORRENDO else 0.0
	aura.modulate.a = lerpf(aura.modulate.a, aura_alvo * (0.7 + 0.3 * sin(tempo * 6.0)), suavizacao)

	escudo_pulso = maxf(escudo_pulso - delta * 4.0, 0.0)
	escudo_alfa = lerpf(escudo_alfa, escudo_alvo, suavizacao)
	escudo.visible = escudo_alfa > 0.02 or escudo_pulso > 0.0
	var luz_escudo := 1.0 + escudo_pulso * 2.5
	escudo.modulate = Color(luz_escudo, luz_escudo, luz_escudo, minf(escudo_alfa + escudo_pulso * 0.3, 1.0))
	escudo.scale = escala_escudo * (1.0 + sin(tempo * 4.0) * 0.025 + escudo_pulso * 0.12)

	sombra.scale = escala_sombra * (1.0 - clampf(altura_alvo / 150.0, 0.0, 0.5))


func _animacao() -> String:
	if tempo_cuspe_visual > 0.0:
		return "cuspir_disparo"
	match estado:
		Estado.INVOCANDO:
			return "invocar"
		Estado.EXPOSTA:
			return "agachada"
		Estado.TRANSICAO, Estado.MORRENDO:
			return "rugido"
		Estado.PERSEGUINDO:
			return "andar" if velocity.length() > 10.0 else "parada"
		Estado.INVESTINDO:
			return "andar"
		Estado.SALTANDO:
			return "salto"
		Estado.DISPARANDO:
			return "cuspir_chuva"
		Estado.ATORDOADA:
			return "tonta"
		Estado.RECUPERANDO:
			if ataque == Ataque.CUSPE or ataque == Ataque.BOMBARDEIO:
				return "cuspir_disparo"
		Estado.PREPARANDO:
			match ataque:
				Ataque.CUSPE, Ataque.CHUVA, Ataque.BOMBARDEIO:
					return "cuspir_preparo"
				Ataque.MORDIDA:
					return "boca"
				Ataque.PATAS, Ataque.PANCADA, Ataque.TERREMOTO:
					return "patas"
				Ataque.INVESTIDA, Ataque.INVESTIDA_FURIOSA, Ataque.SALTO:
					return "agachada"
				Ataque.INVOCACAO:
					return "invocar"
	return "parada"
