extends CPUParticles2D


# Remove a cena quando as particulas terminam
func _ready() -> void:
	finished.connect(queue_free)
