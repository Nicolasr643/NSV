extends Node

var local_points = 0
var rival_points = 0
var local_sets = 0
var rival_sets = 0

const COLOR_RIVAL := "coral"
const COLOR_LOCAL := "teal"

const NOMBRES := {
	"Local": {
		"A": "Fernández", 
		"D": "Gómez", 
		"C": "Rodríguez", 
		"O": "Álvarez", 
		"T": "Suárez", 
		"L": "Benítez"
	},
	"Rival": {
		"A": "Cabrera", 
		"D": "Duarte", 
		"C": "Ibáñez", 
		"O": "Molina", 
		"T": "Paredes", 
		"L": "Vega"
	}
}
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



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			if randi_range(0,1):
				#generate_Event(NOMBRES.Local.pick_random(),1)
				pass
			else:
				#generate_Event(NOMBRES.Rival.pick_random(),0)
				pass
		if event.keycode == KEY_2:
			jugar_punto()

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
		Events.actualizar_rotacion.emit(equipo,[rotacionL[0],jugador_pos(equipo,rotacionL[0])])
	else:
		rotacionR = rotacionR[-1] + rotacionR.substr(0, rotacionR.length() - 1)
		print("Rival")
		print(rotacionR)
		Events.actualizar_rotacion.emit(equipo,[rotacionR[0],jugador_pos(equipo,rotacionR[0])])
		
		
func es_delantero(jugador: String,equipo:String) -> bool:
	if equipo == 'Local':
		return rotacionL.find(jugador) > 0 and rotacionL.find(jugador) < 4
	else:
		return rotacionR.find(jugador) > 0 and rotacionR.find(jugador) < 4
func jugador_en(equipo: String,pos: int) -> String:
	var indice_str := pos - 1 
	var rotacion_actual := rotacionL if equipo == "Local" else rotacionR
	var letra_posicion := rotacion_actual[indice_str]
	return NOMBRES[equipo][letra_posicion]
func jugador_pos(equipo: String,pos: String) -> String:
	return NOMBRES[equipo][pos]
#endregion

#region sheduler
# Saque / Defensa / Armado / Ataque
# Saque -> (Recepcion -> Armado -> Ataque ->)
func jugar_punto() -> void:
	var estado_local = ""
	var estado_rival = ""
	
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
	var entrasaque = randi_range(0,10)
	
	if entrasaque > 8:
		generate_Event(jugador_saque,'Saque',bl_equipo_saque,1)
		return
	if entrasaque < 3:
		generate_Event(jugador_saque,'Saque',bl_equipo_saque,0)
		return
	generate_Event(jugador_saque,'Saque',bl_equipo_saque,2)
	
	var en_juego = true
	var situacion_punto = 0
	var equipo_al_balon = rival_saque
	var bl_equipo_balon = vl_equipo_rival
	var jugador_receptor = jugador_en(rival_saque,randi_range(1,6))
	while en_juego:
		#recepcion
		await get_tree().create_timer(0.5).timeout
		generate_Event(jugador_receptor,'Defensa',bl_equipo_balon,2)
		#armado
		await get_tree().create_timer(0.5).timeout
		generate_Event(jugador_pos(equipo_al_balon,"A"),'Armado',bl_equipo_balon,2)
		#ataque
		await get_tree().create_timer(0.5).timeout
		
		situacion_punto = randi_range(0,10)
		
		if situacion_punto > 8:
			generate_Event(jugador_pos(equipo_al_balon,"D"),'Ataque',bl_equipo_balon,1)
			return
		if situacion_punto < 2:
			generate_Event(jugador_pos(equipo_al_balon,"D"),'Ataque',bl_equipo_balon,0)
			return
		generate_Event(jugador_pos(equipo_al_balon,"D"),'Ataque',bl_equipo_balon,2)
		
		equipo_al_balon = 'Rival' if equipo_al_balon == 'Local' else 'Local'
		bl_equipo_balon = true if equipo_al_balon == 'Local' else false
		
	

#endregion
