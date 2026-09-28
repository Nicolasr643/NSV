extends Control


@export var escena_pelota: PackedScene
@export var escena_sombra_pelota: PackedScene

var pelota = null
var sombra_pelota = null
const dimensiones_cancha ={
	"x0":Vector2i(51, 51),
	"x1":Vector2i(45, 230),
	"y0":Vector2i(272, 56),
	"y1":Vector2i(279, 231)
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.enviar_direccion.connect(calcular_tiro)
	pelota = escena_pelota.instantiate()
	pelota.global_position = Vector2(76, 328)
	
	sombra_pelota = escena_sombra_pelota.instantiate()
	sombra_pelota.global_position = Vector2(76, 369)
	
	add_child(pelota)
	add_child(sombra_pelota)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func calcular_tiro(tiro):
	var tween: Tween
	const GRAVEDAD = 9.8
	const DISTANCIA_MAX = 400 
	const ANGULO = 45
	const DURACION = 3
	var origen = pelota.global_position
	var recorrido: Vector2 = tiro.direccion * DISTANCIA_MAX * tiro.intensidad
	var altura_max := recorrido.length() * tan(deg_to_rad(ANGULO)) / 4.0
	var destino_sombra = origen + recorrido + Vector2(0,pelota.size.y-2)
	tween = create_tween()
	tween.tween_method(mover_pelota.bind(origen, recorrido, altura_max), 0.0, 1.0, DURACION)

	var tween_sombra := create_tween()
	tween_sombra.tween_property(sombra_pelota, "position", destino_sombra, DURACION).set_trans(Tween.TRANS_LINEAR)
	
func mover_pelota(t: float, origen: Vector2, recorrido: Vector2, altura_max: float) -> void:
	var altura := 4.0 * altura_max * t * (1.0 - t)
	pelota.global_position = origen + recorrido * t + Vector2(0.0, -altura)
