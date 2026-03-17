## OverworldPlayer.gd — Movimiento del jugador en el overworld
## CharacterBody2D con movimiento en 4 direcciones, colisiones, interacciones
## Grass encounters, NPCs, entradas a edificios
extends CharacterBody2D

signal encounter_triggered(pokemon_id: int, level: int)
signal interaction_requested(npc: Node)

@export var speed: float = 96.0  # 3 tiles por segundo a 32px por tile
@export var tile_size: int = 32

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _trainer: PlayerTrainer
var _in_grass: bool = false
var _step_counter: float = 0.0
var _encounter_rate: float = 0.1  # 10% por paso en hierba
var _facing: String = "down"
var _is_moving: bool = false

# Pokémon disponibles en hierba (se configura por mapa)
var grass_encounters: Array[Dictionary] = [
    {"id": 16, "min_level": 2, "max_level": 4, "weight": 30},   # Pidgey
    {"id": 19, "min_level": 2, "max_level": 4, "weight": 30},   # Rattata
    {"id": 10, "min_level": 3, "max_level": 5, "weight": 20},   # Caterpie
    {"id": 13, "min_level": 3, "max_level": 5, "weight": 20},   # Weedle
]

func setup(trainer: PlayerTrainer) -> void:
    _trainer = trainer
    global_position = trainer.position * tile_size

func _physics_process(delta: float) -> void:
    var direction := Vector2.ZERO
    direction.x = Input.get_axis("ui_left", "ui_right")
    direction.y = Input.get_axis("ui_up", "ui_down")

    if direction != Vector2.ZERO:
        direction = direction.normalized() if direction.length() > 1 else direction
        # En Pokémon el movimiento es en grilla — simplificado aquí a libre pero orientado a 4 dirs
        if abs(direction.x) > abs(direction.y):
            direction.y = 0
            _facing = "right" if direction.x > 0 else "left"
        else:
            direction.x = 0
            _facing = "down" if direction.y > 0 else "up"

        velocity = direction * speed
        _is_moving = true
        _step_counter += speed * delta

        if _step_counter >= tile_size:
            _step_counter = 0.0
            _check_grass_encounter()
    else:
        velocity = Vector2.ZERO
        _is_moving = false

    move_and_slide()
    _update_animation()
    _update_interaction_ray()

    if Input.is_action_just_pressed("ui_accept"):
        _try_interact()

func _update_animation() -> void:
    if not sprite:
        return
    var anim := "walk_" + _facing if _is_moving else "idle_" + _facing
    if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
        if sprite.animation != anim:
            sprite.play(anim)
    else:
        # Fallback si no hay animaciones configuradas
        if _is_moving:
            sprite.flip_h = _facing == "left"

func _update_interaction_ray() -> void:
    if not interaction_ray:
        return
    match _facing:
        "up":    interaction_ray.target_position = Vector2(0, -tile_size)
        "down":  interaction_ray.target_position = Vector2(0, tile_size)
        "left":  interaction_ray.target_position = Vector2(-tile_size, 0)
        "right": interaction_ray.target_position = Vector2(tile_size, 0)

func _try_interact() -> void:
    if not interaction_ray or not interaction_ray.is_colliding():
        return
    var collider := interaction_ray.get_collider()
    if collider and collider.is_in_group("npc"):
        interaction_requested.emit(collider)

func _check_grass_encounter() -> void:
    if not _in_grass:
        return
    if randf() > _encounter_rate:
        return
    if not _trainer or not _trainer.has_alive_pokemon():
        return

    # Seleccionar Pokémon ponderado
    var total_weight := grass_encounters.reduce(func(acc, e): return acc + e["weight"], 0)
    var roll := randi() % total_weight
    var cumulative := 0
    for entry in grass_encounters:
        cumulative += entry["weight"]
        if roll < cumulative:
            var level := entry["min_level"] + randi() % (entry["max_level"] - entry["min_level"] + 1)
            encounter_triggered.emit(entry["id"], level)
            return

func enter_grass() -> void:
    _in_grass = true

func exit_grass() -> void:
    _in_grass = false
    _step_counter = 0.0
