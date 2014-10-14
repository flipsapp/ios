Feature: Album Screen
  As a user
  I want to see the photos on my device divided in subfolders
  So I can select one photo easiest

@7174 @7454
Scenario: Accessing Choose Photo screen
  Given I am on the "<screen>" screen
  When I touch "Photo" icon
  Then Album screen should slide up from bottom
  | screen      |
  | Camera View |
  | Compose     |

@7174 @7454
Scenario Outline: Choosing a picture when you have more than one folder photos
  Given I am on the "<screen>" screen
  And I have more than one folder with pictures on my galery
  When I touch "Photo" icon
  Then I should see "<screen2>" screen
  And I should see all folders of pictures existents on my galery
  | screen        | screen2 |
  | Camera View   | Albums  |
  | Compose       | Albums  |

@7174 @7454
Scenario Outline: Choosing a picture when you have only one photo
  Given I am on the "<screen>" screen
  And I have only one photo on my galery
  When I touch "Photo" icon
  Then I should see "Album" screen
  And I should see the photo
  | screen      |
  | Camera View |
  | Compose     |

@7174 @7454
Scenario Outline: Choosing a picture when you don't have pictures on the galery
  Given I am on the "<screen>" screen
  When I don't have photos on my galery
  Then I should see "Photo" icon
  | screen      |
  | Camera View |
  | Compose     |

@7174 @7454
Scenario: Touching Photo icon when I don't have pictures on the galery
  Given I am seeing "Photo" icon
  And I don't have pictures on my galery
  When I touch "Photo" icon
  Then I should see a message informing me that I don't have pictures to choose

@7174 @7454
Scenario: Touching Cancel button
  Given I am on the "<screen>" screen
  And I go to "Album" screen
  When I touch "Cancel" button
  Then I should see "<screen>" screen
  | screen      |
  | Camera View |
  | Compose     |

@7174 @7454
Scenario Outline: Verifying title screen
  Given I am on the "<screen>" screen
  When I go to "Album" screen
  Then I should see "<title>" as a title
  | screen      | title  |
  | Camera View | Photo  |
  | Compose     | Albums |

@7174 @7454
Scenario Outline: Verifying design screen
  Given I am on the "Album" screen
  Then The desing screen should be the same on the prototype design