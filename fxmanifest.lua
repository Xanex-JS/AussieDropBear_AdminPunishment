--[[
    Author: AussieDropBear
    Desc: Shock collar for niggas who troll staff
--]]

fx_version 'cerulean'
game 'gta5'

description 'Shock collar for niggas who troll staff made by aussiedropbear'
author 'AussieDropBear'
version '1.0.0'

client_script {
    'client/c_main.lua',
}

shared_script {
    '@ox_lib/init.lua'
}

server_script {
    'server/s_main.lua'
}

lua54 'yes'