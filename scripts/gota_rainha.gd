class_name GotaRainha
extends GotaAcida



@export var cena_poca: PackedScene

var deixar_poca := true


func cortar() -> void:
	deixar_poca = false
	super()


func _estourar() -> void:
	if not estourada and deixar_poca:
		Efeitos.criar(cena_poca, global_position - direcao * 10.0)
	super()
