# rp_jobmoments: Job Moments

Now and then (about **1 task in 20**), a small story event happens during a job and hands the worker a choice. The choices lead into police, detective, or crime roleplay. Pay stays the same on average; moments are about story, not money.

## The moments

| Job | Moment | Choices |
|---|---|---|
| Garbage | **Bloody bag**: a pistol and a bloody shirt | Bag it for police (reward at the front desk) · Keep the pistol · Leave it |
| Garbage | **Lost wallet** with an ID and $60 | Return it to the owner's door ($100 thank-you) · Take the cash · Leave it |
| Taxi | **Left-behind bag** with $300 cash | Turn it in (reward) · Keep it (dirty money) · Leave it |
| Taxi | **Runner**: the passenger bolts without paying | Chase and grab them (**E**) for the fare + a tip · Call it in to police (**G**) · Let them go |

## How it connects to police

- **Every bloody bag is a real case.** Police see an open shooting with the pistol's serial number in **`/cases`**. If the worker kept the pistol, any officer who checks that gun's serial with **`/serial`** sees it's the missing weapon. That makes the carrier a suspect.
- **A kept bag of cash** leaves a case with the cab's plate on it, so police have a lead.
- **Calling in a runner** sends an alert to on-duty police.
- **Running the runner over** is reported as a pedestrian death, with the taxi's plate.
- **Found evidence** is turned in at the police clock-in spot at **Mission Row or Paleto** (third eye → *Turn in found evidence*). Workers get **$100** per item. On-duty officers can log evidence too, but they don't get the reward.

## Commands

- **`/cases`** (on-duty police and staff): the case files, with a GPS button for each scene. **Staff** (`mod` and up) also see the private side: who kept, took, or left what.
- **`/serial [number]`** (on-duty police and staff): checks a weapon serial against the case files.

## Items

Two items were added to `ox_inventory/data/items.lua`:
- **Found Evidence**: use it to set your GPS to the nearest police front desk.
- **Lost Wallet**: use it to set your GPS to the owner's address. The owner waits at their front door.

## Settings

All in **`config.lua`**: how often moments happen, which moments each job gets, rewards, cash amounts, the runner chase time, wallet owner names and homes, and the police desk spots.

## Adding moments to another job

In that job's server code, after a task is finished:

```lua
if GetResourceState('rp_jobmoments') == 'started' then
    exports.rp_jobmoments:OnTask(source, 'jobname')
end
```

Then add the job and its moments to `config.lua`. A new kind of moment needs code in `server/main.lua` and `client/main.lua`.

## Editing the words (Liam)

All text is in **`locales/en.json`**: the stories, the choices, the results, and the case file wording. Only change the words on the right side, and keep every `%s`.

## Database

Created automatically on first start:
- `rp_cases`: case files police can read
- `rp_moment_log`: every choice made (staff only)
