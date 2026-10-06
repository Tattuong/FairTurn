# Google Play IAP — FairTurn

Package: `com.FairTurnMNG.FairTurn`

Remote config: `https://api2.blwsmartware.net/N299.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `ft_pack_1` | 50 |
| `ft_pack_2` | 100 |
| `ft_pack_3` | 200 |
| `ft_pack_4` | 350 |
| `ft_pack_5` | 500 |
| `ft_pack_6` | 750 |
| `ft_pack_7` | 1000 |
| `ft_pack_8` | 1500 |
| `ft_pack_9` | 2200 |
| `ft_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `ft_remove_ads` | Hide shop promo banners |
| `ft_pro` | Longer local history |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
