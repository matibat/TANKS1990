extends Node
## DebugLogger - Centralized logging system with production-safe configuration
## Enable/disable via project settings or environment variable

enum LogLevel {
	NONE = 0,
	ERROR = 1,
	WARN = 2,
	INFO = 3,
	DEBUG = 4,
	TRACE = 5
}

## Configuration
var enabled: bool = false
var log_level: LogLevel = LogLevel.INFO
var log_gameplay: bool = false
var log_physics: bool = false
var log_input: bool = false
var log_spawning: bool = false

func _ready() -> void:
	# Check environment variable first
	if OS.has_environment("DEBUG_LOG"):
		enabled = OS.get_environment("DEBUG_LOG") == "1"
	
	# Check project setting (can be set in editor or per-scene)
	if ProjectSettings.has_setting("debug/log_enabled"):
		enabled = ProjectSettings.get_setting("debug/log_enabled")
	
	# Check individual category settings
	if ProjectSettings.has_setting("debug/log_gameplay"):
		log_gameplay = ProjectSettings.get_setting("debug/log_gameplay")
	if ProjectSettings.has_setting("debug/log_physics"):
		log_physics = ProjectSettings.get_setting("debug/log_physics")
	if ProjectSettings.has_setting("debug/log_input"):
		log_input = ProjectSettings.get_setting("debug/log_input")
	if ProjectSettings.has_setting("debug/log_spawning"):
		log_spawning = ProjectSettings.get_setting("debug/log_spawning")
	
	# Default: enable for debug builds, disable for release
	if not OS.has_environment("DEBUG_LOG") and not ProjectSettings.has_setting("debug/log_enabled"):
		enabled = OS.is_debug_build()
	
	if enabled:
		print("[DebugLogger] Logging enabled (level: %s)" % LogLevel.keys()[log_level])
		print("[DebugLogger] Gameplay: %s | Physics: %s | Input: %s | Spawning: %s" % [log_gameplay, log_physics, log_input, log_spawning])

## Log gameplay events
func gameplay(message: String, data: Dictionary = {}) -> void:
	if enabled and log_gameplay:
		_log("GAMEPLAY", message, data)

## Log physics events
func physics(message: String, data: Dictionary = {}) -> void:
	if enabled and log_physics:
		_log("PHYSICS", message, data)

## Log input events
func input(message: String, data: Dictionary = {}) -> void:
	if enabled and log_input:
		_log("INPUT", message, data)

## Log spawning events
func spawning(message: String, data: Dictionary = {}) -> void:
	if enabled and log_spawning:
		_log("SPAWNING", message, data)

## Log error (always logged if enabled)
func error(message: String, data: Dictionary = {}) -> void:
	if enabled:
		_log("ERROR", message, data)

## Log warning (always logged if enabled)
func warn(message: String, data: Dictionary = {}) -> void:
	if enabled:
		_log("WARN", message, data)

## Log info (always logged if enabled)
func info(message: String, data: Dictionary = {}) -> void:
	if enabled:
		_log("INFO", message, data)

## Log debug (always logged if enabled)
func debug(message: String, data: Dictionary = {}) -> void:
	if enabled and log_level >= LogLevel.DEBUG:
		_log("DEBUG", message, data)

## Internal logging implementation
func _log(category: String, message: String, data: Dictionary) -> void:
	var timestamp = Time.get_ticks_msec()
	var data_str = ""
	if not data.is_empty():
		data_str = " | " + JSON.stringify(data)
	print("[%s ms] [%s] %s%s" % [timestamp, category, message, data_str])
