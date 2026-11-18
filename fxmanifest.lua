fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pure-whip-police'
description 'Police job for WHIP: departments, duty, gear, arrests, records, fines, prison, dispatch, radio and an MDT in whip_phone'
author 'fozenistaken'
version '0.1.0'

dependencies { 'oxmysql', 'whip_core' }
whip_requires '1.2'

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
    'shared/settings.lua',
    'shared/util.lua',
    'shared/catalogue.lua',
    'shared/records_logic.lua',
    'shared/sentence.lua',
    'shared/evidence_logic.lua',
    'shared/traffic_logic.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/points.lua',
    'server/departments.lua',
    'server/duty.lua',
    'server/licences.lua',
    'server/station.lua',
    'server/gear.lua',
    'server/pay.lua',
    'server/contact.lua',
    'data/penal_code.lua',
    'server/records.lua',
    'server/fines.lua',
    'server/front.lua',
    'server/prison.lua',
    'server/dispatch.lua',
    'server/radio.lua',
    'server/evidence.lua',
    'server/traffic.lua',
    'server/feeds.lua',
    'server/impound.lua',
    'server/k9.lua',
    'server/mdt.lua',
    'server/main.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/pwp_wheel_clamp.ytyp'

ui_page 'html/station/index.html'

client_scripts {
    'client/wardrobe.lua',
    'client/station.lua',
    'client/contact.lua',
    'client/maptools.lua',
    'client/dispatch.lua',
    'client/mdt.lua',
    'client/evidence.lua',
    'client/traffic.lua',
    'client/feeds.lua',
    'client/impound.lua',
    'client/k9.lua',
}

files {
    'stream/pwp_wheel_clamp.ytyp',
    'html/station/index.html',
    'html/station/app.js',
    'html/mdt/module.js',
    'html/mdt/livemap.js',
    'html/shared/bracket.js',
    'html/shared/fonts/*.woff2',
    'html/img/items/*.webp',
    'html/img/tiers/*.webp',
}
