# TODO:

#### highest priority

- [-] implement concept of "camera"
    - [x] move camera by keeping player centre of screen
    - [ ] later adjust this so that screen moves when player reaches a certain distance from the centre
- [ ] Create tilemap editor
    - [x] map different 'tiles' to colors - replace with proper textures later
    - [x] begin texture work -- render "void" texture when no texture exists for tile
    - [-] load and display in grid view
        - [x] load and display map
        - [ ] grid view
    - [ ] file writing

#### standard priority

- [ ] embed tilemap editor into main build
    - will use build flags to determine existence or not in binary
- [ ] programmer art
    - [x] player sprite
    - [ ] more entity sprites
    - [ ] bullet, torch sprites (play with lighting once torch is in)
- [ ] add other entities
    - [x] add basic enemy
    - [ ] improve basic enemy
    - [ ] add more kinds of enemy
    - [ ] add friendly entities
- [ ] add pause screen

#### delayed priority

- [ ] maybe get simple unit tests implemented
- [ ] add point/inventory system
    - [ ] give player hold over bullets
- [ ] save game and load from saves -- I'm dreading figuring this out
