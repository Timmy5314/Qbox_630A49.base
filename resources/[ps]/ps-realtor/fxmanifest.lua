fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'

game "gta5"

author "Xirvin & Project Sloth"
version '2.1.0'

description 'Realtor job for ps-housing (Qbox)'
repository 'Project-Sloth/ps-realtor'

lua54 'yes'

ui_page 'html/index.html'
-- ui_page 'http://localhost:3000/' --for dev

shared_script {
  '@ox_lib/init.lua',
  "shared/**",
}

server_script {
  "server/**",
}

client_script {
  'client/**',
}

files {
  'html/**',
}

dependencies {
  'ox_lib',
  'ps-housing',
  'fivem-freecam',
}
