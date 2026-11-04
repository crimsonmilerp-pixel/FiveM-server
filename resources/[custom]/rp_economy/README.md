# rp_economy

The money engine (Phase 2, built Nov 4, 2026). Four parts:

## 1. Income tax, taken off every paycheck and job payout

- Brackets are per **tax week** (Monday to Sunday, starting at midnight US Eastern): 10% up to $1,000, 12% to $4,200, 22% to $8,800, 24% to $16,800, 32% above. They match `docs/economy.xlsx` → Taxes & Loans (US brackets ÷ 12, one real week = one "month").
- Each payout is taxed at the rate for where it lands in your week, so the first $1,000 you earn each week is taxed at 10%, the next part at 12%, and so on. Payouts never get a surprise bill later.
- Taxed: paychecks (police, EMS, mechanics), garbage, taxi fares, trucker, tow, car dealer commission, selling coral, the Scrap and Wine Buyers, and the crew bonus.
- Not taxed: crime money, money from other players, the truck deposit coming back, job moment rewards, and the starting money.
- The old 15% "tax" in the trucker and tow jobs is gone (set to 0); real income tax replaces it.

Other resources pay legal work income with:

```lua
local paid = exports.rp_economy:PayIncome(source, amount, { account = 'bank', reason = 'my-job' })
-- paid = { gross, net, tax, note }   (nil if nothing was paid)
-- paid.note is " ($12 income tax taken off)", or "" when no tax was due
```

Every file that does this has a small `payIncome` helper that pays the full amount instead if rp_economy isn't running.

## 2. The government treasury

- Collects income tax and luxury upkeep. Police and EMS paychecks count as spending.
- It's a record only: **it never stops anyone's pay** (decided Nov 4). It will go below $0 while police pay more than taxes bring in, and that's fine.
- Staff see it with **`/treasury`** (this week and last week, by type).
- Later: fines, a mayor who can see it, and maybe tax rates set in play.

## 3. Weekly bills

- Due once every **real week**, and **only charged while the player is in the city**. Someone away for three weeks comes back to one bill, not three. A new character's first bill is a week after they first load in.
- Bills always come out of the **bank**, and the bank can go below $0. That's the debt: anything paid by card fails until paychecks bring it back up.
- On the bill now:
  - **Car loan payments** (see part 4). Unlike the rest, these are only taken if the bank covers them.
  - **Luxury upkeep** for every owned vehicle priced over $100,000 (6% a year on the part above $100,000, one twelfth each week). A $3M hypercar costs $14,500 a week. Cars under the line cost nothing.
- Coming next: rent and mortgages (NoLag Properties), then home upkeep over $750,000.

## 4. Car loans and credit score (built Nov 4)

- **Where:** the dealership's normal "Finance" button (PDM). It now gives a real loan from the bank instead of Qbox's interest-free payments. When a dealer is clocked in, they finance it for the customer and the customer signs.
- **The offer:** the buyer sees the price, down payment (at least 10%), the loan, the interest rate, the weekly payment and how many weeks, and signs or says no.
- **Credit score:** 300 to 850. Every new character starts at **650**. On-time payment +5, loan paid off +25, missed payment -40, car taken back -150.

  | Score | Rate | Name |
  |---|---|---|
  | 750+ | 5.5% | Excellent |
  | 670-749 | 7% | Good |
  | 580-669 | 11% | Fair |
  | 500-579 | 16% | Poor |
  | under 500 | the bank says no | |

- **How much the bank lends:** all your loan payments together can be up to **$400 a week** (anyone can finance a first car of about $20k), or up to **35% of your average weekly job income** over the last 4 tax weeks if that's more. Up to 3 car loans at once, and no new loan while you're behind on one.
- **Payments:** 12 to 72 weekly payments, taken from the bank with the weekly bills. A loan less than 3 days old skips the next bill. Interest is per "month" (one real week), like the sheet.
- **Missed payment:** if the bank doesn't cover it, the payment is missed: a late fee (5%, at least $25) is added to what you owe and the credit score drops. Each one comes with a warning. **3 missed in a row and the bank takes the car back**: it disappears from the street or garage, the loan closes, and the credit score takes a big hit.
- **In /finances:** the credit score, each loan (what's left, payments made, missed), **catch up** on missed payments, or **pay it off** early (no fee).
- **Selling:** a car with a loan can't be sold, traded, or sold to the used car lot until it's paid off.
- Cars financed with Qbox's old system before Nov 4 aren't tracked any more (they're simply owned).
- Mortgages come later with housing and use the same credit score.

For other scripts: `exports.rp_economy:QuoteCarLoan(source, { model, price, down, weeks })`, `CreateCarLoan(source, vehicleId, quote)`, `HasActiveLoan(vehicleId)`, `BlockLoanSale(source, plate)`.

## Commands

| Command | Who | What |
|---|---|---|
| `/finances` | Everyone | Bank, this tax week's income and tax, credit score, car loans (catch up, pay off), the next weekly bills (an estimate), and the last bills paid. The finance desk at PDM opens it too |
| `/treasury` | Staff (admin) | Treasury balance, money in and out this week and last week |
| `/billsnow [ID]` | Staff (admin) | Charges that player's weekly bills right now, for testing. Loan payments are charged even on a brand-new loan. Their next bills move to a week later |

## Settings and text

- `config.lua`: tax brackets, when the tax week starts, how often bills come, the luxury line and rate, which jobs are government jobs, loans and credit (rates, limits, late fee, misses before the car is taken), who counts as staff.
- `locales/en.json`: everything players read.

## Database (created automatically)

| Table | Holds |
|---|---|
| `rp_economy_income` | Each character's income and tax per tax week |
| `rp_treasury` | Treasury money in (+) and out (-) per week and type. The balance is the sum |
| `rp_bills` | When each character's next weekly bills are due |
| `rp_bill_statements` | Every weekly bill that was charged, line by line |
| `rp_credit` | Each character's credit score (missing = 650) |
| `rp_loans` | Every loan: what's left, the weekly payment, rate, payments made and missed, and whether it's active, paid or repossessed |
