--[[
	---	------	------	------	------	------	------	------	------	------	------	---
	LootSet is an immutable loot container
		built around table-based configurations rather than raw objects
		+ It additionally support luck and retry-based rolling
		+ And support to full type-inferred configs
		
		LootSet also preferred boring and predictable Luck
			+ Luck is applied additively during a weight roll
	---	------	------	------	------	------	------	------	------	------	------	---
]]


const TOTAL_WEIGHT = newproxy(false)
const WEIGHT = newproxy(false)
const SORTED = newproxy(false)
const NAME = newproxy(false)

const SampleFormat = {   
	Header = '[%s]: sampled %d result (Luck: %d, Attempts: %d)',
	Listing = '	- %s : %d (about %.2f%% from %.2f%%)',
}

export type LootSet = {
	Sample: (self: LootSet, label: string, amount: number, luck: number?, attempts: number?) -> (),
	Roll: (self: LootSet, luck: number?, attempts: number?) -> (any, number),
		
	GetWeightOf: (self: LootSet, name: string, usePercentage: boolean?) -> (number),
	ListWeights: (self: LootSet, usePercentage: boolean?) -> {
		{ Weight: number, Item: any } 
	},
}

local LootSet = {}
LootSet.__index = LootSet


local function roll(min: number, max: number, luck: number)
	local value = max - math.floor(max * math.random() + luck)
	return math.clamp(value, min, max)
end


local function toPercentage(value, max)
	return value / max * 100
end


local function weightSort(a, b)
	return a[WEIGHT] < b[WEIGHT]
end


function LootSet.new<t> (config: t) : t & LootSet
	return setmetatable(config :: t, LootSet)
end


function LootSet.loot<t> (weight: number, loot: t): t
	local kind = typeof(loot)
	if kind ~= 'table' then
		error(`LootSet expected a table config, got {kind}`, 2)
	end
	
	loot[WEIGHT] = weight
	return loot
end


function LootSet:GetTotalWeight()
	
	local total_weight = self[TOTAL_WEIGHT]
	if total_weight then -- saved
		return total_weight
	end
	
	-- no weight was cached, set once
	total_weight = 0
	
	for name, item in self do
		if typeof(name) == 'userdata' then
			continue -- ignore this
		end
	
		total_weight += item[WEIGHT]
	end
	
	self[TOTAL_WEIGHT] = total_weight
	return total_weight
end


function LootSet:__getSortedMap()

	local sorted_map = self[SORTED]
	if sorted_map then -- saved
		return sorted_map
	end

	-- no sortmap was cached, set once
	sorted_map = {}
	
	for name, item in self do
		if typeof(name) == 'userdata' then
			continue -- ignore this
		end
		
		item[NAME] = name
		table.insert(sorted_map,item)
	end
	
	table.sort(sorted_map, weightSort)
	self[SORTED] = sorted_map
	
	return sorted_map
end


function LootSet:Roll(luck: number, attempts: number): any
	
	local score, best = math.huge, nil
	local luck = luck or 0
	local attempts = attempts or 1
	
	local sortedMap = self:__getSortedMap()
	local max_weight = self:GetTotalWeight()
	local divider = max_weight / 2
	-- # low weight ---> more weight
	
	local n = 0
	
	for index = 1, attempts do
		local value = roll(0, max_weight, luck)
		-- using middle (max_weight / 2) as divider to reduce iteration
		-- depends on current roll
		
		-- rarer one
		if value > divider then
			local upperbound = 0
			
			for index = 1, #sortedMap  do
				local item = sortedMap[index]
				local weight = item[WEIGHT]
				upperbound += weight
				n += 1
				if value <= upperbound and weight < score then
					best, score = item, weight
					break
				end
			end
			
		else -- common one
			local upperbound = max_weight
			
			for index = #sortedMap, 1, -1  do
				local item = sortedMap[index]
				local weight = item[WEIGHT]
				upperbound -= weight
				n += 1
				if value >= upperbound and weight < score then
					best, score = item, weight
					break
				end
			end
		end
	end
	
	return best, n
end


function LootSet:Sample(label: string, amount: number, luck: number, attempts: number)
	
	local attempts = attempts or 1
	local luck = luck or 0
	local n = 0
	
	local results = {
		--[[
			[item]: number,
			...
		]]
	}
	
	for index = 1, amount do
		local item, nInd = self:Roll(luck, attempts)
		n += nInd
		if results[item] then
			results[item] += 1
		else -- first one
			results[item] = 1
		end
	end
	
	local logs = string.format(SampleFormat.Header, label, amount, luck, attempts) 
	local sortedMap = self:__getSortedMap()
	local max_weight = self:GetTotalWeight()
	
	for _, item in sortedMap do
		
		local acquired = results[item] or 0
		local weight = item[WEIGHT]
		local name = item[NAME] :: string
		
		local estimated = toPercentage(weight, max_weight)
		local sampled = toPercentage(acquired, amount)
		
		logs ..= '\n' .. string.format(SampleFormat.Listing, name, acquired, sampled, estimated)
	end
	
	table.clear(results)
	print(logs .. `\nTotal iteration: {n} ({string.format('%.2f', toPercentage(n, #sortedMap * amount * attempts))}%)`)
end


function LootSet:ListWeights(usePercentage: boolean)
	local sortedMap = self:__getSortedMap()
	local max_weight = self:GetTotalWeight()
	local list = {
		--[[
			{
				Weight: number,
				Item: any,
			},
			...
		]]
	}
	
	for index, item in sortedMap do
		list[index] = {
			Item = item,
			Weight = if usePercentage
				then toPercentage(item[WEIGHT], max_weight)
				else item[WEIGHT]
		}
	end
	
	return list
end


function LootSet:GetWeightOf(name: string, usePercentage: boolean)
	local item = self[name]
	if not item then
		error(`LootSet.{name} does not exist`, 2)
	end
	
	local max_weight = self:GetTotalWeight()
	local weight = item[WEIGHT]
	
	return if usePercentage
		then toPercentage(weight, max_weight)
		else weight
end


return LootSet :: {
	loot: typeof(LootSet.loot),
	new: typeof(LootSet.new),
}