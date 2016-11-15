//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor.uc
//  AUTHOR:  Todd Smith  --  6/23/2015
//  PURPOSE: Edit dem squadz
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor extends UIMPShell_Base
	abstract;

var UIList m_kSlotList;
var UILargeButton LaunchButton;
var array<UIMPSquadSelect_ListItem> UnitInfos;

var localized string m_strReadyButtonText;
var localized string m_strSquadLoadoutChangedDialogTitle;
var localized string m_strSquadLoadoutChangedDialogText;
var localized string m_strSaveAsNewLoadoutButtonText;
var localized string m_strSaveNewInputDialogTitle;
var localized string m_strRenameLoadoutButtonText;
var localized string m_strRenameInputDialogTitle;
var localized string m_strSaveLoadout;
var localized string m_strSquadLoadoutSaveFailedTitle;
var localized string m_strSquadLoadoutSaveFailedText;

var UIPawnMgr m_kPawnMgr;
var XComGameState UpdateState;
var XComGameState_HeadquartersXCom XComHQ;
var array<XComUnitPawn> UnitPawns;
var array<XComGameState_Unit> Squad;
var int SoldierSlotCount;

var string m_strPawnLocationIdentifier;
var string UIDisplayCam;

var  XComGameState m_kSquadLoadout;
var  XComGameState m_kOriginalSquadLoadout;
var  XComGameState m_kTempLobbyLoadout;
var  XComGameState_Unit DirtiedUnit;
var  bool m_bLoadoutDirty;
var  bool m_bSavingLoadout;
var  bool m_bBackingOut;
var  bool m_bAllowEditing;
var  bool m_bKeyboardUp;
var vector MaleSoldierOffset;
var vector FemaleSoldierOffset;

var int m_NumAllowedUnits;

var UIMPShell_SquadCostPanel_LocalPlayer m_kLocalPlayerInfo;

var UISquadSelectMissionInfo m_MissionInfo;

var UINavigationHelp NavHelp;

var class<UIMPShell_Base> UINextScreenClass;

event PreBeginPlay()
{
	super.PreBeginPlay();
	SubscribeToOnCleanupWorld();
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int listItemPadding, listWidth, listX;

	super.InitScreen(InitController, InitMovie, InitName);

	listItemPadding = 6;
	listWidth = m_NumAllowedUnits * (class'UISquadSelect_ListItem'.default.width + listItemPadding);
	listX = Clamp((Movie.UI_RES_X / 2) - (listWidth / 2), 10, Movie.UI_RES_X / 2);
	m_kPawnMgr = Spawn( class'UIPawnMgr', Owner );
	m_kPawnMgr.SetCheckGameState(m_kSquadLoadout);

	if( `ISCONTROLLERACTIVE )	
	{
		m_kSlotList = Spawn(class'UIList_SquadEditor', self);
	}
	else
	{
		m_kSlotList = Spawn(class'UIList', self);
	}
	m_kSlotList.InitList('', listX, -450, Movie.UI_RES_X - 20, 310, true).AnchorBottomLeft();
	m_kSlotList.itemPadding = listItemPadding;

	m_MissionInfo = Spawn(class'UISquadSelectMissionInfo', self);
	m_MissionInfo.InitMissionInfo();

	XComShellPresentationLayer(InitController.Pres).CAMLookAtNamedLocation(CameraTag, 0.0f);

	InitSquadCostPanels();

	NavHelp = m_kMPShellManager.NavHelp;
}

simulated function OnInit()
{
	super.OnInit();

	m_MissionInfo.UpdateDataMP(m_kMPShellManager);

	CreatePawns();
	UpdateNavHelp();
	if( `ISCONTROLLERACTIVE ) Navigator.Clear();
}

simulated function UpdateGamepadFocus()
{
	local UIList_SquadEditor SquadList;

	SquadList = UIList_SquadEditor(m_kSlotList);
	SquadList.GetActiveListItem().OnReceiveFocus();
}

simulated function OnFirstListItemInited(UIPanel Panel)
{
	// bsg-cwade (7.10.16) : removed check so can still check details on squad
	UpdateGamepadFocus();
	// bsg-cwade (7.10.16) : end
//</workshop>
}
function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();

	NavHelp.AddBackButton(BackButtonCallback);
	
	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddSelectNavHelp();
		NavHelp.AddRightHelp(m_strReadyButtonText, class'UIUtilities_Input'.const.ICON_X_SQUARE, EditorReadyButtonCallback);
		NavHelp.AddCenterHelp(class'UIUtilities_Text'.default.m_strGenericDetails, class'UIUtilities_Input'.const.ICON_LSCLICK_L3, InfoButtonCallback);
		NavHelp.AddCenterHelp(m_strRenameLoadoutButtonText, class'UIUtilities_Input'.const.ICON_RSCLICK_R3, RenameLoadoutButtonCallback);
		NavHelp.AddCenterHelp(m_strSaveAsNewLoadoutButtonText, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, SaveAsNewLoadoutButtonCallback);
		NavHelp.AddCenterHelp(class'UIPauseMenu'.default.m_sSaveAndExitGame, class'UIUtilities_Input'.const.ICON_LT_L2,SaveAndExitCallback);
	}
	else
	{
		NavHelp.AddRightHelp(m_strReadyButtonText, "", EditorReadyButtonCallback);
		NavHelp.AddCenterHelp(m_strRenameLoadoutButtonText, "", RenameLoadoutButtonCallback);
		NavHelp.AddCenterHelp(m_strSaveAsNewLoadoutButtonText, "", SaveAsNewLoadoutButtonCallback);
		NavHelp.AddCenterHelp(class'UIPauseMenu'.default.m_sSaveAndExitGame, "",SaveAndExitCallback);
	}
}

function InitSquadCostPanels()
{
	m_kLocalPlayerInfo = Spawn(class'UIMPShell_SquadCostPanel_LocalPlayer', self);
	m_kLocalPlayerInfo.InitLocalPlayerSquadCostPanel(m_kMPShellManager, m_kSquadLoadout);
	m_kLocalPlayerInfo.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_CENTER);
	m_kLocalPlayerInfo.SetPosition(-250, 0);
}

function InitSquadEditor(XComGameState kSquadLoadout)
{
	m_kOriginalSquadLoadout = kSquadLoadout;
	m_kSquadLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kOriginalSquadLoadout);
	m_kPawnMgr.SetCheckGameState(m_kSquadLoadout);

	CreateSquadInfoItems();
	UpdateData();

	Navigator.SetSelected(UnitInfos[0]);
}

simulated function XComUnitPawn CreatePawn(XComGameState_Unit UnitRef, int index)
{
	local name LocationName;
	local PointInSpace PlacementActor;
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local vector    PlacementLocation;
	local array<AnimSet> GremlinHQAnims;

	UnitState = XComGameState_Unit(m_kSquadLoadout.GetGameStateForObjectID(UnitRef.ObjectID));
	if(UnitState.UnitSize > 1)
	{
		LocationName = name('Large'$m_strPawnLocationIdentifier $ index);
	}
	else
	{
		LocationName = name(m_strPawnLocationIdentifier $ index);
	}
	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if(PlacementActor != none && PlacementActor.Tag == LocationName)
			break;
	}
			
	PlacementLocation =  PlacementActor.Location;
	if(UnitState.IsSoldier())
	{
		if(UnitState.kAppearance.iGender == eGender_Male)
			PlacementLocation += MaleSoldierOffset;
		else
			PlacementLocation += FemaleSoldierOffset;
	}

	UnitPawn = m_kPawnMgr.RequestCinematicPawn(self, UnitRef.ObjectID, PlacementLocation, PlacementActor.Rotation, name("Soldier"$(index + 1)));
	UnitPawn.GotoState('CharacterCustomization');

	UnitPawn.CreateVisualInventoryAttachments(m_kPawnMgr, UnitState, m_kSquadLoadout, , false); // spawn weapons and other visible equipment

	GremlinPawn = m_kPawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (GremlinPawn != none)
	{
		SetGremlinMatineeVariable(name("Gremlin"$(index + 1)), GremlinPawn);

		GremlinHQAnims.AddItem(AnimSet'HQ_ANIM.Anims.AS_Gremlin');
		GremlinPawn.XComAddAnimSetsExternal(GremlinHQAnims);
	}

	return UnitPawn;
}

simulated function SetGremlinMatineeVariable(name GremlinName, XComUnitPawn GremlinPawn)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariable(GremlinName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(GremlinPawn);
		}
	}
}

simulated function ClearPawns()
{
	local XComUnitPawn UnitPawn;
	foreach UnitPawns(UnitPawn)
	{
		if(UnitPawn != none)
		{
			m_kPawnMgr.ReleaseCinematicPawn(self, UnitPawn.ObjectID, true);
		}
	}
}

simulated function ClearPawn(int pawnIndex)
{
	if(UnitPawns.Length > pawnIndex)
	{
		m_kPawnMgr.ReleaseCinematicPawn(self, UnitPawns[pawnIndex].ObjectID, true);
		UnitPawns[pawnIndex] = none;
	}
}

function CreateSquadInfoItems()
{
	local XComGameState_Unit kUnit;
	local UIMPSquadSelect_ListItem UnitInfo;
	local int i;

	for(i = 0; i < eMPNumUnitsPerSquad_MAX; i++)
	{
		UnitInfo = UIMPSquadSelect_ListItem(m_kSlotList.CreateItem(class'UIMPSquadSelect_ListItem'));
		UnitInfo.InitSquadListItem(m_kMPShellManager);
		UnitInfo.SetEditable(m_bAllowEditing);
		UnitInfos.AddItem(UnitInfo);
	}

	i = 0;
	if(m_kSquadLoadout != none)
	{
		foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', kUnit)
		{
			UnitInfos[i].SetLoadout(m_kSquadLoadout);
			UnitInfos[i].SetUnit(kUnit);
			i++;
		}

		while(i < m_NumAllowedUnits)
		{
			UnitInfos[i].SetLoadout(m_kSquadLoadout);

			UnitInfos[i++].SetUnit(none);	
		}
	}

	m_kLocalPlayerInfo.SetPlayerLoadout(m_kSquadLoadout);
}

function OnUnitDirtied(XComGameState_Unit kDirtyUnit)
{
	`log(self $ "::" $ GetFuncName() @ (kDirtyUnit != none ? kDirtyUnit.GetFullName() : "Unit deleted"),, 'uixcom_mp');
	m_bLoadoutDirty = true;
}

function BackButtonCallback()
{
	PC.Pres.DeactivateCustomizationManager(true);
	OnCancel();
}

function ShowWriteProfileFailedDialog()
{
	local TDialogueBoxData  kDialogData;

	kDialogData.strTitle = m_strSquadLoadoutSaveFailedTitle;
	kDialogData.strText = m_strSquadLoadoutSaveFailedText;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

function SaveProfileSettingsComplete_SaveButton(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_SaveButton);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		DirtiedUnit = none;
		UpdateData();
	}
	else
	{
		ShowWriteProfileFailedDialog();
	}
}
function SaveAsNewLoadoutButtonCallback()
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_bSavingLoadout),, 'uixcom_mp');
	DisplaySaveAsNewSquadDialog();
}

function RenameLoadoutButtonCallback()
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_bSavingLoadout),, 'uixcom_mp');
	DisplayRenameSquadDialog();
}

function SaveAndExitCallback()
{
	if(!m_bSavingLoadout)
	{
		m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveTempLobbyLoadoutComplete);
		m_bBackingOut = true;
		SaveLoadout();
	}
}

function EditorReadyButtonCallback()
{
	if(!m_bSavingLoadout)
	{
		`log(self $ "::" $ GetFuncName() @ "Saving loadout...",, 'uixcom_mp');
		m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveTempLobbyLoadoutComplete);
		SaveLoadout();
	}
}
function InfoButtonCallback()
{
	local UIMPSquadSelect_ListItem ListItem;

	if(m_kSlotList != None && m_kSlotList.GetSelectedItem() != None)
	{
		ListItem = UIMPSquadSelect_ListItem(m_kSlotList.GetSelectedItem());
		if(ListItem != None)
		{
			ListItem.OnClickedInfoButton(ListItem.InfoButton);
		}
	}
}

function SaveTempLobbyLoadoutComplete(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveTempLobbyLoadoutComplete);
	if(bSuccess)
	{
		if(m_bLoadoutDirty)
		{
			DisplaySaveSquadBeforeReadyDialog();
		}
		else if(m_bBackingOut)
		{
			CloseScreen();
		}
		else
		{
			DoReady();
		}
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "Failed to save temporary loadout");
		ShowWriteProfileFailedDialog();
	}
	m_bSavingLoadout = false;
}

function DoReady()
{
	local UIMPShell_Base nextScreen;
	nextScreen = Spawn(UINextScreenClass, Movie.Pres);
	if(nextScreen != none)
		`SCREENSTACK.Push(nextScreen);
	else
		UpdateData();
}

function string GetSquadLoadoutName()
{
	return XComGameStateContext_SquadSelect(m_kSquadLoadout.GetContext()).strLoadoutName;
}

simulated function CreatePawns()
{
	local XComGameState_Unit Unit, UpdatedUnit;

	foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		UpdatedUnit = XComGameState_Unit(m_kSquadLoadout.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		UnitPawns[Unit.MPSquadLoadoutIndex] = CreatePawn(UpdatedUnit, Unit.MPSquadLoadoutIndex);
	}
}

simulated function UpdateData(optional bool bFillSquad)
{
	local int i, j;
	local bool bFoundUnit;
	local XComGameState_Unit Unit, UpdatedUnit;

	//ClearPawns();
	Squad.Length = 0;

	foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		Squad.AddItem(Unit);
	}

	for(i = 0; i < eMPNumUnitsPerSquad_MAX; ++i)
	{
		bFoundUnit = false;

		UnitInfos[i].SetEditable(m_bAllowEditing && m_kSquadLoadout != none && !m_kLocalPlayerInfo.GetPlayerReady());
		UnitInfos[i].SetLoadout(m_kSquadLoadout);
		for(j = 0; j < Squad.Length; ++j)
		{
			Unit = Squad[j];
			if( (Unit.MPSquadLoadoutIndex == i || Unit.MPSquadLoadoutIndex == INDEX_NONE))
			{
				if(UnitInfos[i].GetUnitRef().ObjectID != Unit.ObjectID || UnitInfos[i].bIsDirty)
				{
					ClearPawn(i);
					UpdatedUnit = XComGameState_Unit(m_kSquadLoadout.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
					UpdatedUnit.MPSquadLoadoutIndex = i;
					UnitInfos[i].SetUnit(UpdatedUnit);
					UnitInfos[i].UpdateData(i);
				
					m_kSquadLoadout.AddStateObject(UpdatedUnit);
					UnitPawns[i] = CreatePawn(UpdatedUnit, i);

					bFoundUnit = true;
					break;
				}
				else if(UnitInfos[i].GetUnit() != none)
				{
					bFoundUnit = true;
					UnitInfos[i].UpdateData(i);
				}
			}
		}

		if(!bFoundUnit)
		{
			if(!m_bAllowEditing)
				UnitInfos[i].Hide();

			UnitInfos[i].SetUnit(none);
			UnitInfos[i].UpdateData(i);
		}
	}

	m_kLocalPlayerInfo.SetPlayerLoadout(m_kSquadLoadout);
}

// SAVE NEW
function DisplaySaveAsNewSquadDialog()
{
	local TInputDialogData kData;
	local int MAX_CHARS;

	MAX_CHARS = 50;

//	if(`ISCONTROLLERACTIVE == false )
//	{
		kData.strTitle = m_strSaveAsNewLoadoutButtonText;
		kData.strInputBoxText = GetSquadLoadoutName();
		kData.iMaxChars = MAX_CHARS;
		kData.fnCallbackAccepted = SaveAsNewDialogCallback_Accept;
		kData.fnCallbackCancelled = SaveAsNewDialogCallback_Cancel;
		
		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
		//WAS:
		//Movie.Pres.UIKeyboard(m_strSaveAsNewLoadoutButtonText,
		//	GetSquadLoadoutName(),
		//	VirtualKeyboard_OnSaveAsNewDialogAccepted,
		//	VirtualKeyboard_OnSaveAsNewDialogCancelled,
		//	false,
		//	MAX_CHARS
		//	);
		//INS:
		m_bKeyboardUp = Movie.Pres.UIKeyboard(m_strSaveAsNewLoadoutButtonText,
			GetSquadLoadoutName(), 
			VirtualKeyboard_OnSaveAsNewDialogAccepted, 
			VirtualKeyboard_OnSaveAsNewDialogCancelled,
			//<workshop> XR-018 JPS 2016/04/14
			//WAS:
			//false,
			true,
			//</workshop>
			MAX_CHARS
		);
		//</workshop>
	}*/

	NavHelp.Hide();
}

function SaveAsNewDialogCallback_Accept(string userInput)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(userInput),, 'uixcom_mp');
	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);
	m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_SaveAsNewButton);
	SaveAsNewLoadout(userInput);

	NavHelp.Show();
}

function SaveAsNewDialogCallback_Cancel(string userInput)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(userInput),, 'uixcom_mp');

	NavHelp.Show();
}

function VirtualKeyboard_OnSaveAsNewDialogAccepted(string text, bool bWasSuccessful)
{
	//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
	//INS:
	m_bKeyboardUp = false;
	//</workshop>

	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		SaveAsNewDialogCallback_Accept(text);
	}
	else
	{
		VirtualKeyboard_OnSaveAsNewDialogCancelled();
	}
}

function VirtualKeyboard_OnSaveAsNewDialogCancelled()
{
	//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
	//INS:
	m_bKeyboardUp = false;
	//</workshop>
	SaveAsNewDialogCallback_Cancel("");
}
function SaveProfileSettingsComplete_SaveAsNewButton(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_SaveAsNewButton);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		DirtiedUnit = none;

		UpdateData();
	}
	else
	{
		ShowWriteProfileFailedDialog();
	}
}

// RENAME
function DisplayRenameSquadDialog()
{
	local TInputDialogData kData;
	local int MAX_CHARS;

	MAX_CHARS = 50;

	//if(`ISCONTROLLERACTIVE == false )
	//{
		kData.strTitle = class'UIMPShell_SquadLoadoutList'.default.m_strRenameSquadDialogHeader;
		kData.strInputBoxText = GetSquadLoadoutName();
		kData.iMaxChars = MAX_CHARS;
		kData.fnCallbackAccepted = RenameDialogCallback_Accept;
		kData.fnCallbackCancelled = RenameDialogCallback_Cancel;
		
		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
		//WAS:
		//Movie.Pres.UIKeyboard(m_strSaveAsNewLoadoutButtonText,
		//	GetSquadLoadoutName(),
		//	VirtualKeyboard_OnSaveAsNewDialogAccepted,
		//	VirtualKeyboard_OnSaveAsNewDialogCancelled,
		//	false,
		//	MAX_CHARS
		//	);
		//INS:
		 m_bKeyboardUp = Movie.Pres.UIKeyboard(class'UIMPShell_SquadLoadoutList'.default.m_strRenameSquadDialogHeader,
			GetSquadLoadoutName(), 
			VirtualKeyboard_OnRenameDialogAccepted, 
			VirtualKeyboard_OnRenameDialogCancelled,
			//<workshop> XR-018 JPS 2016/04/14
			//WAS:
			//false,
			true,
			//</workshop>
			MAX_CHARS
		);
		 //</workshop>
	}*/

	NavHelp.Hide();
}

function RenameDialogCallback_Accept(string userInput)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(userInput),, 'uixcom_mp');
	m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_RenameButton);
	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);
	XComGameStateContext_SquadSelect(m_kSquadLoadout.GetContext()).strLoadoutName = userInput;
	SaveLoadout();

	NavHelp.Show();
}

function RenameDialogCallback_Cancel(string userInput)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(userInput),, 'uixcom_mp');

	NavHelp.Show();
}

function VirtualKeyboard_OnRenameDialogAccepted(string text, bool bWasSuccessful)
{
	//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
	//INS:
	m_bKeyboardUp = false;
	//</workshop>

	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		RenameDialogCallback_Accept(text);
	}
	else
	{
		VirtualKeyboard_OnRenameDialogCancelled();
	}
}

function VirtualKeyboard_OnRenameDialogCancelled()
{
	//<workshop> FAILED_KEYBOARD_BUG JAS 2016/05/19
	//INS:
	m_bKeyboardUp = false;
	//</workshop>

	RenameDialogCallback_Cancel("");
}
function SaveProfileSettingsComplete_RenameButton(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_RenameButton);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		UpdateData();
	}
	else
	{
		ShowWriteProfileFailedDialog();
	}
}


function SaveLoadout()
{
	if(!m_bSavingLoadout)
	{
		m_bSavingLoadout = true;
		m_bLoadoutDirty = false;
		DirtiedUnit = none;
		XComGameStateContext_SquadSelect(m_kSquadLoadout.GetContext()).iLoadoutId = XComGameStateContext_SquadSelect(m_kOriginalSquadLoadout.GetContext()).iLoadoutId;
		m_kMPShellManager.ReplaceSquadLoadout(m_kOriginalSquadLoadout, m_kSquadLoadout);
		m_kMPShellManager.WriteSquadLoadouts();

		m_kTempLobbyLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kSquadLoadout);
		// The original squad loadout wasn't being used for anything except for it's ID, so I'm making it equal to a clone of the loadout
		// so if we save as a new loadout, we can revert the original loadout to it's original state when we saved last. This was to fix
		// the case where if you save, make changes, then save as a new loadout, both old and new loadout would be the same as the latest
		// version of the layout. (kmartinez)
		m_kOriginalSquadLoadout = m_kTempLobbyLoadout;
		`XPROFILESETTINGS.X2MPWriteTempLobbyLoadout(m_kTempLobbyLoadout);
		m_kMPShellManager.SaveProfileSettings();
	}
}

function SaveAsNewLoadout(string strLoadoutName)
{
	local XComGameState kNewLoadout;
	local int i, j;
	local XComGameState_Unit Unit, UpdatedUnit;

	if(!m_bSavingLoadout)
	{
		m_bSavingLoadout = true;
		kNewLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kSquadLoadout, true);
		// This restores the original loadout on the first loadout in case we modified it since saving it. (kmartinez)
		m_kMPShellManager.ReplaceSquadLoadout(m_kSquadLoadout, m_kOriginalSquadLoadout);
		XComGameStateContext_SquadSelect(kNewLoadout.GetContext()).strLoadoutName = strLoadoutName;
		m_kMPShellManager.AddLoadoutToList(kNewLoadout);
		
		m_kMPShellManager.WriteSquadLoadouts();
		m_kMPShellManager.SaveProfileSettings();

		m_kSquadLoadout = kNewLoadout;
		// This used to just copy the reference, but now since we're getting better use out of the original squad loadout variable, we need
		// to create a clone, so that we can restore this loadout if necessary.(kmartinez)
		//m_kOriginalSquadLoadout = m_kSquadLoadout;
		m_kOriginalSquadLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kSquadLoadout);
		Squad.Length = 0;

		foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			Squad.AddItem(Unit);
		}

		m_kPawnMgr.CheckGameState = m_kSquadLoadout;
		for(i = 0; i < eMPNumUnitsPerSquad_MAX; ++i)
		{
			UnitInfos[i].SetLoadout(none);
			for(j = 0; j < Squad.Length; ++j)
			{
				Unit = Squad[j];
				if( (Unit.MPSquadLoadoutIndex == i || Unit.MPSquadLoadoutIndex == INDEX_NONE))
				{
					if(UnitInfos[i].GetUnit() != none)
					{
						ClearPawn(i);
						UpdatedUnit = XComGameState_Unit(m_kSquadLoadout.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
						UpdatedUnit.MPSquadLoadoutIndex = i;
						UnitInfos[i].SetUnit(UpdatedUnit);
						UnitInfos[i].SetLoadout(m_kSquadLoadout);
						UnitInfos[i].UpdateData(i);
				
						m_kSquadLoadout.AddStateObject(UpdatedUnit);
						UnitPawns[i] = CreatePawn(UpdatedUnit, i);
						break;
					}
				}
			}
		}
	}
}

function DisplaySaveSquadBeforeReadyDialog()
{
	local TDialogueBoxData kConfirmData;

	`ONLINEEVENTMGR.m_bMPConfirmExitDialogOpen = true;

	kConfirmData.strTitle = m_strSquadLoadoutChangedDialogTitle;
	kConfirmData.strText = Repl(m_strSquadLoadoutChangedDialogText, "%SQUADNAME", GetSquadLoadoutName());
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDisplaySaveSquadBeforeReadyDialog;
		
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplaySaveSquadBeforeReadyDialog(eUIAction eAction)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(eAction),, 'uixcom_mp');
	if(eAction == eUIAction_Accept)
	{
		m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_ReadyButton);
		SaveLoadout();
	}
	else
	{
		DoReady();
	}
}

function SaveProfileSettingsComplete_ReadyButton(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_ReadyButton);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		DirtiedUnit = none;
		DoReady();
	}

	else
	{
		ShowWriteProfileFailedDialog();
	}
}


function DisplaySaveSquadBeforeExitDialog()
{
	local TDialogueBoxData kConfirmData;

	`ONLINEEVENTMGR.m_bMPConfirmExitDialogOpen = true;

	kConfirmData.strTitle = m_strSquadLoadoutChangedDialogTitle;
	kConfirmData.strText = Repl(m_strSquadLoadoutChangedDialogText, "%SQUADNAME", GetSquadLoadoutName());
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDisplaySaveSquadBeforeExitDialog;
		
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplaySaveSquadBeforeExitDialog(eUIAction eAction)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(eAction),, 'uixcom_mp');
	if(eAction == eUIAction_Accept)
	{
		m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_Exit);
		SaveLoadout();
	}
	else
	{
		CloseScreen();
	}
}

function SaveProfileSettingsComplete_Exit(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_Exit);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		DirtiedUnit = none;
		CloseScreen();
	}
	else
	{
		ShowWriteProfileFailedDialog();
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	XComShellPresentationLayer(PC.Pres).CAMLookAtNamedLocation(CameraTag, 0.0f);
	PC.Pres.Get3DMovie().ShowDisplay(name(DisplayTag));
	m_kLocalPlayerInfo.Show();
	UpdateNavHelp();

	UpdateData();
}

simulated function OnCancel()
{
	if(!m_bSavingLoadout)
	{
		if(m_bLoadoutDirty)
		{
			m_bBackingOut = true;
			DisplaySaveSquadBeforeExitDialog();
		}
		else
		{
			Cleanup();
			CloseScreen();
		}
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if ( m_kSlotList.OnUnrealCommand(cmd, arg) )
	{
		return true;
	}
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B :
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
			OnCancel();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_START :
			EditorReadyButtonCallback();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_X :
			EditorReadyButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
			SaveAsNewLoadoutButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_L3 :
			InfoButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER :
			SaveAndExitCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_R3 :
			RenameLoadoutButtonCallback();
			return true;
		default:
			break;
	}
	return super.OnUnrealCommand(cmd, arg);
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	Cleanup();
}

function Cleanup()
{
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_ReadyButton);
}

simulated function CloseScreen()
{
	ClearPawns();
	super.CloseScreen();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	m_kLocalPlayerInfo.Hide();
	NavHelp.ClearButtonHelp();
}


//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	Package   = "/ package/gfxSquadList/SquadList";
	MCName    = "theScreen";

	m_NumAllowedUnits = 6;
	
	InputState = eInputState_Evaluate;
	bHideOnLoseFocus = true;
	bAutoSelectFirstNavigable = false;
	m_bAllowEditing=true;
	m_bKeyboardUp = false;
	MaleSoldierOffset=(X=0, Y=0, Z=10);
	FemaleSoldierOffset=(X=0, Y=0, Z=5);

	m_strPawnLocationIdentifier = "PreM_UIPawnLocation_SquadSelect_";
	UIDisplayCam = "PreM_UIDisplayCam_SquadSelect";
}