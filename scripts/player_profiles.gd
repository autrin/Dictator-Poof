extends RefCounted
## Each player has two generations. Only replace the older file after a verified write.
const MAGIC := "DPF1"
const MAX_BYTES := 2 * 1024 * 1024
var directory := "user://profiles"
var entries: Dictionary = {}

func refresh() -> void:
	entries.clear()
	var folder := DirAccess.open(directory)
	if folder == null:
		return
	for file in folder.get_files():
		if file.get_extension() not in ["a", "b"]:
			continue
		var id := file.get_basename()
		var entry := read_entry(directory.path_join(file))
		if not entry.is_empty() and entry.revision > entries.get(id, {}).get("revision", 0):
			entries[id] = entry

func read_entry(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() <= 36 or file.get_length() > MAX_BYTES:
		return {}
	if file.get_buffer(4).get_string_from_ascii() != MAGIC:
		return {}
	var checksum := file.get_buffer(32)
	var payload := file.get_buffer(file.get_length() - 36)
	if digest(payload) != checksum:
		return {}
	var value: Variant = bytes_to_var(payload)
	if not value is Dictionary or value.get("version") != 1 or not value.get("run") is Dictionary:
		return {}
	if not value.get("name") is String or not value.get("revision") is int or not value.get("time") is int:
		return {}
	return value

func digest(bytes: PackedByteArray) -> PackedByteArray:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish()

func sorted_ids() -> Array:
	var ids := entries.keys()
	ids.sort_custom(func(a: String, b: String): return entries[a].time > entries[b].time)
	return ids

func new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func create_name_error(raw_name: String) -> String:
	var name_text := raw_name.strip_edges()
	if name_text.is_empty() or name_text.length() > 32:
		return "profile_name_needed"
	for entry in entries.values():
		if name_text.nocasecmp_to(entry.name) == 0:
			return "profile_name_taken"
	return ""

func write(id: String, display_name: String, run: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	var base := directory.path_join(id)
	var revision: int = entries.get(id, {}).get("revision", 0) + 1
	var target := base + (".a" if revision % 2 == 1 else ".b")
	var old := read_entry(target)
	# Another running copy may already have written this generation.
	if old.get("revision", 0) >= revision:
		return false
	var entry := {"version": 1, "revision": revision, "name": display_name,
		"time": int(Time.get_unix_time_from_system() * 1000000), "run": run}
	var payload := var_to_bytes(entry)
	var temp := target + "." + new_id() + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(MAGIC.to_ascii_buffer())
	file.store_buffer(digest(payload))
	file.store_buffer(payload)
	file.close()
	var verified := read_entry(temp)
	if verified.get("revision", 0) != revision or DirAccess.rename_absolute(temp, target) != OK:
		DirAccess.remove_absolute(temp)
		return false
	entries[id] = verified
	return true
