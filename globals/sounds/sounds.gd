extends Node

var sounds: Dictionary[String, AudioStreamPlayer] = {}
var music: Dictionary[String, AudioStreamPlayer] = {}

var current_song := ""
var _pending_song := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Устанавливаем громкость шины "Master" на 10%
	# Формула перевода линейной громкости (0.1) в децибелы: 20 * log10(0.1) ≈ -20 dB
	var master_bus_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(0.1))
	
	_load_sounds_from_directory("res://globals/sounds/sound_effects", sounds, "SFX")
	_load_sounds_from_directory("res://globals/sounds/music", music, "Music")

func _load_sounds_from_directory(dir_path: String, target_dict: Dictionary, bus_name: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Directory not found: ", dir_path)
		return
	
	var dir := DirAccess.open(dir_path)
	if dir == null:
		print("Failed to open directory: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue

		# ГЛАВНОЕ ИСПРАВЛЕНИЕ:
		# В экспортированном билде файлы называются "track.mp3.remap" или "track.mp3.import"
		# Убираем эти расширения, чтобы получить путь к реальному ресурсу
		var clean_file_name := file_name.replace(".remap", "").replace(".import", "")
		var ext := clean_file_name.get_extension().to_lower()
		
		if ext in ["ogg", "wav", "mp3", "flac"]:
			var base_name := clean_file_name.trim_suffix("." + ext)
			
			# Проверяем, не загрузили ли мы этот файл уже (чтобы не дублировать .mp3 и .mp3.import)
			if not target_dict.has(base_name):
				var full_path := dir_path + "/" + clean_file_name
				var audio_player := AudioStreamPlayer.new()
				audio_player.name = base_name
				
				# load() в Godot достаточно умен, чтобы найти ресурс по оригинальному пути,
				# даже если в реальности он переименован в .remap
				var stream = load(full_path)
				if stream:
					audio_player.stream = stream
					audio_player.bus = bus_name
					add_child(audio_player)
					target_dict[base_name] = audio_player
				else:
					print("Failed to load stream: ", full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
func get_files_recursive(p_directory: String) -> PackedStringArray:
	var files := PackedStringArray()
	
	if not DirAccess.dir_exists_absolute(p_directory):
		return files
	
	var dir := DirAccess.open(p_directory)
	if dir == null:
		return files
	
	dir.list_dir_begin()
	var item := dir.get_next()
	
	while item != "":
		var full_path := p_directory + "/" + item
		
		if dir.current_is_dir():
			files.append_array(get_files_recursive(full_path))
		else:
			var ext := item.get_extension().to_lower()
			if ext in ["ogg", "wav", "mp3", "flac"]:
				files.append(full_path)
		
		item = dir.get_next()
	
	dir.list_dir_end()
	return files

func play(p_sound: String, p_volume := 1.0) -> void:
	if not sounds.has(p_sound):
		return
	var audio_player := sounds[p_sound]
	audio_player.volume_linear = p_volume
	audio_player.play()

func set_music(p_music: String, p_volume := 1.0, p_loop := true) -> void:
	if p_music == current_song:
		return
	if not music.has(p_music):
		printerr("Error in sounds.gd: Attempt to play song, \"" + p_music + "\", but no such song exists.")
		return
	if current_song != "":
		music[current_song].stop()
	var audio_player := music[p_music]
	var stream := audio_player.stream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if p_loop else AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		stream.loop = p_loop
	audio_player.volume_linear = p_volume
	audio_player.play()
	current_song = p_music

func stop_music() -> void:
	if current_song != "" and music.has(current_song):
		music[current_song].stop()
	current_song = ""

func fade_out_current(duration: float = 1.2) -> void:
	if current_song == "":
		return
	
	var player = music[current_song]
	var tween = create_tween()
	tween.tween_property(player, "volume_linear", 0.0, duration)
	await tween.finished
	player.stop()
	current_song = ""

func fanfare(fanfare_name: String = "fanfare", return_volume: float = 1.0) -> void:
	_pending_song = current_song
	await fade_out_current()
	play(fanfare_name)
	await get_tree().create_timer(13.0).timeout
	if _pending_song != "":
		set_music(_pending_song, return_volume)
		_pending_song = ""

func fanfare_and_return(fanfare_name: String = "fanfare", return_delay: float = 2.0, return_volume: float = 1.0) -> void:
	_pending_song = current_song
	fade_out_current()
	play(fanfare_name)
	
	var timer := get_tree().create_timer(return_delay)
	timer.timeout.connect(func():
		if _pending_song != "":
			set_music(_pending_song, return_volume)
			_pending_song = ""
	)

func get_sound_duration(sound_name: String) -> float:
	if sounds.has(sound_name) and sounds[sound_name].stream:
		return sounds[sound_name].stream.get_length()
	return 0.0

func fanfare_precise(fanfare_name: String = "fanfare", return_volume: float = 1.0) -> void:
	_pending_song = current_song
	await fade_out_current()
	
	var duration := get_sound_duration(fanfare_name)
	play(fanfare_name)
	
	await get_tree().create_timer(duration).timeout
	
	if _pending_song != "":
		set_music(_pending_song, return_volume)
		_pending_song = ""
