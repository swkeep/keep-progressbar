--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'keep-progressbar'
description 'Lightweight and customizable progress bar script for FiveM'
version '1.0.0'
author 'swkeep'
repository 'https://github.com/swkeep/keep-progressbar'

ui_page 'html/index.html'

client_scripts {
    -- '@ox_lib/init.lua',
    'lua/config.lua',
    'lua/client.lua',
    'lua/locales/*.lua',
    'lua/provider.lua',
    'lua/examples.lua',
}

server_scripts {
    'lua/server.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/themes.css',
    'html/script.js'
}

provide 'progressbar'
provide 'esx_progressbar'
