--========================================================--
--  MAIN.LUA
--  Entry point of the Wisp architecture.
--  Initializes the root Wisp and delegates update, draw,
--  and input handling through its hierarchy.
--========================================================--

-- Initialize debugger if running in VS Code
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

local Root = require("system.root")

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
function love.load()
    root = Root:new()
end

------------------------------------------------------------
-- Update loop
------------------------------------------------------------
function love.update(dt)
    root:update_sorted_draw_list()
    root:collect_streams()
    root:update(dt)
end

------------------------------------------------------------
-- Draw loop
------------------------------------------------------------
function love.draw()
    root:draw()
end

------------------------------------------------------------
-- Input handling
-- Delegates all key events to root wisp hierarchy
------------------------------------------------------------
function love.keypressed(key)
    -- We may want to stream this before it enters the architecture
    root:handle_input("keypressed", key)
end

function love.keyreleased(key)
    -- We may want to stream this before it enters the architecture
    root:handle_input("keyreleased", key)
end
