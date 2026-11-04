fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_eup'
description 'Police uniforms: EUP Law & Order 8.3 by the EUP Team, converted to add-on clothing (it replaces no game clothes)'
version '1.0.0'

-- The clothes themselves are in stream/ (FiveM sends every file in it to players automatically).
-- These two files tell the game that a new clothing collection called rp_eup exists.
files {
    'mp_m_freemode_01_rp_eup.meta',
    'mp_f_freemode_01_rp_eup.meta',
}

data_file 'SHOP_PED_APPAREL_META_FILE' 'mp_m_freemode_01_rp_eup.meta'
data_file 'SHOP_PED_APPAREL_META_FILE' 'mp_f_freemode_01_rp_eup.meta'

client_script 'client/check.lua'
