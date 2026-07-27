class_name SaveData
extends RefCounted

## Minimal local best-score persistence via Godot's ConfigFile, written
## to user:// (backed by IndexedDB in the exported Web build — persists
## across page reloads with no extra setup). Static helpers only, since
## file I/O doesn't need a node in the tree or an autoload.

const SAVE_PATH := "user://retro_route_save.cfg"
const SECTION := "progress"
const KEY_BEST_SCORE := "best_score"


static func load_best_score() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value(SECTION, KEY_BEST_SCORE, 0))


## Saves score as the new best if it beats the current one. Returns
## true if it did (so callers can show a "New Best!" flourish).
static func save_best_score_if_higher(score: int) -> bool:
	if score <= load_best_score():
		return false
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, KEY_BEST_SCORE, score)
	config.save(SAVE_PATH)
	return true
