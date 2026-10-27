-- ============================================================
--  rp_goals - client side (runs in each player's game)
--  Shows the goal screens. All saving and rule-checking
--  happens on the server.
-- ============================================================
local config = require 'config'

local flowRunning = false

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function trim(text)
    return ((text or ''):match('^%s*(.-)%s*$'))
end

local function textLength(text)
    return utf8.len(text) or #text
end

local function categoryLabel(id)
    return locale('category.' .. tostring(id))
end

local function categoryOptions()
    local options = {}
    for i, id in ipairs(config.categories) do
        options[i] = { value = id, label = categoryLabel(id) }
    end
    return options
end

---Waits until nothing else is on screen (spawn picker, clothing editor, loading, pause menu).
local function waitForClearScreen()
    Wait(config.startDelay)

    local clearFor = 0
    while clearFor < config.clearScreenTime do
        Wait(250)
        local busy = IsNuiFocused()
            or IsPauseMenuActive()
            or not IsScreenFadedIn()
            or IsPlayerSwitchInProgress()
            or not LocalPlayer.state.isLoggedIn
        clearFor = busy and 0 or clearFor + 250
    end
end

---Checks the answers before sending them. Returns an error message, or nil if fine.
local function findProblem(values)
    local limits = config.limits

    if not values.category then return locale('error.pick_category') end
    if textLength(values.goal) < limits.goal.min then return locale('error.goal_short', limits.goal.min) end
    if textLength(values.reason) < limits.reason.min then return locale('error.reason_short', limits.reason.min) end
    if textLength(values.firstStep) < limits.firstStep.min then return locale('error.step_short', limits.firstStep.min) end
    if textLength(values.goal) > limits.goal.max
        or textLength(values.reason) > limits.reason.max
        or textLength(values.firstStep) > limits.firstStep.max then
        return locale('error.too_long')
    end
end

local function notifyError(message)
    lib.notify({ title = locale('error.title'), description = message, type = 'error', duration = 7000 })
end

-- ------------------------------------------------------------
-- The goal form
-- ------------------------------------------------------------

---Shows the form. Returns the answers, or nil if the player backed out.
local function showForm(prefill, allowCancel)
    local limits = config.limits

    local answers = lib.inputDialog(locale('form.header'), {
        {
            type = 'select',
            label = locale('form.category_label'),
            description = locale('form.category_desc'),
            options = categoryOptions(),
            default = prefill.category,
            required = true,
            icon = 'layer-group',
        },
        {
            type = 'textarea',
            label = locale('form.goal_label'),
            description = locale('form.goal_desc'),
            placeholder = locale('form.goal_placeholder'),
            default = prefill.goal,
            minLength = limits.goal.min,
            maxLength = limits.goal.max,
            autosize = true,
            required = true,
            icon = 'bullseye',
        },
        {
            type = 'textarea',
            label = locale('form.reason_label'),
            description = locale('form.reason_desc'),
            placeholder = locale('form.reason_placeholder'),
            default = prefill.reason,
            minLength = limits.reason.min,
            maxLength = limits.reason.max,
            autosize = true,
            required = true,
            icon = 'heart',
        },
        {
            type = 'input',
            label = locale('form.step_label'),
            description = locale('form.step_desc'),
            placeholder = locale('form.step_placeholder'),
            default = prefill.firstStep,
            minLength = limits.firstStep.min,
            maxLength = limits.firstStep.max,
            required = true,
            icon = 'shoe-prints',
        },
    }, { allowCancel = allowCancel, size = 'lg' })

    if not answers then return end

    return {
        category = answers[1],
        goal = trim(answers[2]),
        reason = trim(answers[3]),
        firstStep = trim(answers[4]),
    }
end

---The full goal flow.
---mode 'create' = required, cannot be skipped. mode 'change' = optional, can back out.
local function runGoalFlow(mode, current)
    if flowRunning then return end
    flowRunning = true

    local creating = mode == 'create'
    if creating then FreezeEntityPosition(cache.ped, true) end

    if creating then
        lib.alertDialog({
            header = locale('intro.header'),
            content = locale('intro.content', config.changeCooldownDays),
            centered = true,
            size = 'lg',
            labels = { confirm = locale('intro.button') },
        })
    end

    local values = {}
    if current then
        values = { category = current.category, goal = current.goal, reason = current.reason, firstStep = current.firstStep }
    end

    while true do
        local answers = showForm(values, not creating)

        if not answers then
            if not creating then break end -- they decided not to change their goal
            -- Creating is required, so the form simply comes back.
        else
            values = answers
            local problem = findProblem(answers)

            if problem then
                notifyError(problem)
            else
                local choice = lib.alertDialog({
                    header = locale('confirm.header'),
                    content = locale('confirm.content', categoryLabel(answers.category), answers.goal, answers.reason, answers.firstStep, config.changeCooldownDays),
                    centered = true,
                    size = 'lg',
                    cancel = true,
                    labels = { confirm = locale('confirm.yes'), cancel = locale('confirm.edit') },
                })

                if choice == 'confirm' then
                    local ok, err, extra = lib.callback.await('rp_goals:server:save', false, {
                        mode = mode,
                        category = answers.category,
                        goal = answers.goal,
                        reason = answers.reason,
                        firstStep = answers.firstStep,
                    })

                    if ok or err == 'already_set' then
                        lib.notify({
                            title = locale(creating and 'done.title' or 'done.changed_title'),
                            description = locale('done.description', answers.firstStep),
                            type = 'success',
                            icon = 'bullseye',
                            duration = 10000,
                        })
                        break
                    end

                    if extra then
                        notifyError(locale('error.' .. err, extra))
                    else
                        notifyError(locale('error.' .. err))
                    end
                    if err == 'cooldown' then break end
                end
            end
        end

        Wait(0)
    end

    if creating then FreezeEntityPosition(cache.ped, false) end
    flowRunning = false
end

-- ------------------------------------------------------------
-- When a character spawns: show the goal screen, or a reminder
-- ------------------------------------------------------------
local function onCharacterLoaded()
    CreateThread(function()
        local mine = lib.callback.await('rp_goals:server:getMine', false)
        if not mine or not mine.loaded then return end
        local goal = mine.goal

        waitForClearScreen()

        if not goal then
            runGoalFlow('create')
        elseif config.reminderOnSpawn then
            lib.notify({
                title = locale('reminder.title'),
                description = locale('reminder.description', goal.goal),
                type = 'inform',
                icon = 'bullseye',
                duration = config.reminderDuration,
            })
        end
    end)
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', onCharacterLoaded)

-- If this resource restarts while someone is already playing, check them too.
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource then return end
    if LocalPlayer.state.isLoggedIn then onCharacterLoaded() end
end)

-- ------------------------------------------------------------
-- /goal : view your own goal (and change it when allowed)
-- ------------------------------------------------------------
RegisterNetEvent('rp_goals:client:openMine', function()
    if GetInvokingResource() then return end -- only the server may open this

    local mine = lib.callback.await('rp_goals:server:getMine', false)
    if not mine or not mine.loaded then return end
    local goal = mine.goal
    if not goal then return runGoalFlow('create') end

    local changeOption
    if goal.canChange then
        changeOption = {
            title = locale('mine.change'),
            description = locale('mine.change_desc', config.changeCooldownDays),
            icon = 'pen',
            onSelect = function() runGoalFlow('change', goal) end,
        }
    else
        changeOption = {
            title = locale('mine.change'),
            description = locale('mine.change_locked', goal.daysLeft),
            icon = 'lock',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'rp_goals_mine',
        title = locale('mine.title'),
        options = {
            { title = goal.goal, description = categoryLabel(goal.category), icon = 'bullseye', readOnly = true },
            { title = locale('mine.why'), description = goal.reason, icon = 'heart', readOnly = true },
            { title = locale('mine.first_step'), description = goal.firstStep, icon = 'shoe-prints', readOnly = true },
            { title = locale('mine.set_on'), description = goal.setOn, icon = 'calendar', readOnly = true },
            changeOption,
        },
    })
    lib.showContext('rp_goals_mine')
end)

-- ------------------------------------------------------------
-- /goals : staff view of everyone online
-- ------------------------------------------------------------
RegisterNetEvent('rp_goals:client:openStaff', function()
    if GetInvokingResource() then return end

    local list = lib.callback.await('rp_goals:server:staffList', false)
    if not list then return notifyError(locale('error.no_permission')) end

    local options = {}
    for _, player in ipairs(list) do
        local goal = player.goal
        options[#options + 1] = {
            title = locale('staff.row_title', player.name, player.id),
            description = goal and ('[%s] %s'):format(categoryLabel(goal.category), goal.goal) or locale('staff.no_goal'),
            icon = goal and 'bullseye' or 'circle-exclamation',
            readOnly = not goal,
            onSelect = goal and function()
                lib.alertDialog({
                    header = locale('staff.detail_header', player.name, player.citizenid),
                    content = locale('staff.detail_content', categoryLabel(goal.category), goal.goal, goal.reason, goal.firstStep, goal.setOn, goal.timesChanged),
                    centered = true,
                    size = 'lg',
                })
                lib.showContext('rp_goals_staff')
            end or nil,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('staff.empty'), readOnly = true }
    end

    lib.registerContext({ id = 'rp_goals_staff', title = locale('staff.title', #list), options = options })
    lib.showContext('rp_goals_staff')
end)
