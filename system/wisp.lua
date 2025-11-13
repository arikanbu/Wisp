--========================================================--
--  WISP: Unit for Wisp Architecture
--========================================================--

local Wisp = {}
Wisp.__index = Wisp

------------------------------------------------------------
-- Constructor (Family Registration)
------------------------------------------------------------
function Wisp:new(name, parent)
    -- Identity
    local w = setmetatable({}, self)
    math.randomseed(os.clock() * 1e9)
    w.id = tostring(math.random(1e9))
    w.name = name or ""
    -- Root (The only parentless wisp)
    w.root = parent and parent.root or w
    w.root.layering_changed = true
    -- Family
    w.parent = parent or ""
    if parent then parent.children[w.name] = w end
    w.path = (parent and parent.path .. "/" or "") .. w.name
    w.children = {}
    w.members = {}
    if parent then w.root.members[w.name] = w end
    -- Structure
    w.properties = {}
    -- Dynamics
    w.states = {default = true}
    w.processes = {}
    -- Appearance
    w.layer = 0
    w.sorted_draw_list = {}
    w.canvases = {}
    w.appearance = function() end
    -- Focus
    w.attended = false
    -- Controls
    w.controls = {}
    -- Communication
    w.stream_path = w.path .. "(" .. w.id .. ")"
    w.stream_request = nil
    w.stream_content = {}
    -- return
    return w
end

------------------------------------------------------------
-- Functions that Modify or Notify Root
------------------------------------------------------------
function Wisp:assign_layer(layer)
    -- Layer of appearance
    self.layer = layer
    self.root.layering_changed = true
end

function Wisp:annihilate()
  -- Remove from parent
  if self.parent and self.parent.children then
    self.parent.children[self.name] = nil
  end
  -- Remove from root members
  if self.root and self.root.members then
    self.root.members[self.name] = nil
  end
  -- Recursively clear children
  for _, c in pairs(self.children) do
    c:annihilate()
  end
  self.root.layering_changed = true
  -- Clear own references
  self.children = {}
  self.parent = nil
  self.root = nil
end

------------------------------------------------------------
-- Processes
------------------------------------------------------------
function Wisp:activate(method)
    assert(type(method) == "string", "activate: method name must be a string")
    self.processes[method] = true
end

function Wisp:deactivate(method)
  assert(type(method) == "string", "deactivate: method name must be a string")
  self.processes[method] = nil
end

function Wisp:enter_state(state)
  assert(type(state) == "string", "enter_state: state name must be a string")
  self.states[state] = true
end

function Wisp:exit_state(state)
  assert(type(state) == "string", "exit_state: state name must be a string")
  self.states[state] = nil
end

------------------------------------------------------------
-- Update 
------------------------------------------------------------
function Wisp:update(dt)
  for _, w in pairs(self.root.members or {}) do
    -- run active processes
    for name in pairs(w.processes) do
      w[name](w, dt)
    end
    -- stream output
    if w.stream_request
    then
      w:prepare_stream(dt)
      --[[--print stream
      for k, v in pairs(w.stream_content or {}) do
        print(k .. ": " .. v)
      end
      --]]
    end
  end
end

------------------------------------------------------------
-- Appearance
------------------------------------------------------------
function Wisp:add_canvas(name, color)
  local canvas = love.graphics.newCanvas()
  local entry = {
    name = name or ("canvas_" .. tostring(#self.canvases + 1)),
    canvas = canvas,
    color = color or {1, 1, 1, 1}
  }
  table.insert(self.canvases, entry)
  return canvas
end

function Wisp:draw_canvases()
  for _, c in ipairs(self.canvases or {}) do
    local col = c.color or {1, 1, 1, 1}
    love.graphics.setColor(col)
    love.graphics.draw(c.canvas or c)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function Wisp:draw()
    local list = self.root.sorted_draw_list or {}
    for _, w in ipairs(list) do
        if w.canvases and #w.canvases > 0 then
            w:draw_canvases()
        end
        w:appearance()
    end
end

------------------------------------------------------------
-- Communications
------------------------------------------------------------
function Wisp:prepare_stream(dt)
  if not self.stream_request then return end
  local output = {}

  -- states
  if self.stream_request.states then
    local states = {}
    for s in pairs(self.states or {}) do table.insert(states, s) end
    output.states = table.concat(states, ",")
  end

  -- processes
  if self.stream_request.processes then
    local procs = {}
    for p in pairs(self.processes or {}) do table.insert(procs, p) end
    output.processes = table.concat(procs, ",")
  end

  -- helper to stringify tables
  local function stringify(val)
    if type(val) ~= "table" then return tostring(val) end
    local list, is_dict = {}, false
    for k in pairs(val) do
      if type(k) ~= "number" then is_dict = true break end
    end
    if is_dict then
      for k, v in pairs(val) do table.insert(list, tostring(k) .. ":" .. tostring(v)) end
    else
      for _, v in ipairs(val) do table.insert(list, tostring(v)) end
    end
    return table.concat(list, ",")
  end

  -- properties
  if self.stream_request.properties then
    if type(self.stream_request.properties) == "string" then
      for prop in string.gmatch(self.stream_request.properties, '([^,]+)') do
        local val = self.properties[prop]
        if val ~= nil then output[prop] = stringify(val) end
      end
    else
      for k, v in pairs(self.properties or {}) do
        output[k] = stringify(v)
      end
    end
  end

  -- add identity info
  output.stream_path = self.path or ""
  output.attended = tostring(self.attended)
  --output.timestamp = love.timer.getTime()
  output.timestamp = love.timer.getTime() * 1000  -- ms since game start
  output.dt = dt

  self.stream_content = output
  return output
end

------------------------------------------------------------
-- Focus
------------------------------------------------------------
function Wisp:attend(state)
    self.attended = (state == nil) and not self.attended or not not state
end

------------------------------------------------------------
-- Control
------------------------------------------------------------
function Wisp:add_control(args)
  assert(args.action and args.mode and args.event and args.key,
    "add_control: missing required field (action, mode, event, key)")
  self.controls = self.controls or {}

  for _, c in ipairs(self.controls) do
    if c.action == args.action
       and c.mode == args.mode
       and c.event == args.event
       and c.key == args.key then
      return -- duplicate found, skip insert
    end
  end

  table.insert(self.controls, {
    action = args.action,
    mode   = args.mode,
    event  = args.event,
    key    = args.key,
    requires_attend   = args.requires_attend   or false,
    requires_active   = args.requires_active   or false,
    requires_deactive = args.requires_deactive or false
  })
end

function Wisp:remove_control(action, mode)
  for i = #self.controls, 1, -1 do
    local c = self.controls[i]
    if c.action == action and (not mode or c.mode == mode) then
      table.remove(self.controls, i)
    end
  end
end

function Wisp:update_control(args)
  assert(args.action, "update_control: missing 'action'")
  for _, c in ipairs(self.controls) do
    if c.action == args.action and (not args.mode or c.mode == args.mode) then
      c.event = args.event or c.event
      c.key = args.key or c.key
      c.requires_attend   = (args.requires_attend   == nil) and c.requires_attend   or args.requires_attend
      c.requires_active   = (args.requires_active   == nil) and c.requires_active   or args.requires_active
      c.requires_deactive = (args.requires_deactive == nil) and c.requires_deactive or args.requires_deactive
    end
  end
end

function Wisp:handle_input(event, key)
  for _, c in ipairs(self.controls or {}) do
    if c.event == event and c.key == key
       and ((not c.requires_attend) or self.attended)
       and ((not c.requires_active) or self.processes[c.action])
       and ((not c.requires_deactive) or not self.processes[c.action]) then

      local mode, act = c.mode, c.action
      if mode == "fire" then self[act](self)
      elseif mode == "activate" then self.processes[act] = true
      elseif mode == "deactivate" then self.processes[act] = nil
      end
    end
  end
  for _, sub in pairs(self.children) do
    if sub.handle_input then sub:handle_input(event, key) end
  end
end

------------------------------------------------------------
-- Misc.
------------------------------------------------------------
function Wisp:type()
    return getmetatable(self)
end

------------------------------------------------------------
-- Debugging
------------------------------------------------------------



return Wisp
