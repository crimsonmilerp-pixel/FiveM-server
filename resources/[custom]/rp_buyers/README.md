# rp_buyers: NPC Buyers

NPCs who buy legal goods that players gather or make, so the vineyard and the scrap yard actually pay.

## The buyers

| Buyer | Where | Buys |
|---|---|---|
| **Scrap Buyer** | Sandy Shores scrap yard, beside the yard's own NPC. Buys the materials you get from scrapping cars there | Copper $4.70, aluminum $0.60, steel/iron/metal scrap/plastic $0.10, glass/rubber $0.05 (each item = 1 lb, real scrap-yard prices) |
| **Wine Buyer** | Marlowe Vineyard, at the vineyard map marker | Wine $6, grape juice $1.50 (wholesale; the liquor store sells wine for $15) |

Walk up to a buyer and use the target (third eye) → **Sell goods**. The menu shows every item they buy and its price, even ones you don't have. You can sell everything at once or pick an amount. Payment is in **cash**.

Sales under $1 are refused so nobody loses items for $0. Any leftover cents are rounded down.

## Moving a buyer

1. In game, stand exactly where the buyer should stand, facing the way they should face.
2. Type **`/buyerhere`** (admins only). Your position is copied.
3. Open `config.lua`, find the buyer, and replace its `coords = vec4(...)` line by pasting.
4. Upload `config.lua` and type `restart rp_buyers` in the txAdmin Live Console.

## Changing prices or adding a buyer

All in **`config.lua`**. Each buyer has a ped model, a spot, and a list of `{ name = 'item', price = 1.23 }`. Item names must match `ox_inventory/data/items.lua`. A new buyer also needs its name in `locales/en.json` under `buyer`.

Keep buy prices **below** any store price for the same item, or players can buy from the store and sell to the buyer for free money.

## Editing the words (Liam)

All text is in **`locales/en.json`**. Only change the words on the right side, and keep every `%s`.
