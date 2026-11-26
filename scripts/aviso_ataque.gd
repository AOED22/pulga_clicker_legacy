class_name AvisoAtaque
extends Node2D

enum Forma { CIRCULO, SETOR, FAIXA, ANEL }

var forma := Forma.CIRCULO
var raio := 80.0
var raio_interno := 0.0
var arco := 1.5
var comprimento := 300.0
var largura := 60.0
var progresso := 0.0
var cor := Color(1.0, 0.25, 0.2)
var tween: Tween


func _ready() -> void:
	top_level = true
	visible = false


func circulo(centro: Vector2, tamanho: float, nova_cor := Color(1.0, 0.25, 0.2)) -> void:
	raio = tamanho
	_iniciar(Forma.CIRCULO, centro, 0.0, nova_cor)


func anel(centro: Vector2, interno: float, externo: float, nova_cor := Color(1.0, 0.25, 0.2)) -> void:
	raio_interno = interno
	raio = externo
	_iniciar(Forma.ANEL, centro, 0.0, nova_cor)


func setor(centro: Vector2, rotacao_setor: float, tamanho: float, abertura: float, nova_cor := Color(1.0, 0.25, 0.2)) -> void:
	raio = tamanho
	arco = abertura
	_iniciar(Forma.SETOR, centro, rotacao_setor, nova_cor)


func faixa(centro: Vector2, rotacao_faixa: float, tamanho: float, espessura: float, nova_cor := Color(1.0, 0.25, 0.2)) -> void:
	comprimento = tamanho
	largura = espessura
	_iniciar(Forma.FAIXA, centro, rotacao_faixa, nova_cor)


func mirar(centro: Vector2, rotacao_nova: float) -> void:
	global_position = centro
	rotation = rotacao_nova


func atualizar(valor: float) -> void:
	progresso = clampf(valor, 0.0, 1.0)
	queue_redraw()


# o ataque saiu: clareia e some
func disparar() -> void:
	if not visible:
		return
	progresso = 1.0
	queue_redraw()
	if tween and tween.is_valid():
		tween.kill()
	modulate = Color(2.5, 2.5, 2.5, 1.0)
	tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(hide)


func esconder() -> void:
	if tween and tween.is_valid():
		tween.kill()
	visible = false


func _iniciar(nova_forma: Forma, centro: Vector2, rotacao_nova: float, nova_cor: Color) -> void:
	if tween and tween.is_valid():
		tween.kill()
	forma = nova_forma
	cor = nova_cor
	progresso = 0.0
	global_position = centro
	rotation = rotacao_nova
	modulate = Color.WHITE
	visible = true
	queue_redraw()


func _draw() -> void:
	var fundo := Color(cor.r, cor.g, cor.b, 0.2)
	var preenche := Color(cor.r, cor.g, cor.b, 0.5)
	var borda := Color(cor.r, cor.g, cor.b, 0.85)
	match forma:
		Forma.CIRCULO:
			draw_circle(Vector2.ZERO, raio, fundo)
			if progresso > 0.02:
				draw_circle(Vector2.ZERO, raio * progresso, preenche)
			draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, borda, 2.0)
		Forma.SETOR:
			draw_colored_polygon(_pontos_setor(raio), fundo)
			if progresso > 0.02:
				draw_colored_polygon(_pontos_setor(raio * progresso), preenche)
			var contorno := _pontos_setor(raio)
			contorno.append(contorno[0])
			draw_polyline(contorno, borda, 2.0)
		Forma.ANEL:
			var espessura := raio - raio_interno
			draw_arc(Vector2.ZERO, raio_interno + espessura * 0.5, 0.0, TAU, 64, fundo, espessura)
			if progresso > 0.02:
				var espessura_cheia := espessura * progresso
				draw_arc(Vector2.ZERO, raio_interno + espessura_cheia * 0.5, 0.0, TAU, 64, preenche, espessura_cheia)
			draw_arc(Vector2.ZERO, raio, 0.0, TAU, 64, borda, 2.0)
			draw_arc(Vector2.ZERO, raio_interno, 0.0, TAU, 64, borda, 2.0)
		Forma.FAIXA:
			draw_rect(Rect2(0.0, -largura * 0.5, comprimento, largura), fundo)
			if progresso > 0.02:
				draw_rect(Rect2(0.0, -largura * 0.5, comprimento * progresso, largura), preenche)
			draw_rect(Rect2(0.0, -largura * 0.5, comprimento, largura), borda, false, 2.0)


func _pontos_setor(tamanho: float) -> PackedVector2Array:
	var pontos := PackedVector2Array([Vector2.ZERO])
	var passos := 24
	for i in passos + 1:
		var angulo := -arco * 0.5 + arco * float(i) / float(passos)
		pontos.append(Vector2.RIGHT.rotated(angulo) * tamanho)
	return pontos
