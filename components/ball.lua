------------------------------------------------------------
--  BALL MODULE
--  Extends Wisp with motion, controls, breathing, orbiting, and appearance
------------------------------------------------------------

local Wisp = require("system.wisp")
local Ball = setmetatable({}, { __index = Wisp })
Ball.__index = Ball

------------------------------------------------------------
-- Constructor
------------------------------------------------------------
function Ball:new(name, parent, x, y, radius, color)
    -- Base initialization
    local b = Wisp.new(self, name or "ball", parent)
    local w = parent and parent.properties.width or 800
    local h = parent and parent.properties.height or 600

    -- Basic properties
    b.properties = {
        x = x or math.random(50, w - 50),
        y = y or math.random(50, h - 50),
        r = radius or 20,
        color = color or { math.random(), math.random(), math.random() },
        speed = 0.4,
        oxy = 13
    }

    ------------------------------------------------------------
    -- Appearance (draw)
    ------------------------------------------------------------
    -- static canvas 0: large faint circle
    local shade = b:add_canvas("shade", {0, 0, 0, 0.4})
    love.graphics.setCanvas(shade)
    love.graphics.clear()
    love.graphics.circle("fill", b.properties.x, b.properties.y, b.properties.r * 0.2)
    love.graphics.setCanvas()

    -- static canvas 1: smaller highlight
    local highlight = b:add_canvas("highlight", {1, 1, 1, 0.15})
    love.graphics.setCanvas(highlight)
    love.graphics.clear()
    love.graphics.circle("fill", b.properties.x, b.properties.y, b.properties.r * 0.15)
    love.graphics.setCanvas()

    -- dynamic appearance
    b.appearance = function(self)
        love.graphics.setColor(self.properties.color)
        love.graphics.circle("fill", self.properties.x, self.properties.y, self.properties.r)
    end

    function b:layer_forward()
        self:assign_layer(self.layer + 1)
        print(self.layer)
    end
    b:add_control{ action = "layer_forward",    mode = "fire",   event = "keypressed",  key = "i",    requires_attend = true }

    ------------------------------------------------------------
    -- Movement controls
    ------------------------------------------------------------
    function b:move_up()    self.properties.y = self.properties.y - self.properties.speed end
    b:add_control{ action = "move_up",    mode = "activate",   event = "keypressed",  key = "up",    requires_attend = true }
    b:add_control{ action = "move_up",    mode = "deactivate", event = "keyreleased", key = "up",    requires_attend = true }
    b:add_control{ action = "move_up",    mode = "activate",   event = "keypressed",  key = "w",    requires_attend = true }
    b:add_control{ action = "move_up",    mode = "deactivate", event = "keyreleased", key = "w",    requires_attend = true }

    function b:move_down()  self.properties.y = self.properties.y + self.properties.speed end
    b:add_control{ action = "move_down",  mode = "activate",   event = "keypressed",  key = "down",  requires_attend = true }
    b:add_control{ action = "move_down",  mode = "deactivate", event = "keyreleased", key = "down",  requires_attend = true }
    b:add_control{ action = "move_down",  mode = "activate",   event = "keypressed",  key = "s",  requires_attend = true }
    b:add_control{ action = "move_down",  mode = "deactivate", event = "keyreleased", key = "s",  requires_attend = true }

    function b:move_left()  self.properties.x = self.properties.x - self.properties.speed end
    b:add_control{ action = "move_left",  mode = "activate",   event = "keypressed",  key = "left",  requires_attend = true }
    b:add_control{ action = "move_left",  mode = "deactivate", event = "keyreleased", key = "left",  requires_attend = true }
    b:add_control{ action = "move_left",  mode = "activate",   event = "keypressed",  key = "a",  requires_attend = true }
    b:add_control{ action = "move_left",  mode = "deactivate", event = "keyreleased", key = "a",  requires_attend = true }

    function b:move_right() self.properties.x = self.properties.x + self.properties.speed end
    b:add_control{ action = "move_right", mode = "activate",   event = "keypressed",  key = "right", requires_attend = true }
    b:add_control{ action = "move_right", mode = "deactivate", event = "keyreleased", key = "right", requires_attend = true }
    b:add_control{ action = "move_right", mode = "activate",   event = "keypressed",  key = "d", requires_attend = true }
    b:add_control{ action = "move_right", mode = "deactivate", event = "keyreleased", key = "d", requires_attend = true }

    ------------------------------------------------------------
    -- Attention control
    ------------------------------------------------------------
    function b:de_attend() self.attended = false end
    b:add_control{ action = "de_attend", mode = "fire", event = "keypressed", key = "f", requires_attend = true }
    ------------------------------------------------------------
    -- Autonomy process (focus color)
    ------------------------------------------------------------
    b.autonomy = function(self)
        if self.attended then
            self.properties.color = { 0, 0, 1 }   -- blue if attended
        elseif self.properties.color[1] ~= 1 or self.properties.color[2] ~= 0 or self.properties.color[3] ~= 0 then
            self.properties.color = { 1, 0, 0 }   -- red otherwise
        end
    end
    b:activate("autonomy")
    ------------------------------------------------------------
    -- State detection
    ------------------------------------------------------------
    function b:detect_polyball()
        local count = 0
        local function count_descendants(w)
            for _, child in pairs(w.children or {}) do
                count = count + 1
                count_descendants(child)
            end
        end
        count_descendants(self)
        if count > 3 then
            self:enter_state("polyball")
        else
            self:exit_state("polyball")
        end
    end
    b:activate("detect_polyball")
    ------------------------------------------------------------
    -- Breathing processes
    ------------------------------------------------------------
    function b:inhale()
        self.properties.oxy = (self.properties.oxy or 0) + 0.01
    end

    function b:exhale()
        self.properties.oxy = (self.properties.oxy or 0) - 0.01
    end

    function b:breath()
        local oxy = self.properties.oxy or 0
        if oxy >= 12 then
            self:activate("exhale")
            self.processes["inhale"] = nil
        elseif oxy <= 8 then
            self:activate("inhale")
            self.processes["exhale"] = nil
        end
    end
    b:activate("breath")
    function b:scale_radius()
        self.properties.r = self.properties.r + (self.properties.oxy - 10) / 50
    end
    b:activate("scale_radius")
    ------------------------------------------------------------
    -- Orbit system
    ------------------------------------------------------------
    function b:add_orbit()
        -- inherit parent orbit parameters
        local parent_dist = self.properties.orbit_distance or 150
        local orbit_distance = math.random(parent_dist * 0.3, parent_dist * 0.5)
        local parent_speed = self.properties.angular_speed or 1
        local direction = parent_speed >= 0 and 1 or -1
        local angular_speed = 4 * (math.random() * 1.5 + 0.5) * direction

        -- compute first valid orbit position (absolute)
        local angle = math.random() * 2 * math.pi
        local cx, cy = self.properties.x, self.properties.y
        local ox = cx + math.cos(angle) * orbit_distance
        local oy = cy + math.sin(angle) * orbit_distance

        -- create orbiter already positioned correctly
        local orbiter = Ball:new("orbit_" .. tostring(math.random(1e6)), self, ox, oy)
        orbiter.properties.r = self.properties.r * 0.4
        orbiter.properties.angle = angle
        orbiter.properties.orbit_distance = orbit_distance
        orbiter.properties.angular_speed = angular_speed

        -- orbit process
        function orbiter:orbit(dt)
            if not self.parent then return end
            local px, py = self.parent.properties.x, self.parent.properties.y
            local dir = math.atan2(self.properties.y - py, self.properties.x - px)
            dir = dir + dt * self.properties.angular_speed
            local r = self.properties.orbit_distance
            self.properties.x = px + math.cos(dir) * r
            self.properties.y = py + math.sin(dir) * r
        end

        orbiter:activate("orbit")
        return orbiter
    end
    b:add_control{ action = "add_orbit", mode = "fire", event = "keypressed", key = "u", requires_attend = true }
    b:add_control{ action = "annihilate", mode = "fire", event = "keypressed", key = "x", requires_attend = true }
    ------------------------------------------------------------
    return b
end

return Ball
