extends Node

const RUTAS_MUSICA := {
	"menu": "res://recursos/sonidos/musica/menu.ogg",
	"juego": "res://recursos/sonidos/musica/juego.ogg",
	"boss": "res://recursos/sonidos/musica/boss.ogg",
}

const RUTAS_SFX := {
	"paso": "res://recursos/sonidos/sfx/paso.wav",
	"mina": "res://recursos/sonidos/sfx/mina.wav",
	"bandera": "res://recursos/sonidos/sfx/bandera.wav",
	"revelar": "res://recursos/sonidos/sfx/revelar.wav",
	"item": "res://recursos/sonidos/sfx/item.wav",
	"disparo": "res://recursos/sonidos/sfx/disparo.wav",
	"deteccion": "res://recursos/sonidos/sfx/deteccion.wav",
	"victoria": "res://recursos/sonidos/sfx/victoria.wav",
	"derrota": "res://recursos/sonidos/sfx/derrota.wav",
}

const RUTAS_VOZ := {
	"intro_0": "res://recursos/audio/voz/intro_nivel0.ogg",
	"intro_1": "res://recursos/audio/voz/intro_nivel1.ogg",
	"intro_2": "res://recursos/audio/voz/intro_nivel2.ogg",
}

const CANTIDAD_REPRODUCTORES_SFX := 8

var _reproductor_musica: AudioStreamPlayer
var _reproductor_voz: AudioStreamPlayer
var _reproductores_sfx: Array[AudioStreamPlayer] = []
var _indice_sfx := 0
var _musica_actual := ""

func _ready() -> void:
	_reproductor_musica = AudioStreamPlayer.new()
	_reproductor_musica.bus = "Musica"
	add_child(_reproductor_musica)

	_reproductor_voz = AudioStreamPlayer.new()
	_reproductor_voz.bus = "SFX"
	add_child(_reproductor_voz)

	for _i in range(CANTIDAD_REPRODUCTORES_SFX):
		var rep := AudioStreamPlayer.new()
		rep.bus = "SFX"
		add_child(rep)
		_reproductores_sfx.append(rep)

func reproducir_musica(clave: String) -> void:
	if clave == _musica_actual:
		return
	if not RUTAS_MUSICA.has(clave):
		return
	var stream: AudioStream = _cargar(RUTAS_MUSICA[clave])
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_musica_actual = clave
	_reproductor_musica.stream = stream
	_reproductor_musica.play()

func detener_musica() -> void:
	_musica_actual = ""
	_reproductor_musica.stop()

func reproducir_sfx(clave: String) -> void:
	if not RUTAS_SFX.has(clave):
		return
	var stream : AudioStream = _cargar(RUTAS_SFX[clave])
	if stream == null:
		return
	var rep := _reproductores_sfx[_indice_sfx]
	_indice_sfx = (_indice_sfx + 1) % CANTIDAD_REPRODUCTORES_SFX
	rep.stream = stream
	rep.play()

func reproducir_voz(clave: String) -> void:
	if not RUTAS_VOZ.has(clave):
		return
	var stream : AudioStream = _cargar(RUTAS_VOZ[clave])
	if stream == null:
		return
	_reproductor_voz.stream = stream
	_reproductor_voz.play()

func _cargar(ruta: String):
	if not ResourceLoader.exists(ruta):
		return null
	return load(ruta)
