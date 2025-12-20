extends CSGBox3D
## TerrainTile3D - Visual representation of a terrain cell in 3D

enum CellType {
	BRICK = 0,
	STEEL = 1,
	WATER = 2,
	TREES = 3,
	ICE = 4,
	BASE = 5
}

var cell_type: int = CellType.BRICK

func _ready() -> void:
	_setup_visual()

func _setup_visual() -> void:
	# Set size to 1x1 (same as tile size)
	size = Vector3(1.0, 0.5, 1.0)
	
	# Set color based on cell type
	var material = StandardMaterial3D.new()
	
	match cell_type:
		CellType.BRICK:
			material.albedo_color = Color(0.6, 0.3, 0.1) # Brown
		CellType.STEEL:
			material.albedo_color = Color(0.5, 0.5, 0.5) # Gray
		CellType.WATER:
			material.albedo_color = Color(0.1, 0.3, 0.8) # Blue
		CellType.TREES:
			material.albedo_color = Color(0.1, 0.5, 0.1) # Dark Green
		CellType.ICE:
			material.albedo_color = Color(0.7, 0.9, 1.0) # Light Blue
		CellType.BASE:
			material.albedo_color = Color(0.9, 0.8, 0.1) # Yellow
		_:
			material.albedo_color = Color(0.6, 0.3, 0.1)
	
	self.material = material
