-- Minetest Discord Webhook
-- Version v2.1.1

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
    date = defined("dcwebhook.date") or "%d.%m.%Y %H:%M",

    send_chat = conf:get_bool("dcwebhook.send_chat", true),
    send_server_status = conf:get_bool("dcwebhook.send_server_status", true),
    send_joins = conf:get_bool("dcwebhook.send_joins", true),
    send_last_login = conf:get_bool("dcwebhook.send_last_login", false),
    send_leaves = conf:get_bool("dcwebhook.send_leaves", true),
    send_welcomes = conf:get_bool("dcwebhook.send_welcomes", true),
    send_deaths = conf:get_bool("dcwebhook.send_deaths", true),

    name_wrapper = defined("dcwebhook.name_wrapper") or "<**@1**>",
    include_server_status = conf:get_bool("dcwebhook.include_server_status", true),

    startup_text = defined("dcwebhook.startup_text") or texts[lang].startup,
    shutdown_text = defined("dcwebhook.shutdown_text") or texts[lang].shutdown,
    join_text = defined("dcwebhook.join_text") or texts[lang].join,
    last_login_text = defined("dcwebhook.last_login_text") or texts[lang].last_login,
    leave_text = defined("dcwebhook.leave_text") or texts[lang].leave,
    welcome_text = defined("dcwebhook.welcome_text") or texts[lang].welcome,
    death_text = defined("dcwebhook.death_text") or texts[lang].death,

    use_embeds_on_joins = conf:get_bool("dcwebhook.use_embeds_on_joins", true),
    use_embeds_on_leaves = conf:get_bool("dcwebhook.use_embeds_on_leaves", true),
    use_embeds_on_welcomes = conf:get_bool("dcwebhook.use_embeds_on_welcomes", true),
    use_embeds_on_deaths = conf:get_bool("dcwebhook.use_embeds_on_deaths", true),
    use_embeds_on_server_updates = conf:get_bool("dcwebhook.use_embeds_on_server_updates", true),
    notification_prefix = defined("dcwebhook.notification_prefix") or "\\*\\*\\*",

    startup_color = defined("dcwebhook.startup_color") or 5793266,
    shutdown_color = defined("dcwebhook.shutdown_color"),
    join_color = defined("dcwebhook.join_color") or 5763719,
    leave_color = defined("dcwebhook.leave_color") or 15548997,
    welcome_color = defined("dcwebhook.welcome_color") or 5793266,
    death_color = defined("dcwebhook.death_color")
}


local function replace(str, ...)
    local arg = {...}
    return str:gsub("@(.)", function(matched)
        return arg[tonumber(matched)]
    end)
end

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
                content = replace(get.name_wrapper, name) .. "  " .. message
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
        minetest.register_on_joinplayer(function(player, last_login)
            local name = player:get_player_name()

            local data = {}

            if last_login == nil and get.send_welcomes then
                if not get.use_embeds_on_welcomes then
                    data = {
                        content = get.notification_prefix .. " " .. replace(get.welcome_text, name)
                    }
                else
                    data = {
                        content = nil,
                        embeds = {{
                            description = replace(get.welcome_text, name),
                            color = get.welcome_color
                        }}
                    }
                end
            else
                if not get.use_embeds_on_joins then
                    data = {
                        content = get.notification_prefix .. " " .. (get.send_last_login and replace(get.last_login_text, name, os.date(get.date, last_login)) or replace(get.join_text, name))
                    }
                else
                    data = {
                        content = nil,
                        embeds = {{
                            description = get.send_last_login and replace(get.last_login_text, name, os.date(get.date, last_login)) or replace(get.join_text, name),
                            color = get.join_color
                        }}
                    }
                end
            end

            send_webhook(data)
        end)
    end

    if get.send_leaves then
        minetest.register_on_leaveplayer(function(player)
            local name = player:get_player_name()

            local data = {}

            if not get.use_embeds_on_leaves then
                data = {
                    content = get.notification_prefix .. " " .. replace(get.leave_text, name)
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        description = replace(get.leave_text, name),
                        color = get.leave_color
                    }}
                }
            end

            send_webhook(data)
        end)
    end

    if get.send_deaths then
        minetest.register_on_dieplayer(function(player)
            local name = player:get_player_name()

            local data = {}

            if not get.use_embeds_on_deaths then
                data = {
                    content = get.notification_prefix .. " " .. replace(get.death_text, name)
                }
            else
                data = {
                    content = nil,
                    embeds = {{
                        description = replace(get.death_text, name),
                        color = get.death_color
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
