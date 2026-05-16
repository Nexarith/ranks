local modname = minetest.get_current_modname()
local worldpath = minetest.get_worldpath()

-- Create ranks folder if it doesn't exist
local ranks_folder = worldpath .. "/ranks"
minetest.mkdir(ranks_folder)

local ranks_file = ranks_folder .. "/ranks.json"
local player_ranks_file = ranks_folder .. "/player_ranks.json"

local ranks = {}          -- rankname -> {color, privs, alias}
local alias_to_rank = {}  -- alias -> rankname
local player_ranks = {}   -- playername -> rankname

-- Load ranks
local function load_ranks()
    local file = io.open(ranks_file, "r")
    if file then
        local data = file:read("*all")
        file:close()
        ranks = minetest.parse_json(data) or {}
    end

    alias_to_rank = {}
    for rankname, def in pairs(ranks) do
        if def.alias then
            alias_to_rank[def.alias] = rankname
        end
    end
end

-- Load player ranks
local function load_player_ranks()
    local file = io.open(player_ranks_file, "r")
    if file then
        local data = file:read("*all")
        file:close()
        player_ranks = minetest.parse_json(data) or {}
    end
end

-- Save functions
local function save_ranks()
    local file = io.open(ranks_file, "w")
    if file then
        file:write(minetest.write_json(ranks, true))
        file:close()
    end
end

local function save_player_ranks()
    local file = io.open(player_ranks_file, "w")
    if file then
        file:write(minetest.write_json(player_ranks, true))
        file:close()
    end
end

load_ranks()
load_player_ranks()

minetest.register_privilege("ranks_admin", {
    description = "Can manage ranks and assign them",
    give_to_singleplayer = true,
    give_to_admin = true,
})

-- Chat formatting with colored |
local function format_chat_message(name, message)
    local rankname = player_ranks[name]
    if rankname and ranks[rankname] then
        local r = ranks[rankname]
        local colored_prefix = minetest.colorize(r.color, rankname .. " |")
        return colored_prefix .. " <" .. name .. "> " .. message
    end
    return "<" .. name .. "> " .. message
end

minetest.register_on_chat_message(function(name, message)
    if message:sub(1,1) == "/" then return false end
    minetest.chat_send_all(format_chat_message(name, message))
    return true
end)

local function update_nametag(player)
    local name = player:get_player_name()
    local rankname = player_ranks[name]
    if rankname and ranks[rankname] then
        local r = ranks[rankname]
        player:set_nametag_attributes({
            text = minetest.colorize(r.color, rankname) .. " " .. name,
            color = r.color
        })
    else
        player:set_nametag_attributes({text = name})
    end
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    update_nametag(player)

    local rankname = player_ranks[name]
    if rankname and ranks[rankname] then
        minetest.set_player_privs(name, ranks[rankname].privs or {})
    end
end)

local function resolve_rank(rank_or_alias)
    return alias_to_rank[rank_or_alias] or (ranks[rank_or_alias] and rank_or_alias)
end

-- ====================== COMMANDS ======================

minetest.register_chatcommand("ranks_create", {
    params = "<rankname> <hexcolor> [alias]",
    description = "Create a new rank",
    privs = {ranks_admin = true},
    func = function(name, param)
        local rankname, color, alias = param:match("^(%S+)%s+(%S+)%s*(.*)$")
        if not rankname or not color then
            return false, "Usage: /ranks_create <rankname> <hexcolor> [alias]"
        end
        if not color:match("^#") then color = "#" .. color end
        if not color:match("^#%x%x%x%x%x%x$") then
            return false, "Invalid color! Use #RRGGBB"
        end
        if ranks[rankname] then
            return false, "Rank already exists!"
        end

        ranks[rankname] = {
            color = color,
            privs = {},
            alias = (alias and alias ~= "") and alias or nil
        }
        if alias and alias ~= "" then
            alias_to_rank[alias] = rankname
        end
        save_ranks()
        return true, "Rank '" .. rankname .. "' created successfully."
    end
})

minetest.register_chatcommand("ranks_priv", {
    params = "<rank> <add|remove|list> [privilege]",
    description = "Manage privileges for a rank",
    privs = {ranks_admin = true},
    func = function(name, param)
        local rank_or_alias, action, priv = param:match("^(%S+)%s+(%S+)%s*(.*)$")
        local rankname = resolve_rank(rank_or_alias)
        if not rankname then
            return false, "Rank '" .. rank_or_alias .. "' does not exist."
        end

        local def = ranks[rankname]
        def.privs = def.privs or {}

        if action == "list" then
            local list = {}
            for p in pairs(def.privs) do table.insert(list, p) end
            return true, "Privileges for " .. rankname .. ": " .. (#list > 0 and table.concat(list, ", ") or "none")
        end

        if not priv or priv == "" then
            return false, "Usage: /ranks_priv <rank> add/remove <privilege>"
        end

        if action == "add" then
            def.privs[priv] = true
            save_ranks()
            return true, "Added '" .. priv .. "' to rank " .. rankname
        elseif action == "remove" then
            def.privs[priv] = nil
            save_ranks()
            return true, "Removed '" .. priv .. "' from rank " .. rankname
        end
        return false, "Invalid action. Use: add, remove, list"
    end
})

minetest.register_chatcommand("ranks", {
    params = "[<player> [<tag|alias>]]",
    description = "Assign or remove a player's rank",
    privs = {ranks_admin = true},
    func = function(name, param)
        local target, tag_or_alias = param:match("^(%S+)%s*(.*)$")

        if not target then
            local list = {}
            for r in pairs(ranks) do table.insert(list, r) end
            return true, "Available ranks: " .. table.concat(list, ", ")
        end

        if not tag_or_alias or tag_or_alias == "" then
            if player_ranks[target] then
                player_ranks[target] = nil
                save_player_ranks()
                local player = minetest.get_player_by_name(target)
                if player then update_nametag(player) end
                return true, "Rank removed from " .. target
            else
                return false, target .. " has no rank."
            end
        end

        local rankname = resolve_rank(tag_or_alias)
        if not rankname then
            return false, "This tag/alias doesn't exist."
        end

        player_ranks[target] = rankname
        save_player_ranks()

        local player = minetest.get_player_by_name(target)
        if player then update_nametag(player) end

        return true, "Gave rank '" .. rankname .. "' to " .. target
    end
})

minetest.register_chatcommand("myranks", {
    description = "Show your current rank",
    func = function(name)
        local rankname = player_ranks[name]
        if rankname then
            local r = ranks[rankname]
            return true, "Your rank: " .. minetest.colorize(r.color, rankname)
        else
            return true, "You have no rank."
        end
    end
})
