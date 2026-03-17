## BattleUI.gd — Interfaz de batalla estilo Pokémon
## CanvasLayer con: sprites de Pokémon, barras de HP, panel de acciones, log
extends CanvasLayer

# Nodos UI (configurar en editor o crear por código)
@onready var sprite_player: TextureRect = $BattleContainer/PlayerSide/SpritePlayer
@onready var sprite_enemy: TextureRect = $BattleContainer/EnemySide/SpriteEnemy
@onready var hp_bar_player: ProgressBar = $BattleContainer/PlayerSide/HPBar
@onready var hp_bar_enemy: ProgressBar = $BattleContainer/EnemySide/HPBar
@onready var label_player_name: Label = $BattleContainer/PlayerSide/LabelName
@onready var label_enemy_name: Label = $BattleContainer/EnemySide/LabelName
@onready var label_player_level: Label = $BattleContainer/PlayerSide/LabelLevel
@onready var label_enemy_level: Label = $BattleContainer/EnemySide/LabelLevel
@onready var battle_log_label: RichTextLabel = $BattleContainer/LogPanel/BattleLog
@onready var action_panel: Control = $BattleContainer/ActionPanel
@onready var moves_panel: Control = $BattleContainer/MovesPanel
@onready var exp_bar: ProgressBar = $BattleContainer/PlayerSide/ExpBar

var _battle_system: BattleSystem
var _current_pokemon_player: PokemonData
var _current_pokemon_enemy: PokemonData

## Iniciar UI de batalla
func setup_battle(battle: BattleSystem, player: PokemonData, enemy: PokemonData) -> void:
    _battle_system = battle
    _current_pokemon_player = player
    _current_pokemon_enemy = enemy

    _battle_system.battle_log.connect(_on_battle_log)
    _battle_system.move_used.connect(_on_move_used)
    _battle_system.pokemon_fainted.connect(_on_pokemon_fainted)
    _battle_system.exp_gained.connect(_on_exp_gained)
    _battle_system.battle_ended.connect(_on_battle_ended)
    _battle_system.request_player_action.connect(_show_action_panel)

    _update_pokemon_display(player, enemy)
    _load_sprites(player, enemy)

func _update_pokemon_display(player: PokemonData, enemy: PokemonData) -> void:
    if label_player_name: label_player_name.text = player.name_display
    if label_enemy_name:  label_enemy_name.text = enemy.name_display
    if label_player_level: label_player_level.text = "Nv. %d" % player.level
    if label_enemy_level:  label_enemy_level.text = "Nv. %d" % enemy.level
    _update_hp_bars(player, enemy)

func _update_hp_bars(player: PokemonData, enemy: PokemonData) -> void:
    if hp_bar_player:
        hp_bar_player.value = player.hp_ratio() * 100
        hp_bar_player.modulate = _hp_color(player.hp_ratio())
    if hp_bar_enemy:
        hp_bar_enemy.value = enemy.hp_ratio() * 100
        hp_bar_enemy.modulate = _hp_color(enemy.hp_ratio())

func _hp_color(ratio: float) -> Color:
    if ratio > 0.5: return Color(0.2, 0.8, 0.2)
    if ratio > 0.25: return Color(1.0, 0.8, 0.0)
    return Color(0.9, 0.1, 0.1)

func _load_sprites(player: PokemonData, enemy: PokemonData) -> void:
    # Sprite frontal del enemigo (battle front sprite)
    var enemy_path := "res://sprites/pokemon/%d.png" % enemy.pokemon_id
    if ResourceLoader.exists(enemy_path) and sprite_enemy:
        sprite_enemy.texture = load(enemy_path)

    # Sprite trasero del jugador (battle back sprite)
    var player_path := "res://sprites/pokemon/%d_back.png" % player.pokemon_id
    if ResourceLoader.exists(player_path) and sprite_player:
        sprite_player.texture = load(player_path)

func _show_action_panel() -> void:
    if action_panel: action_panel.show()
    if moves_panel: moves_panel.hide()
    _refresh_moves_buttons()

func _refresh_moves_buttons() -> void:
    if not moves_panel:
        return
    for i in 4:
        var btn := moves_panel.get_node_or_null("Move%d" % (i + 1))
        if not btn:
            continue
        if i < _current_pokemon_player.moves.size():
            var move: Dictionary = _current_pokemon_player.moves[i]
            btn.text = "%s\n%d/%d PP" % [move["name"], move["current_pp"], move["max_pp"]]
            btn.disabled = move["current_pp"] <= 0
            btn.show()
        else:
            btn.hide()

## Botón Luchar
func _on_btn_fight_pressed() -> void:
    if action_panel: action_panel.hide()
    if moves_panel: moves_panel.show()

## Botón de movimiento (conectar cada BtnMove desde el editor)
func _on_move_selected(index: int) -> void:
    if index >= _current_pokemon_player.moves.size():
        return
    var move_id: String = _current_pokemon_player.moves[index]["id"]
    _battle_system.submit_action(BattleSystem.ActionType.FIGHT, {"move_id": move_id})
    if moves_panel: moves_panel.hide()

## Botón Huir
func _on_btn_run_pressed() -> void:
    _battle_system.submit_action(BattleSystem.ActionType.RUN)

## Botón Pokémon
func _on_btn_pokemon_pressed() -> void:
    # TODO: abrir panel de selección de party
    pass

## Botón Mochila
func _on_btn_bag_pressed() -> void:
    # TODO: abrir panel de inventario
    pass

func _on_battle_log(message: String) -> void:
    if battle_log_label:
        battle_log_label.append_text(message + "\n")

func _on_move_used(attacker: PokemonData, move_id: String, damage: int, effectiveness: float) -> void:
    _update_hp_bars(_current_pokemon_player, _current_pokemon_enemy)
    # Efecto de shake en sprite enemigo
    if sprite_enemy and not attacker.is_fainted():
        var tween := create_tween()
        tween.tween_property(sprite_enemy, "position:x", sprite_enemy.position.x + 5, 0.05)
        tween.tween_property(sprite_enemy, "position:x", sprite_enemy.position.x - 5, 0.05)
        tween.tween_property(sprite_enemy, "position:x", sprite_enemy.position.x, 0.05)

func _on_pokemon_fainted(pokemon: PokemonData, is_player: bool) -> void:
    var sprite := sprite_player if is_player else sprite_enemy
    if sprite:
        var tween := create_tween()
        tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

func _on_exp_gained(pokemon: PokemonData, amount: int, leveled_up: bool) -> void:
    if exp_bar:
        var tween := create_tween()
        tween.tween_property(exp_bar, "value", (float(pokemon.exp) / float(pokemon.exp_to_next + pokemon.exp)) * 100, 0.5)
    if leveled_up and label_player_level:
        label_player_level.text = "Nv. %d" % pokemon.level

func _on_battle_ended(result: String) -> void:
    await get_tree().create_timer(2.0).timeout
    match result:
        "win":   get_tree().change_scene_to_file("res://escenas/overworld/overworld.tscn")
        "lose":  get_tree().change_scene_to_file("res://escenas/overworld/overworld.tscn")
        "fled":  get_tree().change_scene_to_file("res://escenas/overworld/overworld.tscn")
        "caught": get_tree().change_scene_to_file("res://escenas/overworld/overworld.tscn")
