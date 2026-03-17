## BattleSystem.gd — Sistema de batalla por turnos completo
## Maneja el flujo completo de un combate Pokémon
## Señales para conectar con la UI
extends Node

signal battle_log(message: String)
signal battle_ended(result: String)  # "win", "lose", "fled", "caught"
signal move_used(attacker: PokemonData, move_id: String, damage: int, effectiveness: float)
signal pokemon_fainted(pokemon: PokemonData, is_player: bool)
signal exp_gained(pokemon: PokemonData, amount: int, leveled_up: bool)
signal pokemon_caught(pokemon: PokemonData)
signal turn_started(player_first: bool)
signal request_player_action  # emitida cuando es el turno del jugador

enum BattleState { IDLE, WAITING_INPUT, EXECUTING_TURN, BATTLE_OVER }
enum ActionType { FIGHT, BAG, POKEMON, RUN }

# Participantes
var player_pokemon: PokemonData
var enemy_pokemon: PokemonData
var is_wild_battle: bool = true

# Estado
var state: BattleState = BattleState.IDLE
var _player_action: Dictionary = {}
var _type_chart: Dictionary = {}

func _ready() -> void:
    _load_type_chart()

## Inicia una batalla
func start_battle(player: PokemonData, enemy: PokemonData, wild: bool = true) -> void:
    player_pokemon = player
    enemy_pokemon = enemy
    is_wild_battle = wild
    state = BattleState.WAITING_INPUT
    battle_log.emit("¡Un %s salvaje apareció!" % enemy_pokemon.name_display if wild else "¡%s quiere combatir!" % enemy_pokemon.name_display)
    battle_log.emit("¡Ve, %s!" % player_pokemon.name_display)
    request_player_action.emit()

## Jugador selecciona una acción
func submit_action(action: ActionType, data: Dictionary = {}) -> void:
    if state != BattleState.WAITING_INPUT:
        return
    _player_action = {"type": action, "data": data}
    state = BattleState.EXECUTING_TURN
    _execute_turn()

## Ejecutar un turno completo
func _execute_turn() -> void:
    match _player_action.get("type", ActionType.FIGHT):
        ActionType.RUN:
            _try_run()
            return
        ActionType.BAG:
            _use_item(_player_action.get("data", {}))
            return
        ActionType.FIGHT:
            _execute_fight_turn()
        ActionType.POKEMON:
            _switch_pokemon(_player_action.get("data", {}).get("slot", 0))

func _execute_fight_turn() -> void:
    var player_move_id: String = _player_action.get("data", {}).get("move_id", "tackle")
    var enemy_move_id: String = _pick_enemy_move()

    # Determinar orden por velocidad
    var player_first := player_pokemon.speed >= enemy_pokemon.speed
    if player_first:
        _use_move(player_pokemon, enemy_pokemon, player_move_id, true)
        if not enemy_pokemon.is_fainted():
            _use_move(enemy_pokemon, player_pokemon, enemy_move_id, false)
    else:
        _use_move(enemy_pokemon, player_pokemon, enemy_move_id, false)
        if not player_pokemon.is_fainted():
            _use_move(player_pokemon, enemy_pokemon, player_move_id, true)

    _check_faint_and_continue()

## Calcular y aplicar daño de un movimiento
func _use_move(attacker: PokemonData, defender: PokemonData, move_id: String, is_player: bool) -> void:
    var moves_db := PokemonData._load_moves_db()
    var move: Dictionary = moves_db.get(move_id, {"power": 40, "type": "normal", "category": "physical", "accuracy": 100})

    var move_name := move_id.replace("_", " ").capitalize()
    battle_log.emit("%s usó %s." % [attacker.name_display, move_name])

    # Verificar PP
    for m in attacker.moves:
        if m["id"] == move_id:
            if m["current_pp"] <= 0:
                battle_log.emit("¡No quedan PP!")
                return
            m["current_pp"] -= 1

    # Status moves
    if move.get("category") == "status":
        _apply_status_move(move, attacker, defender)
        return

    # Accuracy check
    var accuracy: int = move.get("accuracy", 100)
    if randi() % 100 >= accuracy:
        battle_log.emit("¡El ataque falló!")
        return

    # Calcular daño (fórmula Gen 3+)
    var damage := _calculate_damage(attacker, defender, move)
    var effectiveness := _get_type_effectiveness(move.get("type", "normal"), defender.types)

    # Mensaje de efectividad
    if effectiveness >= 2.0:
        battle_log.emit("¡Es muy eficaz!")
    elif effectiveness <= 0.5:
        battle_log.emit("No es muy eficaz...")
    elif effectiveness == 0.0:
        battle_log.emit("¡No afecta a %s!" % defender.name_display)
        return

    var fainted := defender.take_damage(damage)
    move_used.emit(attacker, move_id, damage, effectiveness)

    battle_log.emit("%s recibió %d de daño." % [defender.name_display, damage])

    # Efectos secundarios
    _apply_secondary_effect(move, defender)

func _calculate_damage(attacker: PokemonData, defender: PokemonData, move: Dictionary) -> int:
    var power: int = move.get("power", 40)
    var category: String = move.get("category", "physical")

    var atk_stat: float = attacker.attack if category == "physical" else attacker.sp_attack
    var def_stat: float = defender.defense if category == "physical" else defender.sp_defense

    # STAB (Same Type Attack Bonus)
    var stab := 1.5 if move.get("type", "normal") in attacker.types else 1.0

    # Efectividad de tipo
    var effectiveness := _get_type_effectiveness(move.get("type", "normal"), defender.types)

    # Variación aleatoria (85-100%)
    var random_factor := (randi() % 16 + 85) / 100.0

    # Fórmula oficial simplificada
    var damage := int(((2 * attacker.level / 5.0 + 2) * power * atk_stat / def_stat / 50.0 + 2) * stab * effectiveness * random_factor)
    return max(1, damage)

func _get_type_effectiveness(move_type: String, defender_types: Array) -> float:
    var mult := 1.0
    var chart: Dictionary = _type_chart.get(move_type, {})
    for dtype in defender_types:
        mult *= chart.get(dtype, 1.0)
    return mult

func _apply_status_move(move: Dictionary, attacker: PokemonData, defender: PokemonData) -> void:
    var effect: String = move.get("effect", "")
    match effect:
        "lower_atk":
            defender.attack = max(1, int(defender.attack * 0.67))
            battle_log.emit("¡El ataque de %s bajó!" % defender.name_display)
        "lower_spd":
            defender.speed = max(1, int(defender.speed * 0.67))
            battle_log.emit("¡La velocidad de %s bajó!" % defender.name_display)
        "raise_atk_2":
            attacker.attack = int(attacker.attack * 2.0)
            battle_log.emit("¡El ataque de %s subió bruscamente!" % attacker.name_display)
        "raise_sp_atk_2":
            attacker.sp_attack = int(attacker.sp_attack * 2.0)
            battle_log.emit("¡El ataque esp. de %s subió bruscamente!" % attacker.name_display)
        "heal_half":
            var heal_amount := attacker.max_hp / 2
            attacker.heal(heal_amount)
            battle_log.emit("%s recuperó HP." % attacker.name_display)

func _apply_secondary_effect(move: Dictionary, defender: PokemonData) -> void:
    var effect: String = move.get("effect", "")
    if effect.is_empty() or defender.is_fainted():
        return
    var chance := int(effect.split("_").back()) if "_" in effect else 0
    if chance > 0 and randi() % 100 < chance:
        if "burn" in effect and defender.status.is_empty():
            defender.status = "burn"
            battle_log.emit("¡%s se quemó!" % defender.name_display)
        elif "paralyze" in effect and defender.status.is_empty():
            defender.status = "paralysis"
            battle_log.emit("¡%s quedó paralizado!" % defender.name_display)
        elif "freeze" in effect and defender.status.is_empty():
            defender.status = "freeze"
            battle_log.emit("¡%s quedó congelado!" % defender.name_display)
        elif "poison" in effect and defender.status.is_empty():
            defender.status = "poison"
            battle_log.emit("¡%s fue envenenado!" % defender.name_display)

func _pick_enemy_move() -> String:
    if enemy_pokemon.moves.is_empty():
        return "tackle"
    var valid_moves := enemy_pokemon.moves.filter(func(m): return m["current_pp"] > 0)
    if valid_moves.is_empty():
        return "tackle"
    return valid_moves[randi() % valid_moves.size()]["id"]

func _try_run() -> void:
    if not is_wild_battle:
        battle_log.emit("¡No puedes huir de un combate de entrenador!")
        state = BattleState.WAITING_INPUT
        request_player_action.emit()
        return
    battle_log.emit("¡Escapaste!")
    state = BattleState.BATTLE_OVER
    battle_ended.emit("fled")

func _use_item(item_data: Dictionary) -> void:
    var item_id: String = item_data.get("id", "")
    match item_id:
        "poke_ball", "great_ball", "ultra_ball", "master_ball":
            _throw_pokeball(item_id)
            return
        "potion":
            player_pokemon.heal(20)
            battle_log.emit("¡%s recuperó 20 HP!" % player_pokemon.name_display)
        "super_potion":
            player_pokemon.heal(50)
            battle_log.emit("¡%s recuperó 50 HP!" % player_pokemon.name_display)
        "full_restore":
            player_pokemon.heal(player_pokemon.max_hp)
            player_pokemon.status = ""
            battle_log.emit("¡%s se curó completamente!" % player_pokemon.name_display)
        "antidote":
            if player_pokemon.status == "poison":
                player_pokemon.status = ""
                battle_log.emit("¡%s se curó del veneno!" % player_pokemon.name_display)
    # El enemigo ataca después de usar objeto
    if not enemy_pokemon.is_fainted():
        _use_move(enemy_pokemon, player_pokemon, _pick_enemy_move(), false)
    _check_faint_and_continue()

func _throw_pokeball(ball_id: String) -> void:
    if not is_wild_battle:
        battle_log.emit("¡No puedes atrapar al Pokémon de un entrenador!")
        return

    # Tasa base según tipo de Poké Ball
    var ball_bonus := {"poke_ball": 1.0, "great_ball": 1.5, "ultra_ball": 2.0, "master_ball": 255.0}.get(ball_id, 1.0)

    var catch_rate: float = 45.0  # default, idealmente leer de la DB
    var hp_bonus := 1.0 + (1.0 - enemy_pokemon.hp_ratio()) * 2.0
    var status_bonus := 2.0 if enemy_pokemon.status in ["sleep", "freeze"] else (1.5 if enemy_pokemon.status != "" else 1.0)

    var catch_chance := (catch_rate * ball_bonus * hp_bonus * status_bonus) / 255.0

    battle_log.emit("Lanzaste una %s..." % ball_id.replace("_", " ").capitalize())

    if catch_chance >= 1.0 or randf() < catch_chance:
        battle_log.emit("¡Atrapaste a %s!" % enemy_pokemon.name_display)
        state = BattleState.BATTLE_OVER
        pokemon_caught.emit(enemy_pokemon)
        battle_ended.emit("caught")
    else:
        var shakes := int(catch_chance * 3)
        battle_log.emit("¡%s sacudió la Poké Ball y escapó!" % enemy_pokemon.name_display if shakes < 1 else "¡Casi lo atrapas!")

func _check_faint_and_continue() -> void:
    # Aplicar daño de estado al final del turno
    _apply_end_of_turn_status()

    if enemy_pokemon.is_fainted():
        var exp_yield: int = _calculate_exp_yield()
        battle_log.emit("¡%s se debilitó!" % enemy_pokemon.name_display)
        pokemon_fainted.emit(enemy_pokemon, false)
        battle_log.emit("¡%s ganó %d puntos de experiencia!" % [player_pokemon.name_display, exp_yield])
        var leveled_up := player_pokemon.gain_exp(exp_yield)
        exp_gained.emit(player_pokemon, exp_yield, leveled_up)
        if leveled_up:
            battle_log.emit("¡%s subió al nivel %d!" % [player_pokemon.name_display, player_pokemon.level])
        state = BattleState.BATTLE_OVER
        battle_ended.emit("win")
        return

    if player_pokemon.is_fainted():
        battle_log.emit("¡%s se debilitó!" % player_pokemon.name_display)
        pokemon_fainted.emit(player_pokemon, true)
        state = BattleState.BATTLE_OVER
        battle_ended.emit("lose")
        return

    state = BattleState.WAITING_INPUT
    request_player_action.emit()

func _apply_end_of_turn_status() -> void:
    for pokemon in [player_pokemon, enemy_pokemon]:
        match pokemon.status:
            "poison":
                var dmg := max(1, pokemon.max_hp / 8)
                pokemon.take_damage(dmg)
                battle_log.emit("%s sufrió daño por veneno." % pokemon.name_display)
            "burn":
                var dmg := max(1, pokemon.max_hp / 16)
                pokemon.take_damage(dmg)
                battle_log.emit("%s sufrió daño por quemadura." % pokemon.name_display)
            "sleep":
                pokemon.status_turns -= 1
                if pokemon.status_turns <= 0:
                    pokemon.status = ""
                    battle_log.emit("¡%s despertó!" % pokemon.name_display)

func _calculate_exp_yield() -> int:
    var base_exp: int = 64  # default Pokémon gen1
    # Leer de DB si está disponible
    return int(base_exp * enemy_pokemon.level / 7.0)

func _switch_pokemon(slot: int) -> void:
    battle_log.emit("¡Regresa, %s!" % player_pokemon.name_display)
    # El slot change debe ser manejado por el BattleUI — aquí solo notificamos
    battle_log.emit("¡Ve, nuevo Pokémon!")
    if not enemy_pokemon.is_fainted():
        _use_move(enemy_pokemon, player_pokemon, _pick_enemy_move(), false)
    _check_faint_and_continue()

func _load_type_chart() -> void:
    var path := "res://datos/type_chart.json"
    if FileAccess.file_exists(path):
        var f := FileAccess.open(path, FileAccess.READ)
        if f:
            _type_chart = JSON.parse_string(f.get_as_text())
