local component = require('component')
local thread = require('thread')
local event = require('event')
local sides = require('sides')
local gpu = component.gpu
local unicode = require("unicode")

local mei = nil
local db = nil
local tr = nil
local gpu = nil
local wins = {}                     -- windows storage
local cur_fluids = {}               -- drawing fluids

local craftingCheckInterval = 5     -- only check ongoing crafting
local updateGuiInterval = 1
local d_limit = 5                   -- debud recursion limit
local intface_side = nil            -- Me interface side relative to the Transposer (nil = autodetect)
local fluid_extr_side = nil         -- Fluid processing buffer side relative to the Transposer (nil = autodetect)
local precraft_fluids_config = {}   -- config storage
local database_size = 81
local gui_is_show = true
local gui_table_on_line = 3

function init_config()
    local fluids_config = {
        --    fluid name                fluid label                             (fluid amount) (amnt per item) (item name)           (damage)(item label)
            { "molten.solderingalloy",  "Molten Soldering Alloy",                        18432, 144, "gregtech:gt.metaitem.01",      11314,  "Soldering Alloy Ingot" },
            { "molten.rubber",          "Molten Rubber",                                 18432, 144, "gregtech:gt.metaitem.01",      17880,  "Rubber Sheet" },
            { "molten.plastic",         "Molten Polyethylene",                           18432, 144, "gregtech:gt.metaitem.01",      17874,  "Polyethylene Sheet" },
            { "molten.cobalt",          "Molten Cobalt",                                 18432, 144, "gregtech:gt.metaitem.01",      11033,  "Cobalt Ingot" },
            { "molten.hssg",            "Molten HSS-G",                                  18432, 144, "gregtech:gt.metaitem.01",      11372,  "HSS-G Ingot" },
            { "molten.silicone",        "Molten Silicon Rubber",                         18432, 144, "gregtech:gt.metaitem.01",      17471,  "Silicon Rubber Sheet" },
            { "molten.niobiumtitanium", "Molten Niobium Titanium",                       7200,  144, "gregtech:gt.metaitem.01",      11360,  "Niobium-Titanium Ingot" },
            { "molten.steel",           "Molten Steel",                                  7200,  144, "gregtech:gt.metaitem.01",      11305,  "Steel Ingot" },
            { "molten.silver",          "Molten Silver",                                 18432, 144, "gregtech:gt.metaitem.01",      11054,  "Silver Ingot" },
            { "molten.electrum",        "Molten Electrum",                               18432, 144, "gregtech:gt.metaitem.01",      11303,  "Electrum Ingot" },
            { "molten.tungsten",        "Molten Tungsten",                               18432, 144, "gregtech:gt.metaitem.01",      11081,  "Tungsten Ingot" },
            { "molten.aluminium",       "Molten Aluminium",                              18432, 144, "gregtech:gt.metaitem.01",      11019,  "Aluminium Ingot" },
            { "molten.epoxid",          "Molten Epoxid",                                 18432, 144, "gregtech:gt.metaitem.01",      17470,  "Epoxid Sheet" },
            { "molten.tin",             "Molten Tin",                                    18432, 144, "gregtech:gt.metaitem.01",      11057,  "Tin Ingot" },
            { "molten.stainlesssteel",  "Molten Stainless Steel",                        18432, 144, "gregtech:gt.metaitem.01",      11306,  "Stainless Steel Ingot" },
            { "molten.energeticalloy",  "Molten Energetic Alloy",                        18432, 144, "gregtech:gt.metaitem.01",      11366,  "Energetic Alloy Ingot" },
            { "molten.vibrantalloy",    "Molten Vibrant Alloy",                          18432, 144, "gregtech:gt.metaitem.01",      11367,  "Vibrant Alloy Ingot" },
            { "molten.redsteel",        "Molten Red Steel",                              18432, 144, "gregtech:gt.metaitem.01",      11348,  "Red Steel Ingot" },
            { "molten.cupronickel",     "Molten Cupronickel",                            18432, 144, "gregtech:gt.metaitem.01",      11310,  "Cupronickel Ingot" },
            { "molten.hsss",            "Molten HSS-S",                                  18432, 144, "gregtech:gt.metaitem.01",      11374,  "HSS-S Ingot" },
            { "molten.kanthal",         "Molten Kanthal",                                18432, 144, "gregtech:gt.metaitem.01",      11312,  "Kanthal Ingot" },
            { "molten.tantalum",        "Molten Tantalum",                               18432, 144, "gregtech:gt.metaitem.01",      11080,  "Tantalum Ingot" },
            { "molten.naquadah",        "Molten Naquadah",                               18432, 144, "gregtech:gt.metaitem.01",      11324,  "Naquadah Ingot" },
            { "molten.nickel",          "Molten Nickel",                                 18432, 144, "gregtech:gt.metaitem.01",      11034,  "Nickel Ingot" },
            { "molten.chrome",          "Molten Chrome",                                 18432, 144, "gregtech:gt.metaitem.01",      11030,  "Chrome Ingot" },
            { "molten.nichrome",        "Molten Nichrome",                               18432, 144, "gregtech:gt.metaitem.01",      11311,  "Nichrome Ingot" },
            { "molten.trinium",         "Molten Trinium",                                18432, 144, "gregtech:gt.metaitem.01",      11868,  "Trinium Ingot" },
            { "molten.tungstensteel",   "Molten Tungstensteel",                          18432, 144, "gregtech:gt.metaitem.01",      11316,  "Tungstensteel Ingot" },
            { "molten.polytetrafluoroethylene", "Molten Polytetrafluoroethylene",        18432, 144, "gregtech:gt.metaitem.01",      17473,  "Polytetrafluoroethylene Sheet" },
            { "molten.vanadiumgallium", "Molten Vanadium Gallium",                       18432, 144, "gregtech:gt.metaitem.01",      11357,  "Vanadium Gallium Ingot" },
            { "molten.iridium",         "Molten Iridium",                                18432, 144, "gregtech:gt.metaitem.01",      11084,  "Iridium Ingot" },
            { "molten.naquadahalloy",   "Molten Naquadah Alloy",                         18432, 144, "gregtech:gt.metaitem.01",      11325,  "Naquadah Alloy Ingot" },
            { "molten.osmium",          "Molten Osmium",                                 18432, 144, "gregtech:gt.metaitem.01",      11083,  "Osmium Ingot" },
            { "molten.europium",        "Molten Europium",                               18432, 144, "gregtech:gt.metaitem.01",      11070,  "Europium Ingot" },
            { "molten.plutonium",       "Molten Plutonium 239",                          18432, 144, "gregtech:gt.metaitem.01",      11100,  "Plutonium 239 Ingot" },
            { "molten.polybenzimidazole", "Molten Polybenzimidazole",                    18432, 144, "gregtech:gt.metaitem.01",      17599,  "Polybenzimidazole Plate" },
            { "molten.sunnarium",       "Molten Sunnarium",                              18432, 144, "gregtech:gt.metaitem.01",      11318,  "Sunnarium Ingot" },
            { "molten.platinum",        "Molten Platinum",                               18432, 144, "gregtech:gt.metaitem.01",      11085,  "Platinum Ingot" },
            { "molten.tritanium",       "Molten Tritanium",                              7200,  144, "gregtech:gt.metaitem.01",      11329,  "Tritanium Ingot" },
            { "molten.titanium",        "Molten Titanium",                               18432, 144, "gregtech:gt.metaitem.01",      11028,  "Titanium Ingot" },
            --{ "molten.",        "Molten ",         18432, 144, "gregtech:gt.metaitem.01",      ,  " Ingot" },
            { "molten.rhodium-plated palladium", "Molten Rhodium-Plated Palladium",      7200,  144, "bartworks:gt.bwMetaGeneratedingot", 88, "Rhodium-Plated Palladium Ingot" },
            { "molten.pikyonium64b",    "Molten Pikyonium 64B",                          18432, 144, "miscutils:itemIngotPikyonium64B",  0,   "Pikyonium 64B Ingot" },
            { "molten.potin",           "Molten Potin",                                  18432, 144, "miscutils:itemIngotPotin",         0,      "Potin Ingot" },
            { "molten.lafiumcompound",  "Molten Lafium Compound",                        7200,  144, "miscutils:itemIngotLafiumCompound", 0,  "Lafium Compound Ingot" },
            { "molten.triniumnaquadahcarbonite",    "Molten Trinium Naquadah Carbonite", 18432, 144, "miscutils:itemIngotTriniumNaquadahCarbonite", 0,"Trinium Naquadah Alloy Carbonite" },
            { "molten.stellite",        "Molten Stellite",                               18432, 144, "miscutils:itemIngotStellite",  0,      "Stellite Ingot" },
            { "ender",                  "Liquid Ender",                                  20000, 250, "minecraft:ender_pearl",        0,      "Ender Pearl" },
            { "obsidian.molten",        "Molten Obsidian",                               18432, 288, "minecraft:obsidian",           0,      "Obsidian" },
            { "molten.arcanite",        "Molten Arcanite",                               7200,  144, "miscutils:itemIngotArcanite",  0,      "Arcanite Ingot" },
            { "molten.glass",           "Molten Glass",                                  18432, 144, "minecraft:glass",              0,      "Glass" },
            { "molten.redstone",        "Molten Redstone",                               18432, 144, "minecraft:redstone",           0,      "Redstone" },
            { "molten.iron",            "Molten Iron",                                   18432, 144, "minecraft:iron_ingot",         0,      "Iron Ingot" },
            { "molten.blaze",           "Molten Blaze",                                  18432, 144, "minecraft:blaze_powder",       0,      "Blaze Powder" },
            { "molten.glowstone",       "Molten Glowstone",                              18432, 144, "minecraft:glowstone_dust",     0,      "Glowstone dust" }
        }
    local ret_config = {}

    for i, req in ipairs(fluids_config) do
        if #req < 7 or req[1] == nil or req[5] == nil then
            errorExit("Incorect config on line: ", req)
            return
        end

        ret_config[req[1]] = {
            flabel = req[2],
            famnt = req[3],
            api = req[4],
            iname = req[5],
            idmg = req[6] or 0,
            ilabel = req[7]
        }
    end

    return ret_config
end

function main()
    precraft_fluids_config = init_config()
    init()
    init_gui()

    local resetBColor, resetFColor = gpu.getBackground(), gpu.getForeground()
    local background = {}

    table.insert(background, event.listen("key_up", function (key, address, char)
        if char == string.byte('q') then
            event.push('exit')
        end
    end))
    -- table.insert(background, event.listen("touch", failFast(click)))
    table.insert(background, event.timer(craftingCheckInterval, failFast(check_fluid), math.huge))
    table.insert(background, thread.create(failFast(transfer_items_to_craft)))
    table.insert(background, event.timer(updateGuiInterval, failFast(update_gui), math.huge))

    local _, err = event.pull("exit")

    for _, b in ipairs(background) do
        if type(b) == 'table' and b.kill then
            b:kill()
        else
            event.cancel(b)
        end
    end

    gpu.setBackground(resetBColor)
    gpu.setForeground(resetFColor)
    clear_screen()

    if err then
        io.stderr:write(err)
        os.exit(1)
    else
        os.exit(0)
    end
end

function failFast(fn)
    return function(...)
        local res = table.pack(xpcall(fn, debug.traceback, ...))
        if not res[1] then
            event.push('exit', res[2])
        end
        return table.unpack(res, 2)
    end
end

function errorExit(...)
    out(...)
    event.push('exit')
end

-- function click(_, _, screenX, screenY, button, playerName)
--     print("click on ", screenX, screenY, button, playerName)
-- end

----------------------- DEBUG ---------------------------

function object_to_string(level, object)
    local function get_tabs(num)
      local msg = ""
      for i = 0, num do  msg = msg .. "  " end
      return msg
    end
  
    if level == nil then level = 0 end
  
    local message = " "
  
    if object == nil then
      message = message .. "nil"
    elseif type(object) == "boolean" or type(object) == "number" then
      message = message .. tostring(object) end
    if type(object) == "string" then
      message = message..object end
    if type(object) == "function" then
      message = message.."\"__function\"" end
    if type(object) == "table" then
      if level <= d_limit then
        message = message .. "\n" .. get_tabs(level) .. "{\n"
        for key, next_object in pairs(object) do
          message = message .. get_tabs(level + 1) .. "\"" .. key .. "\"" .. ":" .. object_to_string(level + 1, next_object) .. ",\n";
        end
        message = message .. get_tabs(level) .. "}"
      else
        message = message .. "\"" .. "__table" .. "\""
      end
    end
    return message
  end
  
  function rec_obj_to_string(object, ...)
    arg = {...}
    if #arg > 0 then
      return object_to_string(0, object) .. rec_obj_to_string(...)
    else
      return object_to_string(0, object)
    end
  end

  function out(...)
    local message = rec_obj_to_string(...)
    print(message)
  end

----------------------- LOOP ---------------------------

function transfer_items_to_craft()
    while true do
        local _, conf_data, int_slot_num, liq_amnt_in_me = event.pull('transfer_items_to_craft')
        local item = tr.getStackInSlot(intface_side, int_slot_num)

        if item and item.size > 0 and item.name == conf_data.iname and item.damage == conf_data.idmg then
            local ext_size = tr.getInventorySize(fluid_extr_side)
            local free_slot = nil
            local cnt = (conf_data.famnt - liq_amnt_in_me) / conf_data.api + 1

            -- find selected items or free slot in extractor or input bus
            for i = 1, ext_size do
                item = tr.getStackInSlot(fluid_extr_side, i)

                if item == nil then
                    if free_slot == nil then
                        free_slot = i
                    end
                elseif item.name == conf_data.iname and item.damage == conf_data.idmg then
                    free_slot = i
                    cnt = cnt - item.size
                    break
                end
            end
            if free_slot == nil then
                -- red crafting status, free_slot in extractor not found
                update_status(liq_name, 0)
            elseif cnt then
                -- yellow crafting status
                update_status(liq_name, 1)
                tr.transferItem(intface_side, fluid_extr_side, cnt, int_slot_num, free_slot)
            end
        else
            -- red crafting status, not resource for crafting fluid
            update_status(liq_name, 0)
        end
    end
end

function check_fluid()
    local fluids = mei.getFluidsInNetwork()
    local me_int_cfg = {}

    for i = 1,9 do
        item = mei.getInterfaceConfiguration(i)

        if item then
            me_int_cfg[(item.name or "") .. ":" .. math.floor(item.damage)] = i
        end
    end

    for liq_name, conf_data in pairs(precraft_fluids_config) do
        -- find fluid in ME network
        liq_amnt_in_me = 0
        for _, liq in pairs(fluids) do
            if type(liq) == "table" and liq.name == liq_name then
                liq_amnt_in_me = liq.amount
            end
        end

        -- find items for crafting fluid in ME network
        int_slot_num = me_int_cfg[conf_data.iname .. ":" .. conf_data.idmg]

        if liq_amnt_in_me < conf_data.famnt then
            if int_slot_num == nil then
                -- find free slot and set item required for prodution fluid
                local free_slot = nil
                for i = 1,9 do
                    slot = mei.getInterfaceConfiguration(i)
                    if slot == nil then
                        free_slot = i
                        break
                    end
                end

                if free_slot then
                    slot = get_database_slot(conf_data.iname, conf_data.idmg)

                    if slot then
                        mei.setInterfaceConfiguration(free_slot, db.address, slot, 64)
                    else
                        -- orange crafting status, free_slot in interface not found
                        update_status(liq_name, 2)
                        -- print("Failed to install item to the interface: ", conf_data.ilabel)
                    end
                end
            else
                event.push('transfer_items_to_craft', conf_data, int_slot_num, liq_amnt_in_me)
            end
        else
            -- reset interface configuration if fluid level is normal
            if int_slot_num then
                --update_status(liq_name, 3)
                mei.setInterfaceConfiguration(int_slot_num)
            end
        end
    end
end

-------------------- SUPPORTED FUNCTION -----------------------

function get_database_slot(item_name, item_dmg)
    slot = database_size

    for i = 1, database_size - 1 do
        local item = db.get(i)

        if item == nil then
            slot = i
            break
        elseif item.name == item_name and item.damage == (item_dmg or 0) then
            return i
        end
    end

    db.clear(slot)
    local item = {name = item_name, damage = item_dmg or 0}
    local status = mei.getItemsInNetwork(item)

    if status then
        if status["n"] == 1 then
            status = mei.store(item, db.address, slot)
        else
            print("More then one items found in ME: ", item_name, " damage: ", item_dmg)
            status = nil
        end
    else
        print("Item not found in Me network: ", item_name, " damage: ", item_dmg)
    end

    if status then
        return slot
    else
        return 0
    end
end

function init()
    mei = link_component("me_interface")
    tr = link_component("transposer")
    db = link_component("database")
    gpu = link_component("gpu")

    if mei == nil then
        errorExit("ME Interface not found")
        return
    elseif tr == nil then
        errorExit("Transposer not found")
        return
    elseif db == nil then
        errorExit("Database upgrade in Adapter not found")
        return
    end

    if intface_side == nil then
        intface_side = detect_interface_side()
        if intface_side == nil then
            errorExit("Interface not found or not located next to the Transposer")
            return
        end
    end

    if fluid_extr_side == nil then
        fluid_extr_side = detect_not_interface_side()
        if fluid_extr_side == nil then
            errorExit("Fluid extraction not found or not located next to the Transposer")
            return
        end
    end

    print("Check correct database size: ", database_size, "...")
    db.get(database_size)

    print("intface_side", intface_side)
    print("extraction_side", fluid_extr_side)
end

function link_component(comp_name)
    components = component.list(comp_name)
    ret_comp = nil
    for addr, name in pairs(components) do
        if ret_comp == nil then
            ret_comp = component.proxy(addr)
            print("Link component " .. name .. " to address " .. ret_comp.address)
        else
            print("Warning: More then one component " .. name .. " found. Used: " .. ret_comp.address)
        end
    end
    return ret_comp
end

function detect_interface_side()
    for i = 0,5 do
        local name = tr.getInventoryName(i)
        if name == "tile.appliedenergistics2.BlockInterface" then
            return i
        end
    end
end

function detect_not_interface_side()
    for i = 0,5 do
        local name = tr.getInventoryName(i)
        if name ~= nil and name ~= "tile.appliedenergistics2.BlockInterface" then
            return i
        end
    end
end

function get_fluid_by_index(index)
    local i = 1
    for k, v in pairs(precraft_fluids_config) do
        if i == index then
            return k
        end
        i = i + 1
    end

    return nil
end

-------------------- GUI FUNCTION -----------------------

function validate_coordinate(cord, max_limit)
    if cord < 1 then
        cord = 1
        print("Coordinate out of range")
    elseif cord > max_limit then
        cord = max_limit
        print("Coordinate out of range")
    end

    return cord
end

function create_window(x1, y1, x2, y2, color)
    local max_x, max_y = gpu.getResolution()
    local win = {
        x1 = math.floor(validate_coordinate(x1, max_x)),
        x2 = math.floor(validate_coordinate(x2, max_x)),
        y1 = math.floor(validate_coordinate(y1, max_y)),
        y2 = math.floor(validate_coordinate(y2, max_y)),
        color = color
    }

    return win
end

function draw_window(win)
    if not win then
        return
    end

    if win["y2"] - win["y1"] < 4 then
        out("small y size for window:", win["y2"] - win["y1"])
    end

    local resetBColor, resetFColor = gpu.getBackground(), gpu.getForeground()
    gpu.setForeground(win["color"])

    gpu.set(win["x1"], win["y1"], unicode.char(9556)) -- ╔
    gpu.set(win["x1"], win["y2"], unicode.char(9562)) -- ╚
    gpu.set(win["x2"], win["y1"], unicode.char(9559)) -- ╗
    gpu.set(win["x2"], win["y2"], unicode.char(9565)) -- ╝

    gpu.set(win["x1"], win["y1"] + 2, unicode.char(9567)) -- ╟
    gpu.set(win["x2"], win["y1"] + 2, unicode.char(9570)) -- ╢

    
    for i = win["x1"] + 1, win["x2"] - 1 do
        gpu.set(i, win["y1"], unicode.char(9552)) -- ═
    end

    for i = win["x1"] + 1, win["x2"] - 1 do
        gpu.set(i, win["y2"], unicode.char(9552)) -- ═
    end

    for i = win["y1"] + 1, win["y2"] - 1 do
        gpu.set(win["x1"], i, unicode.char(9553)) -- ║
    end

    for i = win["y1"] + 1, win["y2"] - 1 do
        gpu.set(win["x2"], i, unicode.char(9553)) -- ║
    end

    for i = win["x1"] + 1, win["x2"] - 1 do
        gpu.set(i, win["y1"] + 2, unicode.char(9472)) -- ─
    end

    gpu.setBackground(resetBColor)
    gpu.setForeground(resetFColor)
end

function draw_title(win, text)
    local len = win["x2"] - win["x1"] - 3

    if len <= 0 then
        return
    end
    local text = string.sub(text, 1, math.min(string.len(text), len))
    text = text .. string.rep(" ", len - string.len(text))
    gpu.set(win["x1"] + 2, win["y1"] + 1, text)
end

function draw_text(win, text)
    local len = win["x2"] - win["x1"] - 3

    if len <= 0 then
        return
    end
    local text = string.sub(text, 1, math.min(string.len(text), len))
    text = text .. string.rep(" ", len - string.len(text))
    gpu.set(win["x1"] + 2, win["y1"] + 3, text)
end

function clear_screen()
    local x, y = gpu.getResolution()
    gpu.fill(1, 1, x, y, " ")
end

-- status: 0 - need craft, 1 - craft in progress, 2 - me intarface is full, 3 - normal
function update_status(fname, status)
    fluid_index = 0

    for i = 1, #cur_fluids do
        if cur_fluids[i]["name"] == fname then
            fluid_index = i
        end
    end

    if fluid_index == 0 then
        for i = #cur_fluids, 2, -1 do
            cur_fluids[i] = cur_fluids[i - 1]
        end

        cur_fluids[1] = {
            name = fname,
            status = status
        }
    else
        cur_fluids[fluid_index]["status"] = status
    end

    update_gui()
end

function update_color(win, status)
    if status == 0 then
        win["color"] = 0xff0000
    elseif status == 1 then
        win["color"] = 0xffff00
    elseif status == 2 then
        win["color"] = 0xffa500
    elseif status == 3 then
        win["color"] = 0x00ff00
    else
        win["color"] = 0x0000ff
    end
end

function update_gui()
    local fluids = mei.getFluidsInNetwork()

    for i, win in ipairs(wins) do
        local fluid = precraft_fluids_config[cur_fluids[i]["name"]]

        if fluid then
            -- find fluid in ME network
            liq_amnt_in_me = 0
            for _, liq in pairs(fluids) do
                if type(liq) == "table" and liq.name == cur_fluids[i]["name"] then
                    liq_amnt_in_me = math.floor(liq.amount)
                end
            end

            update_color(win, cur_fluids[i]["status"])
            draw_window(win)
            draw_title(win, fluid["flabel"])
            draw_text(win, liq_amnt_in_me .. " / " .. fluid["famnt"])
        end
    end
end

function init_gui()
    local x, y = gpu.maxResolution()
    gpu.setResolution(x, y)
    clear_screen()

    for i = 1, gui_table_on_line do
        local x1 = x / gui_table_on_line * (i - 1) + 2
        local x2 = x / gui_table_on_line * i - 1
        local gui_table_on_colomin = math.floor((y - 1) / 6)

        for j = 1, gui_table_on_colomin do
            local y1 = y / gui_table_on_colomin * (j - 1) + 1
            local y2 = y1 + 4
            local indx = (i - 1) * gui_table_on_colomin + j
            wins[indx] = create_window(x1, y1, x2, y2, 0xff00ff)
            cur_fluids[indx] = {
                name = get_fluid_by_index(indx),
                status = 3 -- normal
            }
        end
    end

    update_gui()
end

main()