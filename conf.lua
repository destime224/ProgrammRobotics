_G.GameV = "0.0.2 alpha"

function love.conf(t)
    t.title = "ProgrammRobotics"
    t.appendidentity = "ProgrammRobotics"
    t.version = "11.4"

    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"

    t.window.borderless = true
    t.window.resizable = true

    t.window.width = 1280
    t.window.height = 720

    t.window.minwidth = 1280
    t.window.minheight = 720

    t.window.x = nil
    t.window.y = nil

    t.modules.joystick = false
end