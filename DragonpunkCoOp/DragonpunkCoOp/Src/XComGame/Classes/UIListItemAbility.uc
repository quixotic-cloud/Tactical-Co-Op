class UIListItemAbility extends UIPanel;

var privatewrite UIList List;
var privatewrite X2AbilityTemplate Ability;

var privatewrite UIScrollingText TitlePanel;
var privatewrite UIText DescPanel;
var privatewrite UIIcon IconPanel;

var privatewrite int Padding;
var privatewrite int IconSize;

simulated function UIListItemAbility InitListItemPerk(X2AbilityTemplate InitAbility, 
	optional EUIState ColorState = eUIState_Normal, optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList'));
	if (List == none)
	{
		`warn("UI list items must be owned by UIList.ItemContainer");
	}
	else if (!List.bIsHorizontal)
	{
		SetWidth(List.Width);

		Ability = InitAbility;

		IconPanel = Spawn(class'UIIcon', Self, 'perkIcon');
		IconPanel.InitIcon('perkIcon',,,, IconSize);		
		IconPanel.SetY(Padding * 0.5);
		IconPanel.LoadIcon(Ability.IconImage);

		TitlePanel = Spawn(class'UIScrollingText', Self, 'tf_title');
		TitlePanel.InitScrollingText('tf_title',, Width - IconSize - Padding, IconSize + Padding);
		TitlePanel.SetSubTitle(Ability.LocFriendlyName);

		DescPanel = Spawn(class'UIText', Self);		
		DescPanel.InitText('tf_description', Ability.GetMyLongDescription(),, OnDescPanelSizeRealized);
		DescPanel.SetPosition(IconPanel.X + IconSize + Padding, 28);
		DescPanel.SetWidth(Width - X - IconSize - (Padding * 2));
	}

	return self;
}

simulated function OnDescPanelSizeRealized()
{
	if (List == None)
	{
		return;
	}

	Height = DescPanel.Y + DescPanel.Height + Padding;

	List.OnItemSizeChanged(Self);
}

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

