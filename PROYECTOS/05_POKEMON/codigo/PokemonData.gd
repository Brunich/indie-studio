## PokemonData.gd — Recurso que representa a un Pokémon en el party
## Instanciar con PokemonData.create(pokemon_id, level)
class_name PokemonData
extends Resource

# Identidad
@export var pokemon_id: int = 1
@export var nickname: String = ""
@export var level: int = 5

# Stats calculados (base + IV + EV + level)
@export var max_hp: int = 20
@export var current_hp: int = 20
@export var attack: int = 10
@export var defense: int = 10
@export var sp_attack: int = 10
@export var sp_defense: int = 10
@export var speed: int = 10

# IVs (Individual Values) — aleatorios al crear, 0-31
@export var iv_hp: int = 0
@export var iv_atk: int = 0
@export var iv_def: int = 0
@export var iv_sp_atk: int = 0
@export var iv_sp_def: int = 0
@export var iv_spd: int = 0

# Experiencia
@export var exp: int = 0
@export var exp_to_next: int = 100

# Movimientos (máx 4)
@export var moves: Array[Dictionary] = []
# Cada move: {"id": "tackle", "current_pp": 35, "max_pp": 35}

# Estado
@export var status: String = ""  # "", "poison", "burn", "paralysis", "sleep", "freeze"
@export var status_turns: int = 0

# Tipos (desde la DB)
var types: Array[String] = []
var base_stats: Dictionary = {}
var name_display: String = ""

## Crea un Pokémon desde la DB en JSON
static func create(pid: int, lv: int) -> PokemonData:
    var data := PokemonData.new()
    data.pokemon_id = pid
    data.level = lv

    # Cargar DB
    var db := _load_db()
    var entry: Dictionary = db.get(str(pid), {})
    if entry.is_empty():
        push_error("PokemonData: Pokémon ID %d no encontrado" % pid)
        return data

    data.name_display = entry.get("name", "Unknown")
    data.nickname = data.name_display
    data.types = entry.get("types", ["normal"])
    data.base_stats = entry.get("base_stats", {})

    # IVs aleatorios
    data.iv_hp    = randi() % 32
    data.iv_atk   = randi() % 32
    data.iv_def   = randi() % 32
    data.iv_sp_atk = randi() % 32
    data.iv_sp_def = randi() % 32
    data.iv_spd   = randi() % 32

    # Calcular stats
    data._recalculate_stats()
    data.current_hp = data.max_hp

    # Moveset inicial (primer movimiento del levelup_moves)
    var levelup_moves = entry.get("levelup_moves", [[1, "tackle"]])
    var moves_db := _load_moves_db()
    for move_entry in levelup_moves:
        var learn_level: int = move_entry[0]
        var move_id: String = move_entry[1]
        if learn_level <= lv and data.moves.size() < 4:
            var move_data: Dictionary = moves_db.get(move_id, {})
            if not move_data.is_empty():
                data.moves.append({
                    "id": move_id,
                    "name": move_id.replace("_", " ").capitalize(),
                    "current_pp": move_data.get("pp", 10),
                    "max_pp": move_data.get("pp", 10),
                })

    if data.moves.is_empty():
        data.moves.append({"id": "tackle", "name": "Tackle", "current_pp": 35, "max_pp": 35})

    # EXP
    data.exp = data._exp_at_level(lv)
    data.exp_to_next = data._exp_at_level(lv + 1) - data.exp

    return data

## Fórmula de stat de Gen 3+ (moderna, compatible con gen 1)
func _recalculate_stats() -> void:
    var bs := base_stats
    max_hp    = _calc_hp(bs.get("hp", 45))
    attack    = _calc_stat(bs.get("attack", 49))
    defense   = _calc_stat(bs.get("defense", 49))
    sp_attack = _calc_stat(bs.get("sp_attack", 65))
    sp_defense = _calc_stat(bs.get("sp_defense", 65))
    speed     = _calc_stat(bs.get("speed", 45))

func _calc_hp(base: int) -> int:
    return int((2 * base + iv_hp) * level / 100.0) + level + 10

func _calc_stat(base: int) -> int:
    return int((2 * base + iv_atk) * level / 100.0) + 5

func _exp_at_level(lv: int) -> int:
    return int(pow(lv, 3))  # experiencia medium-fast

## Daño recibido — retorna true si se desmayó
func take_damage(amount: int) -> bool:
    current_hp = max(0, current_hp - amount)
    return current_hp == 0

## Curación
func heal(amount: int) -> void:
    current_hp = min(max_hp, current_hp + amount)

## HP como porcentaje 0.0 → 1.0
func hp_ratio() -> float:
    return float(current_hp) / float(max_hp)

## ¿Está debilitado?
func is_fainted() -> bool:
    return current_hp <= 0

## Ganar experiencia — retorna true si subió de nivel
func gain_exp(amount: int) -> bool:
    exp += amount
    if exp >= exp_to_next + _exp_at_level(level):
        level += 1
        _recalculate_stats()
        current_hp = min(current_hp + 5, max_hp)  # bonus HP al subir nivel
        exp_to_next = _exp_at_level(level + 1) - _exp_at_level(level)
        return true
    return false

static func _load_db() -> Dictionary:
    var path := "res://datos/pokemon_gen1.json"
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    return JSON.parse_string(f.get_as_text()) if f else {}

static func _load_moves_db() -> Dictionary:
    var path := "res://datos/moves.json"
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    return JSON.parse_string(f.get_as_text()) if f else {}
