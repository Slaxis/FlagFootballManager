extends Control

const T_TITLE: Dictionary = {"pt": "OPÇÕES", "en": "OPTIONS"}
const T_AUDIO: Dictionary = {"pt": "ÁUDIO", "en": "AUDIO"}
const T_MASTER: Dictionary = {"pt": "Geral", "en": "Master"}
const T_MUSIC: Dictionary = {"pt": "Música", "en": "Music"}
const T_SFX: Dictionary = {"pt": "Efeitos", "en": "SFX"}
const T_LANG: Dictionary = {"pt": "IDIOMA", "en": "LANGUAGE"}
const T_BACK: Dictionary = {"pt": "VOLTAR", "en": "BACK"}
const T_RESET: Dictionary = {"pt": "RESTAURAR PADRÃO", "en": "RESET DEFAULTS"}

@onready var title_label: Label = $Margin/VBox/Title
@onready var audio_label: Label = $Margin/VBox/AudioSection/Header
@onready var master_label: Label = $Margin/VBox/AudioSection/MasterRow/Label
@onready var music_label: Label = $Margin/VBox/AudioSection/MusicRow/Label
@onready var sfx_label: Label = $Margin/VBox/AudioSection/SfxRow/Label
@onready var master_slider: HSlider = $Margin/VBox/AudioSection/MasterRow/Slider
@onready var music_slider: HSlider = $Margin/VBox/AudioSection/MusicRow/Slider
@onready var sfx_slider: HSlider = $Margin/VBox/AudioSection/SfxRow/Slider
@onready var master_value: Label = $Margin/VBox/AudioSection/MasterRow/Value
@onready var music_value: Label = $Margin/VBox/AudioSection/MusicRow/Value
@onready var sfx_value: Label = $Margin/VBox/AudioSection/SfxRow/Value
@onready var lang_label: Label = $Margin/VBox/LangSection/Header
@onready var btn_lang_pt: Button = $Margin/VBox/LangSection/Row/BtnPt
@onready var btn_lang_en: Button = $Margin/VBox/LangSection/Row/BtnEn
@onready var btn_reset: Button = $Margin/VBox/Footer/BtnReset
@onready var btn_back: Button = $Margin/VBox/Footer/BtnBack

var _settings: Dictionary = {}

func _ready() -> void:
	_settings = SaveManager.load_settings()
	_update_text()
	master_slider.value = float(_settings.get("volume_master", 1.0))
	music_slider.value = float(_settings.get("volume_music", 0.8))
	sfx_slider.value = float(_settings.get("volume_sfx", 1.0))
	_refresh_values()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	btn_lang_pt.pressed.connect(func() -> void: _set_lang("pt"))
	btn_lang_en.pressed.connect(func() -> void: _set_lang("en"))
	btn_reset.pressed.connect(_on_reset)
	btn_back.pressed.connect(_on_back)
	for btn: Button in [btn_lang_pt, btn_lang_en, btn_reset, btn_back]:
		btn.pressed.connect(func() -> void: Audio.play_sfx("menu_click"))
	_refresh_lang_buttons()

func _update_text() -> void:
	title_label.text = I18n.text(T_TITLE)
	audio_label.text = I18n.text(T_AUDIO)
	master_label.text = I18n.text(T_MASTER)
	music_label.text = I18n.text(T_MUSIC)
	sfx_label.text = I18n.text(T_SFX)
	lang_label.text = I18n.text(T_LANG)
	btn_reset.text = I18n.text(T_RESET)
	btn_back.text = I18n.text(T_BACK)
	btn_lang_pt.text = "PT"
	btn_lang_en.text = "EN"

func _refresh_values() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value * 100.0))
	music_value.text = "%d%%" % int(round(music_slider.value * 100.0))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value * 100.0))

func _refresh_lang_buttons() -> void:
	btn_lang_pt.disabled = I18n.lang == "pt"
	btn_lang_en.disabled = I18n.lang == "en"

func _on_master_changed(v: float) -> void:
	_settings["volume_master"] = v
	SaveManager.apply_audio_settings(_settings)
	SaveManager.save_settings(_settings)
	_refresh_values()

func _on_music_changed(v: float) -> void:
	_settings["volume_music"] = v
	SaveManager.apply_audio_settings(_settings)
	SaveManager.save_settings(_settings)
	_refresh_values()

func _on_sfx_changed(v: float) -> void:
	_settings["volume_sfx"] = v
	SaveManager.apply_audio_settings(_settings)
	SaveManager.save_settings(_settings)
	_refresh_values()

func _set_lang(new_lang: String) -> void:
	if new_lang == I18n.lang:
		return
	I18n.set_lang(new_lang)
	_settings["lang"] = new_lang
	SaveManager.save_settings(_settings)
	_update_text()
	_refresh_lang_buttons()

func _on_reset() -> void:
	_settings = SaveManager.default_settings()
	I18n.set_lang(String(_settings.get("lang", "pt")))
	SaveManager.apply_audio_settings(_settings)
	SaveManager.save_settings(_settings)
	master_slider.value = float(_settings["volume_master"])
	music_slider.value = float(_settings["volume_music"])
	sfx_slider.value = float(_settings["volume_sfx"])
	_update_text()
	_refresh_values()
	_refresh_lang_buttons()

func _on_back() -> void:
	var scene: PackedScene = The.ui("main_menu")
	if scene:
		The.next_scene(scene)
