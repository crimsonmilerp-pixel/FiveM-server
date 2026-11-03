return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging
    minOnDutyLogTimeMinutes = 30,
    formatDateTime = '%m-%d-%Y %H:%M',

    -- While the config boss menu creation still works, it is recommended to use the runtime export instead.
    -- Single menu: { coords = ..., size = ..., rotation = ..., type = ... }
    -- Multiple menus: { { coords = ..., size = ..., rotation = ..., type = ... }, { ... }  }
    ---@alias GroupName string
    ---@type table<GroupName, ZoneInfo|ZoneInfo[]>
    menus = {
        -- [OUR CHANGE] The LSPD boss menu (Captain and Chief: hire, promote, fire) is opened by rp_police at the
        -- captain's desk (rp_police/config.lua, stationMarkers), using this resource's OpenBossMenu export.
        -- A spot here too would show two prompts. See docs/core-changes.md
        lostmc = {
            {
                coords = vec3(983.69, -90.92, 74.85),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 39.68,
                type = 'gang',
            },
            {
                coords = vec3(976.2, -100.57, 74.87),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 42.76,
                type = 'gang',
            },
        },
        vagos = {
            coords = vec3(351.18, -2054.92, 22.09),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
    },
}
