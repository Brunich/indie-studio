## MegaEvolution.gd — Mega Evolución con significado narrativo
## La primera vez que se usa en batalla, el Pokémon muestra resistencia (lore)
## Solo se puede usar 1 vez por batalla — requiere Key Stone + Mega Stone
## Los Pokémon tienen "confianza" — a mayor vínculo, la mega forma dura más
extends Node

signal mega_triggered(pokemon: PokemonData, mega_form: String)
signal mega_ended(pokemon: PokemonData)
signal bond_increased(pokemon: PokemonData, new_bond: int)

## Qué Pokémon pueden mega-evolucionar y en qué forma
## Datos de PokeAPI: /pokemon/{name}-mega / /pokemon/{name}-mega-x / -mega-y
const MEGA_DATA: Dictionary = {
	3:   {"form": "venusaur-mega",    "stone": "venusaurite"},
	6:   {"forms": ["charizard-mega-x", "charizard-mega-y"], "stone": "charizardite-x"},
	9:   {"form": "blastoise-mega",   "stone": "blastoisinite"},
	65:  {"form": "alakazam-mega",    "stone": "alakazite"},
	94:  {"form": "gengar-mega",      "stone": "gengarite"},
	115: {"form": "kangaskhan-mega",  "stone": "kangaskhanite"},
	127: {"form": "pinsir-mega",      "stone": "pinsirite"},
	130: {"form": "gyarados-mega",    "stone": "gyaradosite"},
	142: {"form": "aerodactyl-mega",  "stone": "aerodactylite"},
	150: {"forms": ["mewtwo-mega-x", "mewtwo-mega-y"], "stone": "mewtwonite-x"},
	181: {"form": "ampharos-mega",    "stone": "ampharosite"},
	212: {"form": "scizor-mega",      "stone": "scizorite"},
	214: {"form": "heracross-mega",   "stone": "heracronite"},
	229: {"form": "houndoom-mega",    "stone": "houndoominite"},
	248: {"form": "tyranitar-mega",   "stone": "tyranitarite"},
	257: {"form": "blaziken-mega",    "stone": "blazikenite"},
	260: {"form": "swampert-mega",    "stone": "swampertite"},
	282: {"form": "gardevoir-mega",   "stone": "gardevoirite"},
	303: {"form": "mawile-mega",      "stone": "mawilite"},
	306: {"form": "aggron-mega",      "stone": "aggronite"},
	308: {"form": "medicham-mega",    "stone": "medichamite"},
	310: {"form": "manectric-mega",   "stone": "manectite"},
	354: {"form": "banette-mega",     "stone": "banettite"},
	359: {"form": "absol-mega",       "stone": "absolite"},
	373: {"form": "salamence-mega",   "stone": "salamencite"},
	376: {"form": "metagross-mega",   "stone": "metagrossite"},
	380: {"form": "latias-mega",      "stone": "latiasite"},
	381: {"form": "latios-mega",      "stone": "latiosite"},
	384: {"form": "rayquaza-mega",    "stone": ""},  # Rayquaza no necesita Mega Stone
	428: {"form": "lopunny-mega",     "stone": "lopunnite"},
	445: {"form": "garchomp-mega",    "stone": "garchompite"},
	448: {"form": "lucario-mega",     "stone": "lucarionite"},
	460: {"form": "abomasnow-mega",   "stone": "abomasite"},
	475: {"form": "gallade-mega",     "stone": "galladite"},
	531: {"form": "audino-mega",      "stone": "audinite"},
	719: {"form": "diancie-mega",     "stone": "diancite"},
}

## Vínculo del entrenador con cada Pokémon (0-100)
## 0 = recién capturado, 100 = amigos desde siempre
var _bond: Dictionary = {}  # pokemon_id -> int

## Si el Pokémon ya mega-evolucionó esta batalla
var _used_this_battle: bool = false
var _current_mega: PokemonData = null

func can_mega(pokemon: PokemonData, has_key_stone: bool) -> bool:
	if _used_this_battle:
		return false
	if not has_key_stone:
		return false
	return MEGA_DATA.has(pokemon.pokemon_id)

## Intentar mega-evolucionar (el Pokémon puede resistirse si el vínculo es bajo)
func try_mega_evolve(pokemon: PokemonData) -> bool:
	var bond_level: int = _bond.get(pokemon.pokemon_id, 0)

	# Con vínculo bajo, el Pokémon resiste la transformación
	# Esto es parte de la narrativa: la mega evolución duele sin confianza
	if bond_level < 20:
		mega_triggered.emit(pokemon, "RESISTENCIA")  # señal especial — Pokémon se niega
		return false

	var mega_entry: Dictionary = MEGA_DATA.get(pokemon.pokemon_id, {})
	var mega_form: String = mega_entry.get("form", "")
	if mega_form.is_empty() and mega_entry.has("forms"):
		mega_form = mega_entry["forms"][0]  # default a primera forma

	_used_this_battle = true
	_current_mega = pokemon

	# Aplicar stat boost de mega evolución (aproximado — idealmente cargar de JSON)
	pokemon.attack = int(pokemon.attack * 1.3)
	pokemon.sp_attack = int(pokemon.sp_attack * 1.3)
	pokemon.speed = int(pokemon.speed * 1.1)

	mega_triggered.emit(pokemon, mega_form)
	return true

func reset_battle() -> void:
	_used_this_battle = false
	if _current_mega:
		# Revertir stats (simplificado)
		_current_mega.attack = int(_current_mega.attack / 1.3)
		_current_mega.sp_attack = int(_current_mega.sp_attack / 1.3)
		_current_mega.speed = int(_current_mega.speed / 1.1)
		mega_ended.emit(_current_mega)
		_current_mega = null

func increase_bond(pokemon: PokemonData, amount: int = 1) -> void:
	var current: int = _bond.get(pokemon.pokemon_id, 0)
	var new_bond: int = min(100, current + amount)
	_bond[pokemon.pokemon_id] = new_bond
	bond_increased.emit(pokemon, new_bond)

func get_bond(pokemon: PokemonData) -> int:
	return _bond.get(pokemon.pokemon_id, 0)
