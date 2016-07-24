class X2EnemyGroupTableManager extends X2LootTable
	native(Core)
	config(GameCore);

cpptext
{
}

//native function RollForEntryName(name LookupName, int Index, out Name Results);
native function RollForEntryNames(name LookupName, out Array<Name> Results);
