fx_version 'cerulean'
game 'gta5'

author 'Matula123 / MT Scripts'
description 'QBCore Lottery Script'
version '1.0.0'

shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Ensure you have the MySQL library if you need to use the database
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'qb-core',
    'qb-target'
}
