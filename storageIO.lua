-- Storage IO (storageIO.lua)
-- by Michael Thompson
-- 
-- for the ATM10 modpack for Minecraft: Java Edition
-- meant to be used with CC: Tweaked for storage management
-- coded in Lua

local CONTROLLER = "sophisticatedstorage:controller_0"
local BUFFER     = "minecraft:barrel_4"

--local storage = peripheral.wrap(CONTROLLER)
--local buffer = peripheral.wrap(BUFFER)


--resolve short name to full registry name
--matches against whats in sotrage, exact path wins, otherwise
-- falls back to substring
--returns fullName or nil + a message
local function resolveItem(query)
  query = query:lower()
  local present = {}
  for _, item in pairs(peripheral.call(CONTROLLER, "list")) do
    present[item.name] = true
  end

  local exact, partial = {}, {}
  for name in pairs(present) do
    local full = name:lower()
    local path = (name:match(":(.+)") or name):lower()
    if full == query or path == query then
      exact[#exact + 1] = name
    elseif full:find(query, 1, true) or path:find(query, 1, true) then
      partial[#partial + 1] = name
    end
  end

  local hits = (#exact > 0) and exact or partial
  if #hits == 0 then
    return nil, "No item matching '" .. query .. "' is in storage."
  elseif #hits == 1 then
    return hits[1]
  else
    local msg = "Ambiguous '" .. query .. "' — be more specific:"
    for _, m in ipairs(hits) do msg = msg .. "\n  " .. m end
    return nil, msg
  end
end

--deposit stuff
local function deposit()
  local moved = 0
  for slot in pairs(peripheral.call(BUFFER, "list")) do
    moved = moved + (peripheral.call(CONTROLLER, "pullItems", BUFFER, slot) or 0)
  end
  print(moved > 0 and ("Deposited " .. moved .. " items.") or "Nothing to deposit.")
end

--withdraw stuff without mod name
local function withdraw(query, count)
  local name, err = resolveItem(query)
  if not name then print(err); return end

  local moved = 0
  for slot, item in pairs(peripheral.call(CONTROLLER, "list")) do
    if item.name == name then
      moved = moved + (peripheral.call(CONTROLLER, "pushItems", BUFFER, slot, count - moved) or 0)
      if moved >= count then break end
    end
  end
  print("Withdrew " .. moved .. " of " .. name)
end

--print stuff stored
local function listContents()
  local totals = {}
  for _, item in pairs(peripheral.call(CONTROLLER, "list")) do
    totals[item.name] = (totals[item.name] or 0) + item.count
  end
  local rows = {}
  for n, c in pairs(totals) do rows[#rows + 1] = { n, c } end
  table.sort(rows, function(a, b) return a[2] > b[2] end)
  if #rows == 0 then
    print("Nothing stored.")
    return
  end
  for _, r in ipairs(rows) do
    textutils.pagedPrint(("%6d  %s"):format(r[2], r[1]))
  end
  print(("== %d types =="):format(#rows))
end

--commands
print("\nStorage IO\n-----------\n\nCommands:\n\nlist\ndeposit\nwithdraw <item> <count>\nexit")
while true do
  write("> ")
  local cmd = read()
  if cmd == "list" then
    listContents()
  elseif cmd == "deposit" then
    deposit()
  elseif cmd == "exit" then
    break
  else
    local name, n = cmd:match("^withdraw%s+(%S+)%s+(%d+)$")
    if name then
      withdraw(name, tonumber(n))
    else
      print("Unknown command.")
    end
  end
end