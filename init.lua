-- Minetest Discord Webhook
-- © 2021 activivan

-- Please read readme.md for more information

local http = minetest.request_http_api()
local conf = minetest.settings

if not http then
    minetest.log("error",
        "[Discord Webhook] Can not access HTTP API. Please add this mod to secure.http_mods to grant access")
    return
end

if not conf:get("dcwebhook_url") then
    minetest.log("error", "[Discord Webhook] Discord Webhook URL not set. Please set it in minetest.conf")
    return
end

-- Just doing conf:get_bool("lang", "en") did not work for some reason
if conf:get("lang") then
    lang = conf:get("lang")
else
    lang = "en"
end

local function sendWebhook(data)
    local json = minetest.write_json(data)

    http.fetch({
        url = conf:get("dcwebhook_url"),
        method = "POST",
        extra_headers = {"Content-Type: application/json"},
        data = json
    }, function()
        -- doin nothin
    end)
end

local texts = {
    en = {
        join = "** joined the game",
        leave = "** left the game",
        shutdown = "Server shut down",
        start = "Server started"
    },
    de = {
        join = "** dem Spiel beigetreten",
        leave = "** hat das Spiel verlassen",
        shutdown = "Server heruntergefahren",
        start = "Server gestartet"
    },
    ru = {
        join = "** вошел в игру",
        leave = "** вышел из игры",
        shutdown = "Сервер выключен",
        start = "Сервер запущен"
    },
    nl = {
        join = "** joint het spel",
        leave = "** verliet het spel",
        shutdown = "Server sluit af",
        start = "Server is opgestart"
    },
    fr = {
        join = "** s'est connecté",
        leave = "** est parti",
        shutdown = "Arrêt du serveur",
        start = "Serveur démarré"
    }
}

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()

    local data = {
        content = "\\*\\*\\* **" .. name .. texts[lang].join
    }

    sendWebhook(data)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()

    local data = {
        content =  "\\*\\*\\* **" .. name .. texts[lang].leave
    }

    sendWebhook(data)
end)

minetest.register_on_chat_message(function(name, message)
    sendWebhook({
        content = "<**" .. name .. "**>  " .. message
    })
end)

minetest.register_on_shutdown(function()
    local data = {
        content = nil,
        embeds = {{
            title = texts[lang].shutdown
        }}
    }

    sendWebhook(data)
end)

local function startupMessage()
    local data = {
        content = nil,
        embeds = {{
            title = texts[lang].start,
            -- description = minetest.get_server_status(),
            color = 5793266
        }}
    }

    sendWebhook(data)
end

startupMessage()
