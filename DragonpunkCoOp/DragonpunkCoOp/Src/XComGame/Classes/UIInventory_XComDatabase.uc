
class UIInventory_XComDatabase extends UIInventory;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	//Clear out this header. 
	m_strTotalLabel = "";

	super.InitScreen(InitController, InitMovie, InitName);
	
	SetChooseResearchLayout();
	PopulateData();

	if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M4_ReturnToAvenger') == eObjectiveState_NotStarted)
		MC.FunctionVoid("showIntroOverlay");

	if(XComHQPresentationLayer(Movie.Pres) != none)
	{
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, 0);
		MC.FunctionVoid("setArchiveLayout");
		`XCOMGRI.DoRemoteEvent('RewardsRecap');
	}
}

simulated function int SortEncyclopedia(X2EncyclopediaTemplate EntryA, X2EncyclopediaTemplate EntryB)
{
	if( EntryA.SortingPriority < EntryB.SortingPriority )
	{
		return 1;
	}
	else if( EntryA.SortingPriority > EntryB.SortingPriority )
	{
		return -1;
	}
	return 0;
}

simulated function PopulateData()
{
	local X2EncyclopediaTemplateManager EncyclopediaTemplateMgr;
	local X2DataTemplate Iter;
	local X2EncyclopediaTemplate CurrentHeader, CurrentEntry;
	local UIInventory_HeaderListItem HeaderItem;
	local array<X2EncyclopediaTemplate> HeaderTemplates, EntryTemplates, CategoryTemplates;
	//local UIInventory_HeaderListItem HeaderListItem;

	super.PopulateData();

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	EncyclopediaTemplateMgr = class'X2EncyclopediaTemplateManager'.static.GetEncyclopediaTemplateManager();

	foreach EncyclopediaTemplateMgr.IterateTemplates(Iter, None)
	{
		CurrentEntry = X2EncyclopediaTemplate(Iter);

		if(XComHQ.MeetsAllStrategyRequirements(CurrentEntry.Requirements))
		{
			if(CurrentEntry.bCategoryHeader)
			{
				HeaderTemplates.AddItem(CurrentEntry);
			}
			else
			{
				EntryTemplates.AddItem(CurrentEntry);
			}
		}
	}

	HeaderTemplates.Sort(SortEncyclopedia);

	foreach HeaderTemplates(CurrentHeader)
	{
		HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
		HeaderItem.bIsNavigable = false;
		HeaderItem.InitHeaderItem( "", CurrentHeader.GetListTitle());

		foreach EntryTemplates(CurrentEntry)
		{
			if( CurrentEntry.ListCategory == CurrentHeader.ListCategory )
			{
				CategoryTemplates.AddItem(CurrentEntry);
			}
		}

		CategoryTemplates.Sort(SortEncyclopedia);

		foreach CategoryTemplates(CurrentEntry)
		{
			Spawn(class'UIInventory_ListItem', List.ItemContainer).InitInventoryListXComDatabase(CurrentEntry);
		}

		CategoryTemplates.Remove(0, CategoryTemplates.Length);
	}

	SetCategory("");

	if(List.ItemCount > 0)
	{
		List.SetSelectedIndex(1);
		PopulateXComDatabaseCard(EntryTemplates[0]);
		List.Navigator.SelectFirstAvailable();
	}
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIInventory_ListItem ListItem;
	ListItem = UIInventory_ListItem(ContainerList.GetItem(ItemIndex));
	if( ListItem != none )
	{
		PopulateXComDatabaseCard(ListItem.XComDatabaseEntry);
	}
}

simulated function PopulateXComDatabaseCard(X2EncyclopediaTemplate EncyclopediaEntry)
{
	ItemCard.PopulateXComDatabaseCard(EncyclopediaEntry);
	ItemCard.Show();
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	//TODO @bsteiner : make tactical version
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated event Removed()
{
	super.Removed();
	//TODO @bsteiner : make tactical version
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

defaultproperties
{
	InputState= eInputState_Consume;
	bConsumeMouseEvents = true;
	bAutoSelectFirstNavigable = true;
	DisplayTag="UIDisplay_Council"
	CameraTag="UIDisplayCam_ResistanceScreen"
}