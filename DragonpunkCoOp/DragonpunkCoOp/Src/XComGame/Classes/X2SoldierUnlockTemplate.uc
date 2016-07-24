class X2SoldierUnlockTemplate extends X2StrategyElementTemplate;

var array<name> AllowedClasses;
var bool bAllClasses;
var string strImage;						 //  image associated with this ability

// Cost and Requirements
var config StrategyCost Cost;
var config StrategyRequirement Requirements;

var localized string DisplayName;
var protected localized string Summary;

function string GetDisplayName() { return DisplayName; }
function string GetSummary() { return `XEXPAND.ExpandString(Summary); }

function OnSoldierUnlockPurchased(XComGameState NewGameState);
function OnSoldierAddedToCrew(XComGameState_Unit NewUnitState);

function bool UnlockAppliesToUnit(XComGameState_Unit UnitState)
{
	local X2SoldierClassTemplate SoldierClassTemplate;

	if (UnitState == none)
		return false;
	SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
	if (SoldierClassTemplate == none)
		return false;
	if (!bAllClasses)
	{
		if (AllowedClasses.Find(SoldierClassTemplate.DataName) == INDEX_NONE)
			return false;
	}

	return true;
}

function bool ValidateTemplate(out string strError)
{
	local X2SoldierClassTemplateManager SoldierTemplateMan;
	local name SoldierClass;

	if (AllowedClasses.Length == 0 && !bAllClasses)
	{
		strError = "no AllowedClasses specified, and bAllClasses is false";
		return false;
	}
	SoldierTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();	
	foreach AllowedClasses(SoldierClass)
	{
		if (SoldierTemplateMan.FindSoldierClassTemplate(SoldierClass) == none)
		{
			strError = "references unknown soldier class template" @ SoldierClass;
			return false;
		}
	}
	return super.ValidateTemplate(strError);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}