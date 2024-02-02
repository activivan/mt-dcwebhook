-- Minetest Discord Webhook
-- Version v2.0.0

-- Copyright © 2021-2024 activivan

-- PLEASE READ README.md FOR MORE INFORMATION
-- ------------------------------------------


local http = minetest.request_http_api()
local conf = minetest.settings

if not http then
    minetest.log("error",
        "[Discord Webhook] Can not access HTTP API. Please add this mod to secure.http_mods to grant access.")
    return
end

if not conf:get("dcwebhook.url") then
    -- Upgrading from v1.x.x
    if conf:get("dcwebhook_url") then
        conf:set("dcwebhook.url", conf:get("dcwebhook_url"))
        conf:remove("dcwebhook_url")

        if conf:get("lang") then
            conf:set("dcwebhook.lang", conf:get("lang"))
        end

        minetest.log("warning",
            "[Discord Webhook] Setting keys for Discord Webhook URL and language changed. More information in dcwebhook/settingtypes.txt")

        if not conf:write() then
            minetest.log("error", "[Discord Webhook] Failed to migrate setting keys. Please update manually.")
        end
    else
        minetest.log("error", "[Discord Webhook] Discord Webhook URL not set. Please set it in minetest.conf")
        return
    end
end

local function defined(key)
    local val = conf:get(key)
    if val == nil or val == "" or val == " " then
        return nil
    else
        return val
    end
end

local texts = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/texts.lua")
local lang = defined("dcwebhook.lang") or "en"

-- Use default values if not set
local get = {
    send_chat = conf:get_bool("dcwebhook.send_chat", true),
    send_server_status = conf:get_bool("dcwebhook.send_server_status", true),
    send_joins = conf:get_bool("dcwebhook.send_joins", true),
    send_leaves = conf:get_bool("dcwebhook.send_leaves", true),

    name_wrapper = defined("dcwebhook.name_wrapper") or "<**§**>",
    include_server_status = conf:get_bool("dcwebhook.include_server_status", true),

    startup_text = defined("dcwebhook.startup_text") or texts[lang].startup,
    shutdown_text = defined("dcwebhook.shutdown_text") or texts[lang].shutdown,
    join_text = defined("dcwebhook.join_text") or texts[lang].join,
    leave_text = defined("dcwebhook.leave_text") or texts[lang].leave,

    use_embeds_on_connections = conf:get_bool("dcwebhook.use_embeds_on_connections", true),
    use_embeds_on_server_updates = conf:get_bool("dcwebhook.use_embeds_on_server_updates", true),
    notification_prefix = defined("dcwebhook.notification_prefix") or "\\*\\*\\*",
    
    startup_color = defined("dcwebhook.startup_color") or 5793266,
    shutdown_color = defined("dcwebhook.shutdown_color") or nil,
    join_color = defined("dcwebhook.join_color") or 5763719,
    leave_color = defined("dcwebhook.leave_color") or 15548997
}


local function send_webhook(data)
    local json = minetest.write_json(data)

    http.fetch({
        url = conf:get("dcwebhook.url"),
        method = "POST",
        extra_headers = {"Content-Type: application/json"},
        data = json
    }, function()
        -- doin nothin
    end)
end


local function perform_registrations()
    if get.send_chat then
        minetest.register_on_chat_message(function(name, message)
            send_webhook({
                content = get.name_wrapper:gsub("§", name) .. "  " .. message
            })
        end)
    end

    if get.send_server_status then
        minetest.register_on_shutdown(function()
            local data = {}

            if not get.use_embeds_on_server_updates then
                data = {
                    content = get.notification_prefix .. " " .. get.shutdown_text
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        title = get.shutdown_text,
                        color = get.shutdown_color
                    }}
                }
            end

            send_webhook(data)
        end)

        local function startup_message()
            local data = {}

            if not get.use_embeds_on_server_updates then
                data = {
                    content = get.notification_prefix .. " " .. get.startup_text ..
                        (get.include_server_status and " - " .. minetest.get_server_status() or "")
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        title = get.startup_text,
                        description = get.include_server_status and "\\" .. minetest.get_server_status() or nil, -- prefix \\ because Discord interprets description as Markdown
                        color = get.startup_color
                    }}
                }
            end

            send_webhook(data)
        end

        startup_message()
    end

    if get.send_joins then
        minetest.register_on_joinplayer(function(player)
            local name = player:get_player_name()

            local data = {}

            if not get.use_embeds_on_connections then
                data = {
                    content = get.notification_prefix .. " " .. get.join_text:gsub("§", name)
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        description = get.join_text:gsub("§", name),
                        color = get.join_color
                    }}
                }
            end

            send_webhook(data)
        end)
    end

    if get.send_leaves then
        minetest.register_on_leaveplayer(function(player)
            local name = player:get_player_name()

            local data = {}

            if not get.use_embeds_on_connections then
                data = {
                    content = get.notification_prefix .. " " .. get.leave_text:gsub("§", name)
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        description = get.leave_text:gsub("§", name),
                        color = get.leave_color
                    }}
                }
            end

            send_webhook(data)
        end)
    end
end

-- Perform registrations after other mods loaded because
-- * Chat mirroring will work even if there have been overwrites by other mods
-- * Minetest translation service required for startup message

minetest.after(0, function()
    perform_registrations()
end)
