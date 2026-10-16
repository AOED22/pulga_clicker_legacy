class_name TapeteVelho
extends Node2D

# zona do ultimo checkpoint (static para sobreviver ao reinicio da cena)
static var checkpoint := -1

@export var limites := Rect2i(0, 0, 5200, 600)
@export_multiline var texto_abertura := ""
@export_multiline var texto_final := ""

@onready var jogador: Jogador = $Jogador
@onready var zonas: Node2D = $Zonas
@onready var fade: ColorRect = $Transicao/Fade
@onready var titulo: Label = $Transicao/Titulo


func _ready() -> void:
	add_to_group("fase")
	jogador.definir_limites(limites)
	fade.color.a = 1.0
	titulo.modulate.a = 0.0
	if checkpoint >= 1:
		_voltar_ao_checkpoint()
		create_tween().tween_property(fade, "color:a", 0.0, 0.6)
	else:
		_abertura()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		# shift + R recomeca do zero
		if Input.is_key_pressed(KEY_SHIFT):
			checkpoint = -1
		get_tree().reload_current_scene()


# tela preta com uma frase, depois a luz entra
func _abertura() -> void:
	titulo.text = texto_abertura
	jogador.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(titulo, "modulate:a", 1.0, 1.2)
	tween.tween_interval(1.8)
	tween.tween_property(titulo, "modulate:a", 0.0, 0.8)
	tween.tween_callback(jogador.set_physics_process.bind(true))
	tween.tween_property(fade, "color:a", 0.0, 1.5)


# depois de morrer volta do ultimo checkpoint, sem repetir as zonas anteriores
func _voltar_ao_checkpoint() -> void:
	for i in checkpoint:
		zonas.get_child(i).queue_free()
	var ponto: Node2D = zonas.get_child(checkpoint).get_node("Checkpoint")
	jogador.global_position = ponto.global_position
	jogador.camera.reset_smoothing()


# chamada pela saida da fase
func terminar(cena: String) -> void:
	checkpoint = -1
	jogador.set_physics_process(false)
	titulo.text = texto_final
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.2)
	tween.tween_property(titulo, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_callback(get_tree().change_scene_to_file.bind(cena))
