//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILoadGame
//  AUTHOR:  Katie Hirsch       -- 01/22/10
//           Tronster              
//  PURPOSE: Serves as an interface for loading saved games.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UILoadGame extends UIScreen
	dependson(UIDialogueBox)
	dependson(UIProgressDialogue);

var int m_iCurrentSelection;
var array<OnlineSaveGame> m_arrSaveGames;
var array<UISaveLoadGameListItem> m_arrListItems;
var bool m_bPlayerHasConfirmedLosingProgress; 
var bool m_bLoadInProgress;

var UIList List;
var UIPanel ListBG;

var localized string m_sLoadTitle;
var localized string m_sLoadingInProgress;
var localized string m_sMissingDLCTitle;
var localized string m_sMissingDLCText;
var localized string m_sLoadFailedTitle;
var localized string m_sLoadFailedText;
var localized string m_strLostProgressTitle;
var localized string m_strLostProgressBody;
var localized string m_strLostProgressConfirm;
var localized string m_strDeleteLabel;
var localized string m_strLanguageLabel;
var localized string m_strWrongLanguageText;
var localized string m_strSaveOutOfDateTitle;
var localized string m_strSaveOutOfDateBody;
var localized string m_strLoadAnyway;
var localized string m_strSaveDifferentLanguage;
var localized string m_strSaveDifferentLanguageBody;

var array<int> SaveSlotStatus;

const m_bBlockingSavesFromOtherLanguages = true; //MUST BE ENABLED FOR SHIP!!! -bsteiner

var bool m_bNeedsToLoadDLC1MapImages; 
var bool m_bNeedsToLoadDLC2MapImages;
var bool m_bNeedsToLoadHQAssaultImage;
var bool m_bLoadCompleteCoreMapImages;
var bool m_bLoadCompleteDLC1MapImages;
var bool m_bLoadCompleteDLC2MapImages;
var bool m_bLoadCompleteHQAssaultImage;

// We need to hold references to the images to ensure they don't ever get unloaded by the Garbage Collector - sbatista 7/30/13
// Save the packagese, not the images. bsteiner 8/12/2013
var array<object> m_arrLoadedObjects;

var UINavigationHelp NavHelp;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	NavHelp = InitController.Pres.GetNavHelp();
	if(NavHelp == none)
		NavHelp = Spawn(class'UINavigationHelp',self).InitNavHelp();
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	ListBG = Spawn(class'UIPanel', self);
	ListBG.bIsNavigable = false;
	ListBG.InitPanel('SaveLoadBG'); 
	ListBG.Show();

	List = Spawn(class'UIList', self);
	List.InitList('listMC');
	
	XComInputBase(PC.PlayerInput).RawInputListener = RawInputHandler;
}

simulated function OnInit()
{
	local XComOnlineEventMgr OnlineEventMgr; 

	super.OnInit();	
	if( UIMovie_3D(Movie) == none )
		SetX(500);

	SetTitle(m_sLoadTitle);

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

	Navigator.SetSelected(List);
	if (List.ItemCount > 0)
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}
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

	if (FilterSaveGameList())
	{
		ShowSaveLanguageDialog();	
	}

	`ONLINEEVENTMGR.SortSavedGameListByTimestamp(m_arrSaveGames);	

	BuildMenu();

	// Close progress dialog
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);
}

simulated function bool FilterSaveGameList()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local int SaveGameIndex;
	local int SaveGameID;
	local bool RemoveSave;
	local string CurrentLanguage;
	local string SaveLanguage;
	local bool bDifferentLanguageDetected;

	OnlineEventMgr = `ONLINEEVENTMGR;
	CurrentLanguage = GetLanguage();
	
	SaveGameIndex = 0;
	while( SaveGameIndex < m_arrSaveGames.Length )
	{
		RemoveSave = false;
		SaveGameID = OnlineEventMgr.SaveNameToID(m_arrSaveGames[SaveGameIndex].Filename);

		// Filter out save games made in other languages
		if( m_bBlockingSavesFromOtherLanguages && !class'Engine'.static.IsConsoleAllowed() )
		{
			OnlineEventMgr.GetSaveSlotLanguage(SaveGameID, SaveLanguage);
			if( CurrentLanguage != SaveLanguage )
			{
				RemoveSave = true;
				bDifferentLanguageDetected = true;
			}
		}

		if( RemoveSave )
			m_arrSaveGames.Remove(SaveGameIndex, 1);
		else
			SaveGameIndex++;
	}

	return bDifferentLanguageDetected;
}

simulated function OnSaveDeviceLost()
{
	// Clear any dialogs on this screen
	Movie.Pres.Get2DMovie().DialogBox.ClearDialogs();

	// Back out of this screen entirely
	Movie.Stack.Pop( self );
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repreats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	if( !bIsInited ) 
		return true;
	//if( !QueryAllImagesLoaded() ) return true; //If allow input before the images load, you will crash. Serves you right. -bsteiner

	switch(cmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			return true;
	
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			OnDelete();
			return true;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			OnUDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			OnUDPadDown();
			break;

		default:
			break;			
	}

	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift)
{
	if(ActionMask == class'UIUtilities_Input'.const.FXS_ACTION_PRESS && (Key == 'Delete' || Key == 'BackSpace') && !Movie.Pres.UIIsShowingDialog())
	{
		OnDelete();
		return true;
	}
	return false;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string targetCallback;
	local int selected, buttonNum;

	targetCallBack = args[ 5 ];
	selected = int( Repl(targetCallBack, "saveItem", ""));
	targetCallBack = args[ args.Length - 1 ];
	buttonNum = int( Repl(targetCallBack, "Button", ""));

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		SetSelected(selected);
		
		if(buttonNum == 0)
		{			
			OnAccept();
		}
		else if(buttonNum == 1)
		{
			OnDelete();
		}
	}
	else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
	{
		SetSelected(selected);
		OnAccept();
	}
}

simulated public function OutdatedSaveWarningCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		LoadSelectedSlot();
	}
	else
	{
		//Reset this confirmation	
		m_bPlayerHasConfirmedLosingProgress = false;
	}
}

simulated public function DifferentLangSaveWarningCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		LoadSelectedSlot();
	}
	else
	{
		//Reset this confirmation	
		m_bPlayerHasConfirmedLosingProgress = false;
	}
}

simulated function ShowSaveLanguageDialog()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Normal;
	DialogData.strText = m_strWrongLanguageText;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(DialogData);
}

simulated function LoadSelectedSlot()
{
	local int SaveID;
	local TDialogueBoxData DialogData;
	local TProgressDialogData ProgressDialogData;
	local string MissingDLC;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bLoadInProgress = true;
	
	SaveID = GetSaveID(m_iCurrentSelection);
	if( !`ONLINEEVENTMGR.CheckSaveDLCRequirements(SaveID, MissingDLC) )
	{
		DialogData.eType = eDialog_Warning;
		DialogData.strTitle = m_sMissingDLCTitle;
		DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
				
		DialogData.strText = Repl(m_sMissingDLCText, "%modnames%", MissingDLC);

		DialogData.strAccept = m_strLoadAnyway;
		DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = DevDownloadableContentCheckOverride;

		Movie.Pres.UIRaiseDialog( DialogData );
	}
	else
	{
		`ONLINEEVENTMGR.LoadGame(SaveID, ReadSaveGameComplete);

		// Show a progress dialog if the load is being completed asynchronously
		if( m_bLoadInProgress )
		{
			ProgressDialogData.strTitle = m_sLoadingInProgress;
			Movie.Pres.UIProgressDialog(ProgressDialogData);
		}
	}
}

simulated function ReadSaveGameComplete(bool bWasSuccessful)
{
	local TDialogueBoxData kDialogData;

	m_bLoadInProgress = false;

	// Close progress dialog
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);

	if( bWasSuccessful )
	{
		// Close the load screen
		Movie.Stack.Pop(self);
	}
	else
	{
		// Warn about failed load
		kDialogData.eType     = eDialog_Warning;
		kDialogData.strTitle  = m_sLoadFailedTitle;
		kDialogData.strText   = m_sLoadFailedText;
		kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

		Movie.Pres.UIRaiseDialog( kDialogData );

		// Reset this confirmation
		m_bPlayerHasConfirmedLosingProgress = false;
	}
}

simulated public function ProgressCheckCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		m_bPlayerHasConfirmedLosingProgress = true;
		OnAccept();
	}
	else
	{
		m_bPlayerHasConfirmedLosingProgress = false;
	}
}

simulated function DevDownloadableContentCheckOverride(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		`ONLINEEVENTMGR.LoadGame(GetSaveID(m_iCurrentSelection), ReadSaveGameComplete);
	}
	else
	{
		m_bLoadInProgress = false;
	}
}

simulated function MissingDLCCheckCallback(eUIAction eAction)
{
	m_bLoadInProgress = false;
}

simulated public function OnAccept(optional UIButton control)
{
	local TDialogueBoxData kDialogData;
	local string mapName;

	if(m_bLoadInProgress)
		return;

	if( control != None && control.Owner != None && UISaveLoadGameListItem(control.Owner.Owner) != None )
	{
		SetSelection(UISaveLoadGameListItem(control.Owner.Owner).Index);
	}

	mapName = WorldInfo.GetMapName();
	class'UIUtilities_Image'.static.StripSpecialMissionFromMapName( mapName );

	if (m_iCurrentSelection < 0 || m_iCurrentSelection >= m_arrSaveGames.Length )
	{
		PlaySound(SoundCue'SoundUI.MenuCancelCue', true);
	}
	else if (!m_bPlayerHasConfirmedLosingProgress && WorldInfo.GRI.GameClass.name != 'XComShell') //Do not verify while in shell. This is also a sad hack to be able to check for this. But so it be. 
	{
		kDialogData.eType       = eDialog_Warning;
		kDialogData.strTitle    = m_strLostProgressTitle;
		kDialogData.strText     = m_strLostProgressBody;
		kDialogData.strAccept   = m_strLostProgressConfirm;
		kDialogData.strCancel   = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
		kDialogData.fnCallback  = ProgressCheckCallback;

		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else if (m_arrSaveGames[m_iCurrentSelection].bIsCorrupt)
	{
		kDialogData.eType       = eDialog_Warning;
		kDialogData.strTitle    = m_strSaveOutOfDateTitle;//"SAVE OUT OF DATE";
		kDialogData.strText     = m_strSaveOutOfDateBody;//"This save is out of date and will likely cause undesirable results. Load anyway?";
		kDialogData.strAccept   = m_strLoadAnyway;
		kDialogData.strCancel   = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
		kDialogData.fnCallback  = OutdatedSaveWarningCallback;

		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else if (m_arrListItems[m_iCurrentSelection].bIsDifferentLanguage)
	{
		kDialogData.eType       = eDialog_Warning;
		kDialogData.strTitle    = m_strSaveDifferentLanguage;			//"SAVE USED A DIFFERENT LANGUAGE";
		kDialogData.strText     = m_strSaveDifferentLanguageBody;		//"This save used a different language and may have some missing glyphs. Load anyway?";
		kDialogData.strAccept   = m_strLoadAnyway;
		kDialogData.strCancel   = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
		kDialogData.fnCallback  = DifferentLangSaveWarningCallback;

		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else
	{
		LoadSelectedSlot();
	}
}


// Lower pause screen
simulated public function OnCancel()
{
	NavHelp.ClearButtonHelp();
	`ONLINEEVENTMGR.bInitiateReplayAfterLoad = false;
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated public function OnDelete(optional UIButton control)
{
	local TDialogueBoxData kDialogData;

	if( m_iCurrentSelection >= 0 && m_iCurrentSelection < m_arrSaveGames.Length )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		// Warn before deleting save
		kDialogData.eType     = eDialog_Warning;
		kDialogData.strTitle  = class'UISaveGame'.default.m_sDeleteSaveTitle;
		kDialogData.strText   = class'UISaveGame'.default.m_sDeleteSaveText @ GetCurrentSelectedFilename();
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

simulated function string GetCurrentSelectedFilename()
{
	local string SaveName;
	if(m_arrSaveGames[m_iCurrentSelection].SaveGames[0].SaveGameHeader.PlayerSaveDesc != "")
	{
		SaveName = m_arrSaveGames[m_iCurrentSelection].SaveGames[0].SaveGameHeader.PlayerSaveDesc;
	}
	else
	{
		SaveName = `ONLINEEVENTMGR.m_sEmptySaveString @ `AUTOSAVEMGR.GetNextSaveID();
	}

	return SaveName;
}

simulated function ShowRefreshingListDialog(optional delegate<UIProgressDialogue.ProgressDialogOpenCallback> ProgressDialogOpenCallback=none)
{
	
}

simulated public function OnUDPadUp()
{
	local int numSaves;
	local int newSel;
	numSaves = GetNumSaves();

	if ( numSaves > 1 )
	{
		PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	}

	newSel = m_iCurrentSelection - 1;
	if (newSel < 0)
		newSel = numSaves - 1;

	SetSelection( newSel );
}


simulated public function OnUDPadDown()
{
	local int numSaves;
	local int newSel;
	numSaves = GetNumSaves();

	if ( numSaves > 1 )
	{
		PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	}

	newSel = m_iCurrentSelection + 1;
	if (newSel >= numSaves)
		newSel = 0;

	SetSelection( newSel );
}

simulated function SetTitle( string sTitle )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;

	myValue.s = sTitle;
	myArray.AddItem( myValue );

	Invoke("SetTitle", myArray);
}

simulated function SetSelected( int iTarget )
{
	if (iTarget >=0 && iTarget < List.GetItemCount())
	{
		Navigator.SetSelected(List.GetItem(iTarget));
	}
	else
	{
		Navigator.SetSelected(none);
	}

	/*local ASValue myValue;
	local Array<ASValue> myArray;

	SetSelection(iTarget);

	myValue.Type = AS_Number;

	myValue.n = m_iCurrentSelection;
	myArray.AddItem( myValue );

	Invoke("SetSelected", myArray);*/

}

simulated function SetSelection(int currentSelection)
{
	if( currentSelection == m_iCurrentSelection )
	{
		return;
	}

	if (m_iCurrentSelection >=0 && m_iCurrentSelection < m_arrListItems.Length)
	{
		m_arrListItems[m_iCurrentSelection].HideHighlight();
	}

	m_iCurrentSelection = currentSelection;
	
	if (m_iCurrentSelection < 0)
	{
		m_iCurrentSelection = GetNumSaves();
	}
	else if (m_iCurrentSelection > GetNumSaves())
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

	for( i = 0; i < m_arrSaveGames.Length; i++ )
	{
		m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(i, m_arrSaveGames[i], false, OnAccept, OnDelete, , SetSelection));
		m_arrListItems[i].ProcessMouseEvents(List.OnChildMouseEvent);
	}
	
	m_iCurrentSelection = 0;
}

simulated function int GetSaveID(int iIndex)
{
	if (iIndex >= 0 && iIndex < m_arrSaveGames.Length)
		return `ONLINEEVENTMGR.SaveNameToID(m_arrSaveGames[iIndex].Filename);

	return -1;      //  if it's not in the save game list it can't be loaded 
}

simulated function int GetNumSaves()
{
	return m_arrSaveGames.Length;
}

simulated function CoreImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem(LoadedObject);
	m_bLoadCompleteCoreMapImages = true;
	TestAllImagesLoaded(); 
}
simulated function DLC1ImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem(LoadedObject);
	m_bLoadCompleteDLC1MapImages = true;
	TestAllImagesLoaded(); 
}
simulated function DLC2ImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem(LoadedObject);
	m_bLoadCompleteDLC2MapImages = true;
	TestAllImagesLoaded(); 
}
simulated function HQAssaultImagesLoaded(object LoadedObject) 
{
	m_arrLoadedObjects.AddItem(LoadedObject);
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
	Movie.Pres.SetTimer( 0.2f, false, 'ImageCheck', self );
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
		mapTextureTest = Texture2D(DynamicLoadObject( mapImage, class'Texture2D'));
		
		if( mapTextureTest != none )
		{
			AS_ClearImage( i );
		}
	}
	
	AS_ReloadImages();
}

simulated function AS_Clear()
{
	Movie.ActionScriptVoid(screen.MCPath$".Clear");
}

simulated function AS_ReloadImages()
{
	Movie.ActionScriptVoid(screen.MCPath$".ReloadImages");
}

simulated function AS_ClearImage( int iIndex )
{
	Movie.ActionScriptVoid(screen.MCPath$".ClearImage");
}

event Destroyed()
{
	super.Destroyed();
	m_arrLoadedObjects.Length = 0;
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
		OnlineEventMgr.ClearSaveDeviceLostDelegate(OnSaveDeviceLost);
	}
}

DefaultProperties
{
	m_iCurrentSelection = 0;
	m_bLoadInProgress = false;

	Package = "/ package/gfxSaveLoad/SaveLoad";
	//MCName = "theScreen";

	InputState = eInputState_Evaluate;
	bConsumeMouseEvents=true

	m_bPlayerHasConfirmedLosingProgress=false;

	bAlwaysTick=true; // ensure this screen ticks when the game is paused

	m_bNeedsToLoadDLC1MapImages=false
	m_bNeedsToLoadDLC2MapImages=false 
	m_bLoadCompleteDLC1MapImages=false
	m_bLoadCompleteDLC2MapImages=false
	m_bLoadCompleteCoreMapImages=false
	
	bIsVisible = false; // This screen starts hidden
}
