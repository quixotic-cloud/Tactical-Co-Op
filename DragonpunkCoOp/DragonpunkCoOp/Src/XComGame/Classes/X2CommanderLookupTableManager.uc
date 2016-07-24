class X2CommanderLookupTableManager extends Object
	config(GameCore);

var private config array<CommanderLookupTableEntry> AlienCommanderTables;
var private config array<CommanderLookupTableEntry> AdventCommanderTables;

var X2EnemyGroupTableManager GroupLookupTable;
var bool bInited;

static function X2CommanderLookupTableManager GetCommanderLookupTableManager()
{
	return class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().CommanderLookupTableManager;
}

function Init()
{
	if (!bInited)
	{
		GroupLookupTable = new class'X2EnemyGroupTableManager';
		GroupLookupTable.InitLootTables(false);
		bInited = true;
	}
}

function bool HasEncounteredCharacter(name strCharacter)
{
	return false;
}

function bool FindForceLevelEntry( int iForceLevel, out CommanderLookupTableEntry kEntry_out, bool bAdvent=false )
{
	local int iIndex, iBestIndex, iBestFL, iTableLength;
	local CommanderLookupTableEntry kEntry;

	iBestIndex = -1;
	iTableLength = bAdvent?AdventCommanderTables.Length:AlienCommanderTables.Length;
	// Find index based on force level.
	for (iIndex=0; iIndex < iTableLength; ++iIndex)
	{
		if (bAdvent)
			kEntry = AdventCommanderTables[iIndex];
		else
			kEntry = AlienCommanderTables[iIndex];
		if (kEntry.ForceLevel <= iForceLevel && (iBestIndex == -1 || kEntry.ForceLevel > iBestFL))
		{
			iBestFL = kEntry.ForceLevel;
			iBestIndex = iIndex;
		}
	}

	if (iBestIndex < 0)
		return false;

	if (bAdvent)
		kEntry_out = AdventCommanderTables[iBestIndex];
	else
		kEntry_out = AlienCommanderTables[iBestIndex];

	return true;
}

function name SelectCommander( CommanderLookupTableEntry kEntry )
{
	local array<Name> CommanderOptions;
	local int iIndex;
	local Name strCommander;

	// First pass, find units never encountered before.
	foreach kEntry.Option(strCommander)
	{
		if (!HasEncounteredCharacter(strCommander))
		{
			CommanderOptions.AddItem(strCommander);
		}
	}

	// All encountered already?  Add all options.
	if (CommanderOptions.Length == 0)
		CommanderOptions = kEntry.Option;

	// Never-before encountered options
	if (CommanderOptions.Length > 0)
	{
		iIndex = `SYNC_RAND(CommanderOptions.Length);
		return CommanderOptions[iIndex];
	}

	`Warn("X2CommanderLookupTableManager::SelectCommander() - Found no valid commanders from Commander Lookup Table!  Returning default - Sectoid.");
	return 'Sectoid';
}

function PullNamesFromGroupTable( name strGroupLookupName, out array<name> arrNames)
{
	GroupLookupTable.RollForEntryNames(strGroupLookupName, arrNames);
}