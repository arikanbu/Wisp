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
    a.appearance = function()
    end
    return a
end

return App
