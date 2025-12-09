fx_version 'adamant'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Shiw Scripts'
description 'shiw_walkspeed - Adjustable walking speed for RSG'
version '2.0.0'

client_scripts {
    'client.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

dependencies {
    'rsg-core',
    'ox_lib'
}