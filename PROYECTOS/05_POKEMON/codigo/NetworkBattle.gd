## NetworkBattle.gd — Batallas Pokémon entre jugadores via ENet
## Soporta: LAN directa, servidor dedicado, P2P con relay
## Flujo: ambos jugadores eligen movimiento simultáneo → servidor ejecuta turno
extends Node

signal battle_ready(opponent_name: String, opponent_party: Array)
signal turn_result_received(log_lines: Array[String], state: Dictionary)
signal battle_ended_network(result: String)
signal opponent_disconnected

enum NetworkState { DISCONNECTED, HOSTING, CONNECTING, IN_LOBBY, IN_BATTLE }

const DEFAULT_PORT: int = 7779
const MAX_PLAYERS: int = 2

var state: NetworkState = NetworkState.DISCONNECTED
var _my_action: Dictionary = {}
var _opponent_action: Dictionary = {}
var _both_actions_ready: bool = false
var _is_host: bool = false

## HOSTING
func host_battle(port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("NetworkBattle: no se pudo crear servidor en puerto %d" % port)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_is_host = true
	state = NetworkState.HOSTING
	print("🎮 Hosting batalla en puerto %d" % port)

## CONECTAR COMO CLIENTE
func join_battle(ip: String, port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_error("NetworkBattle: no se pudo conectar a %s:%d" % [ip, port])
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	state = NetworkState.CONNECTING
	print("🔌 Conectando a %s:%d..." % [ip, port])

func disconnect_battle() -> void:
	multiplayer.multiplayer_peer = null
	state = NetworkState.DISCONNECTED

## ─── SEÑALES DE RED ────────────────────────────────────────────
func _on_peer_connected(id: int) -> void:
	print("👤 Jugador conectado: %d" % id)
	state = NetworkState.IN_LOBBY
	# Host envía su info al cliente
	_send_player_info.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	print("👋 Jugador desconectado: %d" % id)
	opponent_disconnected.emit()
	state = NetworkState.DISCONNECTED

func _on_connected_to_server() -> void:
	print("✅ Conectado al servidor")
	state = NetworkState.IN_LOBBY
	_send_player_info.rpc_id(1)  # 1 = host

func _on_connection_failed() -> void:
	push_error("❌ Conexión fallida")
	state = NetworkState.DISCONNECTED

## ─── RPC DE LOBBY ──────────────────────────────────────────────

## Enviar info del jugador al oponente
@rpc("any_peer", "call_remote", "reliable")
func _send_player_info() -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	# TODO: enviar party serializada
	print("📋 Info de jugador %d recibida" % sender_id)
	state = NetworkState.IN_BATTLE

## ─── FLUJO DE TURNO ────────────────────────────────────────────

## Jugador local elige su acción para este turno
func submit_my_action(action_type: int, data: Dictionary) -> void:
	_my_action = {"type": action_type, "data": data}
	# Enviar al host (o si soy host, a todos)
	if _is_host:
		_receive_action.rpc(multiplayer.get_unique_id(), action_type, var_to_str(data))
	else:
		_receive_action.rpc_id(1, multiplayer.get_unique_id(), action_type, var_to_str(data))

## Host recibe acciones de ambos jugadores y ejecuta el turno
@rpc("any_peer", "call_local", "reliable")
func _receive_action(player_id: int, action_type: int, data_str: String) -> void:
	if not _is_host:
		return
	var data: Dictionary = str_to_var(data_str)
	if player_id == 1:  # host
		_my_action = {"type": action_type, "data": data}
	else:
		_opponent_action = {"type": action_type, "data": data}

	# Si ambos enviaron su acción, ejecutar turno
	if not _my_action.is_empty() and not _opponent_action.is_empty():
		_execute_networked_turn()

## Host ejecuta el turno y sincroniza resultado a ambos
func _execute_networked_turn() -> void:
	# El host tiene acceso a BattleSystem y ejecuta el turno
	# Luego envía el resultado a ambos jugadores
	var result_log: Array[String] = []
	var state_dict: Dictionary = {}

	# TODO: conectar con BattleSystem local del host
	# result_log = BattleSystem.execute_pvp_turn(_my_action, _opponent_action)
	# state_dict = BattleSystem.get_state_dict()

	# Enviar resultado a todos
	_sync_turn_result.rpc(var_to_str(result_log), var_to_str(state_dict))

	# Limpiar acciones para el siguiente turno
	_my_action = {}
	_opponent_action = {}

@rpc("authority", "call_local", "reliable")
func _sync_turn_result(log_str: String, state_str: String) -> void:
	var log_lines: Array[String] = []
	var raw = str_to_var(log_str)
	if raw is Array:
		for line in raw:
			log_lines.append(str(line))
	var state_d: Dictionary = str_to_var(state_str) if str_to_var(state_str) is Dictionary else {}
	turn_result_received.emit(log_lines, state_d)

## Sincronizar fin de batalla
@rpc("authority", "call_local", "reliable")
func _sync_battle_end(result: String) -> void:
	battle_ended_network.emit(result)
	state = NetworkState.DISCONNECTED

## ─── SERIALIZACIÓN DE PARTY ────────────────────────────────────

## Convierte una PokemonData a Dictionary para enviar por red
static func serialize_pokemon(p: PokemonData) -> Dictionary:
	return {
		"id": p.pokemon_id,
		"nickname": p.nickname,
		"level": p.level,
		"current_hp": p.current_hp,
		"max_hp": p.max_hp,
		"attack": p.attack,
		"defense": p.defense,
		"sp_attack": p.sp_attack,
		"sp_defense": p.sp_defense,
		"speed": p.speed,
		"moves": p.moves,
		"status": p.status,
		"types": p.types,
	}

static func deserialize_pokemon(d: Dictionary) -> PokemonData:
	var p := PokemonData.new()
	p.pokemon_id = d.get("id", 1)
	p.nickname = d.get("nickname", "")
	p.level = d.get("level", 5)
	p.current_hp = d.get("current_hp", 20)
	p.max_hp = d.get("max_hp", 20)
	p.attack = d.get("attack", 10)
	p.defense = d.get("defense", 10)
	p.sp_attack = d.get("sp_attack", 10)
	p.sp_defense = d.get("sp_defense", 10)
	p.speed = d.get("speed", 10)
	p.moves = d.get("moves", [])
	p.status = d.get("status", "")
	p.types = d.get("types", ["normal"])
	return p
