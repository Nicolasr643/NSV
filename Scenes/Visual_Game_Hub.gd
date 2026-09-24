extends Control

@onready var lb_local_puntaje = $Panel/Puntajes/Box_Local/Puntaje
@onready var lb_rival_puntaje = $Panel/Puntajes/Box_Rival/Puntaje
@onready var lb_set_actual = $Panel/Puntajes/Box_Set/Set
@onready var lb_puntaje = $Panel/Puntajes/Box_Set/Puntaje
@onready var log_template: RichTextLabel = $Panel/Log_Display/ScrollContainer/VBoxContainer/RL_Template
@onready var scroll: ScrollContainer = $Panel/Log_Display/ScrollContainer
@onready var vbox_scroll: VBoxContainer = $Panel/Log_Display/ScrollContainer/VBoxContainer

@onready var lb_saque_l: Label = $"Panel/VBoxContainer/Rotacion/Saque_L"
@onready var lb_saque_r: Label = $"Panel/VBoxContainer/Rotacion/Saque_R"
const COLOR_RIVAL := "coral"
const COLOR_LOCAL := "teal"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_label(lb_local_puntaje,0)
	update_label(lb_rival_puntaje,0)
	update_label(lb_set_actual,[0," - ",0])
	Events.score_point.connect(anotar_punto)
	Events.score_set.connect(actualizar_set)
	Events.finish_game.connect(finalizar_partido)
	Events.draw_event.connect(add_log)
	Events.actualizar_rotacion.connect(actualizar_sacador)

func update_label(label: Label,text: Variant) -> void:
	var text_final := ""
	if text is Array:
		for elem in text:
			text_final += str(elem)
	else:
		text_final = str(text)
	label.text = text_final

#region Manejo de puntos
func anotar_punto(team) -> void:
	if team == 'Local':
		var nuevo_puntaje = int(lb_local_puntaje.text) + 1
		update_label(lb_local_puntaje,nuevo_puntaje)
	if team == 'Rival':
		var nuevo_puntaje = int(lb_rival_puntaje.text) + 1
		update_label(lb_rival_puntaje,nuevo_puntaje)
func actualizar_set(team) -> void:
	var sets = lb_set_actual.text.split(" - ")
	if team == 'Local':
		update_label(lb_set_actual,[int(sets[0])+1," - ",int(sets[1])])
	else:
		update_label(lb_set_actual,[int(sets[0])," - ",int(sets[1])+1])
	update_label(lb_local_puntaje,0)
	update_label(lb_rival_puntaje,0)

func actualizar_sacador(equipo,jugador:Jugador) -> void:
	if equipo == 'Local':
		update_label(lb_saque_l,jugador.posicion_letra + ": " + jugador.nombre)
	else:
		update_label(lb_saque_r,jugador.posicion_letra + ": " + jugador.nombre)
func finalizar_partido(equipo):
	print("Ha ganado "+ equipo)
#endregion


func add_log(evento: Dictionary) -> void:
	var new_log := log_template.duplicate()
	var equipo = evento.team
	var message = evento.message
	var color = ""
	if equipo == 'Local':
		color = COLOR_LOCAL
	if equipo == 'Rival':
		color = COLOR_RIVAL
	new_log.text = ("[color=%s]%s[/color]\n" % [color, message])
	new_log.visible = true
	vbox_scroll.add_child(new_log)
	await get_tree().process_frame
	var scroll_bar = scroll.get_v_scroll_bar()
	scroll.scroll_vertical = scroll_bar.max_value
