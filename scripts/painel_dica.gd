extends CanvasLayer

var tween: Tween
var dono: Object

@onready var painel: PanelContainer = $Margem/Centro/Painel
@onready var texto: RichTextLabel = $Margem/Centro/Painel/Texto


func _ready() -> void:
	add_to_group("painel_dica")
	painel.modulate.a = 0.0


func mostrar(quem: Object, bbcode: String) -> void:
	dono = quem
	texto.text = "[center]" + bbcode + "[/center]"
	painel.modulate = Color(1, 1, 1, 0)
	_animar(1.0, 0.0)


func concluir(quem: Object) -> void:
	if dono != quem:
		return
	dono = null
	painel.modulate = Color(0.6, 1.5, 0.6, 1)
	_animar(0.0, 0.5)


func esconder(quem: Object) -> void:
	if dono != quem:
		return
	dono = null
	_animar(0.0, 0.0)


func _animar(alfa: float, espera: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(painel, "modulate:a", alfa, 0.3).set_delay(espera)
