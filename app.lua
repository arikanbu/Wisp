--========================================================--
--  APP WISP
--========================================================--

local Wisp = require("system.wisp")
local require_components = require("system.require_components")
require_components()
------------------------------------------------------------
--  Define App class
------------------------------------------------------------
local App = setmetatable({}, { __index = Wisp })
App.__index = App

------------------------------------------------------------
--  Constructor
------------------------------------------------------------
function App:new(name, parent)
    local a = Wisp.new(self, name or "app", parent)
    --------------------------------------------------------
    --  Appearance: Background color
    --------------------------------------------------------
    love.graphics.clear(0, 0, 0)
    local bg = love.graphics.newImage("media/background.png")
    local shade = a:add_canvas("shade", {1, 1, 1, 0.2})
    love.graphics.setCanvas(shade)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
    love.graphics.setCanvas()

    a.appearance = function()
        --love.graphics.clear(0.1, 0.1, 0.1)
    end

    --------------------------------------------------------
    --  Controls
    --------------------------------------------------------
    a:add_control{ action = "spawn_ball",     mode = "fire", event = "keypressed", key = "space", requires_attend = false }
    a:add_control{ action = "attend_random",  mode = "fire", event = "keypressed", key = "g",     requires_attend = false }
    a:add_control{ action = "attend_random_2",mode = "fire", event = "keypressed", key = "b",     requires_attend = false }

    --------------------------------------------------------
    --  METHODS
    --------------------------------------------------------
    function a:spawn_ball()
        local b = Ball:new("ball_" .. tostring(os.clock()), self)
        b.stream_request = { states = false, processes = false, properties = true }
    end

    --  Picks N random wisps of a given class type
    function a:pick_random(wisp_type, n)
        local list = {}
        local class = _G[wisp_type]
        if not class then return {} end

        for _, w in pairs(self.root.members) do
            if getmetatable(w) == class then table.insert(list, w) end
        end
        if #list == 0 then return {} end

        local selected, picked = {}, {}
        n = math.min(n, #list)

        while #selected < n do
            local idx = math.random(1, #list)
            if not picked[idx] then
                picked[idx] = true
                table.insert(selected, list[idx])
            end
        end

        return selected
    end


    function a:attend_random()
        for _, w in pairs(self.root.members) do w:attend(false) end
        for _, b in ipairs(self:pick_random("Ball", 1)) do b:attend(true) end
    end

    function a:attend_random_2()
        for _, w in pairs(self.root.members) do w:attend(false) end
        for _, b in ipairs(self:pick_random("Ball", 2)) do b:attend(true) end
    end

    return a
end

return App
