-- ============================================================
--  rp_economy - client side
--  The /finances menu (everyone) and the /treasury menu (staff).
--  The server does all the math; this only shows it.
-- ============================================================

local function money(n)
    n = math.floor(tonumber(n) or 0)
    return (n < 0 and '-$' or '$') .. lib.math.groupdigits(math.abs(n))
end

---"3 days 4 hours", "1 hour 20 minutes", ...
local function duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local days = seconds // 86400
    local hours = (seconds % 86400) // 3600
    local minutes = (seconds % 3600) // 60
    if days >= 2 then return locale('time.days_hours', days, hours) end
    if days == 1 then return locale('time.one_day_hours', hours) end
    if hours >= 2 then return locale('time.hours_minutes', hours, minutes) end
    if hours == 1 then return locale('time.one_hour_minutes', minutes) end
    if minutes >= 2 then return locale('time.minutes', minutes) end
    if minutes == 1 then return locale('time.one_minute') end
    return locale('time.under_a_minute')
end

---A bill line: "label: $amount", or just the label for notes like a missed payment.
local function lineTitle(line)
    local amount = tonumber(line.amount) or 0
    if amount == 0 then return tostring(line.label) end
    return locale('finances.bill_line', tostring(line.label), money(amount))
end

local function lineIcon(line)
    if line.kind == 'loan_missed' or line.kind == 'loan_repossessed' then return 'triangle-exclamation' end
    if line.kind == 'loan_payment' then return 'file-signature' end
    return 'car'
end

-- ------------------------------------------------------------
-- /finances
-- ------------------------------------------------------------
local openFinances

---Pays a loan early ('payoff') or catches up missed payments ('overdue'), after asking.
local function payLoan(loan, mode, amount)
    local answer = lib.alertDialog({
        header = locale('finances.loan_confirm_title', money(amount)),
        content = tostring(loan.label),
        centered = true,
        cancel = true,
    })
    if answer ~= 'confirm' then return lib.showContext('rp_economy_loan_' .. loan.id) end
    local ok, reason = lib.callback.await('rp_economy:server:payLoan', false, loan.id, mode)
    if not ok then
        lib.notify({ description = locale('finances.loan_error_' .. tostring(reason)), type = 'error' })
    end
    openFinances()
end

openFinances = function()
    local data = lib.callback.await('rp_economy:server:finances', false)
    if not data then
        return lib.notify({ description = locale('error.not_loaded'), type = 'error' })
    end

    local options = {}

    -- Bank
    local overdrawn = data.bank < 0
    options[#options + 1] = {
        title = locale('finances.bank', money(data.bank)),
        description = overdrawn and locale('finances.bank_negative_desc', money(data.cash)) or locale('finances.bank_desc', money(data.cash)),
        icon = 'building-columns',
        iconColor = overdrawn and '#e03131' or nil,
        readOnly = true,
    }

    -- Income tax this week
    local week = data.week
    if week.gross > 0 then
        options[#options + 1] = {
            title = locale('finances.tax_week', money(week.gross), money(week.tax)),
            description = locale('finances.tax_week_desc', week.topRate, duration(week.resetsIn)),
            icon = 'receipt',
            readOnly = true,
        }
    else
        options[#options + 1] = {
            title = locale('finances.tax_week_none'),
            description = locale('finances.tax_week_none_desc', duration(week.resetsIn)),
            icon = 'receipt',
            readOnly = true,
        }
    end

    -- Credit score
    local credit = data.credit
    if credit then
        if credit.tier then
            options[#options + 1] = {
                title = locale('finances.credit', credit.score, locale('credit.' .. credit.tier)),
                description = locale('finances.credit_desc', credit.apr),
                icon = 'gauge-high',
                readOnly = true,
            }
        else
            options[#options + 1] = {
                title = locale('finances.credit_none', credit.score),
                description = locale('finances.credit_none_desc'),
                icon = 'gauge-high',
                iconColor = '#e03131',
                readOnly = true,
            }
        end
    end

    -- Loans, each with its own menu to pay early
    for _, loan in ipairs(data.loans or {}) do
        local behind = loan.missed > 0
        local loanMenu = {}
        if behind then
            local overdue = math.min(loan.balance, loan.payment * loan.missed)
            loanMenu[#loanMenu + 1] = {
                title = locale('finances.loan_overdue', money(overdue)),
                description = locale('finances.loan_overdue_desc'),
                icon = 'rotate-left',
                onSelect = function() payLoan(loan, 'overdue', overdue) end,
            }
        end
        loanMenu[#loanMenu + 1] = {
            title = locale('finances.loan_payoff', money(loan.balance)),
            description = locale('finances.loan_payoff_desc'),
            icon = 'circle-check',
            onSelect = function() payLoan(loan, 'payoff', loan.balance) end,
        }
        lib.registerContext({ id = 'rp_economy_loan_' .. loan.id, title = tostring(loan.label), menu = 'rp_economy_finances', options = loanMenu })

        options[#options + 1] = {
            title = locale('finances.loan', tostring(loan.label), money(loan.balance)),
            description = behind
                and locale('finances.loan_desc_missed', loan.missed, data.repoAfter or 3, money(loan.payment), loan.apr)
                or locale('finances.loan_desc', money(loan.payment), loan.made, loan.weeks, loan.apr),
            icon = 'file-signature',
            iconColor = behind and '#e03131' or nil,
            menu = 'rp_economy_loan_' .. loan.id,
        }
    end

    -- Next weekly bills (an estimate: it's worked out again when they're charged)
    local bills = data.bills
    if bills.total > 0 then
        local dueNow = bills.dueIn <= 0
        options[#options + 1] = {
            title = dueNow and locale('finances.next_bills_due') or locale('finances.next_bills', money(bills.total)),
            description = dueNow and locale('finances.next_bills_soon_desc') or locale('finances.next_bills_desc', duration(bills.dueIn)),
            icon = 'file-invoice-dollar',
            readOnly = true,
        }
        for _, line in ipairs(bills.lines) do
            options[#options + 1] = { title = lineTitle(line), icon = lineIcon(line), readOnly = true }
        end
    else
        options[#options + 1] = {
            title = locale('finances.no_bills'),
            description = locale('finances.next_bills_none_desc'),
            icon = 'file-invoice-dollar',
            readOnly = true,
        }
    end

    -- The last bills paid, with the lines in a sub-menu
    local last = data.last
    if last then
        local statement = {}
        for _, line in ipairs(last.lines or {}) do
            statement[#statement + 1] = { title = lineTitle(line), icon = lineIcon(line), readOnly = true }
        end
        statement[#statement + 1] = { title = locale('finances.statement_total', money(last.total)), icon = 'equals', readOnly = true }
        lib.registerContext({
            id = 'rp_economy_statement',
            title = locale('finances.statement_title', duration(last.ago)),
            menu = 'rp_economy_finances',
            options = statement,
        })
        options[#options + 1] = {
            title = locale('finances.last_bills', money(last.total), duration(last.ago)),
            icon = 'clock-rotate-left',
            menu = 'rp_economy_statement',
        }
    else
        options[#options + 1] = { title = locale('finances.last_bills_none'), icon = 'clock-rotate-left', readOnly = true }
    end

    lib.registerContext({ id = 'rp_economy_finances', title = locale('finances.title'), options = options })
    lib.showContext('rp_economy_finances')
end

RegisterNetEvent('rp_economy:client:openFinances', function() openFinances() end)

-- ------------------------------------------------------------
-- /treasury (staff)
-- ------------------------------------------------------------
local function kindLabel(kind)
    local key = 'treasury.kind_' .. tostring(kind)
    local text = locale(key)
    if text == key or not text then return tostring(kind) end
    return text
end

local function addWeek(options, heading, rows)
    options[#options + 1] = { title = heading, icon = 'calendar-week', readOnly = true }
    if #rows == 0 then
        options[#options + 1] = { title = locale('treasury.nothing'), readOnly = true }
        return
    end
    for _, row in ipairs(rows) do
        options[#options + 1] = {
            title = locale('treasury.line', kindLabel(row.kind), money(row.amount)),
            icon = row.amount >= 0 and 'arrow-down' or 'arrow-up',
            iconColor = row.amount >= 0 and '#2f9e44' or '#e03131',
            readOnly = true,
        }
    end
end

RegisterNetEvent('rp_economy:client:openTreasury', function()
    local data = lib.callback.await('rp_economy:server:treasury', false)
    if not data then
        return lib.notify({ description = locale('error.not_staff'), type = 'error' })
    end

    local options = {
        {
            title = locale('treasury.balance', money(data.balance)),
            description = locale('treasury.balance_desc'),
            icon = 'landmark',
            iconColor = data.balance < 0 and '#e03131' or nil,
            readOnly = true,
        },
    }
    addWeek(options, locale('treasury.this_week'), data.thisWeek or {})
    addWeek(options, locale('treasury.last_week'), data.lastWeek or {})

    lib.registerContext({ id = 'rp_economy_treasury', title = locale('treasury.title'), options = options })
    lib.showContext('rp_economy_treasury')
end)
