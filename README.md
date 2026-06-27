<div align="center">

# 🎖️ DARKFIELD

### Sigilo y campo minado tras líneas enemigas

*Un buscaminas no debería darte tanto miedo.*

![Godot](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-355570?logo=godotengine&logoColor=white)
![Plataforma](https://img.shields.io/badge/Plataforma-PC-lightgrey)
![Estado](https://img.shields.io/badge/Estado-Jugable-success)
![Licencia](https://img.shields.io/badge/Proyecto-Académico-orange)

</div>

---

## 📖 Sobre el juego

**Darkfield** es un juego de **sigilo y estrategia para un jugador** que fusiona la mecánica deductiva del **buscaminas clásico** con la tensión de la **evasión en tiempo real**.

No tienes tiempo para pensar tranquilo cada casilla: mientras despejas el campo minado celda por celda, patrullas enemigas barren el terreno con sus linternas. Un paso en falso revela una mina; un paso descuidado te mete en el cono de visión de un cazador. Cada nivel es una negociación constante entre **avanzar** y **esconderse**.

La campaña te lleva a través de territorio hostil hasta el enfrentamiento final contra el **General Karimi**, un comandante enemigo capaz de invocar refuerzos y bombardearte desde la distancia.

---

## 🪖 La historia

> Estás solo, tras las líneas enemigas.
>
> El terreno que te separa del punto de extracción está sembrado de minas y vigilado por patrullas. Tu misión es simple de enunciar y brutal de ejecutar: **limpia el camino, mantente invisible y llega al helicóptero.**
>
> Pero el enemigo sabe que estás ahí. Y su general no piensa dejarte ir.

Tres niveles de dificultad creciente narran el avance del soldado: desde la emboscada inicial, pasando por la zona de guerra abierta, hasta el último bastión donde espera el jefe final.

---

## ✨ Características principales

- 🗺️ **Mapas procedurales** — cada partida genera un campo distinto mediante autómatas celulares. Nunca juegas el mismo nivel dos veces.
- 🧠 **IA enemiga con estados** — los cazadores patrullan, sospechan, persiguen, investigan y regresan. No son obstáculos estáticos: reaccionan a ti.
- 👁️ **Detección por cono de visión** — los enemigos te ven solo si estás dentro de su ángulo, a su alcance y sin paredes de por medio. El sigilo importa.
- 🎒 **Inventario e items** — seis tipos de objetos con efectos únicos que se acumulan entre niveles.
- 💀 **Jefe final con fases** — el General Karimi cambia de comportamiento según su vida, lanza granadas en arco e invoca soldados de apoyo.
- 🌫️ **Niebla de guerra** — solo ves lo que has descubierto. La información es un recurso.
- 🔊 **Audio ambiental** — música distinta por escena y efectos para cada acción.
- ⚙️ **Opciones persistentes** — volumen, brillo y pantalla completa que se recuerdan entre sesiones.
- 💾 **Progreso guardado** — el modo historia recuerda tu avance y tu inventario.

---

## 🎮 Modos de juego

### Modo Historia
La campaña principal. Tres niveles encadenados con dificultad progresiva, desbloqueo por avance y un inventario que persiste de un nivel al siguiente. Lo que recoges en el nivel 1 puede salvarte la vida frente al jefe en el nivel 3.

| Nivel | Nombre | Tamaño | Minas | Enemigos | Novedad |
|:-----:|--------|:------:|:-----:|:--------:|---------|
| 1 | La Emboscada | 15×15 | 10 | 1 | Introducción al sigilo |
| 2 | Zona de Guerra | 21×21 | 25 | 3 | Campo abierto, más patrullas |
| 3 | El Último Bastión | 31×31 | 39 | 5 → **Jefe** | Combate final |

### Partida Rápida
Para jugar niveles sueltos sin narrativa ni progresión, ideal para practicar la mecánica.

---

## 🎒 Items

Los objetos se encuentran dentro de los mapas y también se otorgan al completar niveles. Se acumulan en el inventario y persisten a lo largo de la campaña.

| Item | Efecto |
|------|--------|
| 📡 **Radar** | Revela temporalmente las minas cercanas en un radio. |
| ⚡ **Boost** | Duplica la velocidad de movimiento por unos segundos. |
| ❄️ **Congelado** | Paraliza a todos los cazadores durante un breve lapso. |
| 🛡️ **Escudo** | Absorbe el siguiente golpe que recibirías. |
| 🔫 **Pistola** | Munición para dañar al jefe final. |
| 💥 **Bazuka** | Disparo único de daño masivo contra el jefe. |

---

## 🕹️ Controles

| Tecla | Acción |
|:-----:|--------|
| **↑ ↓ → ←** | Mover al soldado |
| **Espacio** | Revelar casilla |
| **F** | Colocar / quitar bandera |
| **Tab** | Cambiar item activo |
| **E** | Usar item activo |
| **Esc** | Pausa |

Durante la fase del jefe, el soldado dispara en la dirección que mira usando la pistola o la bazuka del inventario.

---

## 🏗️ Arquitectura

El proyecto está construido sobre una **separación estricta entre lógica y presentación**. Las clases de lógica pura (mapa, tablero, generación procedural) heredan de `RefCounted` y no dependen de ningún nodo visual, lo que las hace testeables y reutilizables. La capa de presentación (escenas, actores, HUD) consume esa lógica.

Dos **singletons (autoloads)** actúan como fuente de verdad global:

- **`GameManager`** — centraliza el estado del juego, la configuración de niveles, el inventario y la persistencia.
- **`GestorAudio`** — gestiona música y efectos de sonido con buses separados.

### Estructura de carpetas

```
Darkfield/
├── autoload/             # Singletons globales
│   ├── game_manager.gd   #   Estado, niveles, inventario, guardado
│   └── gestor_audio.gd   #   Música y efectos de sonido
│
├── actors/               # Entidades del juego (lógica + escena)
│   ├── jugador.gd/.tscn   #   El soldado controlado por el jugador
│   ├── cazador.gd/.tscn   #   Enemigo con IA de estados
│   ├── boss.gd/.tscn      #   General Karimi, jefe final
│   └── proyectil.gd/.tscn #   Granadas del jefe
│
├── scenes/               # Pantallas y flujo del juego
│   ├── menu.gd            #   Menú principal
│   ├── juego.gd           #   Escena de juego (orquesta todo)
│   ├── historia.gd        #   Selección de niveles
│   ├── opciones.gd        #   Configuración
│   ├── pausa.gd           #   Menú de pausa
│   └── camara_juego.gd    #   Cámara que sigue al jugador
│
├── scripts/logica/       # Lógica pura, sin dependencia gráfica
│   ├── mapa.gd            #   Representación del mapa y paredes
│   ├── tablero.gd         #   Lógica del buscaminas
│   ├── generador_dungeon.gd  # Generación procedural
│   └── item_mapa.gd       #   Items recogibles
│
└── recursos/             # Assets
    ├── sprites/
    ├── tilesets/
    ├── sonidos/
    └── fuentes/
```

### Patrones de diseño

- **Singleton** — `GameManager` y `GestorAudio` como instancias únicas globales.
- **Máquina de estados finita** — gobierna la IA de cazadores (5 estados) y las fases del jefe.
- **Observador (signals)** — la comunicación entre sistemas usa señales de Godot, desacoplando emisor y receptor.
- **Separación lógica/presentación** — las clases de lógica se comunican mediante datos puros, sin conocer la capa gráfica.

---

## 🧮 Algoritmos destacados

### Generación procedural de mapas — Autómata celular
Cada mapa nace de ruido aleatorio que se suaviza en varios pasos: una celda se vuelve pared si tiene muchos vecinos pared, y suelo si tiene pocos. El resultado son cavernas orgánicas en lugar de cuadrículas rígidas. Una zona segura garantizada alrededor del spawn evita que el jugador aparezca encerrado.

### Conectividad — Flood Fill (BFS)
Tras generar el mapa, una búsqueda en anchura desde el inicio marca todas las celdas alcanzables. Lo que no se alcanza se convierte en pared, garantizando que **el 100% del espacio jugable esté conectado**.

### Revelado en cascada — Flood Fill cardinal
Al descubrir una celda sin minas adyacentes, el revelado se propaga en las cuatro direcciones cardinales mediante una cola iterativa (no recursión, para evitar desbordamiento de pila en mapas grandes). Las paredes actúan como barreras reales del revelado.

### IA de enemigos — Máquina de estados + BFS + cono de visión
Cada cazador alterna entre cinco estados según lo que percibe. La detección combina **distancia, ángulo y línea de visión** (verificada con raycast). La persecución usa pathfinding por BFS, óptimo en una grilla sin pesos. Un sistema de reservas evita que los enemigos se amontonen.

### Jefe final — Fases + proyectiles en arco
El General Karimi reutiliza el pathfinding de los cazadores y añade una máquina de dos fases según su vida. Sus granadas describen una parábola calculada interpolando la posición y sumando un desplazamiento vertical con una función seno.

---

## 🎨 Elementos de infografía

- **Renderizado por capas** — el mundo se compone de varios `TileMapLayer` superpuestos (suelo, paredes, celdas reveladas).
- **Iluminación 2D** — cada cazador porta una luz dinámica; un `CanvasModulate` global crea la atmósfera nocturna.
- **Shaders** — el fondo de los menús usa un shader procedural animado que simula una tormenta de arena.
- **Dibujo vectorial dinámico** — el cono de visión se dibuja en tiempo real con `_draw()`, cambiando de color según el estado de alerta del enemigo.
- **Niebla de guerra** — las celdas no reveladas se cubren con un velo semitransparente que se retira al descubrirlas.

---

## 🚀 Cómo ejecutar

1. Instala **[Godot 4.6](https://godotengine.org/download)** o superior.
2. Clona el repositorio:
   ```bash
   git clone https://github.com/MayraSRS04/Darkfield.git
   ```
3. Abre Godot, pulsa **Importar** y selecciona el archivo `project.godot`.
4. Pulsa **Ejecutar** (`F5`). La escena principal es el menú.

---

## 🛠️ Tecnologías

| | |
|---|---|
| **Motor** | Godot 4.6 |
| **Lenguaje** | GDScript |
| **Sprites** | Kenney — Top-Down Shooter pack |
| **Renderizado** | Forward+ |

---

## 👥 Autores

**Paul Timothy Kuno Serrano** · Código 78533
**Mayra Suzeth Rosas Saavedra** · Código 77944

---

<div align="center">

Proyecto final de la materia **Infografía**
Universidad Privada Boliviana · 2026

</div>
