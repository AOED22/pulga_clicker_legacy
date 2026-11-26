class_name BarraBoss
extends CanvasLayer

@export var boss_name := "Rainha das Formigas"
@export var pixel_scale := 2
@export var phase2_fill: Texture2D
@export var ghost_delay := 0.45
@export var ghost_speed := 0.3
@export var hit_glow := 2.5
@export var hit_glow_recover := 14.0
@export var fade_time := 0.6

var life_fraction := 1.0
var ghost_fraction := 1.0
var ghost_wait := 0.0
var phase1_fill: Texture2D
var fade_tween: Tween

@onready var root: Control = $Root
@onready var holder: Control = $Root/Holder
@onready var plate: NinePatchRect = $Root/Holder/Plate
@onready var name_label: Label = $Root/Name
@onready var ghost_bar: TextureProgressBar = $Root/Holder/GhostBar
@onready var bar: TextureProgressBar = $Root/Holder/Bar


func _ready() -> void:
	holder.scale = Vector2(pixel_scale, pixel_scale)
	var half_width := holder.size.x * pixel_scale * 0.5
	holder.offset_left = -half_width
	holder.offset_right = -half_width + holder.size.x
	
	var plate_center_y := holder.offset_top + (plate.position.y + plate.size.y * 0.5) * pixel_scale
	var label_height := name_label.offset_bottom - name_label.offset_top
	name_label.offset_top = plate_center_y - label_height * 0.5
	name_label.offset_bottom = name_label.offset_top + label_height
	name_label.text = boss_name

	phase1_fill = bar.texture_progress
	for b in [bar, ghost_bar]:
		b.max_value = b.texture_progress.get_width()
	root.modulate.a = 0.0


func _process(delta: float) -> void:
	ghost_wait = maxf(ghost_wait - delta, 0.0)
	if ghost_wait <= 0.0:
		ghost_fraction = move_toward(ghost_fraction, life_fraction, ghost_speed * delta)
	_set_bar(ghost_bar, ghost_fraction)
	bar.tint_progress = bar.tint_progress.lerp(Color.WHITE, 1.0 - exp(-hit_glow_recover * delta))


func ligar(rainha: RainhaFormiga) -> void:
	rainha.vida_mudou.connect(_on_life_changed)
	rainha.fase_mudou.connect(_on_phase_changed)
	life_fraction = 1.0
	ghost_fraction = 1.0
	_set_bar(bar, 1.0)
	_set_bar(ghost_bar, 1.0)


func mostrar() -> void:
	_fade(1.0)


func esconder() -> void:
	_fade(0.0)


func _set_bar(target: TextureProgressBar, fraction: float) -> void:
	
	target.value = roundf(clampf(fraction, 0.0, 1.0) * target.max_value)


func _on_life_changed(value: int, maximum: int) -> void:
	var fraction := float(value) / maxf(maximum, 1)
	if fraction < life_fraction:
		ghost_wait = ghost_delay
		bar.tint_progress = Color(hit_glow, hit_glow, hit_glow)
	life_fraction = fraction
	if fraction > ghost_fraction:
		ghost_fraction = fraction
	_set_bar(bar, fraction)


func _on_phase_changed(phase: int) -> void:
	if phase >= 2 and phase2_fill != null:
		bar.texture_progress = phase2_fill
	else:
		bar.texture_progress = phase1_fill


func _fade(alpha: float) -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(root, "modulate:a", alpha, fade_time)
