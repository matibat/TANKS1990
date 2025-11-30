Feature: Tank Movement Blocking
  As a tank
  I want to be blocked from moving when another tank is in my path
  So that tanks cannot occupy the same space

  Scenario: Tank movement blocked by another tank
    Given two tanks are on the battlefield
    And one tank is positioned directly in front of the other
    When the rear tank attempts to move forward
    Then the rear tank should remain in its original position