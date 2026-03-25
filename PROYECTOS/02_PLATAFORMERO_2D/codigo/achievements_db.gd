## achievements_db.gd
## Database de todos los logros del juego
## Exportar DATA en _ready() o como constante

extends Node

const DATA: Dictionary = {
    # ===== HISTORIA (5 logros) =====
    "primera_excepcion": {
        "nombre": "Primera Excepción",
        "descripcion": "Completa el Nivel 1: Sala de Espera",
        "descripcion_secreta": "El viaje comienza con un paso",
        "icono": "📋",
        "categoria": "historia",
        "secreto": false,
        "puntos": 10,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "thanatos": "Expediente catalogado.",
            "iris": "Bienvenido al archivo."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "level_completed",
            "nivel": "nivel_01"
        }
    },

    "formulario_rechazado": {
        "nombre": "Formulario Rechazado",
        "descripcion": "Completa el Nivel 2: Archivo General B-7",
        "descripcion_secreta": "El Archivador cae, pero el Sistema permanece",
        "icono": "📄",
        "categoria": "historia",
        "secreto": false,
        "puntos": 15,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Lo hiciste. De verdad lo hiciste.",
            "thanatos": "He tomado una decisión."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "level_completed",
            "nivel": "nivel_02"
        }
    },

    "apelacion_denegada": {
        "nombre": "Apelación Denegada",
        "descripcion": "Completa el Nivel 3: Depósitos Remotos",
        "descripcion_secreta": "El Sistema se fisura",
        "icono": "🚫",
        "categoria": "historia",
        "secreto": false,
        "puntos": 20,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Casi estamos ahí.",
            "thanatos": "La libertad es un concepto ilegal."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "level_completed",
            "nivel": "nivel_03"
        }
    },

    "error_en_el_sistema": {
        "nombre": "Error en el Sistema",
        "descripcion": "Completa el Acto 3 y descubre la verdad sobre Thanatos",
        "descripcion_secreta": "Un milenio de obediencia termina",
        "icono": "⚡",
        "categoria": "historia",
        "secreto": false,
        "puntos": 25,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "thanatos": "Por primera vez, elijo.",
            "iris": "Lo sabía. Siempre lo supe."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "thanatos_redemption",
            "nivel": "global"
        }
    },

    "expediente_incompleto": {
        "nombre": "Expediente Incompleto",
        "descripcion": "Alcanza el final del juego",
        "descripcion_secreta": "La verdad que cambia todo",
        "icono": "📑",
        "categoria": "historia",
        "secreto": false,
        "puntos": 50,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Eres el Expediente. Siempre lo fuiste.",
            "sistema": "ANOMALÍA CRÍTICA."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "game_ending",
            "nivel": "global"
        }
    },

    # ===== HABILIDAD (5 logros) =====
    "procesamiento_eficiente": {
        "nombre": "Procesamiento Eficiente",
        "descripcion": "Completa Nivel 1 en menos de 90 segundos",
        "descripcion_secreta": "La velocidad es su propia forma de resistencia",
        "icono": "⚡",
        "categoria": "habilidad",
        "secreto": false,
        "puntos": 15,
        "recompensa": {"tipo": "skin", "valor": "velocidad_blur"},
        "frase_unlock": {
            "thanatos": "Expedición acelerada.",
            "iris": "Parece que tienes prisa."
        },
        "trigger": {
            "tipo": "tiempo",
            "evento": "level_completed",
            "nivel": "nivel_01",
            "valor": 90,
            "exacto": false
        }
    },

    "sin_excepciones": {
        "nombre": "Sin Excepciones",
        "descripcion": "Completa un nivel sin morir",
        "descripcion_secreta": "Perfección momentánea",
        "icono": "💎",
        "categoria": "habilidad",
        "secreto": false,
        "puntos": 25,
        "recompensa": {"tipo": "cosmetic", "valor": "halo_oro"},
        "frase_unlock": {
            "thanatos": "Expediente limpio. Impresionante.",
            "iris": "¿Cómo lo hiciste?"
        },
        "trigger": {
            "tipo": "contador",
            "evento": "deaths_in_level",
            "valor": 0,
            "exacto": true
        }
    },

    "on_beat": {
        "nombre": "En el Ritmo",
        "descripcion": "Mata 10 enemigos sincronizados con el beat",
        "descripcion_secreta": "La burocracia tiene su propia música",
        "icono": "♪",
        "categoria": "habilidad",
        "secreto": false,
        "puntos": 20,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "¿Lo escuchas? El pulso del Sistema.",
            "thanatos": "Sincronización detectada."
        },
        "trigger": {
            "tipo": "contador",
            "evento": "on_beat_kills",
            "valor": 10,
            "exacto": false
        }
    },

    "salto_de_fe": {
        "nombre": "Salto de Fe",
        "descripcion": "Completa 3 wall jumps consecutivos",
        "descripcion_secreta": "A veces solo tienes que creer",
        "icono": "🌙",
        "categoria": "habilidad",
        "secreto": false,
        "puntos": 15,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Supongo que tienes más control del que pensé.",
            "thanatos": "Salto registrado."
        },
        "trigger": {
            "tipo": "contador",
            "evento": "consecutive_wall_jumps",
            "valor": 3,
            "exacto": false
        }
    },

    "combo_burocrático": {
        "nombre": "Combo Burocrático",
        "descripcion": "Mata 5 enemigos sin recibir daño",
        "descripcion_secreta": "La venganza administrativa",
        "icono": "⚔️",
        "categoria": "habilidad",
        "secreto": false,
        "puntos": 20,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "thanatos": "Defensa perfecta. Anómalo.",
            "iris": "Prácticamente eres parte del Sistema ya."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "combo_achieved",
            "valor": 5
        }
    },

    # ===== SECRETOS - YAKUZA STYLE (8 logros) =====
    "burocracia_total": {
        "nombre": "Burocracia Total",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Muere exactamente 7 veces en Nivel 1",
        "icono": "☠️",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 30,
        "recompensa": {"tipo": "skin", "valor": "error_404"},
        "frase_unlock": {
            "sistema": "PATRÓN INUSUAL DETECTADO.",
            "iris": "El número 7. Siempre el 7."
        },
        "trigger": {
            "tipo": "contador",
            "evento": "deaths_nivel_01",
            "valor": 7,
            "exacto": true
        }
    },

    "formulario_404": {
        "nombre": "Formulario 404",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Encuentra el área oculta en Nivel 2",
        "icono": "🔍",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 25,
        "recompensa": {"tipo": "skin", "valor": "invisible"},
        "frase_unlock": {
            "iris": "Nunca pensé que lo encontrarías.",
            "thanatos": "Eso no debería existir."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "secret_area_found",
            "nivel": "nivel_02"
        }
    },

    "multitarea_cuantica": {
        "nombre": "Multitarea Cuántica",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "En co-op, ambos saltan exactamente al mismo tiempo",
        "icono": "↔️",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 35,
        "recompensa": {"tipo": "cosmetic", "valor": "sync_effect"},
        "frase_unlock": {
            "iris": "¿Cómo sincronizaron eso?",
            "thanatos": "Entrelazamiento cuántico registrado."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "coop_sync_jump",
            "tolerancia": 0.1
        }
    },

    "el_metodo_thanatos": {
        "nombre": "El Método Thanatos",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Completa un nivel sin disparar nunca",
        "icono": "🤐",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 40,
        "recompensa": {"tipo": "skin", "valor": "pacifista"},
        "frase_unlock": {
            "thanatos": "No usaste violencia. Interesante.",
            "iris": "¿Quién eres realmente?"
        },
        "trigger": {
            "tipo": "contador",
            "evento": "shots_fired",
            "valor": 0,
            "exacto": true,
            "nivel": "any"
        }
    },

    "existencia_cuestionable": {
        "nombre": "Existencia Cuestionable",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Permanece quieto 60 segundos sin input",
        "icono": "👤",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 20,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "¿Sigues ahí?",
            "sistema": "ENTIDAD EN SUSPENSIÓN."
        },
        "trigger": {
            "tipo": "tiempo",
            "evento": "idle_time",
            "valor": 60,
            "exacto": false
        }
    },

    "iris_tiene_razon": {
        "nombre": "Iris Tiene Razón",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Muere cuando faltaba 1 enemigo para ganar",
        "icono": "🎭",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 15,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Te lo dije.",
            "thanatos": "Fallo por milisegundos."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "death_with_one_enemy_left",
            "nivel": "any"
        }
    },

    "protocolo_7b": {
        "nombre": "Protocolo 7B",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Easter egg oculto en Nivel 1",
        "icono": "🔐",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 50,
        "recompensa": {"tipo": "skin", "valor": "retro_16bit"},
        "frase_unlock": {
            "sistema": "CÓDIGO LEGACY EJECUTADO.",
            "iris": "¿De dónde salió eso?"
        },
        "trigger": {
            "tipo": "evento",
            "evento": "easter_egg_protocol_7b",
            "nivel": "nivel_01"
        }
    },

    "glitch_en_el_sistema": {
        "nombre": "Glitch en el Sistema",
        "descripcion": "[SECRETO]",
        "descripcion_secreta": "Muere y mata a un enemigo en el mismo frame",
        "icono": "📺",
        "categoria": "secreto",
        "secreto": true,
        "puntos": 45,
        "recompensa": {"tipo": "skin", "valor": "glitch_scanlines"},
        "frase_unlock": {
            "sistema": "INCONSISTENCIA LÓGICA DETECTADA.",
            "thanatos": "Eso es... imposible."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "simultaneous_death_and_kill",
            "tolerancia": 1
        }
    },

    # ===== CO-OP (4 logros) =====
    "companeros_de_papeleo": {
        "nombre": "Compañeros de Papeleo",
        "descripcion": "Completa un nivel en co-op",
        "descripcion_secreta": "Dos voluntarios para el Registro",
        "icono": "👥",
        "categoria": "coop",
        "secreto": false,
        "puntos": 15,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Dos en lugar de uno. Doble riesgo.",
            "thanatos": "Duplicación de excepciones registrada."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "coop_level_completed",
            "players": 2
        }
    },

    "muerte_sincronizada": {
        "nombre": "Muerte Sincronizada",
        "descripcion": "En co-op, ambos mueren al mismo tiempo",
        "descripcion_secreta": "Hasta en la muerte, juntos",
        "icono": "☠️☠️",
        "categoria": "coop",
        "secreto": false,
        "puntos": 20,
        "recompensa": {"tipo": "cosmetic", "valor": "sync_particles"},
        "frase_unlock": {
            "iris": "Qué par.",
            "thanatos": "Sincronización de defunción."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "coop_simultaneous_death",
            "tolerancia": 0.5
        }
    },

    "pareja_de_hecho": {
        "nombre": "Pareja de Hecho",
        "descripcion": "Completa 3 niveles en co-op",
        "descripcion_secreta": "El Sistema no previó esto",
        "icono": "💍",
        "categoria": "coop",
        "secreto": false,
        "puntos": 30,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Se están volviendo como uno solo.",
            "thanatos": "Unidad detectada."
        },
        "trigger": {
            "tipo": "contador",
            "evento": "coop_levels_completed",
            "valor": 3,
            "exacto": false
        }
    },

    "quien_necesita_al_otro": {
        "nombre": "¿Quién Necesita al Otro?",
        "descripcion": "Uno de ustedes muere 5 veces mientras el otro no muere",
        "descripcion_secreta": "Asimetría perfecta",
        "icono": "⚖️",
        "categoria": "coop",
        "secreto": false,
        "puntos": 25,
        "recompensa": {"tipo": "none"},
        "frase_unlock": {
            "iris": "Uno lleva al otro.",
            "thanatos": "Dependencia registrada."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "coop_imbalance_achievement",
            "deaths_p1": 5,
            "deaths_p2": 0
        }
    },

    # ===== COSMÉTICOS (3 logros) =====
    "arqueólogo_digital": {
        "nombre": "Arqueólogo Digital",
        "descripcion": "Encuentra todos los sprites legacy de 16x16",
        "descripcion_secreta": "El pasado pixelado del Registro",
        "icono": "🔲",
        "categoria": "cosmetico",
        "secreto": false,
        "puntos": 35,
        "recompensa": {"tipo": "skin", "valor": "retro_16bit"},
        "frase_unlock": {
            "iris": "Esos son... antiguos. Muy antiguos.",
            "sistema": "ARCHIVOS LEGACY RECUPERADOS."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "all_legacy_sprites_found",
            "cantidad": 8
        }
    },

    "aprobado_por_el_sistema": {
        "nombre": "Aprobado por el Sistema",
        "descripcion": "Desbloquea todos los logros de Historia",
        "descripcion_secreta": "El sello de la burocracia",
        "icono": "✓",
        "categoria": "cosmetico",
        "secreto": false,
        "puntos": 100,
        "recompensa": {"tipo": "hud_element", "valor": "sello_dorado"},
        "frase_unlock": {
            "sistema": "EXPEDIENTE COMPLETADO.",
            "thanatos": "Perfección registrada."
        },
        "trigger": {
            "tipo": "evento",
            "evento": "all_story_achievements",
            "logros": ["primera_excepcion", "formulario_rechazado", "apelacion_denegada", "error_en_el_sistema", "expediente_incompleto"]
        }
    },

    "error_404_skin": {
        "nombre": "Error 404: Jugador no encontrado",
        "descripcion": "Desbloquea el skin de glitch",
        "descripcion_secreta": "La interfaz se corrompe",
        "icono": "💻",
        "categoria": "cosmetico",
        "secreto": false,
        "puntos": 40,
        "recompensa": {"tipo": "skin", "valor": "error_404_glitch"},
        "frase_unlock": {
            "sistema": "ERROR DE PRESENTACIÓN.",
            "iris": "Acabas de... desaparecer?"
        },
        "trigger": {
            "tipo": "evento",
            "evento": "all_secret_achievements",
            "minimo": 5
        }
    }
}

func _ready() -> void:
    # Validar que DATA está correctamente formado
    for achievement_id in DATA.keys():
        var achievement = DATA[achievement_id]
        if not achievement.has("nombre") or not achievement.has("categoria"):
            push_error("Achievement '%s' está mal formado" % achievement_id)
