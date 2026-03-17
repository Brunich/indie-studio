## PvPBattleSystem.gd — Maneja batallas PvP (jugador vs jugador)
## Hereda la lógica de BattleSystem, añade manejo de dos partys reales
## El HOST ejecuta la lógica, los clientes solo reciben resultados
extends Node

signal pvp_log(message: String)
signal pvp_turn_done(result: Dictionary)
signal pvp_ended(winner: String)

var player1_pokemon: PokemonData  # Pokémon activo del jugador 1
var player2_pokemon: PokemonData  # Pokémon activo del jugador 2

var _type_chart: Dictionary = {}

func _ready() -> void:
	_load_type_chart()

## Iniciar batalla PvP (llamado por el host después de recibir ambas parties)
func start_pvp(p1: PokemonData, p2: PokemonData) -> void:
	player1_pokemon = p1
	player2_pokemon = p2

## Ejecutar un turno PvP con las acciones de ambos jugadores
## Retorna un array de strings de log para sincronizar
func execute_pvp_turn(action_p1: Dictionary, action_p2: Dictionary) -> Array[String]:
	var log: Array[String] = []

	var move_id_p1: String = action_p1.get("data", {}).get("move_id", "tackle")
	var move_id_p2: String = action_p2.get("data", {}).get("move_id", "tackle")

	# Determinar orden por velocidad (prioridad de Quick Attack, etc.)
	var p1_first := player1_pokemon.speed >= player2_pokemon.speed

	if p1_first:
		log.append_array(_do_move(player1_pokemon, player2_pokemon, move_id_p1))
		if not player2_pokemon.is_fainted():
			log.append_array(_do_move(player2_pokemon, player1_pokemon, move_id_p2))
	else:
		log.append_array(_do_move(player2_pokemon, player1_pokemon, move_id_p2))
		if not player1_pokemon.is_fainted():
			log.append_array(_do_move(player1_pokemon, player2_pokemon, move_id_p1))

	# Check ganador
	if player1_pokemon.is_fainted():
		pvp_ended.emit("player2")
		log.append("¡%s se debilitó! — Jugador 2 gana." % player1_pokemon.name_display)
	elif player2_pokemon.is_fainted():
		pvp_ended.emit("player1")
		log.append("¡%s se debilitó! — Jugador 1 gana." % player2_pokemon.name_display)

	pvp_turn_done.emit(get_state_dict())
	return log

func _do_move(attacker: PokemonData, defender: PokemonData, move_id: String) -> Array[String]:
	var result: Array[String] = []
	var moves_db := PokemonData._load_moves_db()
	var move: Dictionary = moves_db.get(move_id, {"power": 40, "type": "normal", "category": "physical", "accuracy": 100})

	result.append("%s usó %s." % [attacker.name_display, move_id.replace("_", " ").capitalize()])

	if move.get("category") == "status":
		result.append("(efecto de status)")
		return result

	if randi() % 100 >= move.get("accuracy", 100):
		result.append("¡El ataque falló!")
		return result

	var power: int = move.get("power", 40)
	var is_physical: bool = move.get("category") == "physical"
	var atk_stat: float = attacker.attack if is_physical else attacker.sp_attack
	var def_stat: float = defender.defense if is_physical else defender.sp_defense
	var stab := 1.5 if move.get("type", "normal") in attacker.types else 1.0
	var effectiveness := _get_effectiveness(move.get("type", "normal"), defender.types)
	var random_factor := (randi() % 16 + 85) / 100.0
	var damage := int(((2 * attacker.level / 5.0 + 2) * power * atk_stat / def_stat / 50.0 + 2) * stab * effectiveness * random_factor)
	damage = max(1, damage)

	defender.take_damage(damage)
	result.append("%s recibió %d de daño. (HP: %d/%d)" % [defender.name_display, damage, defender.current_hp, defender.max_hp])

	if effectiveness >= 2.0: result.append("¡Es muy eficaz!")
	elif effectiveness <= 0.5: result.append("No es muy eficaz...")

	return result

func get_state_dict() -> Dictionary:
	return {
		"p1_hp": player1_pokemon.current_hp,
		"p1_max_hp": player1_pokemon.max_hp,
		"p1_name": player1_pokemon.name_display,
		"p2_hp": player2_pokemon.current_hp,
		"p2_max_hp": player2_pokemon.max_hp,
		"p2_name": player2_pokemon.name_display,
	}

func _get_effectiveness(move_type: String, defender_types: Array) -> float:
	var mult := 1.0
	var chart: Dictionary = _type_chart.get(move_type, {})
	for dtype in defender_types:
		mult *= chart.get(dtype, 1.0)
	return mult

func _load_type_chart() -> void:
	var path := "res://datos/type_chart.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f: _type_chart = JSON.parse_string(f.get_as_text())
