//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISaveGame
//  AUTHOR:  Katie Hirsch       -- 01/22/10
//           Tronster           -- 04/25/12
//  PURPOSE: Serves as an interface for loading saved games.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISaveGame extends UIScreen
	dependson(UIDialogueBox)
	dependson(UIProgressDialogue);

enum ESaveStage
{
	/** No save is taking place. */
	SaveStage_None,

	/** The save progress dialog is being open. */
	SaveStage_OpeningProgressDialog,

	/** The save game is being written to disk. */
	SaveStage_SavingGame,

	/** The user profile is being written to disk. */
	SaveStage_SavingProfile
};

var int m_iCurrentSelection;
var array<OnlineSaveGame> m_arrSaveGames;
var array<UISaveLoadGameListItem> m_arrListItems;
var OnlineSaveGame m_BlankSaveGame;

var UIList List;
var UIPanel ListBG;

var ESaveStage m_SaveStage; // The current stage a save operation is in

var localized string m_sSaveTitle;
var localized string m_sEmptySlot;
var localized string m_sRefreshingSaveGameList;
var localized string m_sSavingInProgress;
var localized string m_sSavingInProgressPS3;
var localized string m_sOverwriteSaveTitle;
var localized string m_sOverwriteSaveText;
var localized string m_sDeleteSaveTitle;
var localized string m_sDeleteSaveText;
var localized string m_sSaveFailedTitle;
var localized string m_sSaveFailedText;
var localized string m_sStorageFull;
var localized string m_sSelectStorage;
var localized string m_sFreeUpSpace;
var localized string m_sNameSave;

var bool m_bUseStandardFormSaveMsg; // Set to true if saves go over 1 second on Xbox 360
var bool m_bSaveNotificationTimeElapsed; // true if the save notification time requirement has been satisfied
var bool m_bSaveSuccessful; // true when a save has successfully been made

var bool m_bNeedsToLoadDLC1MapImages; 
var bool m_bNeedsToLoadDLC2MapImages;
var bool m_bNeedsToLoadHQAssaultImage;
var bool m_bLoadCompleteCoreMapImages;
var bool m_bLoadCompleteDLC1MapImages;
var bool m_bLoadCompleteDLC2MapImages;
var bool m_bLoadCompleteHQAssaultImage;

// We need to hold references to the images to ensure they don't ever get unloaded by the Garbage Collector - sbatista 7/30/13
var array<object> m_arrLoadedObjects;

var UINavigationHelp NavHelp;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddBackButton(OnCancel);

	ListBG = Spawn(class'UIPanel', self);
	ListBG.InitPanel('SaveLoadBG'); 
	ListBG.Show();

	List = Spawn(class'UIList', self);
	List.InitList('listMC');

	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(List);
	if (List.ItemCount > 0)
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	XComInputBase(PC.PlayerInput).RawInputListener = RawInputHandler;
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	m_iCurrentSelection = ItemIndex;
}

simulated function OnReadSaveGameListStarted()
{
	ShowRefreshingListDialog();
}

simulated function OnReadSaveGameListComplete(bool bWasSuccessful)
{
	if( bWasSuccessful )
		`ONLINEEVENTMGR.GetSaveGames(m_arrSaveGames);
	else
		m_arrSaveGames.Remove(0, m_arrSaveGames.Length);

	FilterSaveGameList();
	`ONLINEEVENTMGR.SortSavedGameListByTimestamp(m_arrSaveGames);		

	BuildMenu();

	// Close progress dialog
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);
}

simulated function FilterSaveGameList()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local int SaveGameIndex;
	local int SaveGameID;
	local bool RemoveSave;
	local string CurrentLanguage;
	local string SaveLanguage;

	OnlineEventMgr = `ONLINEEVENTMGR;
	CurrentLanguage = GetLanguage();
	
	SaveGameIndex = 0;
	while( SaveGameIndex < m_arrSaveGames.Length )
	{
		RemoveSave = false;
		SaveGameID = OnlineEventMgr.SaveNameToID(m_arrSaveGames[SaveGameIndex].Filename);

		// Filter out save games made in other languages
		if( class'UILoadGame'.const.m_bBlockingSavesFromOtherLanguages && !class'Engine'.static.IsConsoleAllowed() )
		{
			OnlineEventMgr.GetSaveSlotLanguage(SaveGameID, SaveLanguage);
			if( CurrentLanguage != SaveLanguage )
				RemoveSave = true;
		}

		if( RemoveSave )
			m_arrSaveGames.Remove(SaveGameIndex, 1);
		else
			SaveGameIndex++;
	}
}

simulated function OnSaveDeviceLost()
{
	// Clear any dialogs on this screen
	Movie.Pres.Get2DMovie().DialogBox.ClearDialogs();

	// Back out of this screen entirely
	Movie.Stack.Pop( self ); 
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	local XComOnlineEventMgr OnlineEventMgr; 

	super.OnInit();	
	SetX(500);
	
	AS_SetTitle(m_sSaveTitle);

	OnlineEventMgr = `ONLINEEVENTMGR;
	if( OnlineEventMgr != none )
	{
		OnlineEventMgr.AddUpdateSaveListStartedDelegate(OnReadSaveGameListStarted);
		OnlineEventMgr.AddUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
		OnlineEventMgr.AddSaveDeviceLostDelegate(OnSaveDeviceLost);
	}

	SubscribeToOnCleanupWorld();	

	if( OnlineEventMgr.bUpdateSaveListInProgress )
		OnReadSaveGameListStarted();
	else
		OnReadSaveGameListComplete(true);

	Show();
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, just pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;

	if( !bIsInited ) 
		return true;
	//if( !QueryAllImagesLoaded() ) return true; //If allow input before the images load, you will crash. Serves you right. -bsteiner

	// Don't accept input if we're in the middle of a save.
	if ( m_SaveStage != SaveStage_None )
		return true;

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			OnAccept();
			break;
	
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			OnDelete();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP: 
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			OnDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			OnDPadDown();
			break;

		default:
			// Do not reset handled, consume input since this
			// is the pause menu which stops any other systems.
			break;			
	}


	return super.OnUnrealCommand(ucmd, ActionMask);
}

simulated function bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift)
{
	if(ActionMask == class'UIUtilities_Input'.const.FXS_ACTION_PRESS && (Key == 'Delete' || Key == 'BackSpace') && !Movie.Pres.UIIsShowingDialog() )
	{
		OnDelete();
		return true;
	}
	return false;
}

simulated public function OnAccept(optional UIButton control)
{
	local TDialogueBoxData kDialogData;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	// Check to see if we're saving over an existing save game
	if( m_iCurrentSelection > 0 )
	{
		// Warn about overwriting an existing save
		kDialogData.eType     = eDialog_Warning;
		kDialogData.strTitle  = m_sOverwriteSaveTitle;
		kDialogData.strText   = m_sOverwriteSaveText;
		kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

		kDialogData.fnCallback  = OverwritingSaveWarningCallback;
		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else
	{
		// Saving into an empty slot
		`ONLINEEVENTMGR.SetPlayerDescription(GetCurrentSelectedFilename());
		Save();
	}
}

simulated function OverwritingSaveWarningCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		`ONLINEEVENTMGR.SetPlayerDescription(GetCurrentSelectedFilename());
		Save();
	}
}

simulated function Save()
{
	local TProgressDialogData kDialogData;

	// Cannot do two saves at the same time
	if( m_SaveStage != SaveStage_None )
	{
		`log("UISaveGame cannot save. A save is already in progress.");
		return;
	}

	// Cannot create a new save if there is insufficient space
	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) && m_iCurrentSelection == 0 && !`ONLINEEVENTMGR.CheckFreeSpaceForSave_Xbox360() )
	{
		`log("UISaveGame cannot save. There is insufficient space on the save device.");
		StorageFullDialog();
		return;
	}

	if( !WorldInfo.IsConsoleBuild() )
	{
		// On PC saving is synchronous and near instantaneous.
		// This being the case there is no point in opening a progress dialog.
		// Just skip straight to the saving game stage.
		m_SaveStage = SaveStage_SavingGame;
		`ONLINEEVENTMGR.SaveGame(GetSaveID(m_iCurrentSelection), false, false, SaveGameComplete);
	}
	else
	{
		// On consoles saving is asynchronous and a little slow. We use a progress dialog here.

		// Cannot save if a progress dialog is open. It will conflict with the
		// progress dialog for the save game which could cause issues.
		if( Movie.Pres.IsInState('State_ProgressDialog') )
		{
			`log("UISaveGame cannot save. A progress dialog is open");
			return;
		}

		m_SaveStage = SaveStage_OpeningProgressDialog;

		if( m_bUseStandardFormSaveMsg )
			kDialogData.strTitle = WorldInfo.IsConsoleBuild(CONSOLE_Xbox360)? m_sSavingInProgress : m_sSavingInProgressPS3;
		else
			kDialogData.strTitle = class'XComOnlineEventMgr'.default.m_strSaving; // Short form saving message

		kDialogData.fnProgressDialogOpenCallback = SaveProgressDialogOpen;
		Movie.Pres.UIProgressDialog(kDialogData);
	}
}

simulated function SaveProgressDialogOpen()
{
	// Now we can move on to the save game stage
	m_SaveStage = SaveStage_SavingGame;
	`ONLINEEVENTMGR.SaveGame(GetSaveID(m_iCurrentSelection), false, false, SaveGameComplete);
	m_bSaveNotificationTimeElapsed = false;
	Movie.Pres.SetTimer((m_bUseStandardFormSaveMsg)? 3 : 1, false, 'SaveNotificationTimeElapsed', self);
}

simulated function SaveNotificationTimeElapsed()
{
	m_bSaveNotificationTimeElapsed = true;
	CloseSavingProgressDialogWhenReady();
}

simulated function SaveGameComplete(bool bWasSuccessful)
{
	if( bWasSuccessful )
	{
		m_bSaveSuccessful = true;

		// Save the profile settings
		m_SaveStage = SaveStage_SavingProfile;

		`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete);
		`ONLINEEVENTMGR.SaveProfileSettings();
	}
	else
	{
		// Close progress dialog
		Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);

		m_SaveStage = SaveStage_None;

		// Warn about failed save
		if( `ONLINEEVENTMGR.OnlineSub.ContentInterface.IsStorageFull() )
			StorageFullDialog();
		else
			FailedSaveDialog();
	}
}

simulated function SaveProfileSettingsComplete(bool bWasSuccessful)
{
	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete);

	if( m_SaveStage == SaveStage_SavingProfile )
	{
		m_SaveStage = SaveStage_None;

		if( WorldInfo.IsConsoleBuild() )
			CloseSavingProgressDialogWhenReady();
		else
			Movie.Stack.Pop(self); // Close the save screen after a successful save is finished
	}
}

/** Checks both the save stage and the progress dialog time to determine if it is ok to close the progress dialog */
simulated function CloseSavingProgressDialogWhenReady()
{
	// Close progress dialog if the save is complete
	if( m_SaveStage == SaveStage_None && m_bSaveNotificationTimeElapsed )
	{
		// Close the progress dialog
		Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);

		// Close the save screen after a successful save is finished
		if( m_bSaveSuccessful )
			Movie.Stack.Pop(self);
	}
}

simulated function FailedSaveDialog()
{
	local TDialogueBoxData DialogData;

	DialogData.eType     = eDialog_Warning;
	DialogData.strTitle  = m_sSaveFailedTitle;
	DialogData.strText   = m_sSaveFailedText;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	Movie.Pres.UIRaiseDialog( DialogData );
}

simulated function StorageFullDialog()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Warning;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		DialogData.strTitle   = m_sStorageFull;
		DialogData.strText    = m_sSelectStorage;
		DialogData.strCancel  = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = StorageFullDialogCallback360;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		DialogData.strTitle   = m_sStorageFull;
		DialogData.strText    = m_sFreeUpSpace;
		DialogData.strCancel  = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = StorageFullDialogCallbackPS3;
	}
	else // PC
	{
		DialogData.strText = m_sStorageFull;
	}

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function StorageFullDialogCallback360(eUIAction eAction)
{
	if( eAction == eUIAction_Accept )
	{
		`ONLINEEVENTMGR.SelectStorageDevice();
	}
}

simulated function StorageFullDialogCallbackPS3(eUIAction eAction)
{
	if( eAction == eUIAction_Accept )
	{
		`ONLINEEVENTMGR.DeleteSaveDataFromListPS3();
	}
}

// Lower pause screen
simulated public function OnCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated public function OnDelete(optional UIButton control)
{
	local TDialogueBoxData kDialogData;

	if( m_iCurrentSelection > 0 && m_iCurrentSelection <= m_arrSaveGames.Length )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		// Warn before deleting save
		kDialogData.eType     = eDialog_Warning;
		kDialogData.strTitle  = m_sDeleteSaveTitle;
		kDialogData.strText   = m_sDeleteSaveText @ GetCurrentSelectedFilename();
		kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

		kDialogData.fnCallback  = DeleteSaveWarningCallback;
		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else
	{
		// Can't delete an empty save slot!
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated public function OnRename(optional UIButton control)
{
	local TInputDialogData kData;

	kData.strTitle = m_sNameSave;
	kData.iMaxChars = 40;
	kData.strInputBoxText = GetCurrentSelectedFilename();
	kData.fnCallbackAccepted = SetCurrentSelectedFilename;
	
	Movie.Pres.UIInputDialog(kData);
}

simulated function SetCurrentSelectedFilename(string text)
{	
	text = Repl(text, "\n", "", false);
	m_arrListItems[m_iCurrentSelection].UpdateSaveName(text);

	`ONLINEEVENTMGR.SetPlayerDescription(text); // Will be cleared by the saving process
	Save();		
}

simulated function string GetCurrentSelectedFilename()
{
	local string SaveName;
	if(m_iCurrentSelection > 0 && m_arrSaveGames[m_iCurrentSelection-1].SaveGames[0].SaveGameHeader.PlayerSaveDesc != "")
	{
		SaveName = m_arrSaveGames[m_iCurrentSelection-1].SaveGames[0].SaveGameHeader.PlayerSaveDesc;
	}
	else
	{
		SaveName = `ONLINEEVENTMGR.m_sEmptySaveString @ `AUTOSAVEMGR.GetNextSaveID();
	}

	return SaveName;
}

simulated function DeleteSaveWarningCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		if (WorldInfo.IsConsoleBuild())
		{
			// On Console start by showing a progress dialog.
			// Then, when the dialog is open, delete the file.
			ShowRefreshingListDialog(DeleteSelectedSaveFile);
		}
		else
		{
			// On PC this is all nearly instantaneous.
			// Skip the progress dialog.
			DeleteSelectedSaveFile();
		}
	}
}

simulated function DeleteSelectedSaveFile()
{
	`ONLINEEVENTMGR.DeleteSaveGame( GetSaveID(m_iCurrentSelection) );
}

simulated function ShowRefreshingListDialog(optional delegate<UIProgressDialogue.ProgressDialogOpenCallback> ProgressDialogOpenCallback=none)
{
}

simulated public function OnDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	SetSelection(m_iCurrentSelection - 1);
}


simulated public function OnDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	SetSelection(m_iCurrentSelection + 1);
}

simulated function SetSelection(int currentSelection)
{
	if (m_iCurrentSelection >=0 && m_iCurrentSelection < m_arrListItems.Length)
	{
		m_arrListItems[m_iCurrentSelection].HideHighlight();
	}

	m_iCurrentSelection = currentSelection;
	
	if (m_iCurrentSelection < 0)
	{
		m_iCurrentSelection = GetNumSaves();
	}
	else if (m_iCurrentSelection >= (GetNumSaves() + 1))
	{
		m_iCurrentSelection = 0;
	}

	if (m_iCurrentSelection >=0 && m_iCurrentSelection < m_arrListItems.Length)
	{
		m_arrListItems[m_iCurrentSelection].ShowHighlight();
	}
}

simulated function BuildMenu()
{
	local int i;

	AS_Clear(); // Will be called after deleting a save
	List.ClearItems();
	m_arrListItems.Remove(0, m_arrListItems.Length);

	m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(0, m_BlankSaveGame, true, OnAccept, OnDelete, OnRename, SetSelection));
	m_arrListItems[0].ProcessMouseEvents(List.OnChildMouseEvent);

	for( i = 1; i <= m_arrSaveGames.Length; i++ )
	{
		m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(i, m_arrSaveGames[i-1], true, OnAccept, OnDelete, OnRename, SetSelection));
		m_arrListItems[i].ProcessMouseEvents(List.OnChildMouseEvent);
	}
	
	m_iCurrentSelection = 0;
}

simulated function int GetSaveID(int iIndex)
{
	if (iIndex > 0 && iIndex <= m_arrSaveGames.Length)
		return `ONLINEEVENTMGR.SaveNameToID(m_arrSaveGames[iIndex-1].Filename);

	return `AUTOSAVEMGR.GetNextSaveID(); //  if not saving over an existing game, get a new save ID
}

simulated function int GetNumSaves()
{
	return m_arrSaveGames.Length;
}

simulated function CoreImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem( LoadedObject );
	m_bLoadCompleteCoreMapImages = true;
	TestAllImagesLoaded(); 
}
simulated function DLC1ImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem( LoadedObject );
	m_bLoadCompleteDLC1MapImages = true;
	TestAllImagesLoaded(); 
}
simulated function DLC2ImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem( LoadedObject );
	m_bLoadCompleteDLC2MapImages = true;
	TestAllImagesLoaded(); 
}
simulated function HQAssaultImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem( LoadedObject );
	m_bLoadCompleteHQAssaultImage = true;
	TestAllImagesLoaded();
}
simulated function bool QueryAllImagesLoaded()
{
	if( !m_bLoadCompleteCoreMapImages )
		return false;

	if( m_bNeedsToLoadDLC1MapImages && !m_bLoadCompleteDLC1MapImages )
		return false;
	
	if( m_bNeedsToLoadDLC2MapImages && !m_bLoadCompleteDLC2MapImages )
		return false;

	if( m_bNeedsToLoadHQAssaultImage && !m_bLoadCompleteHQAssaultImage )
		return false;
	
	return true;
}
simulated function TestAllImagesLoaded()
{
	if( !QueryAllImagesLoaded() ) return; 

	ClearTimer('ImageCheck'); 
	ReloadImages();
	Movie.Pres.UILoadAnimation(false);
}

simulated function ReloadImages() 
{
	//Must call this outside of the async request
	Movie.Pres.SetTimer( 0.1f, false, 'ImageCheck', self );
}

simulated function ImageCheck()
{
	local int i;
	local string mapName, mapImage;
	local Texture2D mapTextureTest;

	//Check to see if any images fail, and clear the image if failed so the default image will stay.
	for( i = 0; i < m_arrSaveGames.Length; i++ )
	{
		`ONLINEEVENTMGR.GetSaveSlotMapName(GetSaveID(i), mapName);
		if(mapName == "") continue;

		mapImage = class'UIUtilities_Image'.static.GetMapImagePackagePath( name(mapName) );
		`log("++++ UISaveGame: SetMapImage - '" $ mapImage $ "'",,'uixcom');
		mapTextureTest = Texture2D(DynamicLoadObject( mapImage, class'Texture2D'));
		
		if( mapTextureTest == none )
		{
			//Do nothing.
			m_arrListItems[i].ClearImage();
		}
	}
	
	AS_ReloadImages();
}

//----------------------------------------------------------------------------
// Flash calls
//----------------------------------------------------------------------------

simulated function AS_AddListItem( int id, string desc, string gameTime, string saveTime, bool bIsDisabled, string imagePath )
{
	Movie.ActionScriptVoid(screen.MCPath$".AddListItem");
}

simulated function AS_ReloadImages()
{
	Movie.ActionScriptVoid(screen.MCPath$".ReloadImages");
}

simulated function AS_Clear()
{
	Movie.ActionScriptVoid(screen.MCPath$".Clear");
}

simulated function AS_SetTitle( string sTitle )
{
	Movie.ActionScriptVoid(screen.MCPath$".SetTitle");
}

//----------------------------------------------------------------------------
// Cleanup
//----------------------------------------------------------------------------

event Destroyed()
{
	super.Destroyed();
	m_arrLoadedObjects.length = 0; 
	DetachDelegates();
	UnsubscribeFromOnCleanupWorld();
}

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	DetachDelegates();
}

simulated function DetachDelegates()
{
	local XComOnlineEventMgr OnlineEventMgr;

	OnlineEventMgr = `ONLINEEVENTMGR;
	if( OnlineEventMgr != none )
	{
		OnlineEventMgr.ClearUpdateSaveListStartedDelegate(OnReadSaveGameListStarted);
		OnlineEventMgr.ClearUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
		OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete);
		OnlineEventMgr.ClearSaveDeviceLostDelegate(OnSaveDeviceLost);
	}
}

DefaultProperties
{
	m_iCurrentSelection = 0;
	m_SaveStage = SaveStage_None;

	Package   = "/ package/gfxSaveLoad/SaveLoad";

	InputState= eInputState_Consume;
	bConsumeMouseEvents=true

	m_bUseStandardFormSaveMsg=false // Set to true if saves go over 1 second on Xbox 360
	m_bSaveSuccessful=false
	
	m_bNeedsToLoadDLC1MapImages=false
	m_bNeedsToLoadDLC2MapImages=false 
	m_bLoadCompleteDLC1MapImages=false
	m_bLoadCompleteDLC2MapImages=false
	m_bLoadCompleteCoreMapImages=true

	bIsVisible = false; // This screen starts hidden
}
