extends CanvasLayer


@export var pixel_scale := 2
@export var damage_flash_alpha := 0.35
@export var damage_flash_time := 0.3
@export var life_follow_speed := 7.0
@export var power_follow_speed := 8.0
@export var power_ready_glow := 1.7
@export var power_pulse_time := 0.45
@export var idle_charge_alpha := 0.45

var player: Jogador
var last_life := -1
var life_target := 1.0
var life_shown := 1.0
var power_target := 0.0
var power_shown := 0.0
var pulse_tween: Tween
var power_ready := false

@onready var bars: Control = $Root/Bars
@onready var damage_flash: ColorRect = $Root/DamageFlash
@onready var life_bar: TextureProgressBar = $Root/Bars/LifeBar
@onready var power_bar: TextureProgressBar = $Root/Bars/PowerBar
@onready var charge_bar: TextureProgressBar = $Root/Bars/ChargeBar


func _ready() -> void:
	bars.scale = Vector2(pixel_scale, pixel_scale)
	for bar in [life_bar, power_bar, charge_bar]:
		bar.max_value = bar.texture_progress.get_width()
	player = get_tree().get_first_node_in_group("jogador")
	if player == null:
		return
	player.vida_mudou.connect(_on_life_changed)
	player.poder_mudou.connect(_on_power_changed)
	_on_life_changed(player.vida, player.vida_max)
	_on_power_changed(player.poder)
	life_shown = life_target
	power_shown = power_target
	_set_bar(life_bar, life_shown)
	_set_bar(power_bar, power_shown)


func _process(delta: float) -> void:
	if player == null:
		return
	life_shown = _follow(life_shown, life_target, life_follow_speed, delta)
	_set_bar(life_bar, life_shown)
	power_shown = lerpf(power_shown, power_target, 1.0 - exp(-power_follow_speed * delta))
	_set_bar(power_bar, power_shown)

	var charging: bool = player.estado == Jogador.Estado.CARGA
	var charge := player.carga / player.carga_max if charging else 0.0
	_set_bar(charge_bar, charge)
	charge_bar.modulate.a = 1.0 if charging else idle_charge_alpha



func _follow(current: float, target: float, speed: float, delta: float) -> float:
	var next := lerpf(current, target, 1.0 - exp(-speed * delta))
	return target if absf(next - target) < 0.002 else next


func _set_bar(bar: TextureProgressBar, fraction: float) -> void:
	bar.value = roundf(clampf(fraction, 0.0, 1.0) * bar.max_value)


func _on_life_changed(value: int, maximum: int) -> void:
	life_target = float(value) / maxf(maximum, 1)
	if last_life >= 0 and value < last_life:
		_flash_damage()
	last_life = value


func _on_power_changed(value: float) -> void:
	power_target = value / player.poder_max
	var is_ready: bool = value >= player.custo_habilidade
	if is_ready != power_ready:
		power_ready = is_ready
		_set_power_pulse(is_ready)



func _set_power_pulse(active: bool) -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	if not active:
		power_bar.tint_progress = Color.WHITE
		return
	var glow := Color(power_ready_glow, power_ready_glow, power_ready_glow)
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(power_bar, "tint_progress", glow, power_pulse_time)
	pulse_tween.tween_property(power_bar, "tint_progress", Color.WHITE, power_pulse_time)


func _flash_damage() -> void:
	damage_flash.color.a = damage_flash_alpha
	create_tween().tween_property(damage_flash, "color:a", 0.0, damage_flash_time)
