//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_AbilityContainer.uc
//  AUTHOR:  Brit Steiner, Tronster
//  PURPOSE: Containers holding current soldiers ability icons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_AbilityContainer extends UIPanel
	dependson( X2GameRuleset )
	dependson( UITacticalHUD )
	dependson( UIAnchoredMessageMgr);

// These values must be mirrored in the AbilityContainer actionscript file.
const MAX_NUM_ABILITIES = 15;
const MAX_NUM_ABILITIES_PER_ROW = 7;

var bool bShownAbilityError;

var int                      m_iCurrentIndex;    // Index of selected item.

var int TargetIndex;
var array<AvailableAction> m_arrAbilities;
var array<UITacticalHUD_Ability> m_arrUIAbilities;

var int              m_iMouseTargetedAbilityIndex;  //Captures the targeted ability clicked by the mouse 
var int                      m_kWatchVar_Enemy;             // Watching which enemy is targeted 
var int                      m_iUseOnlyAbility;             // Don't allow the user to use any ability except the designated ability. -dwuenschell

var int                      m_iSelectionOnButtonDown;      // The current index when an input is pressed

var X2TargetingMethod TargetingMethod;

var StateObjectReference LastActiveUnitRef;

//----------------------------------------------------------------------------
// LOCALIZATION
//
var localized string m_sNoTargetsHelp;
var localized string m_sNoAmmoHelp;
var localized string m_sNoMedikitTargetsHelp;
var localized string m_sNoMedikitChargesHelp;
var localized string m_sNewDefensiveLabel;
var localized string m_sNewOffensiveLabel;
var localized string m_sCanFreeAimHelp;
var localized string m_sHowToFreeAimHelp;
var localized string m_sNoTarget;
var localized string m_strAbilityHoverConfirm;

var localized string m_strHitFriendliesTitle;
var localized string m_strHitFriendliesBody;
var localized string m_strHitFriendliesAccept;
var localized string m_strHitFriendliesCancel;

var localized string m_strHitFriendlyObjectTitle;
var localized string m_strHitFriendlyObjectBody;
var localized string m_strHitFriendlyObjectAccept;
var localized string m_strHitFriendlyObjectCancel;

var localized string m_strMeleeAttackName;

//----------------------------------------------------------------------------
// METHODS
//

simulated function UITacticalHUD_AbilityContainer InitAbilityContainer()
{
	local int i;
	local UITacticalHUD_Ability kItem;

	InitPanel();

	// Pre-cache UI data array
	for(i = 0; i < MAX_NUM_ABILITIES; ++i)
	{	
		kItem = Spawn(class'UITacticalHUD_Ability', self);
		kItem.InitAbilityItem(name("AbilityItem_" $ i));
		m_arrUIAbilities.AddItem(kItem);
	}

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	if(!Movie.IsMouseActive())
		mc.FunctionString("SetHelp", class'UIUtilities_Input'.const.ICON_RT_R2);
}

simulated function X2TargetingMethod GetTargetingMethod()
{
	return TargetingMethod;
}

simulated function NotifyCanceled()
{
	ResetMouse(); 
	UpdateHelpMessage(""); //Clears out any message when canceling the mode. 
	Invoke("Deactivate");  //Animate back to top corner. Handle this here instead of in "clear", so that we prevent unwanted animations when staying in show mode. 
	if(TargetingMethod != none)
	{
		TargetingMethod.Canceled();
		TargetingMethod = none;
	}

	if(m_iCurrentIndex != -1)
		m_arrUIAbilities[m_iCurrentIndex].OnLoseFocus();
	
	RefreshTutorialShine(true); //Force a show refresh, since the menu is canceling out.
	
	m_iCurrentIndex = -1;
}

simulated function RefreshTutorialShine(optional bool bIgnoreMenuStatus = false)
{	
	local int i;
	
	if( !`REPLAY.bInTutorial ) return; 

	for( i = 0; i < MAX_NUM_ABILITIES; ++i )
	{
		m_arrUIAbilities[i].RefreshShine(bIgnoreMenuStatus);
	}
}

simulated function SetSelectionOnInputPress (int ucmd)
{
	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):  
		case (class'UIUtilities_Input'.const.FXS_L_MOUSE_UP):  
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):  
			m_iSelectionOnButtonDown = m_iCurrentIndex;
		break;
	}
}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	local bool bHandled;
	
	bHandled = true;

	// Only allow releases through.
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0 )
		return false;

	if( !CanAcceptAbilityInput() )
	{
		return false;
	}

	// ignore the virtual dpad inputs on PC, we want to pass them along to the camera for rotation
	// since PC has the extra buttons to dedicate to ability selection
	// VALVE disabled for Steam controller, this didn't appear to work in the
	// first place and dpad didn't do anything in shot HUD?
	/*if ( `BATTLE != none && `BATTLE.ProfileSettingsActivateMouse() )
	{
		switch(ucmd)
		{
			case (class'UIUtilities_Input'.const.FXS_DPAD_UP):
			case (class'UIUtilities_Input'.const.FXS_DPAD_DOWN):
			case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
			case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
				return false;
			default:
		}
	}*/

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):  
		case (class'UIUtilities_Input'.const.FXS_L_MOUSE_UP):  
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			if( UITacticalHUD(Owner).IsMenuRaised() )
				OnAccept();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
			if( UITacticalHUD(Owner).IsMenuRaised() )
				UITacticalHUD(Owner).CancelTargetingAction();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_TAB):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
			if( TargetingMethod != none )
				TargetingMethod.NextTarget();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):
			if( TargetingMethod != none )
				TargetingMethod.PrevTarget();
			else
				bHandled = false;
			break;

		//case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
		case (class'UIUtilities_Input'.const.FXS_ARROW_LEFT):
			if( UITacticalHUD(Owner).IsMenuRaised() )
				CycleAbilitySelection(-1);
			else
				bHandled = false;
			break;

		//case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):	
		case (class'UIUtilities_Input'.const.FXS_ARROW_RIGHT):
			if( UITacticalHUD(Owner).IsMenuRaised() )
				CycleAbilitySelection(1);	
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
		case (class'UIUtilities_Input'.const.FXS_KEY_X):

			// Don't allow user to swap weapons in the tutorial if we're not supposed to.
			if( `BATTLE.m_kDesc.m_bIsTutorial && `TACTICALGRI != none && `TACTICALGRI.DirectedExperience != none && !`TACTICALGRI.DirectedExperience.AllowSwapWeapons() )
			{
				bHandled = false;
				break;
			}

			if( UITacticalHUD(Owner).IsMenuRaised() )
				OnCycleWeapons();
			else
				bHandled = false;
			break;

		case (class'UIUtilities_Input'.const.FXS_KEY_1):	DirectConfirmAbility( 0 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_2):	DirectConfirmAbility( 1 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_3):	DirectConfirmAbility( 2 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_4):	DirectConfirmAbility( 3 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_5):	DirectConfirmAbility( 4 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_6):	DirectConfirmAbility( 5 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_7):	DirectConfirmAbility( 6 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_8):	DirectConfirmAbility( 7 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_9):	DirectConfirmAbility( 8 ); break;
		case (class'UIUtilities_Input'.const.FXS_KEY_0):	DirectConfirmAbility( 9 ); break;

		default: 
			bHandled = false;
			break;
	}

	return bHandled;
}

simulated function bool AbilityClicked(int index)
{
	if( !XComTacticalInput(XComTacticalController(PC).PlayerInput).PreProcessCheckGameLogic( class'UIUtilities_Input'.const.FXS_BUTTON_Y, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) )
		return false;

	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return false;
		}
	}

	//Update the selection based on what the mouse clicked
	m_iMouseTargetedAbilityIndex = index;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	//If the HUD is closed, then trigger it to open
	return SelectAbility( m_iMouseTargetedAbilityIndex );
}

// Reset any mouse-specific data.
// Expected use: keyboard or controller nav. 
function ResetMouse()
{
	m_iMouseTargetedAbilityIndex = -1;
}

function DirectSelectAbility( int index )
{
	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return;
		}
	}

	//Check if it's in range, and bail if out of range 
	if( index >= m_arrAbilities.Length )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose); 
		return; 
	}

	if( m_iMouseTargetedAbilityIndex != index )
	{
		//Update the selection 
		m_iMouseTargetedAbilityIndex = index;
		SelectAbility( m_iMouseTargetedAbilityIndex );
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
}

function DirectConfirmAbility(int index, optional bool ActivateViaHotKey)
{
	// For the tutorial, don't allow the user to bring up the HUD by clicking on it if the right trigger is disabled.
	if( `BATTLE.m_kDesc.m_bIsTutorial )
	{
		if( XComTacticalInput(XComTacticalController(PC).PlayerInput).ButtonIsDisabled( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) )
		{
			PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			return;
		}
	}

	//Check if it's in range, and bail if out of range 
	if( index >= m_arrAbilities.Length - UITacticalHUD(screen).m_kMouseControls.CommandAbilities.Length)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose); 
		return; 
	}

	if( m_iMouseTargetedAbilityIndex != index )
	{
		//Update the selection 
		m_iMouseTargetedAbilityIndex = index;
		SelectAbility(m_iMouseTargetedAbilityIndex, ActivateViaHotKey);
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	} 
	else
	{
		OnAccept();
	}
}

simulated public function bool OnAccept( optional string strOption = "" )
{
	return ConfirmAbility();
}

simulated public function bool ConfirmAbility( optional AvailableAction AvailableActionInfo )
{
	local XComGameStateHistory          History;
	local array<vector>                 TargetLocations;
	local AvailableTarget               AdditionalTarget;
	local bool					        bSubmitSuccess;
	local XComGameStateContext          AbilityContext;
	local XComGameState_Ability         AbilityState;
	local array<TTile>                  PathTiles;
	local string                        ConfirmSound;

	ResetMouse();

	//return if the current selection on release does not match the same option that was selected on press
	if( m_iCurrentIndex != m_iSelectionOnButtonDown && !Movie.IsMouseActive() )
		return false;	
	
	if( AvailableActionInfo.AbilityObjectRef.ObjectID <= 0 ) // See if one was sent in as a param
		AvailableActionInfo = GetSelectedAction();

	if(AvailableActionInfo.AbilityObjectRef.ObjectID <= 0)
		return false;

	if( TargetingMethod != none ) 
		TargetIndex = TargetingMethod.GetTargetIndex();

	//overwrite Targeting Method which does not exist for cases such as opening of doors
	if(AvailableActionInfo.AvailableTargetCurrIndex > 0)
	{
		TargetIndex = AvailableActionInfo.AvailableTargetCurrIndex;
	}
	if( TargetingMethod != none )
	{
		TargetingMethod.GetTargetLocations(TargetLocations);
		if( TargetingMethod.GetAdditionalTargets(AdditionalTarget) )
		{
			AvailableActionInfo.AvailableTargets.AddItem(AdditionalTarget);
		}

		if (AvailableActionInfo.AvailableCode == 'AA_Success')
		{
			AvailableActionInfo.AvailableCode = TargetingMethod.ValidateTargetLocations(TargetLocations);
		}
	}
	
	// Cann't activate the ability, so bail out
	if(AvailableActionInfo.AvailableCode != 'AA_Success')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		m_iCurrentIndex = -1;
		return false;
	}

	if (TargetingMethod != none)
	{
		if(!TargetingMethod.VerifyTargetableFromIndividualMethod(ConfirmAbility))
		{
			return true;
		}

		TargetingMethod.GetPreAbilityPath(PathTiles);
	}

	// add a UI visualization guard
	LastActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();

	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	AbilityContext = AbilityState.GetParentGameState().GetContext();

	AbilityContext.SetSendGameState(true);
	bSubmitSuccess = class'XComGameStateContext_Ability'.static.ActivateAbility(AvailableActionInfo, TargetIndex, TargetLocations, TargetingMethod, PathTiles);
	AbilityContext.SetSendGameState(false);

	if (bSubmitSuccess)
	{
		ConfirmSound = AbilityState.GetMyTemplate().AbilityConfirmSound;
		if (ConfirmSound != "")
			`SOUNDMGR.PlaySoundEvent(ConfirmSound);

		TargetingMethod.Committed();
		TargetingMethod = none;

		XComPresentationLayer(Owner.Owner).PopTargetingStates();

		PC.SetInputState('ActiveUnit_Moving');

		`Pres.m_kUIMouseCursor.HideMouseCursor();
	}

	m_iCurrentIndex = -1;

	return bSubmitSuccess;
}
function HitFriendliesDialogue() 
{
	local TDialogueBoxData kDialogData; 
	
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strHitFriendliesTitle;
	kDialogData.strText = m_strHitFriendliesBody;
	kDialogData.strAccept = m_strHitFriendliesAccept;
	kDialogData.strCancel = m_strHitFriendliesCancel;
	kDialogData.fnCallback = HitFriendliesDialogueCallback;

	XComPresentationLayer(Movie.Pres).UIRaiseDialog( kDialogData );
	XComPresentationLayer(Movie.Pres).SetHackUIBusy(true);
	XComPresentationLayer(Movie.Pres).UIFriendlyFirePopup();
}

function HitFriendlyObjectDialogue()
{
	local TDialogueBoxData kDialogData; 
	
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strHitFriendlyObjectTitle;
	kDialogData.strText = m_strHitFriendlyObjectBody;
	kDialogData.strAccept = m_strHitFriendlyObjectAccept;
	kDialogData.strCancel = m_strHitFriendlyObjectCancel;
	kDialogData.fnCallback = HitFriendliesDialogueCallback;

	XComPresentationLayer(Movie.Pres).UIRaiseDialog( kDialogData );
	XComPresentationLayer(Movie.Pres).SetHackUIBusy(true);
	XComPresentationLayer(Movie.Pres).UIFriendlyFirePopup();
}

simulated public function HitFriendliesDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		HitFriendliesAccepted();
		XComPresentationLayer(Movie.Pres).SetHackUIBusy(false);
	}
	else if( eAction == eUIAction_Cancel )
	{
		HitFriendliesDeclined();
		XComPresentationLayer(Movie.Pres).SetHackUIBusy(false);
	}

	if( XComPresentationLayer(Movie.Pres).IsInState( 'State_FriendlyFirePopup' ) )
		XComPresentationLayer(Movie.Pres).PopState();
}
public function HitFriendliesAccepted()
{
	// TODO:TARGETING
	//if (kTargetingAction != none)
	//{
	//	kTargetingAction.m_bPleaseHitFriendlies = true;

		// HAX: OnAccept does some state manipulation which requires the state stack to be purged of the popup dialog state.
		//      This should not cause a problem since the function above (which calls us) does a state check before poping the dialog state.
		//      We need to perform the same call in both functions since cancelling or accepting needs to remove the state - sbatista 6/18/12
		if( XComPresentationLayer(Movie.Pres).IsInState( 'State_FriendlyFirePopup' ) )
			XComPresentationLayer(Movie.Pres).PopState();

	//	OnAccept();
	//	kTargetingAction.m_bPleaseHitFriendlies = false;
	//}
}

public function HitFriendliesDeclined()
{
	//Do nothing. 
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(TargetingMethod != none)
	{
		TargetingMethod.Update(DeltaTime);
	}
}

simulated function bool CanAcceptAbilityInput()
{
	// when switching units, don't tneed to wait on visualization
	if( LastActiveUnitRef.ObjectID != XComTacticalController(PC).GetActiveUnitStateRef().ObjectID )
	{
		return true;
	}

	if( class'XComGameStateVisualizationMgr'.static.VisualizerBusy() )
	{
		return false;
	}

	return true;
}

simulated static function bool ShouldShowAbilityIcon(out AvailableAction AbilityAvailableInfo, optional out int ShowOnCommanderHUD)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;

	if( AbilityAvailableInfo.AbilityObjectRef.ObjectID < 1 ||
		AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_NeverShow || 
		(AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_ShowIfAvailable && AbilityAvailableInfo.AvailableCode != 'AA_Success'))
	{
			return false;
	}

	if (AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_ShowIfAvailableOrNoTargets)
	{
		if (AbilityAvailableInfo.AvailableCode != 'AA_Success' && AbilityAvailableInfo.AvailableCode != 'AA_NoTargets')
			return false;
	}

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityAvailableInfo.AbilityObjectRef.ObjectID));
	if(AbilityState == none)
	{
		return false;
	}

	AbilityTemplate = AbilityState.GetMyTemplate();

	if (AbilityTemplate == none)
	{
		return false;
	}

	if (AbilityAvailableInfo.eAbilityIconBehaviorHUD == eAbilityIconBehavior_HideSpecificErrors)
	{
		if (AbilityTemplate.HideErrors.Find(AbilityAvailableInfo.AvailableCode) != INDEX_NONE)
			return false;
	}

	ShowOnCommanderHUD = AbilityTemplate.bCommanderAbility ? 1 : 0;

	return true;
}

simulated function UpdateAbilitiesArray() 
{
	local int i;
	local int len;
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local array<AvailableAction> arrCommandAbilities;
	local int bCommanderAbility;

	local AvailableAction AbilityAvailableInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	

	//Hide any AOE indicators from old abilities
	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		HideAOE(i);
	}

	//Clear out the array 
	m_arrAbilities.Length = 0;

	// Loop through all abilities.
	Ruleset = `XCOMGAME.GameRuleset;
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	len = UnitInfoCache.AvailableActions.Length;
	for(i = 0; i < len; i++)
	{	
		// Obtain unit's ability.
		AbilityAvailableInfo = UnitInfoCache.AvailableActions[i];

		if(ShouldShowAbilityIcon(AbilityAvailableInfo, bCommanderAbility))
		{
			//Separate out the command abilities to send to the CommandHUD, and do not want to show them in the regular list. 
			// Commented out in case we bring CommanderHUD back.
			if( bCommanderAbility == 1 )
			{
				arrCommandAbilities.AddItem(AbilityAvailableInfo);
			}

			//Add to our list of abilities 
			m_arrAbilities.AddItem(AbilityAvailableInfo);
		}
	}

	arrCommandAbilities.Sort(SortAbilities);
	m_arrAbilities.Sort(SortAbilities);
	PopulateFlash();

	UITacticalHUD(screen).m_kShotInfoWings.Show();
	UITacticalHUD(screen).m_kMouseControls.SetCommandAbilities(arrCommandAbilities);
	UITacticalHUD(screen).m_kMouseControls.UpdateControls();

	//  jbouscher: I am 99% certain this call is entirely redundant, so commenting it out
	//kUnit.UpdateUnitBuffs();

	// If we're in shot mode, then set the current ability index based on what (if anything) was populated.
	if( UITacticalHUD(screen).IsMenuRaised() && m_arrAbilities.Length > 0 )
	{
		if( m_iMouseTargetedAbilityIndex == -1 )
		{
			// MHU - We reset the ability selection if it's not initialized.
			//       We also define the initial shot determined in XGAction_Fire.
			//       Otherwise, retain the last selection.
			if (m_iCurrentIndex < 0)
				SetAbilityByIndex( 0 );
			else
				SetAbilityByIndex( m_iCurrentIndex );
		}
	}

	// Do this after assigning the CurrentIndex
	UpdateWatchVariables();
	CheckForHelpMessages();
	DoTutorialChecks();
}

simulated function DoTutorialChecks()
{
	local XComGameStateHistory History;
	local int Index;
	local Name AbilityName;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit ActiveUnit;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(XComTacticalController(PC).GetActiveUnitStateRef().ObjectID));

	if (XComHQ != None && !XComHQ.bHasPlayedMeleeTutorial && !ActiveUnit.IsConcealed())
	{
		for (Index = 0; Index < m_arrAbilities.Length; Index++)
		{
			if (m_arrAbilities[Index].AvailableCode == 'AA_Success' && m_arrAbilities[Index].AvailableTargets.Length > 0)
			{
				AbilityName = XComGameState_Ability(History.GetGameStateForObjectID((m_arrAbilities[Index].AbilityObjectRef.ObjectID))).GetMyTemplateName();

				if (AbilityName == 'SwordSlice')
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Melee Tutorial");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForMeleeTutorial;

					// Update the HQ state to record that we saw this enemy type
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(XComHQ.Class, XComHQ.ObjectID));
					XComHQ.bHasPlayedMeleeTutorial = true;
					NewGameState.AddStateObject(XComHQ);

					`TACTICALRULES.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(class'XLocalizedData'.default.MeleeTutorialTitle,
																										class'XLocalizedData'.default.MeleeTutorialText,
																										class'UIUtilities_Image'.static.GetTutorialImage_Melee());
				}
			}
		}
	}
}

static function BuildVisualizationForMeleeTutorial(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_PlayNarrative NarrativeAction;

	NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	NarrativeAction.Moment = XComNarrativeMoment'X2NarrativeMoments.CENTRAL_Tactical_Tutorial_Misison_Two_Melee';
	NarrativeAction.WaitForCompletion = false;

	BuildTrack.StateObject_OldState = VisualizeGameState.GetGameStateForObjectIndex(0);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectIndex(0);
	OutVisualizationTracks.AddItem(BuildTrack);

}

simulated function int SortAbilities(AvailableAction A, AvailableAction B)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AA, BB;
	local bool bACommander, bBCommander;

	History = `XCOMHISTORY;

	AA = XComGameState_Ability(History.GetGameStateForObjectID(A.AbilityObjectRef.ObjectID));
	BB = XComGameState_Ability(History.GetGameStateForObjectID(B.AbilityObjectRef.ObjectID));

	bACommander = AA.GetMyTemplate().bCommanderAbility;
	bBCommander = BB.GetMyTemplate().bCommanderAbility;

	if(bACommander && !bBCommander) return -1;
	else if(!bACommander && bBCommander) return 1;

	if(A.ShotHUDPriority < B.ShotHUDPriority) return 1;
	else if(A.ShotHUDPriority > B.ShotHUDPriority) return -1;
	else return 0;
}

simulated function int GetAbilityIndexByHotKey(int KeyCode)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.DefaultKeyBinding == KeyCode)
		{
			return i;
		}
	}

	return INDEX_NONE;
}


simulated function int GetAbilityIndex(AvailableAction A)
{
	local int i;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		if(m_arrAbilities[i] == A)
			return i;
	}

	return INDEX_NONE;
}

simulated function int GetAbilityIndexByName(name A)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if(AbilityTemplate.DataName == A)
			return i;
	}

	return INDEX_NONE;
}

// Build Flash pieces based on abilities loaded.
// Assumes the containing screen has made the appropriate invoke/timeline calls.
simulated function PopulateFlash()
{
	local int i, len, numActiveAbilities;
	local AvailableAction AvailableActionInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local UITacticalHUD_AbilityTooltip TooltipAbility;

	//Process the number of abilities, verify that it does not violate UI assumptions
	len = m_arrAbilities.Length;

	numActiveAbilities = 0;
	for( i = 0; i < len; i++ )
	{
		AvailableActionInfo = m_arrAbilities[i];

		AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if(!AbilityTemplate.bCommanderAbility)
		{
			m_arrUIAbilities[numActiveAbilities].UpdateData(numActiveAbilities, AvailableActionInfo);
			numActiveAbilities++;
		}
	}
	
	mc.FunctionNum("SetNumActiveAbilities", numActiveAbilities);
	
	if(numActiveAbilities >= MAX_NUM_ABILITIES && !bShownAbilityError)
	{
		bShownAbilityError = true;
		Movie.Pres.PopupDebugDialog("UI ERROR", "More abilities are being updated than UI supports( " $ len $"). Please report this to UI team and provide a save.");
	}

	Show();

	// Refresh the ability tooltip if it's open
	TooltipAbility = UITacticalHUD_AbilityTooltip(Movie.Pres.m_kTooltipMgr.GetChildByName('TooltipAbility'));
	if(TooltipAbility != none && TooltipAbility.bIsVisible)
		TooltipAbility.RefreshData();
}

simulated function CycleAbilitySelection(int step)
{
	local int index;

	// Ignore if index was never set (e.g. nothing was populated.)
	if (m_iCurrentIndex == -1)
		return;

	index = m_iCurrentIndex + step; // MHU - Not safe to update m_iCurrentIndex (this variable is watched) here. 
									//       We must allow SetAbilityByIndex to handle actual increment for us.

	if(index > m_arrAbilities.Length - 1) 
		index = 0;
	else if(index < 0) 
		index = m_arrAbilities.Length - 1;
	
	ResetMouse();
	SelectAbility( index );
}
simulated function CycleAbilitySelectionRow(int step)
{
	local int index;

	// Ignore if index was never set (e.g. nothing was populated.)
	if (m_iCurrentIndex == -1)
		return;

	index = MAX_NUM_ABILITIES + (m_iCurrentIndex + (step * MAX_NUM_ABILITIES_PER_ROW));
	index = index % MAX_NUM_ABILITIES;

	if(index != m_iCurrentIndex && index >= 0 && index < m_arrAbilities.Length )
	{
		ResetMouse();
		SelectAbility( index );
	}
}

simulated function bool GetDefaultTargetingAbility(int TargetObjectID, out AvailableAction DefaultAction, optional bool SelectReloadLast = false)
{
	local int i, j;
	local name AbilityName;
	local AvailableAction AbilityAction;
	local AvailableAction ReloadAction;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost AbilityCost;

	for(i = 0; i < m_arrAbilities.Length; i++)
	{
		AbilityAction = m_arrAbilities[i];
		AbilityName = name(class'XGAIBehavior'.static.GetAbilityName(AbilityAction));

		// We'll want to default to the reload action if the user doesn't have enough ammo for the default ability
		if(AbilityName == 'Reload' && AbilityAction.ShotHUDPriority == class'UIUtilities_Tactical'.const.MUST_RELOAD_PRIORITY)
		{
			ReloadAction = AbilityAction;
			DefaultAction = AbilityAction;
		}

		// Find the first available ability that includes the enemy as a target
		if(AbilityAction.AvailableCode == 'AA_Success')
		{
			for(j = 0; j < AbilityAction.AvailableTargets.Length; ++j)
			{
				if(AbilityAction.AvailableTargets[j].PrimaryTarget.ObjectID == TargetObjectID)
				{
					// if this action requires ammo, and we need to reload, select the reload action instead
					if(!SelectReloadLast && ReloadAction.AbilityObjectRef.ObjectID > 0)
					{
						AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
						`assert(AbilityTemplate != none);

						foreach AbilityTemplate.AbilityCosts(AbilityCost)
						{
							if(X2AbilityCost_Ammo(AbilityCost) != none)
							{
								DefaultAction = ReloadAction;
								return true;
							}
						}
					}
				
					// don't need to reload, so use this ability
					DefaultAction = AbilityAction;
					return true;
				}
			}
		}
	}

	return DefaultAction.AbilityObjectRef.ObjectID > 0;
}

simulated function bool DirectTargetObjectWithDefaultTargetingAbility(int TargetObjectID, optional bool AutoConfirmIfFreeCost = false)
{
	local XComGameStateHistory History;
	local AvailableAction DefaultAction;
	local X2AbilityTemplate Template;
	local XComGameState_Ability Ability;
	local int Index;

	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
	{
		return false;
	}

	// find the default ability for targeting this target
	if(GetDefaultTargetingAbility(TargetObjectID, DefaultAction))
	{
		for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
		{
			if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
			{
				DefaultAction.AvailableTargetCurrIndex = Index;
			}
		}

		// first check if we can autoconfirm it (direct activation without bringing up the hud)
		if(AutoConfirmIfFreeCost)
		{
			History = `XCOMHISTORY;
			Ability = XComGameState_Ability(History.GetGameStateForObjectID(DefaultAction.AbilityObjectRef.ObjectID));
			Template = Ability.GetMyTemplate();
			if(Template.CanAfford(Ability) == 'AA_Success' 
				&& Template.IsFreeCost(Ability)
				&& ConfirmAbility(DefaultAction))
			{
				return true;
			}
		}
		
		// set the ability
		SelectAbilityByAbilityObject(DefaultAction);

		// find the target's index in the target array
		for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
		{
			if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
			{
				// target the enemy unit
				TargetingMethod.DirectSetTarget(Index);
				return true;
			}
		}
	}

	return false;
}

simulated function bool DirectTargetObject(int TargetObjectID, optional bool AutoConfirmIfFreeCost = false)
{
	local XComGameStateHistory History;
	local AvailableAction DefaultAction;
	local X2AbilityTemplate Template;
	local XComGameState_Ability Ability;
	local int Index;

	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
	{
		return false;
	}

	if(m_iCurrentIndex < 0 || m_iCurrentIndex > m_arrAbilities.Length)
	{
		return DirectTargetObjectWithDefaultTargetingAbility(TargetObjectID, AutoConfirmIfFreeCost);
	}

	DefaultAction = m_arrAbilities[m_iCurrentIndex];
	
	// first check if we can autoconfirm it (direct activation without bringing up the hud)
	if(AutoConfirmIfFreeCost)
	{
		History = `XCOMHISTORY;
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(DefaultAction.AbilityObjectRef.ObjectID));
		Template = Ability.GetMyTemplate();
		if(Template.CanAfford(Ability) == 'AA_Success' 
			&& Template.IsFreeCost(Ability)
			&& ConfirmAbility(DefaultAction))
		{
			return true;
		}
	}
		
	// set the ability
	SelectAbilityByAbilityObject(DefaultAction);

	// find the target's index in the target array
	for(Index = 0; Index < DefaultAction.AvailableTargets.Length; Index++)
	{
		if(DefaultAction.AvailableTargets[Index].PrimaryTarget.ObjectID == TargetObjectID)
		{
			// target the enemy unit
			TargetingMethod.DirectSetTarget(Index);
			return true;
		}
	}

	// we were unable to set the target with the current ability, lets try the default ability
	return DirectTargetObjectWithDefaultTargetingAbility(TargetObjectID, AutoConfirmIfFreeCost);
}


// Select ability at index, and then update all associated visuals. 
simulated function bool SelectAbility( int index, optional bool ActivateViaHotKey )
{
	if(!SetAbilityByIndex( index, ActivateViaHotKey ))
	{
		return false;
	}
	
	PopulateFlash();
	UpdateWatchVariables();
	CheckForHelpMessages();

	// Update targetting reticules
	if(UITacticalHUD(Owner).GetReticleMode() != eUIReticle_NONE && GetTargetingMethod() != none)
		UITacticalHUD(Owner).TargetEnemy(GetTargetingMethod().GetTargetIndex());

	//Update sightline HUD (targeting head icons) 
	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.RefreshSelectedEnemy();

	return true;
}

simulated function ShowAOE(int Index)
{
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState;
	local XGUnit UnitVisualizer;

	AvailableActionInfo = m_arrAbilities[Index];
	if( AvailableActionInfo.AbilityObjectRef.ObjectID == 0 )
	{
		return;
	}
		
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	if( AbilityState.GetMyTemplate().AbilityPassiveAOEStyle != none )
	{
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.SetupAOEActor(AbilityState);
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
		if( UnitState.m_bSubsystem )
			UnitVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.OwningObjectId));
		else
			UnitVisualizer = XGUnit(UnitState.GetVisualizer());
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.DrawAOETiles(AbilityState, UnitVisualizer.Location);
	}

		
}

simulated function HideAOE(int Index)
{
	local AvailableAction AvailableActionInfo;
	local XComGameState_Ability AbilityState;

	AvailableActionInfo = m_arrAbilities[Index];
	if( AvailableActionInfo.AbilityObjectRef.ObjectID == 0 )
	{
		return;
	}

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	if( AbilityState.GetMyTemplate().AbilityPassiveAOEStyle != none )
	{
		AbilityState.GetMyTemplate().AbilityPassiveAOEStyle.DestroyAOEActor();
	}
}

simulated function SelectAbilityByAbilityObject( AvailableAction Ability )
{
	local int AbilityIndex;

	for(AbilityIndex = 0; AbilityIndex < m_arrAbilities.Length; AbilityIndex++)
	{
		if(m_arrAbilities[AbilityIndex].AbilityObjectRef == Ability.AbilityObjectRef)
		{
			DirectSelectAbility(AbilityIndex);
			return;
		}
	}
}

public function OnCycleWeapons()
{
	local XGUnit                kUnit;
	kUnit = XComTacticalController(PC).GetActiveUnit();
	// MP: we don't allow certain UI interactions such as switching weapons while in the shot hud.
	// we cant just check UITacticalHUD::IsMenuRaised() because that gets called from the
	// XGAction_Fire Execute state and there is a slight delay between the input and when
	// that actually happens that would allow other UI interactions to take place and could hang the game. -tsmith 
	if (kUnit != none && 
		(WorldInfo.NetMode == NM_Standalone || (!XComTacticalController(PC).m_bInputInShotHUD && !XComTacticalController(PC).m_bInputSwitchingWeapons)) &&
		kUnit.CycleWeapons())
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		XComTacticalController(PC).m_bInputSwitchingWeapons = true;
	}
}

// Setup an ability. Eventually this should be the ONLY way to select an ability. Everything must route through it.
simulated function bool SetAbilityByIndex( int AbilityIndex, optional bool ActivatedViaHotKey  )
{	
	local UITacticalHUD         TacticalHUD;
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit    UnitState;
	local XGUnit                UnitVisualizer;
	local GameRulesCache_Unit	UnitInfoCache;
	local int                   PreviousIndex;
	local int                   DefaultTargetIndex;
	local name					PreviousInptuState;

	if(AbilityIndex == m_iCurrentIndex)
		return false; // we are already using this ability

	//See if anything is happening in general that should block ability activation
	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
		return false;

	//Don't activate any abilities if the HUD is not visible.
	if (!Screen.bIsVisible)
		return false;

	//Don't activate any abilities if the active unit has none. (TTP #21216)
	`XCOMGAME.GameRuleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);
	if (UnitInfoCache.AvailableActions.Length == 0)
		return false;

	AvailableActionInfo = m_arrAbilities[AbilityIndex];
	if(AvailableActionInfo.AbilityObjectRef.ObjectID == 0)
		return false;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (UnitState.m_bSubsystem)
		UnitVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.OwningObjectId));
	else
		UnitVisualizer = XGUnit(UnitState.GetVisualizer());

	if(UnitVisualizer != XComTacticalController(PC).GetActiveUnit())
		return false;

	//No ability activation while we are moving. Maybe we can add an exception for moving twice in a row ... but double move can
	//do the same
	if (UnitVisualizer.m_bIsMoving)
	{
		return false;
	}

	if( AbilityIndex < 0 || AbilityIndex >= m_arrAbilities.Length )
	{
		`warn("Attempt to set ability to focus with illegal index: '" $ AbilityIndex $ "', numAbilities: '" $ m_arrAbilities.Length $ "'.");
		return false;
	}

	PreviousIndex = m_iCurrentIndex;
	m_iMouseTargetedAbilityIndex = AbilityIndex; // make sure this gets updated
	m_iCurrentIndex = AbilityIndex;
	
	if(TargetingMethod != none)
	{
		// if switching abilities, the previous targeting method will still be active. Cancel it.
		TargetingMethod.Canceled();
	}

	// Immediately trigger the ability if it bypasses confirmation
	if(AbilityState.GetMyTemplate().bBypassAbilityConfirm)
	{
		OnAccept();
		return true;
	}

	// make sure our input is in the right mode
	PreviousInptuState = XComTacticalInput(PC.PlayerInput).GetStateName();
	XComTacticalInput(PC.PlayerInput).GotoState('UsingTargetingMethod');

	if(AvailableActionInfo.AvailableTargets.Length > 0 || AvailableActionInfo.bFreeAim)
	{
		TargetingMethod = new AbilityState.GetMyTemplate().TargetingMethod;
		TargetingMethod.Init(AvailableActionInfo);

		DefaultTargetIndex = Max(TargetingMethod.GetTargetIndex(), 0);
	}

	if (AbilityState.GetMyTemplate().bNoConfirmationWithHotKey && ActivatedViaHotKey)
	{
		// if the OnAccept fails, because unavailable or other similar reasons, we need to put the input state back. 
		if( !OnAccept() )
			XComTacticalInput(PC.PlayerInput).GotoState(PreviousInptuState);
		return true;
	}

	if(PreviousIndex != -1)
		m_arrUIAbilities[PreviousIndex].OnLoseFocus();
	if(m_iCurrentIndex != -1)
		m_arrUIAbilities[m_iCurrentIndex].OnReceiveFocus();

	TacticalHUD = UITacticalHUD(Screen);

	if( !TacticalHUD.IsMenuRaised() )
		TacticalHUD.RaiseTargetSystem();

	if(AvailableActionInfo.bFreeAim)
		TacticalHUD.OnFreeAimChange();

	TacticalHUD.RealizeTargetingReticules(DefaultTargetIndex);
	TacticalHUD.m_kShotHUD.Update();

	return true;
}

//Used by the mouse hover tooltip to figure out which ability to get info from 
simulated function XComGameState_Ability GetAbilityAtIndex( int AbilityIndex )
{
	local AvailableAction       AvailableActionInfo;
	local XComGameState_Ability AbilityState;

	if( AbilityIndex < 0 || AbilityIndex >= m_arrAbilities.Length )
	{
		`warn("Attempt to get ability with illegal index: '" $ AbilityIndex $ "', numAbilities: '" $ m_arrAbilities.Length $ "'.");
		return none;
	}

	AvailableActionInfo = m_arrAbilities[AbilityIndex];
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);
	return AbilityState; 
}

simulated function XComGameState_Ability GetCurrentSelectedAbility()
{ 
	if( m_iCurrentIndex == -1 )
		return none;
	else
		return GetAbilityAtIndex(m_iCurrentIndex);
}

function XGUnit GetMouseTargetedUnit()
{
	local XComTacticalHUD HUD; 
	local IMouseInteractionInterface LastInterface; 
	local XComUnitPawnNativeBase kPawn; 
	local XGUnit kTargetedUnit;

	HUD = XComTacticalHUD(PC.myHUD);
	if( HUD == none ) return none; 

	LastInterface = HUD.CachedMouseInteractionInterface; 
	if( LastInterface == none ) return none; 
	
	kPawn = XComUnitPawnNativeBase(LastInterface);	
	if( kPawn == none ) return none; 

	//This is the next unit we want to set as active 
	kTargetedUnit = XGUnit(kPawn.GetGameUnit());
	if( kTargetedUnit == none ) return none; 

	return kTargetedUnit;

}

simulated function AvailableAction GetSelectedAction()
{
	local AvailableAction NoAction;
	if( m_iCurrentIndex >= 0 && m_iCurrentIndex < m_arrAbilities.Length )
	{	
		return m_arrAbilities[m_iCurrentIndex];
	}
	else
	{
		`log("Ability out of bounds. Current: '" $ string(m_iCurrentIndex) $ "' Length: '" $ string( m_arrAbilities.Length) $ "'",,'XCom_GameStates');
	}
	return NoAction;
}

simulated function AvailableAction GetShotActionForTooltip()
{
	local AvailableAction NoAction;
	local XComGameState_Ability AvailableAbility;
	local int i;

	if( m_iCurrentIndex >= 0 && m_iCurrentIndex < m_arrAbilities.Length )
	{	
		return m_arrAbilities[m_iCurrentIndex];
	}
	else if( m_arrAbilities.Length > 0 )
	{
		for( i = 0; i < m_arrAbilities.Length; i++ )
		{
			AvailableAbility = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID(m_arrAbilities[i].AbilityObjectRef.ObjectID));
			if(AvailableAbility.GetMyTemplate().DisplayTargetHitChance)
				return m_arrAbilities[i];
		}
	}
	return NoAction;
}

simulated function bool IsSelectedValue( int i )
{
	return (m_iCurrentIndex == i);
}

simulated function int GetSelectedIndex()
{
	return m_iCurrentIndex;
}

simulated function bool CheckForNotifier( XGUnit kUnit )
{
	local XGWeapon      kActiveWeapon;
	local XGInventory   kInventory;

	kInventory = kUnit.GetInventory();
	kActiveWeapon = kInventory.GetActiveWeapon();
	
	if (kActiveWeapon != none)
	{
		if ( true )
		{
			if (! ( kActiveWeapon.GetRemainingAmmo() > 0 || 
					(kInventory.GetNumClips( kActiveWeapon.GameplayType() ) > 0)) )
			{
				return true;
			}
		}
	}

	return false;
}


simulated function CheckForHelpMessages()
{
	UITacticalHUD(Owner).LockTheReticles(false);

	//@TODO - rmcfall - figure out how to handle help messages later
	//for(i = 0; i < kUnit.GetNumAbilities(); i++)
	//{	
	//	kAbility = GetSelectedAbility();
	//	if( kAbility != none &&
	//		IsAbilityValidWithoutTarget(kAbility) )
	//	{
	//		kTargetedAbility = XGAbility_Targeted(kAbility);

	//		if (kTargetedAbility == none ||             // If the ability is not targeted
	//			kTargetedAbility.GetPrimaryTarget() == none)     // or if the targeted ability has no target 
	//		{
	//			if (kTargetedAbility.HasProperty( eProp_TraceWorld ))
	//			{

	//				// MHU - HelpMessage is continuously updated depending on what the unit is currently
	//				//       aiming at. At this point, there's no information available.
	//				UpdateHelpMessage( m_sNoTarget );
	//				UITacticalHUD(Owner).SetReticleAimPercentages( -1, -1 );
	//				return;
	//			}
	//			else if (!kTargetedAbility.HasProperty( eProp_FreeAim )) // free aim has no target implications
	//			{
	//				// check for no ammo
	//				if(kTargetedAbility.m_kWeapon != none
	//					&& kTargetedAbility.m_kWeapon.GetRemainingAmmo() <= 0
	//					&& kTargetedAbility.HasProperty( eProp_FireWeapon ))
	//				{
	//					UpdateHelpMessage(m_sNoAmmoHelp);
	//				}
	//				else
	//				{
	//					switch (kTargetedAbility.GetType())
	//					{
	//					case eAbility_MedikitHeal:
	//						if (kUnit.GetMediKitCharges() <= 0)
	//							UpdateHelpMessage(m_sNoMedikitChargesHelp);
	//						else
	//						{
	//							kUnit.GetNumPotentialMedikitTargets(iTargets);
	//							if (iTargets > 0)
	//								UpdateHelpMessage(m_sNoMedikitTargetsHelp);
	//						}
	//						break;
	//					case eAbility_Revive:							
	//					case eAbility_Stabilize:
	//						if (kUnit.GetMediKitCharges() <= 0)
	//							UpdateHelpMessage(m_sNoMedikitChargesHelp);
	//						else
	//						{
	//							kUnit.GetNumPotentialStabilizeTargets(iTargets);
	//							if (iTargets > 0)
	//								UpdateHelpMessage(m_sNoMedikitTargetsHelp);
	//						}
	//						break;
	//					default:
	//						UpdateHelpMessage( m_sNoTargetsHelp);
	//						break;
	//					}
	//				}

	//				UITacticalHUD(Owner).SetReticleAimPercentages( -1, -1 );
	//				//UITacticalHUD(Owner).LockTheReticles(false);
	//				return;
	//			}

	//		}
	//	}
	//}

	//If no message was found, clear any message that may  be displayed currently.
	UpdateHelpMessage("");
}

simulated function UpdateHelpMessage( string strMsg )
{
	UITacticalHUD(Owner).SetReticleMessages(strMsg);
}

simulated function UpdateWatchVariables()
{
	//@TODO - rmcfall - support m_bFreeAiming changes
}

simulated function OnFreeAimChange()
{
	UITacticalHUD(Owner).OnFreeAimChange(); 
	CheckForHelpMessages();
}
simulated function bool IsEmpty()
{
	return( m_arrAbilities.Length == 0 ) ;
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	LibID = "AbilityContainer";
	MCName = "AbilityContainerMC";
		
	m_iCurrentIndex = -1;
	
	m_iUseOnlyAbility = -1;  // Only used in ShootAtLocation Kismet Action.  -DMW
	
	m_iMouseTargetedAbilityIndex = -1;

	bAnimateOnInit = false;
}
