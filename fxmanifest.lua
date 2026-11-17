fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pure-whip-police'
description 'Police job for WHIP: departments, duty, gear, arrests, records, fines, prison, dispatch, radio and an MDT in whip_phone'
author 'fozenistaken'
version '0.1.0'

dependency 'whip_core'
whip_requires '1.2'

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
    'shared/settings.lua',
    'shared/util.lua',
}

server_scripts {
    'server/points.lua',
    'server/departments.lua',
    'server/duty.lua',
    'server/main.lua',
}
