# LootSet `1.0.0`

---

LootSet is an immutable loot container built around table-based configurations rather than raw objects

### Features

- Immutable configuration
- Full Luau type inference
- Weighted loot rolls
- Linear luck modifier
- Retry-based rolling
- Built-in sampling utilities

---

### Installation

##### Creator Store

you can get the module directly from [Creator Store](https://create.roblox.com/store/asset/73521444680703/LootSet)

##### Releases

if you need specific versions you can look into [releases](https://github.com/Meowtsun/LootSet/releases)

##### Wally

you can install using Wally `meowtsun/lootset@1.0.0`

---

### Overview

```lua
-- StoneDepositConfig.lua

local LootSet = require(...)
return LootSet.new({

    Wood = LootSet.loot(50, {
        DisplayName = "Wood",
        SellPrice = 1,
        StackSize = 99,
    }),

    Iron = LootSet.loot(15, {
        DisplayName = "Iron Ingot",
        SellPrice = 5,
        StackSize = 99,
    }),

    Diamond = LootSet.loot(3, {
        DisplayName = "Diamond",
        SellPrice = 25,
        StackSize = 10,
    }),

})
```

```lua
-- other scripts

local config = require("StoneDepositConfig.lua")
local asPercentage = true

print(config.Iron.DisplayName) -- Iron Ingot
print(config:GetWeightOf('Iron', asPercentage) -- ~22.06
-- usable as config

local luck = 0
local item = config:Roll(luck)
print(item)
print(item.DisplayName)
print(item.StackSize)
-- usable as lootbag, luck & attempts supported

local amount, luck = 300, 20
config:Sample('High Luck Test', amount, luck)
-- sampling for testing
```

---

### APIs

`LootSet.new(config: t) -> (LootSet & t)` - give back LootSet object

`LootSet.loot(weight: number, item: a) -> a` - for assigning loot

`LootSet:Roll(luck: number?, attempts: number?) -> a` - get random item, luck and attempts can be provided

`LootSet:Sample(name: string, amount: number, luck: number?, attempts: number?) -> ()` - sample results, prints in output

`LootSet:GetWeightOf(name: string, usePercentage: boolean?) -> (number)` - get weight of an item, use assigned index

`ListWeights: (self: LootSet, usePercentage: boolean?) -> {{Weight: number,Item: any}}` - get entire array of items and their weight
