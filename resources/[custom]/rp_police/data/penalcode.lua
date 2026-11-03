-- ============================================================
--  Penal Code v1 (draft by Claude, Nov 2, 2026, for Liam to polish)
--
--  Based on real California law, kept grounded. Police use it as the
--  reference for fines and jail time; judges and the MDT will use the
--  same list later. Everyone can read it in game with /penalcode.
--
--  HOW TO EDIT (Liam): change the words in title and desc freely.
--  fine = dollars (real-world amounts, like the rest of our economy).
--  jail = minutes in jail, served while online (1 minute = about 1 real month).
--  class = 'infraction' (ticket), 'misdemeanor' or 'felony'.
--  Keep each id unique and don't change ids once charges are in use.
--
--  NPC cases rule (Pillar D): a crime the server made up (an NPC
--  shooting behind a found gun, a runaway fare) is never charged
--  against a player. Charge only what the player actually did:
--  possession, keeping found property, lying, planting evidence.
-- ============================================================
return {
    maxJail = 120, -- longest total sentence police can recommend (minutes). Longer goes to a judge.

    categories = {
        {
            id = 'traffic',
            charges = {
                { id = 'T01', class = 'infraction', fine = 238, jail = 0, title = 'Speeding (1-15 over)', desc = 'Driving up to 15 mph over the posted limit.' },
                { id = 'T02', class = 'infraction', fine = 367, jail = 0, title = 'Speeding (16-25 over)', desc = 'Driving 16 to 25 mph over the posted limit.' },
                { id = 'T03', class = 'infraction', fine = 490, jail = 0, title = 'Speeding (26+ over)', desc = 'Driving 26 mph or more over the posted limit.' },
                { id = 'T04', class = 'infraction', fine = 490, jail = 0, title = 'Running a red light or stop sign', desc = 'Failing to stop at a red signal or stop sign.' },
                { id = 'T05', class = 'infraction', fine = 238, jail = 0, title = 'Illegal turn or lane change', desc = 'Unsafe or illegal turn, U-turn or lane change.' },
                { id = 'T06', class = 'infraction', fine = 162, jail = 0, title = 'Using a phone while driving', desc = 'Holding a phone while driving.' },
                { id = 'T07', class = 'infraction', fine = 238, jail = 0, title = 'Driving without a license', desc = 'Driving without a valid driver license.' },
                { id = 'T08', class = 'infraction', fine = 100, jail = 0, title = 'Illegal parking', desc = 'Parking in a red zone, on the sidewalk, or blocking traffic.' },
                { id = 'T09', class = 'infraction', fine = 490, jail = 0, title = 'Failure to yield to emergency vehicle', desc = 'Not pulling over for police, fire or EMS with lights on.' },
                { id = 'T10', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Reckless driving', desc = 'Driving with willful disregard for the safety of people or property.' },
                { id = 'T11', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Speed contest / street racing', desc = 'Racing another vehicle on a public road.' },
                { id = 'T12', class = 'misdemeanor', fine = 2000, jail = 15, title = 'Driving under the influence', desc = 'Driving while impaired by alcohol or drugs.' },
                { id = 'T13', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Evading a peace officer', desc = 'Fleeing police who are trying to stop you.' },
                { id = 'T14', class = 'felony', fine = 5000, jail = 25, title = 'Evading with reckless driving', desc = 'Fleeing police while driving dangerously.' },
                { id = 'T15', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Hit and run (property)', desc = 'Leaving the scene of a crash that damaged property.' },
                { id = 'T16', class = 'felony', fine = 5000, jail = 25, title = 'Hit and run (injury)', desc = 'Leaving the scene of a crash where someone was hurt.' },
                { id = 'T17', class = 'felony', fine = 10000, jail = 40, title = 'Vehicular manslaughter', desc = 'Killing someone through dangerous or impaired driving.' },
            },
        },
        {
            id = 'public',
            charges = {
                { id = 'P01', class = 'infraction', fine = 250, jail = 0, title = 'Disturbing the peace', desc = 'Fighting, loud noise or offensive words in public.' },
                { id = 'P02', class = 'misdemeanor', fine = 250, jail = 5, title = 'Public intoxication', desc = 'Drunk or high in public and unable to care for yourself.' },
                { id = 'P03', class = 'infraction', fine = 250, jail = 0, title = 'Trespassing', desc = 'Entering or staying on property after being told to leave.' },
                { id = 'P04', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Loitering on private property', desc = 'Hanging around a business or property with no lawful reason after warning.' },
                { id = 'P05', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Indecent exposure', desc = 'Exposing yourself in public.' },
                { id = 'P06', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Vandalism (under $400)', desc = 'Damaging or defacing property worth under $400.' },
                { id = 'P07', class = 'felony', fine = 5000, jail = 20, title = 'Vandalism ($400+)', desc = 'Damaging or defacing property worth $400 or more.' },
            },
        },
        {
            id = 'property',
            charges = {
                { id = 'R01', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Petty theft', desc = 'Stealing property worth under $950.' },
                { id = 'R02', class = 'felony', fine = 5000, jail = 20, title = 'Grand theft', desc = 'Stealing property worth $950 or more.' },
                { id = 'R03', class = 'felony', fine = 5000, jail = 25, title = 'Grand theft auto', desc = 'Stealing a vehicle.' },
                { id = 'R04', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Joyriding', desc = 'Taking a vehicle without permission, meaning to give it back.' },
                { id = 'R05', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Keeping lost property', desc = 'Keeping money or property you found without trying to return it (wallets, bags, packages).' },
                { id = 'R06', class = 'felony', fine = 5000, jail = 20, title = 'Receiving stolen property', desc = 'Buying, keeping or selling property you know is stolen.' },
                { id = 'R07', class = 'felony', fine = 5000, jail = 30, title = 'Burglary', desc = 'Entering a home or business to commit theft or another felony.' },
                { id = 'R08', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Possession of burglary tools', desc = 'Carrying lockpicks or tools with intent to break in.' },
                { id = 'R09', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Defrauding a driver', desc = 'Leaving a taxi or ride without paying the fare.' },
                { id = 'R10', class = 'felony', fine = 10000, jail = 30, title = 'Money laundering', desc = 'Moving dirty money to hide where it came from.' },
                { id = 'R11', class = 'felony', fine = 10000, jail = 30, title = 'Fraud', desc = 'Tricking someone out of money or property.' },
            },
        },
        {
            id = 'violent',
            charges = {
                { id = 'V01', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Assault', desc = 'Attempting or threatening to hurt someone.' },
                { id = 'V02', class = 'misdemeanor', fine = 2000, jail = 15, title = 'Battery', desc = 'Using force or violence on someone.' },
                { id = 'V03', class = 'felony', fine = 10000, jail = 40, title = 'Assault with a deadly weapon', desc = 'Attacking someone with a weapon or with force likely to cause great harm.' },
                { id = 'V04', class = 'felony', fine = 10000, jail = 35, title = 'Robbery', desc = 'Taking property from a person by force or fear.' },
                { id = 'V05', class = 'felony', fine = 10000, jail = 50, title = 'Armed robbery', desc = 'Robbery using a firearm or deadly weapon.' },
                { id = 'V06', class = 'felony', fine = 10000, jail = 50, title = 'Kidnapping', desc = 'Moving or holding a person against their will.' },
                { id = 'V07', class = 'felony', fine = 5000, jail = 25, title = 'Carjacking', desc = 'Taking a vehicle from its driver by force or fear.' },
                { id = 'V08', class = 'felony', fine = 10000, jail = 60, title = 'Attempted murder', desc = 'Trying to kill someone.' },
                { id = 'V09', class = 'felony', fine = 10000, jail = 60, title = 'Manslaughter', desc = 'Killing someone without intent, in the heat of passion or through recklessness.' },
                { id = 'V10', class = 'felony', fine = 10000, jail = 90, title = 'Second-degree murder', desc = 'Killing someone with intent, but without planning.' },
                { id = 'V11', class = 'felony', fine = 10000, jail = 120, title = 'First-degree murder', desc = 'Planned, deliberate killing. Goes to a judge.' },
                { id = 'V12', class = 'felony', fine = 10000, jail = 40, title = 'Criminal threats', desc = 'Threatening to kill or seriously hurt someone, meant to cause fear.' },
            },
        },
        {
            id = 'weapons',
            charges = {
                { id = 'W01', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Brandishing a weapon', desc = 'Drawing or showing a weapon in a threatening way.' },
                { id = 'W02', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Carrying a firearm without a license', desc = 'Carrying a gun without a weapon license.' },
                { id = 'W03', class = 'felony', fine = 5000, jail = 20, title = 'Possession of an unregistered firearm', desc = 'Having a gun with no registration (no serial on file to you).' },
                { id = 'W04', class = 'felony', fine = 5000, jail = 25, title = 'Possession of a stolen or evidence-linked firearm', desc = 'Having a gun reported stolen or tied to an open case. Proves possession, not who fired it.' },
                { id = 'W05', class = 'felony', fine = 5000, jail = 20, title = 'Discharging a firearm in public', desc = 'Firing a gun in a public place with no lawful reason.' },
                { id = 'W06', class = 'felony', fine = 10000, jail = 30, title = 'Weapons trafficking', desc = 'Selling or moving guns illegally.' },
                { id = 'W07', class = 'felony', fine = 10000, jail = 30, title = 'Possession of an explosive or incendiary device', desc = 'Having a Molotov or other homemade explosive.' },
            },
        },
        {
            id = 'drugs',
            charges = {
                { id = 'D01', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Possession of a controlled substance', desc = 'Having illegal drugs for personal use.' },
                { id = 'D02', class = 'felony', fine = 5000, jail = 25, title = 'Possession for sale', desc = 'Having drugs packaged or in amounts meant for selling.' },
                { id = 'D03', class = 'felony', fine = 10000, jail = 40, title = 'Drug trafficking', desc = 'Selling, transporting or bringing in large amounts of drugs (bricks).' },
                { id = 'D04', class = 'felony', fine = 10000, jail = 40, title = 'Manufacturing drugs', desc = 'Growing or cooking drugs to sell.' },
                { id = 'D05', class = 'misdemeanor', fine = 1000, jail = 5, title = 'Possession of drug paraphernalia', desc = 'Having pipes, scales or baggies for drug use or sale.' },
            },
        },
        {
            id = 'justice',
            charges = {
                { id = 'J01', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Resisting or obstructing an officer', desc = 'Resisting arrest or getting in the way of an officer doing their job.' },
                { id = 'J02', class = 'infraction', fine = 250, jail = 0, title = 'Failure to identify', desc = 'Refusing to give your name to police when lawfully detained.' },
                { id = 'J03', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Giving false information to police', desc = 'Lying about your identity or about facts to an officer.' },
                { id = 'J04', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Filing a false police report', desc = 'Reporting a crime you know did not happen.' },
                { id = 'J05', class = 'felony', fine = 10000, jail = 30, title = 'Tampering with or planting evidence', desc = 'Hiding, destroying, faking or planting evidence.' },
                { id = 'J06', class = 'felony', fine = 10000, jail = 30, title = 'Bribery of an official', desc = 'Offering or taking money to influence an official.' },
                { id = 'J07', class = 'misdemeanor', fine = 2000, jail = 15, title = 'Impersonating a peace officer', desc = 'Pretending to be a police officer.' },
                { id = 'J08', class = 'felony', fine = 10000, jail = 30, title = 'Escape from custody', desc = 'Escaping from police custody, jail or prison.' },
                { id = 'J09', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Contempt of court', desc = 'Disobeying a court order or disrupting court.' },
                { id = 'J10', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Violating parole or probation', desc = 'Breaking the conditions of release.' },
                { id = 'J11', class = 'misdemeanor', fine = 1000, jail = 10, title = 'Misuse of 911', desc = 'Calling 911 with no emergency, on purpose.' },
                { id = 'J12', class = 'felony', fine = 10000, jail = 30, title = 'Corruption of an officer', desc = 'An officer abusing their badge: taking bribes, selling department gear, helping criminals.' },
            },
        },
    },
}
