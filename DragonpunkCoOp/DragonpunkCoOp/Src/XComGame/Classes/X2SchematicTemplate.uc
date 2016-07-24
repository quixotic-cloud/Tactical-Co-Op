class X2SchematicTemplate extends X2ItemTemplate;

var(X2SchematicTemplate) array<name>	ItemsToUpgrade; // Deprecated! Still here to support mods compiled before this change
var(X2SchematicTemplate) array<name>	ItemRewards; // Items which should be given to the player when this schematic is built
var(X2SchematicTemplate) name			ReferenceItemTemplate; // Item which should be referenced for text & loc information

var(X2SchematicTemplate) bool			bSquadUpgrade; // Does this schematic provide an upgrade for the entire squad

var(X2SchematicTemplate) localized string	m_strSquadUpgrade;

function string GetItemFriendlyName(optional int ItemID = 0, optional bool bShowSquadUpgrade = true)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ReferenceTemplate;
	local string NameStr;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ReferenceTemplate = ItemTemplateManager.FindItemTemplate(ReferenceItemTemplate);

	FriendlyName = ReferenceTemplate.FriendlyName;
	NameStr = super.GetItemFriendlyName(ItemID);

	if (bSquadUpgrade && bShowSquadUpgrade)
	{
		NameStr @= m_strSquadUpgrade;
	}

	return NameStr;
}

function string GetItemBriefSummary(optional int ItemID = 0)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ReferenceTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ReferenceTemplate = ItemTemplateManager.FindItemTemplate(ReferenceItemTemplate);

	BriefSummary = ReferenceTemplate.BriefSummary;

	return super.GetItemBriefSummary(ItemID);
}

DefaultProperties
{
	ItemCat="schematic"
	CanBeBuilt = true;
	bOneTimeBuild = true;
	HideInInventory = true;
	HideInLootRecovered = true;
	bSquadUpgrade = true
	bShouldCreateDifficultyVariants=true
}