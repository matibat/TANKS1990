Feature: Power-Up Terrain Integration
  As a player
  I want the Shovel power-up to fortify the base correctly
  So that the base is protected from enemy fire temporarily

  Background:
    Given a game scene with TerrainManager
    And the TerrainManager is in the "terrain_manager" group
    And a player tank in the scene

  Scenario: TerrainManager is findable by power-ups
    Given a Shovel power-up in the scene
    When the power-up searches for TerrainManager
    Then it should find the TerrainManager by group
    And the TerrainManager should be the correct instance

  Scenario: Shovel power-up fortifies base with steel
    Given brick tiles around the base position (13, 25)
    And a Shovel power-up collected by the player
    When the Shovel effect is applied
    Then the tiles around (13, 25) should be changed to steel
    And there should be a 3x3 fortified area

  Scenario: Fortified tiles revert after timeout
    Given brick tiles around the base
    And a Shovel power-up with 100ms fortification time
    When the Shovel effect is applied
    Then the tiles should be steel immediately
    And after 150ms the tiles should revert to brick

  Scenario: Shovel power-up handles missing TerrainManager gracefully
    Given no TerrainManager in the scene
    And a Shovel power-up collected by the player
    When the Shovel effect is applied
    Then the game should not crash
    And a warning should be logged

  Scenario: All power-ups check properties with 'in' operator
    Given the power-up source files:
      | star_power_up.gd   |
      | tank_power_up.gd   |
      | clock_power_up.gd  |
      | helmet_power_up.gd |
    When checking property existence in apply_effect methods
    Then all should use "property" in object syntax
    And none should use object.has("property") syntax

  Scenario: TerrainManager methods are correctly named
    Given a TerrainManager with tiles set
    When getting a tile at coordinates (13, 24)
    Then the method "get_tile_at_coords(x, y)" should work
    And the method should return the correct TileType enum value
