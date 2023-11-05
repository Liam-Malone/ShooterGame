# TODO:

### Highest Priority

- [-] implement concept of "camera"
    - [x] move camera by keeping player centre of screen
    - [ ] allow player to move a certain distance from centre of screen before moving
- [-] Create tilemap editor
    - [x] map different 'tiles' to colors - replace with proper textures later
    - [x] begin texture work -- render "void" texture when no texture exists for tile
    - [-] load and display in grid view
        - [x] load and display map
        - [ ] grid view
    - [x] file writing

> tilemap editor is located in game-tools/map-editor

### Standard Priority

- [-] programmer art
    - [x] player sprite
    - [ ] textures for more of the tiles
    - [ ] more entity sprites
    - [ ] bullet, torch sprites (play with lighting once torch is in)
- [-] add other entities
    - [x] add basic enemy
    - [ ] improve basic enemy
    - [ ] add more kinds of enemy
    - [ ] add friendly entities
- [ ] add pause screen
- [ ] add inventory system
    - [ ] give player control over their bullets
    - [ ] enable player to hold tools

### Delayed Priority

- [ ] embed tilemap editor into main build
    - will use build flags to determine existence or not in binary
- [ ] save game and load from saves -- I'm dreading figuring this out
