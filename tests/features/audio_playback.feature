Feature: Audio Playback on Game Events
  As a game
  I want to play appropriate sounds when events occur
  So that players get audio feedback for game actions

  Scenario: Player tank movement plays move sound
    Given the game is running
    And the player tank exists
    When the player tank moves
    Then the tank move sound should play

  Scenario: Enemy tank movement plays move sound
    Given the game is running
    And an enemy tank exists
    When the enemy tank moves
    Then the enemy tank move sound should play

  Scenario: Tank firing plays shoot sound
    Given the game is running
    And the player tank exists
    When the player tank fires a bullet
    Then the tank shoot sound should play

  Scenario: Tank explosion plays explosion sound
    Given the game is running
    And a tank exists
    When the tank is destroyed
    Then the tank explosion sound should play

  Scenario: Bullet hitting tank plays hit sound
    Given the game is running
    And a bullet exists
    When the bullet hits a tank
    Then the bullet hit sound should play

  Scenario: Stage completion plays completion sound
    Given the game is running
    When the stage is completed
    Then the stage complete sound should play

  Scenario: Game over plays game over sound
    Given the game is running
    When the game ends
    Then the game over sound should play