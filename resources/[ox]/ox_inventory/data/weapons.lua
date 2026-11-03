return {
	-- [OUR CHANGE] Pillar C (grounded world). Removed so they can't exist on the server: sci-fi and joke weapons
	-- (ray guns, railguns, EMP and snowball launchers, snowballs, candy cane, stone hatchet, battle axe, hazard and
	-- fertilizer cans, firework launcher), heavy military weapons and explosives (minigun, RPG, homing, grenade and
	-- compact launchers, frag grenades, sticky bombs, proximity mines, pipe bombs, machine guns, .50 cal sniper) and
	-- their ammo, and every gun skin except wood, metal, camo, brushstroke and woodland. See docs/core-changes.md
	Weapons = {
		['WEAPON_BATTLERIFLE'] = {
			label = 'Battle Rifle',
			weight = 3300,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
		},

		['WEAPON_TECPISTOL'] = {
			label = 'Tactical SMG',
			weight = 1500,
			durability = 0.075,
			ammoname = 'ammo-9',
		},

		['WEAPON_ADVANCEDRIFLE'] = {
			label = 'Advanced Rifle',
			weight = 3100,
			durability = 0.03,
			ammoname = 'ammo-rifle',
		},

		['WEAPON_APPISTOL'] = {
			label = 'AP Pistol',
			weight = 1400,
			durability = 0.1,
			ammoname = 'ammo-9',
		},

		['WEAPON_ASSAULTRIFLE'] = {
			label = 'Assault Rifle',
			weight = 4500,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
		},

		['WEAPON_ASSAULTRIFLE_MK2'] = {
			label = 'Assault Rifle MK2',
			weight = 2950,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
		},

		['WEAPON_ASSAULTSHOTGUN'] = {
			label = 'Assault Shotgun',
			weight = 5200,
			durability = 0.05,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_ASSAULTSMG'] = {
			label = 'Assault SMG',
			weight = 2900,
			durability = 0.05,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_BALL'] = {
			label = 'Ball',
			weight = 149,
			throwable = true,
		},

		['WEAPON_BAT'] = {
			label = 'Bat',
			weight = 1134,
			durability = 0.1,
		},

		['WEAPON_BOTTLE'] = {
			label = 'Bottle',
			weight = 350,
			durability = 0.1,
		},

		['WEAPON_BULLPUPRIFLE'] = {
			label = 'Bullpup Rifle',
			weight = 2900,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_BULLPUPRIFLE_MK2'] = {
			label = 'Bullpup Rifle MK2',
			weight = 2900,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_BULLPUPSHOTGUN'] = {
			label = 'Bullpup Shotgun',
			weight = 3100,
			durability = 0.2,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_BZGAS'] = {
			label = 'BZ Gas',
			weight = 600,
			throwable = true,
		},

		['WEAPON_CARBINERIFLE'] = {
			label = 'Carbine Rifle',
			weight = 3100,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_CARBINERIFLE_MK2'] = {
			label = 'Carbine Rifle MK2',
			weight = 3000,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_CERAMICPISTOL'] = {
			label = 'Ceramic Pistol',
			weight = 800,
			durability = 0.2,
			ammoname = 'ammo-9'
		},

		['WEAPON_PISTOLXM3'] = {
			label = 'WM 29 Pistol',
			weight = 969,
			durability = 0.2,
			ammoname = 'ammo-9'
		},

		['WEAPON_COMBATPDW'] = {
			label = 'Combat PDW',
			weight = 2300,
			durability = 0.1,
			ammoname = 'ammo-9'
		},

		['WEAPON_COMBATPISTOL'] = {
			label = 'Combat Pistol',
			weight = 785,
			durability = 0.2,
			ammoname = 'ammo-9'
		},

		['WEAPON_COMBATSHOTGUN'] = {
			label = 'Combat Shotgun',
			weight = 4400,
			durability = 0.2,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_COMPACTRIFLE'] = {
			label = 'Compact Rifle',
			weight = 3600,
			durability = 0.05,
			ammoname = 'ammo-rifle2'
		},

		['WEAPON_CROWBAR'] = {
			label = 'Crowbar',
			weight = 2500,
			durability = 0.1,
		},

		['WEAPON_DAGGER'] = {
			label = 'Dagger',
			weight = 800,
			durability = 0.1,
		},

		['WEAPON_DBSHOTGUN'] = {
			label = 'Double Barrel Shotgun',
			weight = 3175,
			durability = 0.4,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_DOUBLEACTION'] = {
			label = 'Double Action Revolver',
			weight = 940,
			durability = 0.2,
			ammoname = 'ammo-38'
		},

		['WEAPON_FIREEXTINGUISHER'] = {
			label = 'Fire Extinguisher',
			weight = 8616,
            durability = 0.006
		},

		['WEAPON_FLARE'] = {
			label = 'Flare',
			weight = 250,
			throwable = true,
		},

		['WEAPON_FLAREGUN'] = {
			label = 'Flare Gun',
			weight = 1000,
			durability = 0.5,
			ammoname = 'ammo-flare'
		},

		['WEAPON_FLASHLIGHT'] = {
			label = 'Flashlight',
			weight = 125,
			durability = 0.1,
		},

		['WEAPON_GOLFCLUB'] = {
			label = 'Golf Club',
			weight = 330,
			durability = 0.1,
		},

		['WEAPON_GUSENBERG'] = {
			label = 'Gusenberg',
			weight = 4900,
			durability = 0.04,
			ammoname = 'ammo-45'
		},

		['WEAPON_HAMMER'] = {
			label = 'Hammer',
			weight = 1200,
			durability = 0.1,
		},

		['WEAPON_HATCHET'] = {
			label = 'Hatchet',
			weight = 1000,
			durability = 0.1,
		},

		['WEAPON_HEAVYRIFLE'] = {
			label = 'Heavy Rifle',
			weight = 3300,
			durability = 0.2,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_METALDETECTOR'] = {
			label = 'Metal Detector',
			weight = 1200,
		},

		['WEAPON_HEAVYPISTOL'] = {
			label = 'Heavy Pistol',
			weight = 1100,
			durability = 0.2,
			ammoname = 'ammo-45'
		},

		['WEAPON_HEAVYSHOTGUN'] = {
			label = 'Heavy Shotgun',
			weight = 3600,
			durability = 0.1,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_KNIFE'] = {
			label = 'Knife',
			weight = 300,
			durability = 0.1,
		},

		['WEAPON_KNUCKLE'] = {
			label = 'Knuckle Dusters',
			weight = 300,
			durability = 0.1,
		},

		['WEAPON_MACHETE'] = {
			label = 'Machete',
			weight = 1000,
			durability = 0.1,
		},

		['WEAPON_MACHINEPISTOL'] = {
			label = 'Machine Pistol',
			weight = 1400,
			durability = 0.05,
			ammoname = 'ammo-9'
		},

		['WEAPON_MARKSMANPISTOL'] = {
			label = 'Marksman Pistol',
			weight = 1588,
			durability = 0.5,
			ammoname = 'ammo-22'
		},

		['WEAPON_MARKSMANRIFLE'] = {
			label = 'Marksman Rifle',
			weight = 7500,
			durability = 0.4,
			ammoname = 'ammo-sniper'
		},

		['WEAPON_MARKSMANRIFLE_MK2'] = {
			label = 'Marksman Rifle MK2',
			weight = 4000,
			durability = 0.4,
			ammoname = 'ammo-sniper'
		},

		['WEAPON_MICROSMG'] = {
			label = 'Micro SMG',
			weight = 3000,
			durability = 0.1,
			ammoname = 'ammo-45'
		},

		['WEAPON_MILITARYRIFLE'] = {
			label = 'Military Rifle',
			weight = 3600,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_MINISMG'] = {
			label = 'Mini SMG',
			weight = 1270,
			durability = 0.05,
			ammoname = 'ammo-9'
		},

		['WEAPON_MOLOTOV'] = {
			label = 'Molotov',
			weight = 1800,
			throwable = true,
		},

		['WEAPON_MUSKET'] = {
			label = 'Musket',
			weight = 4500,
			durability = 0.5,
			ammoname = 'ammo-musket'
		},

		['WEAPON_NAVYREVOLVER'] = {
			label = 'Navy Revolver',
			weight = 4000,
			durability = 0.2,
			ammoname = 'ammo-44'
		},

		['WEAPON_NIGHTSTICK'] = {
			label = 'Nightstick',
			weight = 1000,
			durability = 0.1,
		},

		['WEAPON_PETROLCAN'] = {
			label = 'Jerry Can',
			weight = 4000,
		},

		['WEAPON_GADGETPISTOL'] = {
			label = 'Perico Pistol',
			weight = 1750,
			durability = 0.1,
			ammoname = 'ammo-9'
		},

		['WEAPON_PISTOL'] = {
			label = 'Pistol',
			weight = 1130,
			durability = 0.1,
			ammoname = 'ammo-9',
		},

		['WEAPON_PISTOL50'] = {
			label = 'Pistol .50',
			weight = 2000,
			durability = 0.1,
			ammoname = 'ammo-50'
		},

		['WEAPON_PISTOL_MK2'] = {
			label = 'Pistol MK2',
			weight = 1000,
			durability = 0.5,
			ammoname = 'ammo-9'
		},

		['WEAPON_POOLCUE'] = {
			label = 'Pool Cue',
			weight = 146,
			durability = 0.1,
		},

		['WEAPON_PUMPSHOTGUN'] = {
			label = 'Pump Shotgun',
			weight = 3400,
			durability = 0.1,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_PUMPSHOTGUN_MK2'] = {
			label = 'Pump Shotgun MK2',
			weight = 3200,
			durability = 0.1,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_REVOLVER'] = {
			label = 'Revolver',
			weight = 2260,
			durability = 0.1,
			ammoname = 'ammo-44'
		},

		['WEAPON_REVOLVER_MK2'] = {
			label = 'Revolver MK2',
			weight = 2600,
			durability = 0.1,
			ammoname = 'ammo-44'
		},

		['WEAPON_SAWNOFFSHOTGUN'] = {
			label = 'Sawn Off Shotgun',
			weight = 2380,
			durability = 0.1,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_SMG'] = {
			label = 'SMG',
			weight = 3084,
			durability = 0.8,
			ammoname = 'ammo-9'
		},

		['WEAPON_SMG_MK2'] = {
			label = 'SMG Mk2',
			weight = 2700,
			durability = 0.05,
			ammoname = 'ammo-9'
		},

		['WEAPON_SMOKEGRENADE'] = {
			label = 'Smoke Grenade',
			weight = 600,
			throwable = true,
		},

		['WEAPON_SNIPERRIFLE'] = {
			label = 'Sniper Rifle',
			weight = 5000,
			durability = 0.5,
			ammoname = 'ammo-sniper'
		},

		['WEAPON_SNSPISTOL'] = {
			label = 'SNS Pistol',
			weight = 465,
			durability = 0.1,
			ammoname = 'ammo-45'
		},

		['WEAPON_SNSPISTOL_MK2'] = {
			label = 'SNS Pistol MK2',
			weight = 465,
			durability = 0.1,
			ammoname = 'ammo-45'
		},

		['WEAPON_SPECIALCARBINE'] = {
			label = 'Special Carbine',
			weight = 3000,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_SPECIALCARBINE_MK2'] = {
			label = 'Special Carbine MK2',
			weight = 3370,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_STUNGUN'] = {
			label = 'Tazer',
			weight = 227,
			durability = 0.1,
		},

		['WEAPON_AUTOSHOTGUN'] = {
			label = 'Sweeper Shotgun',
			weight = 4400,
			durability = 0.05,
			ammoname = 'ammo-shotgun'
		},

		['WEAPON_SWITCHBLADE'] = {
			label = 'Switchblade',
			weight = 300,
			durability = 0.1,
			anim = { 'anim@melee@switchblade@holster', 'unholster', 200, 'anim@melee@switchblade@holster', 'holster', 600 },
		},

		['WEAPON_VINTAGEPISTOL'] = {
			label = 'Vintage Pistol',
			weight = 700,
			durability = 0.1,
			ammoname = 'ammo-9'
		},

		['WEAPON_WRENCH'] = {
			label = 'Wrench',
			weight = 2500,
			durability = 0.1,
		},

		['WEAPON_PRECISIONRIFLE'] = {
			label = 'Precision Rifle',
			weight = 4800,
			durability = 0.4,
			ammoname = 'ammo-sniper'
		},

		['WEAPON_TACTICALRIFLE'] = {
			label = 'Tactical Rifle',
			weight = 3400,
			durability = 0.03,
			ammoname = 'ammo-rifle'
		},

		['WEAPON_TEARGAS'] = {
			label = 'Tear Gas',
			weight = 600,
			throwable = true,
		},
	},

	Components = {
		['at_flashlight'] = {
			label = 'Tactical Flashlight',
			weight = 120,
			type = 'flashlight',
			client = {
				component = {
					`COMPONENT_AT_AR_FLSH`,
					`COMPONENT_AT_AR_FLSH_REH`,
					`COMPONENT_AT_PI_FLSH`,
					`COMPONENT_AT_PI_FLSH_02`,
					`COMPONENT_AT_PI_FLSH_03`,
				},
				usetime = 2500
			}
		},

		['at_suppressor_light'] = {
			label = 'Suppressor',
			weight = 280,
			type = 'muzzle',
			client = {
                image = 'at_suppressor.png',
				component = {
					`COMPONENT_AT_PI_SUPP`,
					`COMPONENT_AT_PI_SUPP_02`,
					`COMPONENT_CERAMICPISTOL_SUPP`,
					`COMPONENT_PISTOLXM3_SUPP`
				},
				usetime = 2500
			}
		},

		['at_suppressor_heavy'] = {
			label = 'Tactical Suppressor',
			weight = 280,
			type = 'muzzle',
			client = {
                image = 'at_suppressor.png',
				component = {
					`COMPONENT_AT_AR_SUPP`,
					`COMPONENT_AT_AR_SUPP_02`,
					`COMPONENT_AT_SR_SUPP`,
					`COMPONENT_AT_SR_SUPP_03`,
				},
				usetime = 2500
			}
		},

		['at_grip'] = {
			label = 'Grip',
			type = 'grip',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_AR_AFGRIP`,
					`COMPONENT_AT_AR_AFGRIP_02`
				},
				usetime = 2500
			}
		},

		['at_barrel'] = {
			label = 'Heavy Barrel',
			type = 'barrel',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_AR_BARREL_02`,
					`COMPONENT_AT_BP_BARREL_02`,
					`COMPONENT_AT_CR_BARREL_02`,
					`COMPONENT_AT_MG_BARREL_02`,
					`COMPONENT_AT_MRFL_BARREL_02`,
					`COMPONENT_AT_SB_BARREL_02`,
					`COMPONENT_AT_SC_BARREL_02`,
					`COMPONENT_AT_SR_BARREL_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_pistol'] = {
			label = 'Extended Pistol Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended.png',
				component = {
					`COMPONENT_APPISTOL_CLIP_02`,
					`COMPONENT_CERAMICPISTOL_CLIP_02`,
					`COMPONENT_COMBATPISTOL_CLIP_02`,
					`COMPONENT_HEAVYPISTOL_CLIP_02`,
					`COMPONENT_PISTOL_CLIP_02`,
					`COMPONENT_PISTOL_MK2_CLIP_02`,
					`COMPONENT_PISTOL50_CLIP_02`,
					`COMPONENT_SNSPISTOL_CLIP_02`,
					`COMPONENT_SNSPISTOL_MK2_CLIP_02`,
					`COMPONENT_VINTAGEPISTOL_CLIP_02`,
                    `COMPONENT_TECPISTOL_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_smg'] = {
			label = 'Extended SMG Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended.png',
				component = {
					`COMPONENT_ASSAULTSMG_CLIP_02`,
					`COMPONENT_COMBATPDW_CLIP_02`,
					`COMPONENT_MACHINEPISTOL_CLIP_02`,
					`COMPONENT_MICROSMG_CLIP_02`,
					`COMPONENT_MINISMG_CLIP_02`,
					`COMPONENT_SMG_CLIP_02`,
					`COMPONENT_SMG_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_shotgun'] = {
			label = 'Extended Shotgun Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_ASSAULTSHOTGUN_CLIP_02`,
					`COMPONENT_HEAVYSHOTGUN_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_rifle'] = {
			label = 'Extended Rifle Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_ADVANCEDRIFLE_CLIP_02`,
					`COMPONENT_ASSAULTRIFLE_CLIP_02`,
					`COMPONENT_ASSAULTRIFLE_MK2_CLIP_02`,
					`COMPONENT_BULLPUPRIFLE_CLIP_02`,
					`COMPONENT_BULLPUPRIFLE_MK2_CLIP_02`,
					`COMPONENT_CARBINERIFLE_CLIP_02`,
					`COMPONENT_CARBINERIFLE_MK2_CLIP_02`,
					`COMPONENT_COMPACTRIFLE_CLIP_02`,
					`COMPONENT_HEAVYRIFLE_CLIP_02`,
					`COMPONENT_MILITARYRIFLE_CLIP_02`,
					`COMPONENT_SPECIALCARBINE_CLIP_02`,
					`COMPONENT_SPECIALCARBINE_MK2_CLIP_02`,
					`COMPONENT_TACTICALRIFLE_CLIP_02`,
					`COMPONENT_BATTLERIFLE_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_mg'] = {
			label = 'Extended MG Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_GUSENBERG_CLIP_02`,
					`COMPONENT_MG_CLIP_02`,
					`COMPONENT_COMBATMG_CLIP_02`,
					`COMPONENT_COMBATMG_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_sniper'] = {
			label = 'Extended Sniper Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_HEAVYSNIPER_MK2_CLIP_02`,
					`COMPONENT_MARKSMANRIFLE_CLIP_02`,
					`COMPONENT_MARKSMANRIFLE_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_drum_smg'] = {
			label = 'SMG Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_COMBATPDW_CLIP_03`,
					`COMPONENT_MACHINEPISTOL_CLIP_03`,
					`COMPONENT_SMG_CLIP_03`,
				},
				usetime = 2500
			}
		},

		['at_clip_drum_shotgun'] = {
			label = 'Shotgun Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_HEAVYSHOTGUN_CLIP_03`
				},
				usetime = 2500
			}
		},

		['at_clip_drum_rifle'] = {
			label = 'Rifle Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_ASSAULTRIFLE_CLIP_03`,
					`COMPONENT_COMPACTRIFLE_CLIP_03`,
					`COMPONENT_CARBINERIFLE_CLIP_03`,
					`COMPONENT_SPECIALCARBINE_CLIP_03`,
				},
				usetime = 2500
			}
		},

		['at_compensator'] = {
			label = 'Compensator',
			type = 'muzzle',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_PI_COMP`,
					`COMPONENT_AT_PI_COMP_02`,
					`COMPONENT_AT_PI_COMP_03`
				},
				usetime = 2500
			}
		},

		['at_scope_macro'] = {
			label = 'Macro Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MACRO`,
					`COMPONENT_AT_SCOPE_MACRO_02`,
					`COMPONENT_AT_SCOPE_MACRO_MK2`,
					`COMPONENT_AT_SCOPE_MACRO_02_MK2`,
					`COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_small'] = {
			label = 'Small Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_SMALL`,
					`COMPONENT_AT_SCOPE_SMALL_02`,
					`COMPONENT_AT_SCOPE_SMALL_MK2`,
					`COMPONENT_AT_SCOPE_SMALL_SMG_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_medium'] = {
			label = 'Medium Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MEDIUM`,
					`COMPONENT_AT_SCOPE_MEDIUM_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_large'] = {
			label = 'Large Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_LARGE_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_advanced'] = {
			label = 'Advanced Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MAX`
				},
				usetime = 2500
			}
		},

		['at_scope_nv'] = {
			label = 'NV Scope',
			type = 'sight',
			weight = 420,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_NV`
				},
				usetime = 2500
			}
		},

		['at_scope_thermal'] = {
			label = 'Thermal Scope',
			type = 'sight',
			weight = 420,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_THERMAL`
				},
				usetime = 2500
			}
		},

		['at_scope_holo'] = {
			label = 'Holographic Sight',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_PI_RAIL`,
					`COMPONENT_AT_PI_RAIL_02`,
					`COMPONENT_AT_SIGHTS`,
					`COMPONENT_AT_SIGHTS_SMG`
				},
				usetime = 2500
			}
		},

		['at_muzzle_flat'] = {
			label = 'Flat Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_01`
				},
				usetime = 2500
			}
		},

		['at_muzzle_tactical'] = {
			label = 'Tactical Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_02`
				},
				usetime = 2500
			}
		},

		['at_muzzle_fat'] = {
			label = 'Fat Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_03`
				},
				usetime = 2500
			}
		},

		['at_muzzle_precision'] = {
			label = 'Precision Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_04`
				},
				usetime = 2500
			}
		},

		['at_muzzle_heavy'] = {
			label = 'Heavy Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_05`
				},
				usetime = 2500
			}
		},

		['at_muzzle_slanted'] = {
			label = 'Slanted Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_06`
				},
				usetime = 2500
			}
		},

		['at_muzzle_split'] = {
			label = 'Split Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_07`
				},
				usetime = 2500
			}
		},

		['at_muzzle_squared'] = {
			label = 'Squared Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_08`
				},
				usetime = 2500
			}
		},

		['at_muzzle_bell'] = {
			label = 'Bell Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_09`
				},
				usetime = 2500
			}
		},

		['at_skin_wood'] = {
			label = 'Wood Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_HEAVYPISTOL_VARMOD_LUXE`,
					`COMPONENT_SNIPERRIFLE_VARMOD_LUXE`,
					`COMPONENT_SNSPISTOL_VARMOD_LOWRIDER`
				},
				usetime = 2500
			}
		},

		['at_skin_metal'] = {
			label = 'Metal Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE`,
					`COMPONENT_APPISTOL_VARMOD_LUXE`,
					`COMPONENT_BULLPUPRIFLE_VARMOD_LOW`,
					`COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE`,
					`COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER`
				},
				usetime = 2500
			}
		},

		['at_skin_camo'] = {
			label = 'Camo Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO`,
					`COMPONENT_COMBATMG_MK2_CAMO`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO`,
					`COMPONENT_PISTOL_MK2_CAMO`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO`,
					`COMPONENT_REVOLVER_MK2_CAMO`,
					`COMPONENT_SMG_MK2_CAMO`,
					`COMPONENT_SNSPISTOL_MK2_CAMO`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO`,
				},
				usetime = 2500
			}
		},

		['at_skin_brushstroke'] = {
			label = 'Brushstroke Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_02`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_02`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_02`,
					`COMPONENT_COMBATMG_MK2_CAMO_02`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_02`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_02`,
					`COMPONENT_PISTOL_MK2_CAMO_02`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_02`,
					`COMPONENT_REVOLVER_MK2_CAMO_02`,
					`COMPONENT_SMG_MK2_CAMO_02`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_02`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_02`,
				},
				usetime = 2500
			}
		},

		['at_skin_woodland'] = {
			label = 'Woodland Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_03`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_03`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_03`,
					`COMPONENT_COMBATMG_MK2_CAMO_03`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_03`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_03`,
					`COMPONENT_PISTOL_MK2_CAMO_03`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_03`,
					`COMPONENT_REVOLVER_MK2_CAMO_03`,
					`COMPONENT_SMG_MK2_CAMO_03`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_03`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_03`,
				},
				usetime = 2500
			}
		},

	},

	Ammo = {
		['ammo-22'] = {
			label = '.22 Long Rifle',
			weight = 3,
		},

		['ammo-38'] = {
			label = '.38 LC',
			weight = 15,
		},

		['ammo-44'] = {
			label = '.44 Magnum',
			weight = 16,
		},

		['ammo-45'] = {
			label = '.45 ACP',
			weight = 15,
		},

		['ammo-50'] = {
			label = '.50 AE',
			weight = 45,
		},

		['ammo-9'] = {
			label = '9mm',
			weight = 7,
		},

		['ammo-flare'] = {
			label = 'Flare round',
			weight = 38,
		},

		['ammo-musket'] = {
			label = '.50 Ball',
			weight = 38,
		},

		['ammo-rifle'] = {
			label = '5.56x45',
			weight = 4,
		},

		['ammo-rifle2'] = {
			label = '7.62x39',
			weight = 8,
		},

		['ammo-shotgun'] = {
			label = '12 Gauge',
			weight = 38,
		},

		['ammo-sniper'] = {
			label = '7.62x51',
			weight = 9,
		},

	}
}
