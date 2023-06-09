# ProgrammRobotics

Welcome to my game without buttons and etc. The game with only console and output.
This is my first game and I beginner in programming and GameDev, so it can be so bad...

## Installing

1. Download LÖVE (love2d) 11.4
2. Zip this folder and change file format .zip to .love
3. Double click love folder

> You also can do command `love .` being in folder

## Commands
> Lua is used. You can use several Lua functions like ipairs, assert and etc

### game
`game.version` - game version (string)
`game.quit` - quit the game (function)
`game.export` - NONE (function)
`game.createWorld` - create the world (function)
Also create `game.world`

### game.output
`game.output.print` - print the message (function, ...)
`game.output.error` - raise error (function, message)
`game.output.clear` - clear output history (function)

### game.settings
> There are not functions. Use overrides. For example `game.settings.fullscreen = true`
`game.settings.fullscreen` - fullscreen (boolean)
`game.settings.fullscreenType` - fullscreen type (string desktop|exclusive|normal")
`game.settings.windowX` - window posX (number)
`game.settings.windowY` - window posY (number)
`game.settings.windowWidth` - window width (number)
`game.settings.windowHeight` - window height (number)
`game.settings.VSync` - VSync (boolean)

### game.world
`game.world.getWidth` - return world width (function)
`game.world.getHeight` - return world height (function)
`game.world.getSeed` - return world seed (function)

### game.world.engineer
> It's only one entity in the game
`game.world.entity.getX` - return entity posX (function)
`game.world.entity.getY` - return entity posY (function)
`game.world.entity.getRotate` - return entity rotate (function)
`game.world.entity.getWidth` - return entity width (function)
`game.world.entity.getHeight` - return entity height (function)
`game.world.entity.getSpeed` - return entity speed (function)
`game.world.entity.getTag` - return entity tag (function)
`game.world.entity.walkTo` - make entity walk to coords (function, x, y)