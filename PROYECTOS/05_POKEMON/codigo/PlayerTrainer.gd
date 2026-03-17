## PlayerTrainer.gd — Datos persistentes del entrenador jugador
## Autoload o recurso del SaveSystem
extends Resource

@export var trainer_name: String = "Ash"
@export var money: int = 3000
@export var badges: int = 0
@export var play_time_seconds: float = 0.0

# Party (máx 6 Pokémon)
@export var party: Array[PokemonData] = []

# Bag (items)
@export var bag: Dictionary = {
    "poke_ball": 5,
    "potion": 3,
}

# Pokédex (IDs vistos y atrapados)
@export var pokedex_seen: Array[int] = []
@export var pokedex_caught: Array[int] = []

# Posición en el mundo
@export var current_map: String = "ciudad_inicio"
@export var position: Vector2 = Vector2(10, 10)

func add_pokemon(pokemon: PokemonData) -> bool:
    if party.size() >= 6:
        return false  # TODO: enviar a PC Box
    party.append(pokemon)
    if pokemon.pokemon_id not in pokedex_caught:
        pokedex_caught.append(pokemon.pokemon_id)
    return true

func get_first_alive() -> PokemonData:
    for pokemon in party:
        if not pokemon.is_fainted():
            return pokemon
    return null

func has_alive_pokemon() -> bool:
    return get_first_alive() != null

func add_item(item_id: String, amount: int = 1) -> void:
    bag[item_id] = bag.get(item_id, 0) + amount

func use_item(item_id: String) -> bool:
    if bag.get(item_id, 0) <= 0:
        return false
    bag[item_id] -= 1
    if bag[item_id] == 0:
        bag.erase(item_id)
    return true

func see_pokemon(pokemon_id: int) -> void:
    if pokemon_id not in pokedex_seen:
        pokedex_seen.append(pokemon_id)

func earn_money(amount: int) -> void:
    money += amount

func spend_money(amount: int) -> bool:
    if money < amount:
        return false
    money -= amount
    return true
