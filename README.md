# ProgrammRobotics

Welcome to my game without buttons and etc. The game is with only console and output.
This is my first game and I beginner in programming and GameDev, so it can be so bad...

## Installing
1. Download LÖVE (love2d) 11.4
2. Zip this folder and change file format .zip to .love
3. Double click love folder

> You also can do command `love .` being in folder

## Commands
> Lua is used. You can use several Lua functions like ipairs, assert and etc

### game
- `game.version` - game version (string)
- `game.quit` - quits the game (function)
- `game.credits` - prints credits (function)
- `game.createWorld` - creates the world (function)
Also creates `game.world`

### game.output
- `game.output.print` - prints the message (function, ...)
- `game.output.warn` - prints the warning message (function, ...)
- `game.output.clear` - clears output history (function)

### game.console
- `game.console.error` - raises error (function, message)

### game.settings
> There are not functions. Use overrides. For example `game.settings.fullscreen = true`
- `game.settings.fullscreen` - fullscreen (boolean)
- `game.settings.fullscreenType` - fullscreen type (string desktop|exclusive|normal")
- `game.settings.windowX` - window posX (number)
- `game.settings.windowY` - window posY (number)
- `game.settings.windowWidth` - window width (number)
- `game.settings.windowHeight` - window height (number)
- `game.settings.display` - display (number)
- `game.settings.VSync` - VSync (boolean)
- `game.settings.borderless` - window borderless (boolean)
- `game.settings.resizable` - window resizable (boolean)

### game.world
- `game.world.getWidth` - returns world width (function)
- `game.world.getHeight` - returns world height (function)
- `game.world.getSeed` - returns world seed (function)

### game.world.engineer
> It's only one entity in the game
- `game.world.engineer.getX` - returns engineer posX (function)
- `game.world.engineer.getY` - returns engineer posY (function)
- `game.world.engineer.getRotate` - returns engineer rotate (function)
- `game.world.engineer.getWidth` - returns engineer width (function)
- `game.world.engineer.getHeight` - returns engineer height (function)
- `game.world.engineer.getSpeed` - returns engineer speed (function)
- `game.world.engineer.getType` - returns engineer type "entity" (function)
- `game.world.engineer.getName` - returns engineer name "engineer" (function)
- `game.world.engineer.walkTo` - makes engineer to walk to coords (function, x, y)
- `game.world.engineer.walkToVector` - makes engineer to walk to vector (function, dx, dy)
- `game.world.engineer.rotate` - makes engineer to rotate (function, r)

### game.world.base
- `game.world.build.getX` - returns base left-top posX (function)
- `game.world.build.getY` - returns base left-top posY (function)
- `game.world.build.getCenteredX` - returns base centerX (function)
- `game.world.build.getCenteredY` - returns base centerY (function)
- `game.world.build.getWidth` - returns base maximum width (function)
- `game.world.build.getHeight` - returns base maximum height (function)
- `game.world.build.getType` - returns base type "build" (function)
- `game.world.build.getName` - returns base name "base" (function)