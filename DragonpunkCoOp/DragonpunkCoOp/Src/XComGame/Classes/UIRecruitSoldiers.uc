
class UIRecruitSoldiers extends UIScreen;

var UIList List;

var array<XComGameState_Unit> m_arrRecruits;

var public localized string m_strListTitle;
var public localized string m_strNoRecruits;
var public localized string m_strCost;
var public localized string m_strTime;
var public localized string m_strInstant;
var public localized string m_strSupplies;
var public localized string m_strNotEnoughSuppliesToRecruitDialogueTitle; 
var public localized string m_strNotEnoughSuppliesToRecruitDialogueBody;

var int DeferredSoldierPictureListIndex; //The list index for the last selected soldier

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIPanel BG;

	super.InitScreen(InitController, InitMovie, InitName);

	List = Spawn(class'UIList', self);
	List.InitList('listMC');
	List.itemPadding = 5;
	List.OnSelectionChanged = OnRecruitChanged;
	List.OnItemDoubleClicked = OnRecruitSelected;

	BG = Spawn(class'UIPanel', self).InitPanel('InventoryListBG');
	BG.ProcessMouseEvents(List.OnChildMouseEvent);

	UpdateData();
	UpdateNavHelp();
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);

	if(`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp(class'UIRecruitmentListItem'.default.RecruitConfirmLabel);
}

simulated function UpdateData()
{
	local int i;
	local XComGameState_Unit Recruit;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	AS_SetTitle(m_strListTitle);

	List.ClearItems();
	m_arrRecruits.Length = 0;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(ResistanceHQ != none)
	{
		for(i = 0; i < ResistanceHQ.Recruits.Length; i++)
		{
			Recruit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ResistanceHQ.Recruits[i].ObjectID));
			m_arrRecruits.AddItem(Recruit);
			UIRecruitmentListItem(List.CreateItem(class'UIRecruitmentListItem')).InitRecruitItem(Recruit);
		}
	}

	if(m_arrRecruits.Length > 0)
	{
		List.SetSelectedIndex(0, true);
		List.Navigator.SelectFirstAvailable();
	}
	else
	{
		List.SetSelectedIndex(-1, true);
		AS_SetEmpty(m_strNoRecruits);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if(List.SelectedIndex != INDEX_NONE)
				OnRecruitSelected(List, List.SelectedIndex);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateData();
	UpdateNavHelp();
}

//------------------------------------------------------

simulated function OnRecruitChanged( UIList kList, int itemIndex )
{
	local XGParamTag LocTag;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Recruit;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local X2ImageCaptureManager CapMan;		
	local Texture2D StaffPicture;
	local string ImageString;

	if(itemIndex == INDEX_NONE) return;

	Recruit = m_arrRecruits[itemIndex];
	UnitRef = Recruit.GetReference();
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.IntValue0 = ResistanceHQ.GetRecruitSupplyCost();

	AS_SetCost(m_strCost, `XEXPAND.ExpandString(m_strSupplies));
	AS_SetDescription(Recruit.GetBackground());
	AS_SetTime(m_strTime, m_strInstant);
	AS_SetPicture(); // hide picture until character portrait is loaded
	
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());	
	ImageString = "UnitPicture"$UnitRef.ObjectID;
	StaffPicture = CapMan.GetStoredImage(UnitRef, name(ImageString));
	if(StaffPicture == none)
	{
		DeferredSoldierPictureListIndex = itemIndex;
		ClearTimer(nameof(DeferredUpdateSoldierPicture));
		SetTimer(0.1f, false, nameof(DeferredUpdateSoldierPicture));
	}	
	else
	{
		AS_SetPicture("img:///"$PathName(StaffPicture));
	}
}

function DeferredUpdateSoldierPicture()
{	
	local StateObjectReference UnitRef;
	local XComGameState_Unit Recruit;
	local XComPhotographer_Strategy Photo;	

	Recruit = m_arrRecruits[DeferredSoldierPictureListIndex];
	UnitRef = Recruit.GetReference();
		
	Photo = `GAME.StrategyPhotographer;	
	if (!Photo.HasPendingHeadshot(UnitRef, OnSoldierHeadCaptureFinished))
	{
		Photo.AddHeadshotRequest(UnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, OnSoldierHeadCaptureFinished,, false, true);
	}	
}

function OnSoldierHeadCaptureFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local string TextureName;
	local Texture2D SoldierPicture;
	local X2ImageCaptureManager CaptureManager;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Recruit;
	
	CaptureManager = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());

	TextureName = "UnitPicture"$ReqInfo.UnitRef.ObjectID;
	SoldierPicture = RenderTarget.ConstructTexture2DScript(CaptureManager, TextureName, false, false, false);
	CaptureManager.StoreImage(ReqInfo.UnitRef, SoldierPicture, name(TextureName));
	
	Recruit = m_arrRecruits[DeferredSoldierPictureListIndex];
	UnitRef = Recruit.GetReference();
	
	if (ReqInfo.UnitRef == UnitRef)
		AS_SetPicture("img:///"$PathName(SoldierPicture));
}

simulated function OnRecruitSelected( UIList kList, int itemIndex )
{
	local XComGameState_Unit Recruit;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	if(XComHQ.GetSupplies() >= ResistanceHQ.GetRecruitSupplyCost())
	{
		Recruit = m_arrRecruits[itemIndex];
		
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Recruit_Soldier");
		ResistanceHQ.GiveRecruit(Recruit.GetReference());
		UpdateData(); // Refresh the list

		`HQPRES.m_kAvengerHUD.UpdateResources();
	}
	else
	{
		if( XComHQ.GetSupplies() < ResistanceHQ.GetRecruitSupplyCost()) 
			NotEnoughSuppliesDialogue();

		//`HQPRES.SOUND().PlaySFX(`HQPRES.m_kSoundMgr.m_kSounds.SFX_UI_No);
	}
}

simulated function NotEnoughSuppliesDialogue()
{
	local TDialogueBoxData kDialogData;
	kDialogData.strTitle = m_strNotEnoughSuppliesToRecruitDialogueTitle; 
	kDialogData.strText = m_strNotEnoughSuppliesToRecruitDialogueBody; 
	Movie.Pres.UIRaiseDialog(kDialogData);
}

//==============================================================================

simulated function AS_SetTitle(string title)
{
	MC.FunctionString("setTitle", title);
}

simulated function AS_SetEmpty(string label)
{
	MC.FunctionString("setEmpty", label);
}

simulated function AS_SetCost(string label, string value)
{
	MC.BeginFunctionOp("setCost");
	MC.QueueString(label);
	MC.QueueString(value);
	MC.EndOp();
}

simulated function AS_SetTime(string label, string value)
{
	MC.BeginFunctionOp("setTime");
	MC.QueueString(label);
	MC.QueueString(value);
	MC.EndOp();
}

simulated function AS_SetDescription(string text)
{
	MC.FunctionString("setDescription", text);
}

simulated function AS_SetPicture(optional string path)
{
	local ASValue Data;
	local array<ASValue> DataArray;
	
	Data.Type = AS_String;
	Data.s = path;
	DataArray.AddItem(Data);

	Invoke("setPicture", DataArray);
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxNewRecruit/NewRecruit";
	bHideOnLoseFocus = false;
}