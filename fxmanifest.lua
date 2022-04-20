fx_version "adamant"
game "gta5"
version "2.4.0"

server_scripts {
    "@async/async.lua",
    "@mysql-async/lib/MySQL.lua",
    "@es_extended/locale.lua",
    "config.lua",
    "server/esx_shop-sv.lua"
}

client_scripts {
    "@es_extended/locale.lua",
    "config.lua",
    "client/esx_shop-cl.lua"
}
