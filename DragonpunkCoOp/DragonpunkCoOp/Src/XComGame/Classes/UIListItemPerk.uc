//--    --------------------------------------------------------------------------
//  FILE:    UIListItemPerk.uc
//  AUTHOR:  Jake Akemann
//  PURPOSE: Used in UIList to display Perk info, icon, and a description together in one item
//----------------------------------------------------------------------------

class UIListItemPerk extends UIPanel;

var privatewrite UIList List;
var privatewrite UISummary_UnitEffect Perk;

var privatewrite UIScrollingText TitlePanel;
var privatewrite UIText DescPanel;
var privatewrite UIIcon IconPanel;

var privatewrite int Padding;
var privatewrite int IconSize;

simulated function UIListItemPerk InitListItemPerk(UISummary_UnitEffect InitPerk, optional EUIState ColorState = eUIState_Normal, optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList')); // list items must be owned by UIList.ItemContainer
	if(List == none)
		`warn("UI list items must be owned by UIList.ItemContainer");
	else if( !List.bIsHorizontal )
	{
		SetWidth(List.Width);

		Perk = InitPerk;

		IconPanel = Spawn(class'UIIcon', Self,'perkIcon');
		IconPanel.InitIcon('perkIcon',,,,IconSize);		
		IconPanel.SetY(Padding * 0.5f);
		RefreshIcon(); //logic to place the icon and give it a proper color based on the perk type

		//note: The TitlePanel and DescPanel are re-created here - Flash versions seem to still exist but are blank
		//we could probably take take them out of the FLA to ease confusion, but leaving in at the moment because memory impact is minimal - JTA 2016/1/2

		TitlePanel = Spawn(class'UIScrollingText', Self, 'tf_title');
		TitlePanel.InitScrollingText('tf_title',,Width - IconSize - Padding,IconSize + Padding);
		TitlePanel.SetSubTitle(Perk.Name);

		DescPanel = Spawn(class'UIText', Self);		
		DescPanel.InitText('tf_description',Perk.Description,,OnDescPanelSizeRealized);
		DescPanel.SetPosition(IconPanel.X + IconSize + Padding, 28);
		DescPanel.SetWidth(Width - X - IconSize - (Padding*2));
	}

	return self;
}

//called from Actionscript when it knows how big the textfield is. This function notifies the parent list that it's height has changed
simulated function OnDescPanelSizeRealized()
{
	if(List == None)
		return;

	//adds up the height of the total list item + padding so the list items look evenly spaced in the parent list
	Height = DescPanel.Y + DescPanel.Height + Padding;

	List.OnItemSizeChanged(Self);
}

simulated function RefreshIcon()
{
	local EUIState BGState;

	switch(Perk.AbilitySourceName)
	{
	case 'eAbilitySource_Perk':
		BGState = eUIState_Warning;
		break;
	case 'eAbilitySource_Debuff':
		BGState = eUIState_Bad;
		break;
	case 'eAbilitySource_Psionic':
		BGState = eUIState_Psyonic;
		break;
	case 'eAbilitySource_Commander': 
		BGState = eUIState_Good;
		break;
	case 'eAbilitySource_Item':
	case 'eAbilitySource_Standard':
	default:
		BGState = eUIState_Normal;
	}

	IconPanel.SetBGColorState(BGState);
	IconPanel.LoadIcon(Perk.Icon);
}

//intentionally does not call the super function
simulated function SetWidth(float NewWidth)
{
	Width = NewWidth;
}

defaultproperties
{
	LibID = "mc_perkListItem";
	bCascadeFocus = false;	
	Height = 125;
	Padding = 12;
	IconSize = 32;
}

