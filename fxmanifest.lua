--[[ 
    Author: AussieDropBear
    Desc: Shock collar & comms service for staff 
--]]

fx_version 'cerulean'
game 'gta5'

description 'Shock collar & comms service for staff by aussiedropbear'
author 'AussieDropBear'
version '1.0.0'

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/c_comms.lua',
    'client/c_main.lua'
}

server_scripts {
    'server/s_comms.lua',
    'server/s_main.lua'
}
