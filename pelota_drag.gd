class_name Pelota
extends Control

signal disparo_lanzado(direccion: Vector2, intensidad: float)

const RADIO_MAX := 120.0
const INTENSIDAD_MIN := 0.1

var arrastrando := false

@onready var flecha: Flecha = $Flecha
@onready var icono_pelota: TextureRect = $Icono

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			iniciar_arrastre()
		elif arrastrando:

			var tiro = soltar(event.position)
			Events.enviar_direccion.emit(tiro)
	elif event is InputEventMouseMotion and arrastrando:
		actualizar_arrastre(event.position)

func iniciar_arrastre() -> void:
	arrastrando = true
	flecha.position = icono_pelota.size / 2
	flecha.mostrar(Vector2.ZERO, 0.0)

func actualizar_arrastre(pos_mouse: Vector2) -> void:
	var disparo := calcular_disparo(pos_mouse)
	flecha.mostrar(disparo.direccion, disparo.intensidad)

func soltar(pos_mouse: Vector2):
	arrastrando = false
	var disparo := calcular_disparo(pos_mouse)
	flecha.ocultar()
	if disparo.intensidad >= INTENSIDAD_MIN:
		disparo_lanzado.emit(disparo.direccion, disparo.intensidad)
	return {"direccion": disparo.direccion, "intensidad": disparo.intensidad}

func calcular_disparo(pos_mouse: Vector2) -> Dictionary:
	var arrastre := pos_mouse - icono_pelota.size / 2.0
	var intensidad := clampf(arrastre.length() / RADIO_MAX, 0.0, 1.0)
	var direccion := -arrastre.normalized()
	return {"direccion": direccion, "intensidad": intensidad}
