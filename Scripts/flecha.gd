class_name Flecha
extends Control

const LARGO_MAX := 90
const GROSOR_MIN := 0.0
var GROSOR_MAX := self.size.x * 0.5

var direccion := Vector2.ZERO
var intensidad := 0.0



func mostrar(nueva_direccion: Vector2, nueva_intensidad: float) -> void:
	direccion = nueva_direccion
	intensidad = nueva_intensidad
	visible = true
	queue_redraw()

func ocultar() -> void:
	visible = false

func _draw() -> void:
	if intensidad <= 0.0:
		return
	var punta := direccion * LARGO_MAX * intensidad
	var grosor := lerpf(GROSOR_MIN, GROSOR_MAX, intensidad)
	var lateral := direccion.orthogonal()
	var base := punta - direccion * grosor * 2.0
	draw_line(Vector2.ZERO, base, Color.WHITE, grosor)
	draw_colored_polygon(PackedVector2Array([punta, base + lateral * grosor * 1.5, base - lateral * grosor * 1.5]), Color.WHITE)
