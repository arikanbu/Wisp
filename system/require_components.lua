--========================================================--
--  REQUIRE_COMPONENTS
--  Auto-requires all modules from /components except excluded.
--========================================================--

return function(exclude)
    exclude = exclude or {}
    local folder = "components"

    for _, file in ipairs(love.filesystem.getDirectoryItems(folder)) do
        if file:match("%.lua$") then
            local name = file:match("^(.-)%.lua$")
            if not exclude[name] then
                local mod = folder .. "." .. name
                local global_name = name:gsub("^%l", string.upper)
                _G[global_name] = require(mod)
            end
        end
    end
end
