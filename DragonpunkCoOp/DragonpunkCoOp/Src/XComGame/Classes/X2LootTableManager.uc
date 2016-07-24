class X2LootTableManager extends X2LootTable
	native(Core)
	config(GameCore);


var config array<GlobalLootCarrier> GlobalLootCarriers;

static function X2LootTableManager GetLootTableManager()
{
	return class'X2ItemTemplateManager'.static.GetItemTemplateManager().LootTableManager;
}

function int FindGlobalLootCarrier(name CarrierName)
{
	local int i;

	for (i = 0; i < GlobalLootCarriers.Length; ++i)
	{
		if (GlobalLootCarriers[i].CarrierName == CarrierName)
			return i;
	}
	return -1;
}

native function RollForLootCarrier(const out LootCarrier Carrier, out LootResults Results);
native function RollForGlobalLootCarrier(int Index, out LootResults Results);
native static function string LootResultsToString(const out LootResults Results);
