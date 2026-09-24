class_name Jugador
extends Resource

@export var nombre: String
@export var equipo: String
@export var posicion_letra: String

@export_range(0, 100) var fuerza: int
@export_range(0, 100) var precision: int
@export_range(0, 100) var recepcion: int
@export_range(0, 100) var bloqueo: int
@export_range(0, 100) var afinidad_armador: int

var energia: float
