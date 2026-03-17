## ============================================================
## MECÁNICA: Movimiento del Jugador (Plataformero 2D)
## Generado: 16 de marzo 2026 | Semana 1 | Fase: Fundamentos
## Motor: Godot 4 / GDScript
## Para: Bruno — Indie Dev Portfolio | UANL Monterrey
## ============================================================
##
## QUÉ HACE ESTE CÓDIGO:
## Controla a tu personaje en un plataformero 2D clásico.
## Puede caminar izquierda/derecha, saltar, y caer con gravedad.
## Tiene "coyote time" (puedes saltar un instante después de caer)
## y "jump buffer" (el salto funciona si presionas justo antes de tocar suelo).
## Estas dos técnicas son lo que hace que un plataformero se SIENTA bien.
##
## CÓMO USARLO EN GODOT 4:
## 1. Crea una escena nueva
## 2. Agrega un nodo raíz: CharacterBody2D
## 3. Adentro agrega: CollisionShape2D + Sprite2D (o AnimatedSprite2D)
## 4. En CollisionShape2D, crea una forma (CapsuleShape2D o RectangleShape2D)
## 5. Adjunta ESTE script al nodo CharacterBody2D
## 6. Dale play y usa las flechas o WASD + Espacio para moverte
##
## NODOS REQUERIDOS EN LA ESCENA:
##   CharacterBody2D (con este script)
##   └── CollisionShape2D (forma del personaje)
##   └── Sprite2D o AnimatedSprite2D (imagen del personaje)
##   └── [opcional] Camera2D (para que la cámara siga al jugador)
## ============================================================

extends CharacterBody2D

# ---- VARIABLES EXPORTABLES ----
# @export = puedes cambiar este valor directo desde el Inspector de Godot sin tocar código

@export var speed: float = 200.0          ## Velocidad horizontal (píxeles por segundo)
@export var jump_force: float = -450.0    ## Fuerza del salto (negativo = hacia arriba en Godot)
@export var gravity_multiplier: float = 2.5  ## Multiplicador de gravedad (más alto = caída más pesada)

# ---- CONSTANTES DEL MOTOR ----
# get_gravity() devuelve la gravedad configurada en Project Settings > Physics > 2D
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# ---- VARIABLES DE ESTADO ----
var coyote_time: float = 0.12    ## Tiempo en segundos que puedes saltar después de caer
var jump_buffer: float = 0.10    ## Tiempo que se recuerda un salto presionado antes de tocar
var coyote_timer: float = 0.0    ## Contador del coyote time
var jump_buffer_timer: float = 0.0  ## Contador del jump buffer

# ---- REFERENCIA AL SPRITE ----
# Si tienes AnimatedSprite2D en vez de Sprite2D, cambia el tipo aquí
@onready var sprite: Sprite2D = $Sprite2D  # Ajusta si tu nodo se llama diferente


## _ready() se ejecuta UNA VEZ cuando la escena carga
func _ready() -> void:
	print("Jugador listo! Usa flechas/WASD para moverte, Espacio para saltar.")


## _physics_process(delta) se ejecuta CADA FRAME (60 veces por segundo)
## delta = tiempo desde el último frame (normalmente ~0.016 segundos)
## Usamos delta para que el movimiento sea igual sin importar los FPS
func _physics_process(delta: float) -> void:

	# --- GRAVEDAD ---
	# Si el personaje está en el aire, aplicamos gravedad
	# is_on_floor() = true cuando está tocando el suelo
	if not is_on_floor():
		velocity.y += gravity * gravity_multiplier * delta

	# --- COYOTE TIME ---
	# Si acaba de salir del suelo (cayó), damos una ventana para saltar
	if is_on_floor():
		coyote_timer = coyote_time  # Recargamos el coyote time al tocar suelo
	else:
		coyote_timer -= delta  # Consumimos el tiempo disponible

	# --- JUMP BUFFER ---
	# Si el jugador presionó saltar, guardamos esa acción por un momento
	if Input.is_action_just_pressed("ui_accept"):  # Espacio o Enter
		jump_buffer_timer = jump_buffer
	else:
		jump_buffer_timer -= delta

	# --- SALTO ---
	# El salto ocurre si: hay buffer de salto activo Y hay coyote time disponible
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force  # Aplicamos la fuerza del salto
		coyote_timer = 0.0        # Consumimos el coyote time
		jump_buffer_timer = 0.0   # Consumimos el buffer

	# --- MOVIMIENTO HORIZONTAL ---
	# Input.get_axis devuelve: -1 (izquierda), 0 (quieto), +1 (derecha)
	var direction: float = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		velocity.x = direction * speed  # Aplicamos velocidad en la dirección
		# Volteamos el sprite según la dirección
		if sprite:
			sprite.flip_h = direction < 0.0  # true = mirando izquierda
	else:
		# Sin input → desaceleración gradual (no frenazo brusco)
		velocity.x = move_toward(velocity.x, 0.0, speed * 0.2)

	# --- APLICAR MOVIMIENTO ---
	# move_and_slide() mueve al personaje y maneja las colisiones automáticamente
	move_and_slide()


# ============================================================
# EXPERIMENTOS SUGERIDOS PARA BRUNO:
#
# 1. Cambia `speed` de 200 a 350 → el personaje se siente más veloz
# 2. Cambia `jump_force` de -450 a -600 → salto más alto
# 3. Cambia `gravity_multiplier` de 2.5 a 1.0 → caída flotante (como Mario)
#    o a 4.0 → caída pesada (como Celeste)
# 4. Intenta agregar un DOBLE SALTO: necesitas una variable `jumps_left: int = 2`
#    y contar cuántos saltos ha dado desde que tocó el suelo
# 5. Agrega animaciones: cuando velocity.x != 0, play("walk"), si no, play("idle")
#
# PRÓXIMA MECÁNICA SUGERIDA: Disparar proyectiles (Bullet scene + instanciar)
# ============================================================
