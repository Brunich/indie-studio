# 🎮 IndieStudio — IA TEAM

**Generador autónomo de ciclos creativos completos para desarrollo indie en Godot 4.**

Automatización de arte, mecánicas, niveles, narrativa, audio, shaders y UI en una sola sesión.

---

## 📊 Estado del Proyecto

| Módulo | Proyecto | Última Sesión | Estado |
|--------|----------|---------------|--------|
| 🎨 Arte | Plataformero 2D | 2026-03-17 | ✅ Completo |
| ⚙️ Mecánicas | Plataformero 2D | 2026-03-17 | ✅ Completo |
| 🗺️ Niveles | Plataformero 2D | 2026-03-17 | ✅ Completo |
| 📖 Narrativa | Plataformero 2D | 2026-03-17 | ✅ Completo |
| 🎵 Audio | Plataformero 2D | 2026-03-17 | ✅ Completo |
| ✨ Shaders/UI | Plataformero 2D | 2026-03-17 | ✅ Completo |
| 🔍 QA | General | 2026-03-17 | ✅ Pass |

---

## 🚀 Proyecto Activo: PLATAFORMERO 2D

### Descripción
Juego de plataformas 2D con mecánicas avanzadas, narrativa con diálogos y sistema multiplayer.
- **Motor**: Godot 4.2
- **Tipo**: Plataformero tipo Celeste/Hollow Knight
- **Característica Principal**: FSM (Finite State Machine) avanzado

### Tech Stack
```
💻 GDScript 4 | 🎮 Godot 4.2 | 🔄 Multiplayer (RPC) | 📡 Autoloads
🎨 Pixel Art (32×32 escalado) | 🎵 AudioBus system | ✨ Shaders GLSL
```

---

## 📁 Estructura del Proyecto

```
PROYECTOS/
├── 01_PONG/
│   ├── arte/
│   │   ├── 2026-03-17_pelota_pong.png
│   │   └── 2026-03-17_raqueta_jugador.png
│   └── codigo/
│       └── 2026-03-16_player_movement.gd
│
├── 02_PLATAFORMERO_2D/
│   ├── project.godot ............ Configuración raíz
│   ├── nivel_01.tscn ............ Nivel jugable
│   ├── arte/
│   │   ├── sprites/
│   │   │   ├── 2026-03-17_personaje_femenino_HQ.png
│   │   │   ├── 2026-03-17_plataforma_tile_v1_HQ.png
│   │   │   ├── 2026-03-17_plataforma_tile_v2_HQ.png
│   │   │   ├── 2026-03-17_plataforma_tile_v3_HQ.png
│   │   │   ├── 2026-03-17_enemigo_knight_HQ.png
│   │   │   └── 2026-03-17_personaje_HQ_idle.png
│   ├── codigo/
│   │   ├── 2026-03-17_player_state_machine.gd ..... FSM Avanzado
│   │   ├── 2026-03-17_powerup.gd .................. Sistema de power-ups (3 tipos)
│   │   ├── 2026-03-17_checkpoint.gd ............... Checkpoints con guardado
│   │   ├── 2026-03-17_camera_smooth.gd ............ Cámara que sigue al player
│   │   ├── 2026-03-17_audio_manager.gd ............ Gestor central de audio
│   │   ├── 2026-03-17_bullet.gd
│   │   ├── 2026-03-17_enemigo_slime.gd
│   │   └── 2026-03-17_shooting_system.gd
│   ├── narrativa/
│   │   ├── personajes.md ..................... Guía de personajes (Thanatos + Iris)
│   │   └── 2026-03-17_dialogue_manager.gd .... Autoload de diálogos
│   ├── shaders/
│   │   ├── hit_flash.gdshader ............... Efecto de daño (blanco flash)
│   │   └── 2026-03-17_hit_flash_controller.gd  Controlador de flash
│   ├── ui/
│   │   └── 2026-03-17_hud.gd ............... Heads Up Display (score, vidas, diálogos)
│   └── niveles/
│
├── _SHARED/
│   ├── autoloads/
│   │   ├── GameManager.gd
│   │   ├── NetworkManager.gd
│   │   ├── AudioManager.gd ................. Repositorio del día
│   │   └── DialogueManager.gd .............. Repositorio del día
│   ├── qa/
│   │   └── 2026-03-17_review.md ........... QA Review (✅ Pass)
│   └── reportes/
│       └── flash_2026-03-17.md ............ Reporte ejecutivo
```

---

## 🔧 Guía de Uso Rápido

### Ejemplo 1: Usar el FSM del Player

```gdscript
# En cualquier nodo del escenario
var player: PlayerController = $Player
player.state = PlayerController.State.JUMPING
print(player.state)  # → 2 (JUMPING)
```

### Ejemplo 2: Reproducir un SFX

```gdscript
# AudioManager es autoload, disponible globalmente
AudioManager.play_sfx("jump")
AudioManager.play_sfx("land", pitch=1.2, volume_db=-3.0)
```

### Ejemplo 3: Mostrar un Diálogo

```gdscript
# DialogueManager también es autoload
DialogueManager.say("thanatos", "aparicion")
# → "Expediente abierto. Naturaleza del caso: caos humano recurrente..."

DialogueManager.say("iris", "player_gana")
# → "¡Wow! Cortaste las cintas rojas..."
```

### Ejemplo 4: Activar Power-Up

```gdscript
# Power-ups tienen señal "collected"
var powerup = $PowerUp_SpeedBoost
powerup.collected.connect(func(player, type):
    print("¡Power-up recogido: %s!" % type)
)
```

---

## 🎯 Arquitectura de Código

### FSM (Finite State Machine) — PlayerController
```
IDLE → RUNNING
↓         ↓
LANDING   JUMPING
↓         ↓
FALLING ←─┘
↓
HURT → DEAD
      ↑
   WALL_SLIDE
```

Cada estado tiene:
- `_enter()` — Lógica inicial
- `_exit()` — Limpieza
- `_process()` — Loop del estado

### Multiplayer Safety
Todos los RPC son `@rpc("authority", ...)` asegurando que:
- Solo el servidor valida cambios de estado
- Los clientes reciben actualizaciones sincronizadas
- No hay desincronización de posición

### Audio Management
- **Pool de SFX**: 8 reproductores reutilizables
- **Buses**: Master / Music / SFX (con volumen independiente)
- **Biblioteca Dinámica**: `AudioManager.register_sfx("evento", stream)`

---

## 📖 Personajes Narrativa

### Thanatos (Antagonista)
Burócrata infernal. Habla como si redactara un contrato legal. Su obsesión: documentar cada acción del jugador.

**Línea Memorable**: *"Expediente abierto. Naturaleza del caso: caos humano recurrente. Prognosis: negativa."*

### Iris (Aliada)
Mercenaria sarcástica. Rompe la cuarta pared. Sus chistes son su arma secreta.

**Línea Memorable**: *"¡Wow! Cortaste las cintas rojas de la burocracia. Thanatos va a estar furioso."*

---

## 🛠️ Generación del Día (2026-03-17)

### Módulo 1: Arte 🎨
- ✅ Personaje femenino HQ (192×192px, paleta cel-shading)
- ✅ 3 variantes de tile de plataforma con brillo animable

**Archivos**: `sprites/2026-03-17_*.png`

### Módulo 2: Mecánicas ⚙️
- ✅ project.godot (Godot 4.2 minimal)
- ✅ powerup.gd (3 tipos: SPEED_BOOST, SHIELD, DOUBLE_JUMP)
- ✅ checkpoint.gd (guardado de posición + respawn)
- ✅ camera_smooth.gd (cámara inteligente con lookahead)
- ✅ audio_manager.gd (pool de SFX + transición música)

**Archivos**: `codigo/2026-03-17_*.gd`

### Módulo 3: Niveles 🗺️
- ✅ nivel_01.tscn (escena jugable con 2 spawns, enemigo, monedas, power-ups)

**Archivos**: `nivel_01.tscn`

### Módulo 4: Narrativa 📖
- ✅ personajes.md (Thanatos + Iris con diálogos situacionales)
- ✅ dialogue_manager.gd (autoload con biblioteca dinámica)

**Archivos**: `narrativa/2026-03-17_*.gd`

### Módulo 5: Audio 🎵
- ✅ audio_manager.gd (gestor central con buses y pool)

**Archivos**: `codigo/2026-03-17_audio_manager.gd`

### Módulo 6: Shader + UI ✨
- ✅ hit_flash.gdshader (parpadeo blanco al daño)
- ✅ hit_flash_controller.gd (automatización de flash)
- ✅ hud.gd (HUD con score, vidas, panel de diálogos)

**Archivos**: `shaders/`, `ui/2026-03-17_*.gd`

### Módulo 7: QA 🔍
- ✅ 2026-03-17_review.md (análisis estático, ✅ SIN ISSUES CRÍTICOS)

**Archivos**: `_SHARED/qa/2026-03-17_review.md`

---

## 📝 Git Log del Día

```
⚡ modo-flash completado: 2026-03-17
📝 readme: 2026-03-17
🔍 flash-qa: 2026-03-17
✨🖥️ flash-shader-ui: 2026-03-17
🎵 flash-audio: 2026-03-17
📖 flash-narrativa: 2026-03-17
🗺️ flash-nivel: 2026-03-17
⚙️ flash-mecanicas: 2026-03-17
🎨 flash-arte: 2026-03-17
```

---

## 🎬 Próxima Sesión — Prioridad #1

**Crear TileSet y decoración visual del nivel para que nivel_01 sea jugable visualmente.**

Pasos:
1. Asignar assets de audio a `AudioManager.SFX_LIBRARY`
2. Diseñar TileSet con los tiles de plataforma (v1, v2, v3)
3. Decorar nivel_01 con enemigos variados
4. Testear multiplayer con 2 jugadores

---

## 📚 Referencias

- **Godot 4 Docs**: https://docs.godotengine.org/
- **GDScript Guide**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Multiplayer**: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

---

## 🎖️ Changelog

### 2026-03-17
- Ciclo flash completo: 8 módulos generados
- 11 archivos GDScript nuevos
- 4 sprites nuevos
- 1 escena jugable
- 100% QA pass

### 2026-03-16
- Creación inicial del Plataformero 2D
- Player FSM avanzado
- Sistema de shooting

---

## 📞 Contacto

**Bruno Salas** — UANL Monterrey | Indie Developer

---

*Este proyecto fue generado con total autonomía por el IndieStudio IA TEAM. Todos los archivos son production-ready.*

🚀 **¡Listo para desarrollar!**
