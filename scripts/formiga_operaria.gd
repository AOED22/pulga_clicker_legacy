class_name FormigaOperaria
extends Inimigo

enum Estado { ANDANDO, PREPARANDO, INVESTINDO, RECUPERANDO, TONTA }

@export_group("Movimento")
@export var velocidade := 62.0
@export var alcance_visao := 320.0
@export var giro := 2.0

@export_group("Escudo")
@export var escudo_max := 3
@export var angulo_escudo := 65.0

@export_group("Investida")
@export var alcance_investida := 230.0
@export var tempo_preparo := 0.85
@export var tempo_travar := 0.25
@export var distancia_investida := 280.0
@export var velocidade_inicial := 140.0
@export var velocidade_investida := 480.0
@export var dano_investida := 2
@export var tempo_recuperacao := 0.7
@export var tempo_tonta := 1.5
@export var recarga_investida := 1.2

@export_group("Furia")
@export var velocidade_furia := 1.35
@export var preparo_furia := 0.7

@export_group("Cenas")
@export var fx_poeira: PackedScene
@export var fx_migalhas: PackedScene

var estado := Estado.ANDANDO
var tempo_estado := 0.0
var duracao_preparo := 1.0
var olhando := Vector2.RIGHT
var direcao_investida := Vector2.RIGHT
var percorrido := 0.0
var recarga := 1.0
var tempo_poeira := 0.0
var escudo_vida := 0
var dano_normal := 0
var tremida_escudo := 0.0
var flash_escudo := 0.0

@onready var pivo: Node2D = $Visual/Pivo
@onready var escudo: Sprite2D = $Visual/Pivo/Escudo
@onready var trilha: Node2D = $Trilha
@onready var trilha_area: Sprite2D = $Trilha/Area
@onready var trilha_preenche: Sprite2D = $Trilha/Preenchimento


func _ready() -> void:
	super()
	escudo_vida = escudo_max
	dano_normal = dano_contato
	recarga = randf_range(0.6, 1.4)
	if _jogador_vivo():
		olhando = (jogador.global_position - global_position).normalized()
	trilha_area.scale.x = distancia_investida / trilha_area.texture.get_size().x
	trilha.visible = false


func bloqueia(direcao_golpe: Vector2) -> bool:
	if escudo_vida <= 0:
		return false
	return olhando.dot(-direcao_golpe.normalized()) > cos(deg_to_rad(angulo_escudo))


func receber_bloqueio(empurrao: Vector2) -> void:
	impulso = empurrao * 0.2
	tremida_escudo = 6.0
	flash_escudo = 0.08
	Efeitos.criar(fx_migalhas, global_position + olhando * 26.0, olhando.angle())
	Efeitos.tremer(0.12)
	Efeitos.hit_stop(0.04)
	_rachar_escudo()


func receber_dano(dano: int, empurrao: Vector2) -> bool:
	if estado == Estado.TONTA:
		dano += 1
	return super(dano, empurrao)


func _ao_ser_atingido() -> void:
	recarga = maxf(recarga, 0.6)
	if estado != Estado.TONTA:
		_mudar_estado(Estado.ANDANDO)


func _comportamento(delta: float) -> Vector2:
	var ate := jogador.global_position - global_position
	var direcao := ate.normalized()
	var furia := escudo_vida <= 0
	recarga = maxf(recarga - delta, 0.0)
	match estado:
		Estado.ANDANDO:
			olhando = _girar(olhando, direcao, giro * delta)
			if ate.length() > alcance_visao:
				return Vector2.ZERO
			if recarga <= 0.0 and ate.length() <= alcance_investida and olhando.dot(direcao) > 0.9:
				_mudar_estado(Estado.PREPARANDO)
				return Vector2.ZERO
			return olhando * velocidade * (velocidade_furia if furia else 1.0) + _separacao()
		Estado.PREPARANDO:
			tempo_estado -= delta
			if tempo_estado > tempo_travar:
				olhando = _girar(olhando, direcao, giro * 1.5 * delta)
			tempo_poeira -= delta
			if tempo_poeira <= 0.0:
				tempo_poeira = 0.12
				Efeitos.criar(fx_poeira, global_position - olhando * 14.0, olhando.angle() + PI)
			if tempo_estado <= 0.0:
				direcao_investida = olhando
				_mudar_estado(Estado.INVESTINDO)
		Estado.INVESTINDO:
			if percorrido > 12.0 and get_slide_collision_count() > 0:
				_bater()
				return Vector2.ZERO
			if tempo_contato > 0.0:
				_mudar_estado(Estado.RECUPERANDO)
				return Vector2.ZERO
			var progresso := clampf(percorrido / distancia_investida, 0.0, 1.0)
			var maxima := velocidade_investida * (1.15 if furia else 1.0)
			var vel := lerpf(velocidade_inicial, maxima, progresso * progresso)
			percorrido += vel * delta
			tempo_poeira -= delta
			if tempo_poeira <= 0.0:
				tempo_poeira = 0.06
				Efeitos.criar(fx_poeira, global_position - direcao_investida * 14.0, direcao_investida.angle() + PI)
			if percorrido >= distancia_investida:
				_mudar_estado(Estado.RECUPERANDO)
			return direcao_investida * vel
		Estado.RECUPERANDO:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.ANDANDO)
		Estado.TONTA:
			tempo_estado -= delta
			if tempo_estado <= 0.0:
				_mudar_estado(Estado.ANDANDO)
	return Vector2.ZERO


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	dano_contato = dano_normal
	match novo:
		Estado.PREPARANDO:
			duracao_preparo = tempo_preparo * (preparo_furia if escudo_vida <= 0 else 1.0)
			tempo_estado = duracao_preparo
			tempo_poeira = 0.0
		Estado.INVESTINDO:
			dano_contato = dano_investida
			tempo_contato = 0.0
			percorrido = 0.0
		Estado.RECUPERANDO:
			tempo_estado = tempo_recuperacao
			recarga = recarga_investida
		Estado.TONTA:
			tempo_estado = tempo_tonta
			recarga = recarga_investida


func _girar(atual: Vector2, alvo: Vector2, passo: float) -> Vector2:
	return atual.rotated(clampf(atual.angle_to(alvo), -passo, passo))


func _bater() -> void:
	var objeto := get_slide_collision(0).get_collider()
	if objeto is ObjetoCenario:
		objeto.atingido(direcao_investida)
	Efeitos.criar(fx_poeira, global_position + direcao_investida * 18.0, direcao_investida.angle() + PI)
	Efeitos.tremer(0.35)
	Efeitos.hit_stop(0.05, 0.1)
	impulso = -direcao_investida * 160.0
	visual.scale = Vector2(0.7, 1.3)
	_mudar_estado(Estado.TONTA)
	if escudo_vida > 0:
		_rachar_escudo()


func _rachar_escudo() -> void:
	escudo_vida -= 1
	if escudo_vida > 0:
		return
	escudo.visible = false
	Efeitos.criar(fx_migalhas, global_position + olhando * 24.0, olhando.angle())
	Efeitos.criar(fx_migalhas, global_position + olhando * 24.0, olhando.angle() + 0.8)
	Efeitos.criar(fx_migalhas, global_position + olhando * 24.0, olhando.angle() - 0.8)
	Efeitos.tremer(0.3)
	Efeitos.hit_stop(0.06, 0.1)
	atordoado = 0.5
	visual.scale = Vector2(1.4, 0.7)
	if estado != Estado.TONTA:
		_mudar_estado(Estado.ANDANDO)


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-16.0 * delta)
	var escala_alvo := Vector2.ONE
	var cor := Color.WHITE
	var pulinho := 0.0
	var tremida := 0.0
	var balanco := 0.0
	flash_escudo = maxf(flash_escudo - delta, 0.0)
	tremida_escudo = move_toward(tremida_escudo, 0.0, 40.0 * delta)

	match estado:
		Estado.ANDANDO:
			if velocity.length() > 10.0:
				pulinho = absf(sin(tempo * 10.0)) * 1.5
		Estado.PREPARANDO:
			var progresso := 1.0 - tempo_estado / duracao_preparo
			escala_alvo = Vector2(0.85, 1.2)
			tremida = progresso * 1.5
			cor = Color.WHITE.lerp(Color(1.6, 0.8, 0.6), progresso)
		Estado.INVESTINDO:
			escala_alvo = Vector2(1.3, 0.8)
		Estado.RECUPERANDO:
			escala_alvo = Vector2(0.9, 1.1)
		Estado.TONTA:
			escala_alvo = Vector2(0.9, 1.1)
			balanco = sin(tempo * 10.0) * 0.18
			cor = Color(0.85, 0.85, 1.0)

	if escudo_vida <= 0 and estado != Estado.PREPARANDO:
		cor = cor * Color(1.3, 0.85, 0.7)
	cor = _cor_com_status(cor, estado == Estado.PREPARANDO)

	pivo.scale = pivo.scale.lerp(escala_alvo, suavizacao)
	pivo.rotation = olhando.angle() + balanco
	visual.scale = visual.scale.lerp(Vector2.ONE, suavizacao)
	visual.position = Vector2(sin(tempo * 70.0) * tremida, -pulinho)
	visual.modulate = cor

	var fracao := float(escudo_vida) / float(escudo_max)
	escudo.scale = escudo.scale.lerp(Vector2.ONE * lerpf(0.6, 1.0, fracao), suavizacao)
	escudo.position.x = 25.0 - tremida_escudo
	escudo.modulate = Color(3.0, 3.0, 3.0) if flash_escudo > 0.0 else Color(1.5, 1.15, 0.6)

	trilha.visible = estado == Estado.PREPARANDO
	if trilha.visible:
		var progresso_trilha := 1.0 - tempo_estado / duracao_preparo
		trilha.global_position = global_position
		trilha.rotation = olhando.angle()
		trilha_preenche.scale.x = trilha_area.scale.x * progresso_trilha
		trilha.modulate.a = 1.0 if tempo_estado <= tempo_travar else 0.55
