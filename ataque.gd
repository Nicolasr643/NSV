extends Control

@onready var ball: TextureButton = %Ball

const ALTURA_ARCO := 40.0
var tween := create_tween()

func _ready() -> void:
	ball.pressed.connect(_on_ball_clicked)
	_lanzar_pelota()

func _lanzar_pelota() -> void:
	ball.position.x = -ball.size.x
	ball.position.y = size.y / 2 - ball.size.y / 2
	var y_base := ball.position.y

	tween.tween_method(_mover_arco.bind(y_base), 0.0, 1.0, 1.5)
	tween.finished.connect(_on_pelota_salio)

func _mover_arco(t: float, y_base: float) -> void:
	ball.position.x = lerpf(-ball.size.x, size.x, t)
	var altura := 4.0 * ALTURA_ARCO * t * (1.0 - t)
	ball.position.y = y_base - altura

func _on_ball_clicked() -> void:
	tween.kill()
	var posicion_pelota := ball.position
	var posicion_click := get_local_mouse_position()
	var amplitud = ball.size
	posicion_click = posicion_click - posicion_pelota
	
	var distancia = Vector2()
	distancia.x = (2*posicion_click.x - amplitud.x)/amplitud.x
	distancia.y = (2*posicion_click.y - amplitud.y)/amplitud.y
	Events.direccion_afinada.emit(distancia)
	self.queue_free()

func _on_pelota_salio() -> void:
	print("se fue sin tocar")
