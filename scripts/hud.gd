extends CanvasLayer

var cor_poder := Color(0.4, 0.6, 1.0)
var cor_poder_pronto := Color(1.0, 0.85, 0.3)
var alfa_flash_dano := 0.35
var duracao_flash_dano := 0.3

var jogador: Jogador
var vida_anterior := -1

@onready var barra_vida: ProgressBar = $Painel/BarraVida
@onready var barra_poder: ProgressBar = $Painel/BarraPoder
@onready var flash_dano: ColorRect = $Painel/FlashDano


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	barra_poder.max_value = jogador.poder_max
	jogador.vida_mudou.connect(_ao_vida_mudar)
	jogador.poder_mudou.connect(_ao_poder_mudar)
	_ao_vida_mudar(jogador.vida, jogador.vida_max)
	_ao_poder_mudar(jogador.poder)


func _ao_vida_mudar(valor: int, maximo: int) -> void:
	barra_vida.max_value = maximo
	barra_vida.value = valor
	# Pisca a tela em vermelho ao perder vida
	if vida_anterior >= 0 and valor < vida_anterior:
		_piscar_dano()
	vida_anterior = valor


func _ao_poder_mudar(valor: float) -> void:
	barra_poder.value = valor
	# A barra muda de cor quando a habilidade ja pode ser usada
	if valor >= jogador.custo_habilidade:
		barra_poder.modulate = cor_poder_pronto
	else:
		barra_poder.modulate = cor_poder


func _piscar_dano() -> void:
	flash_dano.color.a = alfa_flash_dano
	create_tween().tween_property(flash_dano, "color:a", 0.0, duracao_flash_dano)
