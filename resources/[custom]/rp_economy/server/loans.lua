-- ============================================================
--  rp_economy - loans (car loans now; mortgages come with housing)
--  Credit score, loan offers, weekly payments (charged with the
--  weekly bills), late fees, and the bank taking the car back
--  after too many missed payments in a row (decided Nov 4).
-- ============================================================
local config = require 'config'

local LOANS = config.loans
local CAR = LOANS.car

local L = {}
local ctx                 -- helpers from server/main.lua (set by L.init)
local loanedVehicles = {} -- [vehicleId] = true while a loan on it is active
local busy = {}           -- [source] = true while a pay-off is being handled

L.TABLES = {
    [[CREATE TABLE IF NOT EXISTS `rp_credit` (
        `citizenid`  VARCHAR(50)  NOT NULL,
        `score`      INT          NOT NULL,
        `updated_at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    [[CREATE TABLE IF NOT EXISTS `rp_loans` (
        `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid`     VARCHAR(50)  NOT NULL,
        `kind`          VARCHAR(20)  NOT NULL,
        `vehicle_id`    INT          NULL,
        `plate`         VARCHAR(15)  NULL,
        `label`         VARCHAR(100) NOT NULL,
        `principal`     BIGINT       NOT NULL,
        `apr_bp`        INT          NOT NULL,
        `term_weeks`    INT          NOT NULL,
        `payment`       BIGINT       NOT NULL,
        `balance`       BIGINT       NOT NULL,
        `payments_made` INT          NOT NULL DEFAULT 0,
        `missed`        INT          NOT NULL DEFAULT 0,
        `status`        VARCHAR(20)  NOT NULL DEFAULT 'active',
        `created_at`    INT UNSIGNED NOT NULL,
        `closed_at`     INT UNSIGNED NULL,
        PRIMARY KEY (`id`),
        KEY `citizen` (`citizenid`, `status`),
        KEY `vehicle` (`vehicle_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
}

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function num(v) return tonumber(v) or 0 end

local function trimPlate(plate)
    return (tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

---"11" or "5.5"
local function aprText(apr)
    local text = ('%.1f'):format(apr)
    return (text:gsub('%.0$', ''))
end

local function vehicleLabel(model)
    local data = ctx.vehicleData(model)
    if not data then return ctx.clean(model) end
    return ctx.clean(('%s %s'):format(data.brand or '', data.name or model))
end

---The same weekly payment every week until the balance is gone (interest is per "month" = per week).
local function weeklyPayment(principal, apr, weeks)
    local rate = apr / 1200
    if rate <= 0 then return math.ceil(principal / weeks) end
    return math.ceil(principal * rate / (1 - (1 + rate) ^ -weeks))
end

---This week's interest on a balance.
local function interestOn(balance, aprBp)
    return math.floor(balance * aprBp / 120000)
end

-- ------------------------------------------------------------
-- Credit score
-- ------------------------------------------------------------
local function getScore(citizenid)
    local score = MySQL.scalar.await('SELECT `score` FROM `rp_credit` WHERE `citizenid` = ?', { citizenid })
    return tonumber(score) or LOANS.startScore
end

local function changeScore(citizenid, delta)
    local score = math.max(LOANS.minScore, math.min(LOANS.maxScore, math.floor(getScore(citizenid) + delta)))
    MySQL.query.await('INSERT INTO `rp_credit` (`citizenid`, `score`, `updated_at`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `score` = VALUES(`score`), `updated_at` = VALUES(`updated_at`)',
        { citizenid, score, os.time() })
    return score
end

---The rate tier for a score, or nil if the bank won't lend.
local function tierFor(score)
    for _, tier in ipairs(LOANS.rates) do
        if score >= tier.minScore then return tier end
    end
end

local function activeLoans(citizenid)
    return MySQL.query.await('SELECT * FROM `rp_loans` WHERE `citizenid` = ? AND `status` = ? ORDER BY `id`', { citizenid, 'active' }) or {}
end

---Average weekly job income over the last few tax weeks (this one included).
local function averageIncome(citizenid)
    local week = ctx.weekNumber()
    local total = MySQL.scalar.await('SELECT COALESCE(SUM(`gross`), 0) FROM `rp_economy_income` WHERE `citizenid` = ? AND `week` > ? AND `week` <= ?',
        { citizenid, week - CAR.incomeWeeks, week })
    return math.floor(num(total) / CAR.incomeWeeks)
end

-- ------------------------------------------------------------
-- Offers
-- ------------------------------------------------------------
local function refuse(reason) return { ok = false, reason = reason } end

---Works out a car loan offer for a player. Nothing is charged or saved.
---@param source number the buyer
---@param data { model: string, price: number, down: number, weeks: number }
function L.quote(source, data)
    local player = ctx.getPlayer(source)
    if not player or type(data) ~= 'table' then return refuse(locale('loan.error_no_player')) end
    local citizenid = player.PlayerData.citizenid

    local price = math.floor(num(data.price))
    local down = math.floor(tonumber(data.down) or -1)
    local weeks = math.floor(num(data.weeks))
    if price <= 0 then return refuse(locale('loan.error_bad_car')) end

    local minDown = math.ceil(price * CAR.minDownPercent / 100)
    if down < minDown then return refuse(locale('loan.error_down_small', ctx.money(minDown), CAR.minDownPercent)) end

    local principal = price - down
    if principal < CAR.minLoan then return refuse(locale('loan.error_too_small', ctx.money(CAR.minLoan))) end
    if weeks < CAR.minWeeks or weeks > CAR.maxWeeks then return refuse(locale('loan.error_weeks', CAR.minWeeks, CAR.maxWeeks)) end

    local score = getScore(citizenid)
    local tier = tierFor(score)
    if not tier then return refuse(locale('loan.error_score', score)) end

    local loans, existing = activeLoans(citizenid), 0
    if #loans >= CAR.maxActive then return refuse(locale('loan.error_max_active', CAR.maxActive)) end
    for _, loan in ipairs(loans) do
        if num(loan.missed) > 0 then return refuse(locale('loan.error_behind')) end
        existing = existing + num(loan.payment)
    end

    local payment = weeklyPayment(principal, tier.apr, weeks)
    local limit = math.max(CAR.starterPayment, math.floor(averageIncome(citizenid) * CAR.incomeShare))
    if existing + payment > limit then
        return refuse(locale('loan.error_afford', ctx.money(math.max(0, limit - existing)), ctx.money(payment)))
    end

    local label = vehicleLabel(data.model)
    local quote = {
        ok = true, model = data.model, label = label, price = price, down = down, principal = principal,
        weeks = weeks, apr = tier.apr, score = score, tier = tier.id, payment = payment, total = payment * weeks,
    }
    quote.title = locale('loan.offer_title', label)
    quote.text = locale('loan.offer_text', ctx.money(price), ctx.money(down), ctx.money(principal), aprText(tier.apr),
        score, locale('credit.' .. tier.id), ctx.money(payment), weeks, ctx.money(quote.total), CAR.missesBeforeRepo)
    quote.accept = locale('loan.offer_accept')
    quote.decline = locale('loan.offer_decline')
    return quote
end

---Records a car loan after the car was created. `quote` must come from L.quote.
function L.create(source, vehicleId, quote)
    local player = ctx.getPlayer(source)
    if not player or type(quote) ~= 'table' or not quote.ok then return false end
    vehicleId = tonumber(vehicleId)
    local plate = vehicleId and MySQL.scalar.await('SELECT `plate` FROM `player_vehicles` WHERE `id` = ?', { vehicleId })

    local id = MySQL.insert.await([[INSERT INTO `rp_loans`
        (`citizenid`, `kind`, `vehicle_id`, `plate`, `label`, `principal`, `apr_bp`, `term_weeks`, `payment`, `balance`, `created_at`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        player.PlayerData.citizenid, 'car', vehicleId, plate and trimPlate(plate) or nil, quote.label,
        quote.principal, math.floor(quote.apr * 100 + 0.5), quote.weeks, quote.payment, quote.principal, os.time(),
    })
    if vehicleId then loanedVehicles[vehicleId] = true end
    ctx.notify(source, locale('loan.created_title'), 'success', 12000,
        locale('loan.created', ctx.money(quote.payment), quote.weeks, CAR.firstPaymentAfterDays))
    return id
end

-- ------------------------------------------------------------
-- Repossession
-- ------------------------------------------------------------
local function repossess(loan)
    local vehicleId = tonumber(loan.vehicle_id)
    loanedVehicles[vehicleId or -1] = nil
    if not vehicleId then return end

    -- Take it off the street if it's out, then off the owner's list.
    local plate = trimPlate(loan.plate)
    if plate ~= '' then
        for _, entity in ipairs(GetAllVehicles()) do
            if DoesEntityExist(entity) and trimPlate(GetVehicleNumberPlateText(entity)) == plate then
                DeleteEntity(entity)
            end
        end
    end
    exports.qbx_vehicles:DeletePlayerVehicles('vehicleId', vehicleId)
end

-- ------------------------------------------------------------
-- Weekly payments (called by the weekly bills in server/main.lua)
-- ------------------------------------------------------------
---Charges every active loan's payment from the bank (never below $0: if it doesn't cover it, the payment is missed).
---@param skipWait? boolean staff testing (/billsnow): charge even a brand-new loan
---@return table lines statement lines, integer paid total actually paid
function L.charge(source, citizenid, now, skipWait)
    local lines, paidTotal = {}, 0
    for _, loan in ipairs(activeLoans(citizenid)) do
        if skipWait or num(loan.created_at) <= now - CAR.firstPaymentAfterDays * 86400 then
            local player = ctx.getPlayer(source)
            if not player or player.PlayerData.citizenid ~= citizenid then break end

            local balance, payment, aprBp = num(loan.balance), num(loan.payment), num(loan.apr_bp)
            local interest = interestOn(balance, aprBp)
            local due = math.min(payment, balance + interest)
            local bank = num(player.PlayerData.money and player.PlayerData.money.bank)
            local label = loan.plate and ('%s (%s)'):format(loan.label, loan.plate) or loan.label

            if due > 0 and bank >= due and player.Functions.RemoveMoney('bank', due, 'loan-payment') then
                balance = balance + interest - due
                paidTotal = paidTotal + due
                lines[#lines + 1] = { kind = 'loan_payment', label = locale('loan.line_paid', label), amount = due }
                local made = num(loan.payments_made) + 1
                if balance <= 0 then
                    MySQL.update.await('UPDATE `rp_loans` SET `balance` = 0, `payments_made` = ?, `missed` = 0, `status` = ?, `closed_at` = ? WHERE `id` = ?',
                        { made, 'paid', now, loan.id })
                    loanedVehicles[tonumber(loan.vehicle_id) or -1] = nil
                    local score = changeScore(citizenid, LOANS.scoreChange.onTime + LOANS.scoreChange.paidOff)
                    ctx.notify(source, locale('loan.paid_off_title'), 'success', 12000, locale('loan.paid_off', label, score))
                else
                    MySQL.update.await('UPDATE `rp_loans` SET `balance` = ?, `payments_made` = ?, `missed` = 0 WHERE `id` = ?',
                        { balance, made, loan.id })
                    changeScore(citizenid, LOANS.scoreChange.onTime)
                end
            else
                local missed = num(loan.missed) + 1
                local fee = math.max(CAR.minLateFee, math.floor(payment * CAR.lateFeePercent / 100))
                balance = balance + interest + fee
                local score = changeScore(citizenid, LOANS.scoreChange.missed)
                lines[#lines + 1] = { kind = 'loan_missed', label = locale('loan.line_missed', label, ctx.money(fee)), amount = 0 }

                if missed >= CAR.missesBeforeRepo then
                    repossess(loan)
                    MySQL.update.await('UPDATE `rp_loans` SET `balance` = ?, `missed` = ?, `status` = ?, `closed_at` = ? WHERE `id` = ?',
                        { balance, missed, 'repossessed', now, loan.id })
                    score = changeScore(citizenid, LOANS.scoreChange.repossessed)
                    lines[#lines + 1] = { kind = 'loan_repossessed', label = locale('loan.line_repo', label), amount = 0 }
                    ctx.notify(source, locale('loan.repo_title'), 'error', 20000, locale('loan.repo', label, score))
                else
                    MySQL.update.await('UPDATE `rp_loans` SET `balance` = ?, `missed` = ? WHERE `id` = ?', { balance, missed, loan.id })
                    ctx.notify(source, locale('loan.missed_title'), 'error', 20000,
                        locale('loan.missed', label, ctx.money(due), ctx.money(fee), missed, CAR.missesBeforeRepo, score))
                end
            end
        end
    end
    return lines, paidTotal
end

---What the loans will take at the next weekly bill (an estimate for /finances).
function L.estimate(citizenid)
    local lines = {}
    for _, loan in ipairs(activeLoans(citizenid)) do
        local balance = num(loan.balance)
        local due = math.min(num(loan.payment), balance + interestOn(balance, num(loan.apr_bp)))
        local label = loan.plate and ('%s (%s)'):format(loan.label, loan.plate) or loan.label
        lines[#lines + 1] = { kind = 'loan_payment', label = locale('loan.line_paid', label), amount = due }
    end
    return lines
end

---Credit and loans for /finances.
function L.financesData(citizenid)
    local score = getScore(citizenid)
    local tier = tierFor(score)
    local list = {}
    for _, loan in ipairs(activeLoans(citizenid)) do
        list[#list + 1] = {
            id = loan.id,
            label = loan.plate and ('%s (%s)'):format(loan.label, loan.plate) or loan.label,
            balance = num(loan.balance),
            payment = num(loan.payment),
            made = num(loan.payments_made),
            weeks = num(loan.term_weeks),
            missed = num(loan.missed),
            apr = aprText(num(loan.apr_bp) / 100),
        }
    end
    return {
        credit = {
            score = score,
            tier = tier and tier.id or nil,
            apr = tier and aprText(tier.apr) or nil,
        },
        loans = list,
        repoAfter = CAR.missesBeforeRepo,
    }
end

-- ------------------------------------------------------------
-- Paying early (from /finances)
-- ------------------------------------------------------------
lib.callback.register('rp_economy:server:payLoan', function(source, loanId, mode)
    if busy[source] then return false, 'busy' end
    local player = ctx.getPlayer(source)
    if not player or (mode ~= 'payoff' and mode ~= 'overdue') then return false, 'not_found' end
    busy[source] = true

    local ok, result, amount = pcall(function()
        local citizenid = player.PlayerData.citizenid
        local loan = MySQL.single.await('SELECT * FROM `rp_loans` WHERE `id` = ? AND `citizenid` = ? AND `status` = ?', { tonumber(loanId) or 0, citizenid, 'active' })
        if not loan then return false, 'not_found' end

        local balance, missed = num(loan.balance), num(loan.missed)
        local pay
        if mode == 'payoff' then
            pay = balance
        else
            if missed <= 0 then return false, 'nothing_overdue' end
            pay = math.min(balance, num(loan.payment) * missed)
        end

        player = ctx.getPlayer(source)
        if not player or player.PlayerData.citizenid ~= citizenid then return false, 'not_found' end
        if num(player.PlayerData.money.bank) < pay then return false, 'not_enough' end
        if not player.Functions.RemoveMoney('bank', pay, mode == 'payoff' and 'loan-payoff' or 'loan-catch-up') then return false, 'not_enough' end

        local now = os.time()
        local left = balance - pay
        if left <= 0 then
            MySQL.update.await('UPDATE `rp_loans` SET `balance` = 0, `missed` = 0, `status` = ?, `closed_at` = ? WHERE `id` = ?', { 'paid', now, loan.id })
            loanedVehicles[tonumber(loan.vehicle_id) or -1] = nil
            changeScore(citizenid, LOANS.scoreChange.paidOff)
        else
            MySQL.update.await('UPDATE `rp_loans` SET `balance` = ?, `missed` = 0 WHERE `id` = ?', { left, loan.id })
        end
        return true, pay
    end)

    busy[source] = nil
    if not ok then
        lib.print.error(('loan payment failed for player %s: %s'):format(source, result))
        return false, 'not_found'
    end
    if result then
        local text = mode == 'payoff' and locale('loan.paid_off_now', ctx.money(amount)) or locale('loan.caught_up', ctx.money(amount))
        ctx.notify(source, text, 'success', 10000)
    end
    return result, amount
end)

-- ------------------------------------------------------------
-- Selling a car with a loan on it
-- ------------------------------------------------------------
function L.hasActiveLoan(vehicleId)
    return loanedVehicles[tonumber(vehicleId) or -1] == true
end

---For other scripts: true (and tells the player why) if this car can't be sold or traded yet.
function L.blockSale(source, plate, vehicleId)
    vehicleId = tonumber(vehicleId)
    if not vehicleId and plate then
        vehicleId = tonumber(MySQL.scalar.await('SELECT `id` FROM `player_vehicles` WHERE `plate` = ?', { trimPlate(plate) }))
    end
    if vehicleId and loanedVehicles[vehicleId] then
        if source then ctx.notify(source, locale('loan.no_sale'), 'error', 10000) end
        return true
    end
    return false
end

-- ------------------------------------------------------------
-- Start-up
-- ------------------------------------------------------------
function L.init(helpers)
    ctx = helpers
end

function L.start()
    for _, row in ipairs(MySQL.query.await('SELECT `vehicle_id` FROM `rp_loans` WHERE `status` = ? AND `vehicle_id` IS NOT NULL', { 'active' }) or {}) do
        loanedVehicles[tonumber(row.vehicle_id)] = true
    end
    -- Safety net: no ownership change for a car with an active loan, whatever tries it.
    if GetResourceState('qbx_vehicles') == 'started' then
        exports.qbx_vehicles:registerHook('changeVehicleOwner', function(payload)
            if payload and loanedVehicles[tonumber(payload.vehicleId) or -1] then return false end
        end)
    end
end

exports('QuoteCarLoan', L.quote)
exports('CreateCarLoan', L.create)
exports('HasActiveLoan', L.hasActiveLoan)
exports('BlockLoanSale', L.blockSale)

return L
