extends Node

var local_points = 0
var rival_points = 0
var local_sets = 0
var rival_sets = 0

const COLOR_RIVAL := "coral"
const COLOR_LOCAL := "teal"

var roster_local: Array[Jugador] = []
var roster_rival: Array[Jugador] = []

const NOMBRES := {
	"Local": ["Fernández", "Rosa (Yo)", "Rodríguez", "Álvarez", "Suárez", "Benítez"],
	"Rival": ["Cabrera", "Duarte", "Ibáñez", "Molina", "Paredes", "Vega"]
}

@onready var attack_scene: PackedScene = preload("res://Scenes/cancha.tscn")

const POSICIONES := ["A", "D", "C", "O", "T", "L"]
const MENSAJES := {
	"Saque": ["Saca"],
	"Defensa": ["Pero Recibe"],
	"Armado": ["Un armado por parte de"],
	"Ataque": ["Ataque de"],
}

# Posiones Armador,Delantero (punta1), Central, Opuesto, Trasero (punta2), Libero
var rotacionL := "ADCOTL"
var rotacionR := "ADCOTL"

var sacador = "Local"
# Shedule

#Probabilidades debug
var probabilidad_juego = 0.2
var usuario = null

#Posiciones Ataques:




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generar_roster()
	for pj in roster_local:
		print(pj.nombre)
	usuario = roster_local.filter(func(j): return j.es_usuario).front()
	print("Jugador: ", usuario )



#region Debug Equipo Crear
func generar_roster() -> void:
	var posiciones := ["A", "D", "C", "O", "T", "L"]
	for i in posiciones.size():
		roster_local.append(crear_jugador(NOMBRES["Local"][i], "Local", posiciones[i]))
		roster_rival.append(crear_jugador(NOMBRES["Rival"][i], "Rival", posiciones[i]))

func crear_jugador(nombre: String, equipo: String, posicion: String) -> Jugador:
	var j := Jugador.new()
	j.nombre = nombre
	j.equipo = equipo
	j.posicion_letra = posicion
	if nombre == "Rosa (Yo)":
		j.es_usuario = true
	else:
		j.es_usuario = false
	return j
#endregion
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			pass
		if event.keycode == KEY_2:
			jugar_partido()

func score_point(equipo: String) -> void:
	if equipo == 'Local':
		if local_points == 24:
			Events.score_set.emit(equipo)
			local_points = 0
			local_sets += 1
		else:
			Events.score_point.emit(equipo)
			local_points += 1
	if equipo == 'Rival':
		if rival_points == 24:
			Events.score_set.emit(equipo)
			rival_points = 0
			rival_sets += 1
		else:
			Events.score_point.emit(equipo)
			rival_points +=1
	if local_sets > 1 or rival_sets > 1:
		Events.finish_game.emit(equipo)
		

#region event_log			
func generate_Event(atacante: String,tipo_accion:String, es_local: bool, es_punto: int) -> void:
	var equipo := "Local" if es_local else "Rival"
	var mensaje := "%s %s %s" % [MENSAJES[tipo_accion][0],atacante, equipo]
	if es_punto == 1:
		mensaje += " y anota!"
	if es_punto == 0:
		mensaje += " y  falla!"
		
	var evento := {"team": equipo, "message": mensaje, "fue_punto": es_punto}
	Events.draw_event.emit(evento)
	if es_punto != 2:
		process_event(evento)

func process_event(evento: Dictionary) -> void:
	var punto = evento.fue_punto
	var equipo =""
	if not punto:
		equipo = 'Rival' if evento.team == 'Local' else 'Local'
	else:
		equipo = evento.team
	score_point(equipo)
	if equipo != sacador:
		sacador = equipo
		rotar(equipo)
#endregion

#region posiciones
func rotar(equipo) -> void:
	if equipo == 'Local':
		rotacionL = rotacionL[-1] + rotacionL.substr(0, rotacionL.length() - 1)
		print("Local")
		print(rotacionL)
		Events.actualizar_rotacion.emit(equipo,jugador_pos(equipo,rotacionL[0]))
	else:
		rotacionR = rotacionR[-1] + rotacionR.substr(0, rotacionR.length() - 1)
		print("Rival")
		print(rotacionR)
		Events.actualizar_rotacion.emit(equipo,jugador_pos(equipo,rotacionR[0]))
		
		
func es_delantero(jugador: Jugador) -> bool:
	var rotacion := rotacionL if jugador.equipo == 'Local' else rotacionR
	var indice := rotacion.find(jugador.posicion_letra)
	return indice > 0 and indice < 4
	
func jugador_en(equipo: String, numero_pos: int) -> Jugador:
	var indice_str := numero_pos - 1
	var rotacion_actual := rotacionL if equipo == "Local" else rotacionR
	var letra_posicion := rotacion_actual[indice_str]
	return jugador_pos(equipo, letra_posicion)

func jugador_pos(equipo: String, pos: String) -> Jugador:
	var indice_roster := POSICIONES.find(pos)
	var roster := roster_local if equipo == "Local" else roster_rival
	return roster[indice_roster]
	
#endregion

#region sheduler
# Saque / Defensa / Armado / Ataque
# Saque -> (Recepcion -> Armado -> Ataque ->)
func jugar_partido() -> void:
	while local_points < 25 or rival_points < 25:
		await jugar_punto()


func jugar_punto() -> void:
	var estado_local = ""
	var estado_rival = ""
	var entrasaque = 0
	
	var bl_equipo_saque = sacador == 'Local'
	var rival_saque = 'Rival' if sacador == 'Local' else 'Local' 
	var vl_equipo_rival = not bl_equipo_saque
	if estado_local == "":
		if sacador == "Local":
			estado_local = 'Saque'
			estado_rival = 'Defensa'
		else:
			estado_rival = 'Saque'
			estado_local = 'Defensa'
	# Punto de saque
	var jugador_saque = jugador_en(sacador,1)
	if jugador_saque == usuario:
		entrasaque = await escena_ataque(usuario,true)
	else:
		entrasaque = randi_range(0,10)
	
	if entrasaque > 8:
		generate_Event(jugador_saque.nombre,'Saque',bl_equipo_saque,1)
		return
	if entrasaque < 3:
		generate_Event(jugador_saque.nombre,'Saque',bl_equipo_saque,0)
		return
	generate_Event(jugador_saque.nombre,'Saque',bl_equipo_saque,2)
	
	var en_juego = true
	var situacion_punto = 0
	var equipo_al_balon = rival_saque
	var bl_equipo_balon = vl_equipo_rival
	
	while en_juego:
		
		#recepcion
		await get_tree().create_timer(0.5).timeout
		generate_Event(jugador_pos(equipo_al_balon,"L").nombre,'Defensa',bl_equipo_balon,2)
		#armado
		await get_tree().create_timer(0.5).timeout
		generate_Event(jugador_pos(equipo_al_balon,"A").nombre,'Armado',bl_equipo_balon,2)
		#ataque
		await get_tree().create_timer(0.5).timeout
		
		if randi_range(0,10)/10 <= probabilidad_juego and equipo_al_balon == 'Local':
			situacion_punto = await escena_ataque(usuario)
		else:
			situacion_punto = randi_range(0,10)
		
		if situacion_punto > 8:
			generate_Event(jugador_pos(equipo_al_balon,"D").nombre,'Ataque',bl_equipo_balon,1)
			return
		if situacion_punto < 2:
			generate_Event(jugador_pos(equipo_al_balon,"D").nombre,'Ataque',bl_equipo_balon,0)
			return
		generate_Event(jugador_pos(equipo_al_balon,"D").nombre,'Ataque',bl_equipo_balon,2)
		
		equipo_al_balon = 'Rival' if equipo_al_balon == 'Local' else 'Local'
		bl_equipo_balon = true if equipo_al_balon == 'Local' else false
		
	

#endregion

#region escenas
func escena_ataque(usuario,es_saque = false) -> int:
	
	
	var cancha = attack_scene.instantiate()
	Events.mostrar_logs.emit(false)
	cancha.global_position = Vector2(0,0)
	if es_saque:
		cancha.posicion_ataque = Vector2(230, 564)
	elif es_delantero(usuario):
		cancha.posicion_ataque = Vector2(76, 328)
	else:
		cancha.posicion_ataque = Vector2(155, 458)
	add_child(cancha)
	await Events.ataque_terminado
	
	print(cancha.estado_final)
	var resultado = cancha.estado_final
	cancha.queue_free()
	Events.mostrar_logs.emit(true)
	return resultado
	
	
#endregion
