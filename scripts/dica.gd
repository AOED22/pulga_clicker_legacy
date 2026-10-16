class_name Dica
extends Area2D

# ajuda que so aparece se o jogador ficar parado na area sem fazer a acao
@export_multiline var texto := ""
# acoes que completam a dica (dash, atacar, acertou, execucao, cortou, super_pulo, pouso, esmagou, habilidade)
@export var acoes := PackedStringArray()
# segundos dentro da area ate a dica aparecer
@export var atraso := 5.0

var dentro := false
var mostrando := false
var feita := false
var tempo := 0.0


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	var jogador: Jogador = get_tree().get_first_node_in_group("jogador")
	jogador.acao_feita.connect(_ao_acao)


func _process(delta: float) -> void:
	if not dentro or feita or mostrando:
		return
	tempo += delta
	if tempo >= atraso:
		mostrando = true
		_painel().mostrar(self, texto)


func _painel() -> PainelDica:
	return get_tree().get_first_node_in_group("painel_dica")


func _ao_entrar(corpo: Node2D) -> void:
	if corpo is Jogador:
		dentro = true
		tempo = 0.0


func _ao_sair(corpo: Node2D) -> void:
	if not (corpo is Jogador):
		return
	dentro = false
	if mostrando:
		mostrando = false
		_painel().esconder(self)


# se o jogador ja fez a acao sozinho a dica nunca aparece
func _ao_acao(nome: StringName) -> void:
	if not dentro or feita or not (String(nome) in acoes):
		return
	feita = true
	if mostrando:
		mostrando = false
		_painel().concluir(self)
