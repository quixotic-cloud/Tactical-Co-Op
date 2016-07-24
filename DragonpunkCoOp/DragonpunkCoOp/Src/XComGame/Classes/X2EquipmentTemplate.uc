class X2EquipmentTemplate extends X2ItemTemplate
	native(Core);

/**
 * Equipment is the parent class for all items that can go in a unit's inventory (armor, weapons, misc items, etc.)
 * See X2WeaponTemplate for weapons.
 */

struct native UIStatMarkup
{
	var() int StatModifier;
	var() bool bForceShow;					// If true, this markup will display even if the modifier is 0
	var() localized string StatLabel;		// The user-friendly label associated with this modifier
	var() localized string StatUnit;		// The user-display unit for the stat, such as '%'
	var() ECharStatType StatType;			// The stat type of this markup (if applicable)
	var() delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;	// A function to check if the stat should be displayed or not
};

struct native AltGameArchetypeUse
{
	var() string ArchetypeString;
	var() delegate<ShouldUseGameArchetype> UseGameArchetypeFn;
};

var(X2EquipmentTemplate) string					GameArchetype;          //  archetype in editor with mesh, etc.
var(X2EquipmentTemplate) string					AltGameArchetype;       //  alternate archetype (e.g. female)
var(X2EquipmentTemplate) string					CosmeticUnitTemplate;	//  if there is a cosmetic unit associated with this item, specify the name of the template here
var(X2EquipmentTemplate) array<name>			Abilities;              //  list of Ability Template names this item grants its owner         
var(X2EquipmentTemplate) EInventorySlot			InventorySlot;
var(X2EquipmentTemplate) int					StatBoostPowerLevel;	 // corresponds to "rarity" of item, used for Personal Combat Sims
var(X2EquipmentTemplate) array<ECharStatType>	StatsToBoost;			 // What character stats does this item apply the boosts to?
var(X2EquipmentTemplate) bool					bUseBoostIncrement;		// If the item should boost stats using a hard increment value instead of a percentage. Used by some PCSs (HP, mobility)
var(X2EquipmentTemplate) string                 EquipNarrative;         //  Narrative moment to play when equipping this item in the armory
var(X2EquipmentTemplate) array<UIStatMarkup>	UIStatMarkups;			//  Values to display in the UI (so we don't have to dig through abilities and effects)
var(X2EquipmentTemplate) string					EquipSound;				// Sound to play on equip in the armory (Must be defined in the DefaultGameData.ini)

var(X2EquipmentTemplate) array<AltGameArchetypeUse>          AltGameArchetypeArray;

delegate bool ShouldUseGameArchetype(XComGameState_Item ItemState, XComGameState_Unit UnitState, string ConsiderArchetype);

function bool ValidateTemplate(out string strError)
{
	local name AbilityName;
	local X2AbilityTemplateManager AbilityTemplateManager;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach Abilities(AbilityName)
	{
		if (AbilityTemplateManager.FindAbilityTemplate(AbilityName) == none)
		{
			strError = "references an invalid ability:" @ AbilityName;
			return false;
		}
	}

	return super.ValidateTemplate(strError);
}

function SetUIStatMarkup(String InLabel,
	optional ECharStatType InStatType = eStat_Invalid, 
	optional int Amount = 0, 
	optional bool ForceShow = false, 
	optional delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShowUIStatFn,
	optional String InUnit)
{
	local UIStatMarkup StatMarkup;

	StatMarkup.StatLabel = InLabel;
	StatMarkup.StatUnit = InUnit;
	StatMarkup.StatModifier = Amount;
	StatMarkup.StatType = InStatType;
	StatMarkup.bForceShow = ForceShow;
	StatMarkup.ShouldStatDisplayFn = ShowUIStatFn;
			
	UIStatMarkups.AddItem(StatMarkup);
}

function int GetUIStatMarkup(ECharStatType Stat, optional XComGameState_Item Item)
{
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;
	local int Index;

	for( Index = 0; Index < UIStatMarkups.Length; ++Index )
	{
		ShouldStatDisplayFn = UIStatMarkups[Index].ShouldStatDisplayFn;
		if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
		{
			continue;
		}

		if( UIStatMarkups[Index].StatType == Stat)
		{
			return UIStatMarkups[Index].StatModifier;
		}
	}

	return 0;
}

function string DetermineGameArchetypeForUnit(XComGameState_Item ItemState, XComGameState_Unit UnitState)
{
	local delegate<ShouldUseGameArchetype> UseDelegate;
	local int i;

	for (i = 0; i < AltGameArchetypeArray.Length; ++i)
	{
		UseDelegate = AltGameArchetypeArray[i].UseGameArchetypeFn;
		if (UseDelegate != none && UseDelegate(ItemState, UnitState, AltGameArchetypeArray[i].ArchetypeString))
			return AltGameArchetypeArray[i].ArchetypeString;
	}
	return GameArchetype;
}