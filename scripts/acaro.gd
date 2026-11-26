class_name Acaro
extends Inimigo

enum Estado { PERSEGUINDO, PREPARANDO, INVESTINDO, RECUPERANDO }

@export_group("Movimento")
@export var velocidade := 80.0
@export var alcance_visao := 380.0

@export_group("Investida")
@export var alcance_investida := 110.0
@export var tempo_preparo := 0.45
@export var tempo_investida := 0.22
@export var velocidade_investida := 380.0
@export var tempo_recuperacao := 0.6

var estado := Estado.PERSEGUINDO
var direcao_investida := Vector2.ZERO
var tempo_estado := 0.0
var duracao_estado := 1.0
var tempo_dano := 0.0

@onready var sprite: AnimatedSprite2D = $Visual/Sprite


func _ao_ser_atingido() -> void:
	tempo_dano = 0.25
	sprite.stop()
	sprite.play(&"dano")
	_mudar_estado(Estado.PERSEGUINDO)


func _ao_morrer() -> void:
	_deixar_corpo(sprite)


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
	duracao_estado = maxf(tempo_estado, 0.01)


func _atualizar_visual(delta: float) -> void:
	var suavizacao := 1.0 - exp(-16.0 * delta)
	var escala_alvo := Vector2.ONE
	var cor := Color.WHITE
	var pulinho := 0.0

	tempo_dano = maxf(tempo_dano - delta, 0.0)

	match estado:
		Estado.PERSEGUINDO:
			if velocity.length() > 10.0 and tempo_dano <= 0.0:
				pulinho = absf(sin(tempo * 12.0)) * 1.0
		Estado.PREPARANDO:
			if int(tempo * 20.0) % 2 == 0:
				cor = Color(1.8, 0.7, 0.7)

	cor = _cor_com_status(cor, estado == Estado.PREPARANDO)

	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)
	visual.position.y = -pulinho
	visual.modulate = cor
	_atualizar_animacao()


func _atualizar_animacao() -> void:
	var olhar := velocity.x
	if estado == Estado.INVESTINDO:
		olhar = direcao_investida.x
	elif _jogador_vivo():
		olhar = jogador.global_position.x - global_position.x
	if absf(olhar) > 0.1:
		sprite.flip_h = olhar < 0.0

	var progresso := 1.0 - tempo_estado / duracao_estado
	match estado:
		Estado.PREPARANDO:
			_quadro_por_progresso(&"preparar", progresso)
		Estado.INVESTINDO:
			_tocar(&"investida", 1.0)
		Estado.RECUPERANDO:
			_tocar(&"recuperar", 1.0)
		_:
			if tempo_dano > 0.0:
				_tocar(&"dano", 1.0)
			elif velocity.length() > velocidade * 0.15 and atordoado <= 0.0:
				_tocar(&"andar", clampf(velocity.length() / velocidade, 0.6, 1.25))
			else:
				_tocar(&"idle", 1.0)


func _tocar(nome: StringName, velocidade_anim: float) -> void:
	sprite.speed_scale = velocidade_anim
	var mudou := sprite.animation != nome
	if mudou or (not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(nome)):
		sprite.play(nome)


func _quadro_por_progresso(nome: StringName, progresso: float) -> void:
	var total := sprite.sprite_frames.get_frame_count(nome)
	if sprite.animation != nome:
		sprite.animation = nome
	sprite.pause()
	sprite.frame = clampi(int(progresso * total), 0, total - 1)
