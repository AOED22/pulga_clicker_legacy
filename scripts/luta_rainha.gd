extends Node2D

static var viu_abertura := false

@export var limites := Rect2i(0, 0, 1200, 720)
@export_multiline var texto_abertura := ""
@export_multiline var texto_final := ""
@export_file("*.tscn") var proxima_cena := "res://cenas/main.tscn"
@export_group("Musica")
@export var musica_fase1: AudioStream
@export var musica_fase2: AudioStream

var dicas_exposta := 0

@onready var jogador: Jogador = $Jogador
@onready var rainha: RainhaFormiga = $RainhaFormiga
@onready var barra: BarraBoss = $BarraBoss
@onready var fade: ColorRect = $Transicao/Fade
@onready var titulo: Label = $Transicao/Titulo
@onready var musica: AudioStreamPlayer = $Musica


func _ready() -> void:
	jogador.definir_limites(limites)
	barra.ligar(rainha)
	rainha.morreu.connect(_ao_rainha_morrer)
	rainha.fase_mudou.connect(_ao_fase_mudar)
	rainha.exposta_mudou.connect(_ao_exposta_mudar)
	rainha.onda_iniciada.connect(_ao_onda_iniciada)
	fade.color.a = 1.0
	titulo.modulate.a = 0.0
	if viu_abertura:
		_comeco_rapido()
	else:
		_abertura()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()


func _abertura() -> void:
	viu_abertura = true
	titulo.text = texto_abertura
	jogador.set_physics_process(false)
	var camera := jogador.camera
	camera.foco = rainha
	camera.foco_forca = 1.0
	var tween := create_tween()
	tween.tween_property(titulo, "modulate:a", 1.0, 1.2)
	tween.tween_interval(1.8)
	tween.tween_property(titulo, "modulate:a", 0.0, 0.8)
	tween.tween_property(fade, "color:a", 0.0, 1.5)
	tween.tween_interval(0.6)

	tween.tween_property(camera, "foco_forca", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_comecar_luta)


func _comeco_rapido() -> void:
	jogador.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.6)
	tween.tween_interval(0.3)
	tween.tween_callback(_comecar_luta)


func _comecar_luta() -> void:
	jogador.set_physics_process(true)
	jogador.camera.foco = null
	barra.mostrar()
	_tocar(musica_fase1)
	rainha.iniciar_luta()


func _ao_fase_mudar(fase: int) -> void:
	if fase == 2:
		_tocar(musica_fase2)


func _tocar(stream: AudioStream) -> void:
	if stream == null:
		return
	if musica.playing:
		var tween := create_tween()
		tween.tween_property(musica, "volume_db", -40.0, 0.4)
		await tween.finished
	musica.stream = stream
	musica.volume_db = 0.0
	musica.play()



func _ao_onda_iniciada(numero: int) -> void:
	if numero == 1:
		_dica("A Rainha está [color=#6ab0ff]protegida[/color] enquanto houver formigas vivas.\nElimine todas elas!", 4.0)


func _ao_exposta_mudar(exposta: bool) -> void:
	var painel := get_tree().get_first_node_in_group("painel_dica")
	if not exposta:
		if painel:
			painel.esconder(self)
		return
	if dicas_exposta < 2:
		dicas_exposta += 1
		_dica("O [color=#ffd966]brilho dourado[/color] mostra que a Rainha está exposta.\nAtaque agora!", 3.0)


func _dica(texto: String, duracao: float) -> void:
	var painel := get_tree().get_first_node_in_group("painel_dica")
	if painel == null:
		return
	painel.mostrar(self, texto)
	await get_tree().create_timer(duracao).timeout
	painel.esconder(self)


 
func _ao_rainha_morrer() -> void:
	barra.esconder()
	Checkpoint.atual = -1
	get_tree().call_group("pocas", "queue_free")
	get_tree().call_group("zonas_boss", "queue_free")
	jogador.invencibilidade = 99.0
	await get_tree().create_timer(1.2, true, false, true).timeout
	titulo.text = texto_final
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.2)
	tween.tween_property(titulo, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind(proxima_cena))
