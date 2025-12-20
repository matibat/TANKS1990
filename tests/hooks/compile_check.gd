extends SceneTree
## Compile Check Script - Validates all GDScript files can be parsed and compiled
## Used by Makefile's check-compile target for early-fail detection

const SCRIPT_DIRS = [
	"res://src/",
	"res://scenes3d/",
	"res://tests/",
]

const EXCLUDED_DIRS = [
	"res://.gut/", # GUT framework's own tests
	"res://addons/gut/test/", # GUT framework test directory
]

func _init():
	print("Checking GDScript compilation...")
	var has_errors = false
	var checked_count = 0
	
	for dir_path in SCRIPT_DIRS:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
			
		var scripts = _find_gdscript_files(dir_path)
		for script_path in scripts:
			checked_count += 1
			if not _check_script(script_path):
				has_errors = true
	
	if has_errors:
		print("\n❌ Compilation check failed - fix errors above")
		quit(1)
	else:
		print("✅ Checked %d scripts - all compiled successfully" % checked_count)
		quit(0)

func _find_gdscript_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	
	# Check if this directory should be excluded
	for excluded in EXCLUDED_DIRS:
		if dir_path.begins_with(excluded):
			return files
	
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				files.append_array(_find_gdscript_files(full_path))
		elif file_name.ends_with(".gd"):
			files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

func _check_script(script_path: String) -> bool:
	# Try to load the script - this will trigger parse/compile errors
	var script = load(script_path)
	
	if script == null:
		push_error("Failed to load script: %s" % script_path)
		return false
	
	# Additional validation: check if it's actually a GDScript
	if not script is GDScript:
		push_error("Not a valid GDScript: %s" % script_path)
		return false
	
	return true
