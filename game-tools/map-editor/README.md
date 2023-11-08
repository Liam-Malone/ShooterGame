# TILEMAP EDITOR

This is a simple tilemap editor that I will be using to create maps for the game. 

This is currently _*very much unfinished*_ and still a WIP.

> This will be in its own standalone repo when I'm happier with the state of it

## DESIRED FEATURES:

- [x] load and display map (very simple format) in tile-grid
- [-] allow editing of map
    - [x] clicking in grid to edit tiles
    - [x] draw across tiles
    - [x] delete (reset) selected tiles
    - [-] move camera around map 
        - [x] move camera
        - [ ] and separate window size from map size -- draw border around map
    - [ ] toolbar (at side)
    - [ ] list of available textures
    - [ ] load in new textures
    - [ ] option to select output file
    - [ ] option to create new map of desired size
    - [ ] allow resizing of map
- [x] render textures based on id of tile in memory
- [x] write to file at end
- [ ] open editor indpendent of a map and prompt for map to load
- [ ] launch editor from CLI with map to load right away

### To Come Later:

- [ ] Integrate into a larger level-editor that can manage entities too
- [ ] maybe refine map formatting to enable this

## END GOAL:

To be able to run the level-editor from within dev build of game to edit at runtime
> (this will be handled with build flags and conditional compilation -- need to figure this out too)
