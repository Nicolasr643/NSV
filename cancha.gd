extends Control


@export var escena_pelota: PackedScene
@export var escena_sombra_pelota: PackedScene
@export var escena_presicion: PackedScene

var pelota = null
var sombra_pelota = null
var presicion = null


#Variables de Tiro
var tirobase = null
const OFFSET_SOMBRA := 10.0
const ALTURA_BASE := 30.0
const ALTURA_TOPE := 120.0
const DISTANCIA_MAX := 400.0
const VELOCIDAD_PX_S := 500.0
const DURACION_MIN := 1.0
const DURACION_MAX := 3.0
const DESVIO_MAX_GRADOS := 30.0

var tween: Tween

var estado_final: int


const dimensiones_cancha ={
	"x0":Vector2i(51, 51),
	"x1":Vector2i(45, 230),
	"y0":Vector2i(272, 56),
	"y1":Vector2i(279, 231)
}

var posicion_ataque = null
var posicion_sombra = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.direccion_seleccionada.connect(afinar_tiro)
	Events.direccion_afinada.connect(calcular_tiro)
	pelota = escena_pelota.instantiate()
	pelota.global_position = posicion_ataque
	
	sombra_pelota = escena_sombra_pelota.instantiate()
	sombra_pelota.global_position = posicion_ataque + Vector2(0,50)
	
	add_child(pelota)
	add_child(sombra_pelota)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#region Tiro
func calcular_tiro(ajuste):
	if tween:
		tween.kill()
	var origen_suelo = pelota.global_position + Vector2(0.0, ALTURA_BASE)
	var distancia: float = DISTANCIA_MAX * tirobase.intensidad * (1.0 + ajuste.y)
	var duracion := clampf(distancia / VELOCIDAD_PX_S, DURACION_MIN, DURACION_MAX)
	var direccion: Vector2 = tirobase.direccion.rotated(deg_to_rad(DESVIO_MAX_GRADOS * -ajuste.x))
	var recorrido := direccion * distancia
	var elevacion := deg_to_rad(clampf(75.0 * ajuste.y, 0.0, 75.0))
	var altura_max := minf(distancia * tan(elevacion) / 4.0, ALTURA_TOPE)

	tween = create_tween()
	tween.tween_method(mover_pelota.bind(origen_suelo, recorrido, altura_max), 0.0, 1.0, duracion)
	fue_punto(recorrido + origen_suelo)
	await get_tree().create_timer(1.0).timeout
	tween.finished.connect(ataque_finalizado)

func mover_pelota(t: float, origen_suelo: Vector2, recorrido: Vector2, altura_max: float) -> void:
	var suelo := origen_suelo + recorrido * t
	var altura := ALTURA_BASE * (1.0 - t) + 4.0 * altura_max * t * (1.0 - t)
	pelota.global_position = suelo - Vector2(0.0, altura)
	sombra_pelota.global_position = suelo + Vector2(0.0, OFFSET_SOMBRA)
	
func afinar_tiro(tiro):
	tirobase = tiro
	presicion = escena_presicion.instantiate()
	add_child(presicion)
#endregion


func fue_punto(ubicacion: Vector2):
	var poligono := PackedVector2Array([
		dimensiones_cancha.x0,
		dimensiones_cancha.y0,
		dimensiones_cancha.y1,
		dimensiones_cancha.x1,
	])
	if (Geometry2D.is_point_in_polygon(ubicacion, poligono)):
		estado_final = 10
	else:
		estado_final = 1
func ataque_finalizado() -> void:
	Events.ataque_terminado.emit()
	
