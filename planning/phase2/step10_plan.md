# Phase 2 · Step 10 Plan: Mounts tab, slots, Wolf and Horses in the shop
**Status:** BUILT 2026-09-24.
**Inputs:** PHASE_2_GOALS.md Step 10, GDD v1.8 (Mount Slot Progression, Horse, shop tabs), Garret's answers below.

## Decisions (Garret, 2026-09-24)
| Topic | Decision |
|---|---|
| Wolf damage | 1.5 per hit: a Grey Leaf (2 health) takes **2 passes**. Revisit when Leaf tiers exist (players may meet tougher Leaves before the Wolf). |
| Slots | **Capacity.** "Mount Slot" is a leveled row (slots 2–3 now; 4–6 after bosses later). "Horse" and "Wolf" rows buy a mount into the next free spot. Mounts space themselves evenly (GDD); moving never pays Gold. |
| Prices | Mount Slot 60 (×2.5 → 150 for slot 3). Wolf 80 (one per run, GDD). Extra Horse 150 (×1.5 each, up to 5 extras). |
| Selling | Extra Horses sell back for **50%** of what the last one cost. The starting Horse can't be sold (you always keep an income). |
| Tabs | **Carousel** (Speed, Boost Power, Ticket Booth) / **Combat** (Click Damage) / **Mounts** (Mount Slot, Horse, Wolf). |
| Start of run | Horse only; the hand-placed Wolf is removed. |
| Sprites | Kenney Animal Pack Remastered (CC0): Horse = `horse.png`, Wolf = `dog.png` (grey husky), round outline style. Top of the head points outward. Placeholder shapes stay for mounts without a sprite. |

## How it works
- **GameState** keeps the mount roster (an ordered list like horse, wolf, horse) and slot capacity. New effects: `ADD_MOUNT_SLOT`, `BUY_MOUNT` (the upgrade's `mount_scene` says which scene). A mount can only be bought with a free slot. `try_sell_mount()` refunds 50% of the last level's price (a refund, so it doesn't count toward Gold/sec).
- **UpgradeData** gains `tab`, `mount_scene`, `sell_refund_fraction`.
- **Game** builds mount nodes from the roster and lays them out evenly on the carousel (first one at the top, like the booth). Existing mounts are reused, so a Wolf keeps its hit memory, and a re-placed Wolf re-seeds itself so moving it never gives a free hit. The fixed Slot1–6 markers go away.
- **Shop** becomes a TabContainer with three tabs. Mount rows say "Needs an empty slot" when full, and the Horse row has a Sell button.

## Scene change (Game.tscn)
```
ShopPanel (PanelContainer, upgrade_shop.gd)
└── ShopMargin (MarginContainer)
    └── ShopTabs (TabContainer, unique name)   ← replaces UpgradeRows; tab pages built in code
World/Carousel/MountSlots (Node2D)            ← Slot1–6 markers, Horse and Wolf instances removed; mounts built in code
```

## Tests
- Slot/mount rules: no free slot → can't buy; slot adds room; Wolf once; Horse price grows; selling refunds 50%, frees a slot, doesn't count as income; the starting Horse can't be sold.
- Layout: n mounts are evenly spaced, the first at the top; re-spacing a Horse never pays a booth pass.
- Game scene: buying Slot 2 then Wolf puts a Wolf on the carousel that kills a latched Leaf; selling a Horse removes its node.
- Shop: three tabs, rows on the right tab, "needs an empty slot" state.

## Your steps
- Open Game.tscn and save once; check the shop tabs look right.
- Playtest: slot → Wolf moment; second Horse; selling.
- Replace placeholder text: tab titles, row names/descriptions, "Needs an empty slot", "Sell %d".
