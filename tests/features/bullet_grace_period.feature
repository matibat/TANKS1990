Feature: Bullet Grace Period
  As a player
  I want bullets to not collide with the tank that fired them
  So that bullets don't freeze immediately after being fired

  Background:
    Given a game scene with tanks and bullets
    And a player tank at position (100, 100)

  Scenario: Bullet initialized with grace period
    When a bullet is fired from the player tank
    Then the bullet should have an active grace timer
    And the grace timer should be 100 milliseconds

  Scenario: Bullet ignores owner during grace period
    Given a bullet fired from the player tank
    And the grace period is still active
    When the bullet collides with the player tank
    Then the collision should be ignored
    And the player tank should not take damage

  Scenario: Bullet damages owner after grace period expires
    Given a bullet fired from the player tank
    And the grace period has expired
    When the bullet physics collides with owner tank position
    Then the bullet should be able to register the collision
    # Note: In practice bullets move away, but logic allows it

  Scenario: Bullet damages other tanks during grace period
    Given a bullet fired from the player tank
    And the grace period is still active
    And an enemy tank at position (100, 80)
    When the bullet collides with the enemy tank
    Then the collision should be processed
    And the enemy tank should take damage

  Scenario: Bullet moves away from owner during grace period
    Given a bullet fired from the player tank upward
    And the grace period is 100 milliseconds
    When 2 physics frames pass
    Then the bullet should have moved away from the player tank
    And the bullet should not be at the player tank position

  Scenario: Grace timer decreases over time
    Given a bullet fired from the player tank
    And the grace timer is 100 milliseconds
    When 3 physics frames pass
    Then the grace timer should be less than 100 milliseconds
    And the grace timer should be greater than or equal to 0
