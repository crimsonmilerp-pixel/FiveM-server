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
        -- [OUR CHANGE] LSPD boss menu (Captain and Chief): hire Cadets, promote, fire.
        -- At the desk in the captain's office, Mission Row ground floor (door just past the front desk).
        -- Nothing shows on the floor: stand on the spot as Captain or Chief and "[E] - Open Boss Management" appears.
        -- (Qbox's old default, 461.45, -986.2, was the back hallway by the roof stairs.) See docs/core-changes.md
        police = {
            coords = vec3(448.4, -973.2, 30.69),
            size = vec3(2.0, 2.0, 2.0),
            rotation = 0.0,
            type = 'job',
        },
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
