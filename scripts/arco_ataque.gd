class_name ArcoAtaque
extends Node2D

@export var raio_interno := 22.0
@export var raio_externo := 72.0
@export var cor := Color(0.85, 0.9, 1.0, 0.65)

var angulo_inicio := 0.0
var angulo_fim := 0.0


func definir(inicio: float, fim: float) -> void:
	angulo_inicio = inicio
	angulo_fim = fim
	queue_redraw()


func _draw() -> void:
	var varredura := angulo_fim - angulo_inicio
	if absf(varredura) < 0.01:
		return
	var segmentos := maxi(3, int(absf(varredura) / 0.08))
	var borda := Color(1.0, 1.0, 1.0)
	for i in segmentos:
		var f0 := float(i) / segmentos
		var f1 := float(i + 1) / segmentos
		var a0 := angulo_inicio + varredura * f0
		var a1 := angulo_inicio + varredura * f1
		var c0 := Color(cor.r, cor.g, cor.b, cor.a * pow(f0, 1.6))
		var c1 := Color(cor.r, cor.g, cor.b, cor.a * pow(f1, 1.6))
		var pontos := PackedVector2Array([
			Vector2.from_angle(a0) * raio_interno,
			Vector2.from_angle(a0) * raio_externo,
			Vector2.from_angle(a1) * raio_externo,
			Vector2.from_angle(a1) * raio_interno,
		])
		draw_polygon(pontos, PackedColorArray([c0, c0, c1, c1]))
		var cb := Color(borda.r, borda.g, borda.b, pow(f1, 1.6))
		draw_line(Vector2.from_angle(a0) * raio_externo, Vector2.from_angle(a1) * raio_externo, cb, 2.5)
	draw_line(
		Vector2.from_angle(angulo_fim) * raio_interno,
		Vector2.from_angle(angulo_fim) * raio_externo,
		borda, 3.0)
