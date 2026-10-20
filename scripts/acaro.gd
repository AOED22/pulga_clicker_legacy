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


func _ao_ser_atingido() -> void:
	_mudar_estado(Estado.PERSEGUINDO)


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
			escala_alvo = Vector2(1.25, 0.75)
			if int(tempo * 20.0) % 2 == 0:
				cor = Color(1.8, 0.7, 0.7)
		Estado.INVESTINDO:
			escala_alvo = Vector2(0.8, 1.25)

	cor = _cor_com_status(cor, estado == Estado.PREPARANDO)

	visual.scale = visual.scale.lerp(escala_alvo, suavizacao)
	visual.position.y = -pulinho
	visual.modulate = cor
