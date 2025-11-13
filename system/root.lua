--========================================================--
--  ROOT WISP
--  Top-level container of the entire Wisp hierarchy.
--  Holds and manages the App wisp as its primary child.
--========================================================--

local Wisp = require("system.wisp")
local App  = require("app")

------------------------------------------------------------
-- Class definition
------------------------------------------------------------
local Root = setmetatable({}, { __index = Wisp })
Root.__index = Root

------------------------------------------------------------
-- Constructor
------------------------------------------------------------
function Root:new()
    local r = Wisp.new(self, "root", nil)

    -- root itself has no visual logic
    r.appearance = function() end

    -- create and attach the App wisp
    local app = App:new("app", r)
    app:assign_layer(-1)

    --------------------------------------------------------
    -- Print all members
    --------------------------------------------------------
    function r:print_members()
        if not self.members then return end
        local t = {}
        for k in pairs(self.members) do table.insert(t, k) end
        --print("Wisps:", "{" .. table.concat(t, ",") .. "}")
    end

    --------------------------------------------------------
    -- Update sorted draw list
    --------------------------------------------------------
    function r:update_sorted_draw_list()
        if not self.layering_changed then return end
        self.sorted_draw_list = {}
        for _, w in pairs(self.members or {}) do
            table.insert(self.sorted_draw_list, w)
        end
        table.sort(self.sorted_draw_list, function(a, b)
            return (a.layer or 0) < (b.layer or 0)
        end)
        self.layering_changed = false
    end

    --------------------------------------------------------
    -- Collect all streams from members
    --------------------------------------------------------
    function r:collect_streams()
        local collected = {}
        for _, w in pairs(self.members or {}) do
            if w.stream_content and next(w.stream_content) then
                collected[w.id] = w.stream_content
                w.stream_content = {} -- clear but keep table
            end
        end
        self.collected_streams = collected

        -- print collected streams
        for id, content in pairs(collected) do
            print("Stream from:", id)
            for k, v in pairs(content) do
                print("  " .. k .. ": " .. tostring(v))
            end
        end
        return collected
    end

    return r
end

return Root
