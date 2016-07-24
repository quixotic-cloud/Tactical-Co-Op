
class UIArmory_WeaponUpgradeStats extends UIPanel;

function UIArmory_WeaponUpgradeStats InitStats(optional name InstanceName, optional StateObjectReference WeaponRef)
{
	InitPanel(InstanceName);

	if(WeaponRef.ObjectID > 0)
		PopulateData(XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID)));
	else
		Hide();

	return self;
}

simulated function PopulateData(XComGameState_Item Weapon, optional X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local int i;
	local array<UISummary_ItemStat> ItemStats;

	ItemStats = Weapon.GetUISummary_WeaponStats(UpgradeTemplate);

	// pass label - value string pairs as variable arguments to be processed in flash
	MC.BeginFunctionOp("updateWeaponStats");
	for(i = 0; i < ItemStats.Length; ++i)
	{
		MC.QueueString(ItemStats[i].Label); 
		MC.QueueString(ItemStats[i].Value);
	}
	MC.EndOp();

	Show();
}

function SetAmmo(int current, int modifier)
{
	mc.BeginFunctionOp("setAmmo");
	mc.QueueString(class'XLocalizedData'.default.ClipSizeLabel);
	mc.QueueString(string(current));
	mc.QueueString(GetModifierString(modifier));
	mc.EndOp();
}

function SetAccuracy(int current, int modifier)
{
	mc.BeginFunctionOp("setAccuracy");
	mc.QueueString(class'XLocalizedData'.default.AimLabel);
	mc.QueueString(string(current));
	mc.QueueString(GetModifierString(modifier));
	mc.EndOp();
}

function SetRange(int current, int modifier)
{
	mc.BeginFunctionOp("setRange");
	mc.QueueString(class'XLocalizedData'.default.RangeLabel);
	mc.QueueString(string(current));
	mc.QueueString(GetModifierString(modifier));
	mc.EndOp();
}

function string GetModifierString(int modifier)
{
	if(modifier == 0)
		return "";
	else if(modifier > 0)
		return "+" $ modifier;
	else
		return string(modifier);
}

//==============================================================================

defaultproperties
{
	LibID = "WeaponStats";
	width = 320;
	height = 170;
}