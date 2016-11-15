//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD.uc
//  AUTHORS: Brit Steiner, Katie Hirsch, Tronster
//
//  PURPOSE: Container for specific abilities menu representations.
//           Actually this is more of a container than having anything to do with the
//           original radial menu.  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD extends UIScreen dependson(X2GameRuleset);

enum eUI_ReticleMode
{
	eUIReticle_NONE,
	eUIReticle_Overshoulder,
	eUIReticle_Offensive,
	eUIReticle_Defensive,
	eUIReticle_Sword,
	eUIReticle_Advent,
	eUIReticle_Alien
};

enum eUI_ConcealmentMode
{
	eUIConcealment_None,
	eUIConcealment_Individual,
	eUIConcealment_Squad,
};

//----------------------------------------------------------------------------
// MEMBERS
//

var eUI_ConcealmentMode                 ConcealmentMode;
var eUI_ReticleMode                     m_eReticleMode;
var UITacticalHUD_Inventory                     m_kInventory;
var UITacticalHUD_ShotHUD                       m_kShotHUD;
var UITacticalHUD_AbilityContainer              m_kAbilityHUD;
var UITacticalHUD_SoldierInfo                   m_kStatsContainer;
var UITacticalHUD_PerkContainer                 m_kPerks;
var UIObjectiveList						        m_kObjectivesControl;
var UITacticalHUD_MouseControls                 m_kMouseControls;
var UITacticalHUD_Enemies					    m_kEnemyTargets;
var UITacticalHUD_Countdown						m_kCountdown;
var UITacticalHUD_Tooltips						m_kTooltips;
var UIStrategyTutorialBox                       m_kTutorialHelpBox;
var UITacticalHUD_CommanderHUD					m_kCommanderHUD;
var UITacticalHUD_ShotWings						m_kShotInfoWings;
var UITargetingReticle							m_kTargetReticle;
var UITacticalHUD_ChallengeCountdown            m_kChallengeCountdown; // DEPRECATED bsteiner 3/24/2016

var UIEventNoticesTactical						m_kEventNotices;

var bool m_isMenuRaised;
var bool m_bForceOverheadView;

var bool m_bIgnoreShowUntilInternalUpdate;		//The Show function will immediately return until Show is called from InternalUpdate.
var bool m_bIsHidingShotHUDForSecondaryMovement;

var UIButton CharInfoButton;
var UIButton SkyrangerButton;
var localized string m_strEvac;
//</workshop>
var bool m_bEnemyInfoVisible;
var localized string m_strNavHelpCharShow;
var localized string m_strNavHelpEnemyShow;
var localized string m_strNavHelpEnemyHide;

var localized string m_strConcealed;
var localized string m_strSquadConcealed;
var localized string m_strRevealed;

//----------------------------------------------------------------------------
// METHODS
//

simulated function X2TargetingMethod GetTargetingMethod()
{
	return m_kAbilityHUD.GetTargetingMethod();
}
simulated function HideInputButtonRelatedHUDElements(bool bHide)
{
	if(bHide)
	{
		if (SkyrangerButton != none)
			SkyrangerButton.Hide();

		m_kAbilityHUD.Hide();
		m_kEnemyTargets.Hide();
		CharInfoButton.Hide();
	}
	else
	{
		UpdateSkyrangerButton();
		m_kAbilityHUD.Show();
		if (m_kEnemyTargets.GetEnemyCount() > 0)
		{
			m_kEnemyTargets.Show();
		}

		CharInfoButton.Show();

		Show();
	}
}

simulated function OnToggleHUDElements(SeqAct_ToggleHUDElements Action)
{
	local int i;

	if (Action.InputLinks[0].bHasImpulse)
	{
		for (i = 0; i < Action.HudElements.Length; ++i)
		{
			switch(Action.HudElements[i])
			{
				case eHUDElement_InfoBox:
					m_kShotHUD.Hide();
					break;
				case eHUDElement_Abilities:
					m_kAbilityHUD.Hide();
					break;
				case eHUDElement_WeaponContainer:
					m_kInventory.Hide();
					break;
				case eHUDElement_StatsContainer:
					m_kStatsContainer.Hide();
					break;
				case eHUDElement_Perks:
					m_kPerks.Hide();
					break;
				case eHUDElement_MouseControls:
					if( m_kMouseControls != none )
						m_kMouseControls.Hide();
					if (SkyrangerButton != none)
					{
						SkyrangerButton.Hide();
					}
					CharInfoButton.Hide();
					break;
				case eHUDElement_Countdown:
					m_kCountdown.Hide(); 
					break;
			}
		}
	}
	else if (Action.InputLinks[1].bHasImpulse)
	{
		for (i = 0; i < Action.HudElements.Length; ++i)
		{
			switch(Action.HudElements[i])
			{
				case eHUDElement_InfoBox:
					m_kShotHUD.Show();
					break;
				case eHUDElement_Abilities:
					m_kAbilityHUD.Show();
					break;
				case eHUDElement_WeaponContainer:
					m_kInventory.Show();
					break;
				case eHUDElement_StatsContainer:
					m_kStatsContainer.Show();
					break;
				case eHUDElement_Perks:
					m_kPerks.Show();
					break;
				case eHUDElement_MouseControls:
					if( m_kMouseControls != none )
						m_kMouseControls.Show();
					if (SkyrangerButton != none)
					{
						SkyrangerButton.Show();
					}
					CharInfoButton.Show();
					break;
				case eHUDElement_Countdown:
					m_kCountdown.Show(); 
					break;
			}
		}
	}
}

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	

	// Shot information panel
	m_kShotHUD = Spawn(class'UITacticalHUD_ShotHUD', self).InitShotHUD();

	// Ability Container
	m_kAbilityHUD = Spawn(class'UITacticalHUD_AbilityContainer', self).InitAbilityContainer();

	// Perk Container
	m_kPerks = Spawn(class'UITacticalHUD_PerkContainer', self).InitPerkContainer();

	// Weapon Rack
	m_kInventory = Spawn(class'UITacticalHUD_Inventory', self).InitInventory();
	
	// Soldier stats
	m_kStatsContainer = Spawn(class'UITacticalHUD_SoldierInfo', self).InitStatsContainer();

	// Objectives List
	m_kObjectivesControl = Spawn(class'UIObjectiveList', self).InitObjectiveList(); 
	
	//Alien heads
	m_kEnemyTargets	= Spawn(class'UITacticalHUD_Enemies', self).InitEnemyTargets();

	//Reinforcements counter
	m_kCountdown = Spawn(class'UITacticalHUD_Countdown', self).InitCountdown();

	//Tooltip Movie
	m_kTooltips = Spawn(class'UITacticalHUD_Tooltips', self).InitTooltips();

	// Commander HUD buttons 
	m_kCommanderHUD = Spawn(class'UITacticalHUD_CommanderHUD', Screen).InitCommanderHUD();

	// Shot Stats wings
	m_kShotInfoWings = Spawn(class'UITacticalHUD_ShotWings', Screen).InitShotWings();

	// Target Reticle
	m_kTargetReticle = Spawn(class'UITargetingReticle', Screen).InitTargetingReticle();

	//Event notice watcher. 
	m_kEventNotices = new(self) class'UIEventNoticesTactical';
	m_kEventNotices.Init();
}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();
	
	if( Movie.IsMouseActive() )
	{
		m_kMouseControls = Spawn(class'UITacticalHUD_MouseControls', self).InitMouseControls();
	}
	else
	{
		if (!`XENGINE.IsMultiplayerGame())
		{
			SkyrangerButton = Spawn(class'UIButton', self);
			SkyrangerButton.InitButton('SkyrangerButton', m_strEvac,, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
			SkyrangerButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3);
			SkyrangerButton.SetFontSize(26);
			SkyrangerButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
			SkyrangerButton.SetPosition(-195, 15);
			SkyrangerButton.OnSizeRealized = OnSkyrangerButtonSizeRealized;
			SkyrangerButton.Hide();
			UpdateSkyrangerButton();
		}

		CharInfoButton = Spawn(class'UIButton', self);
		CharInfoButton.InitButton('CharInfo', m_strNavHelpCharShow,,eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		CharInfoButton.SetTextShadow(true);
		CharInfoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
		CharInfoButton.SetPosition(30, 980);

		//NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
		//NavHelp.SetY(NavHelp.Y - 65); //NavHelp's default location overlaps with the static character info, so we're offsetting it here
	}

	LowerTargetSystem();

	// multiplayer specific watches -tsmith 
	if(WorldInfo.NetMode != NM_Standalone)
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalGRI(WorldInfo.GRI).m_kBattle, 'm_iPlayerTurn', m_kInventory, m_kInventory.ForceUpdate);
	
	// Force initial update.
	// Currently game core is raising update after building abilities but it's
	// happening before this screen is spawned.
	Update();

	Movie.UpdateHighestDepthScreens();
}
simulated function OnSkyrangerButtonSizeRealized()
{
	SkyrangerButton.SetPosition(-45 - SkyrangerButton.Width, 15);
}

// Delays call to OnInit until this function returns true
simulated function bool CheckDependencies()
{
	return XComTacticalGRI(WorldInfo.GRI) != none && XComTacticalGRI(WorldInfo.GRI).m_kBattle != none;
}

simulated function bool SelectTargetByHotKey(int ActionMask, int KeyCode)
{
	local int EnemyIndex;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return false;

	EnemyIndex = KeyCode - class'UIUtilities_Input'.const.FXS_KEY_F1;

	if (EnemyIndex >= m_kEnemyTargets.GetEnemyCount())
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
		return false;
	}

	m_kEnemyTargets.SelectEnemyByIndex(EnemyIndex);
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	local bool bHandled;    // Has input been 'consumed'?

	//set the current selection in the AbilityContainer
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 && m_kAbilityHUD != none)
		m_kAbilityHUD.SetSelectionOnInputPress(cmd);

	// Only allow releases through past this point.
	if ( ( arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0 )
		return false;

	if( m_kAbilityHUD != none )
	{
		bHandled = m_kAbilityHUD.OnUnrealCommand(cmd, arg); 
	}

	// Rest of the system ignores input if not in a shot menu mode.
	// Need to return bHandled to prevent double weapon switching. -TMH
 	if ( !m_isMenuRaised )		
		return bHandled;

	if ( !bHandled )
		bHandled = m_kShotHUD.OnUnrealCommand(cmd, arg);

	if ( !bHandled )
	{
		if (cmd >= class'UIUtilities_Input'.const.FXS_KEY_F1 && cmd <= class'UIUtilities_Input'.const.FXS_KEY_F8)
		{
			bHandled = SelectTargetByHotKey(arg, cmd);
		}
		else
		{
			switch(cmd)
			{
				case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):	
				case (class'UIUtilities_Input'.const.FXS_MOUSE_4):	
					GetTargetingMethod().PrevTarget();
					bHandled=true;
					break;

				case (class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT):
					if(IsActionPathingWithTarget())
					{
						bHandled = false;
					}
					else
					{
						GetTargetingMethod().PrevTarget();
						bHandled = true;
					}
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
				case (class'UIUtilities_Input'.const.FXS_KEY_TAB):
				case (class'UIUtilities_Input'.const.FXS_MOUSE_5):	
					GetTargetingMethod().NextTarget();
					bHandled=true;
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER): // if the press the button to raise the menu again, close it.
				case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
					bHandled = CancelTargetingAction();
					break; 

				case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
					if (!IsActionPathingWithTarget())
					{
						bHandled = CancelTargetingAction();
					}
					else
					{
						bHandled = false;
					}
					break;

				case (class'UIUtilities_Input'.const.FXS_BUTTON_START):

					CancelTargetingAction();
					Movie.Pres.UIPauseMenu( );
					bHandled = true;
					break;
			
				default: 				
					bHandled = false;
					break;
			}
		}
	}

	if ( !bHandled )
		bHandled = super.OnUnrealCommand(cmd, arg);

	return bHandled;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
//	local string callbackTarget;

	if(cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		return;

//	callbackTarget = args[args.Length - 1];
}

simulated function UpdateSkyrangerButton()
{
	local int i;
	local AvailableAction AvailableActionInfo;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local bool bButtonVisible;

	for (i = 0; i < m_kAbilityHUD.m_arrAbilities.Length; i++)
	{
		AvailableActionInfo = m_kAbilityHUD.m_arrAbilities[i];
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_kAbilityHUD.m_arrAbilities[i].AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		if (AbilityTemplate.DataName == 'PlaceEvacZone')
		{
			bButtonVisible = AvailableActionInfo.AvailableCode == 'AA_Success' &&
				(!`REPLAY.bInTutorial || `TUTORIAL.IsNextAbility(AbilityTemplate.DataName));
			break;
		}
	}

	if (bButtonVisible)
	{
		SkyrangerButton.Show();
	}
	else
	{
		SkyrangerButton.Hide();
	}
}
simulated function TargetHighestHitChanceEnemy()
{
	local AvailableAction AvailableActionInfo;
	local int HighestHitChanceIndex;
	local float HighestHitChance;
	local array<Availabletarget> Targets;	
	local float HitChance;
	local int i;
	
	AvailableActionInfo = m_kAbilityHUD.GetSelectedAction();
	//AvailableActionInfo.AvailableTargets = m_kAbilityHUD.SortTargets(AvailableActionInfo.AvailableTargets);

	Targets = AvailableActionInfo.AvailableTargets;
	for (i = 0; i < Targets.Length; i++)
	{
		HitChance = m_kEnemyTargets.GetHitChanceForObjectRef(Targets[i].PrimaryTarget);
		if (HitChance > HighestHitChance)
		{
			HighestHitChance = HitChance;
			HighestHitChanceIndex = i;
		}
	}

	m_kAbilityHUD.GetTargetingMethod().DirectSetTarget(HighestHitChanceIndex);
	TargetEnemy(HighestHitChanceIndex);
}
simulated function RaiseTargetSystem()
{
	local XGUnit kUnit;

	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;

	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = -1;
	m_bIsHidingShotHUDForSecondaryMovement = false;
	Ruleset = `XCOMGAME.GameRuleset;	
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	kUnit = XComTacticalController(PC).GetActiveUnit();
	if (kUnit == none )
	{
		`warn("Unable to raise tactical UI targeting system due to GetActiveUnit() being none.");
		return;
	}

	m_kAbilityHUD.SetAlpha(1.0);
	m_bForceOverheadView = false;
	m_isMenuRaised = true;
	XComTacticalController(PC).m_bInputInShotHUD = true;

	// attempt to target the default guy (will open shot hud even without enemy, this should be cleaned up)
	//TargetEnemy(0);
	TargetHighestHitChanceEnemy();

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();

	UpdateSkyrangerButton();
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit(  m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );

	m_kObjectivesControl.Hide();
	m_kShotInfoWings.Show();
	CharInfoButton.Show();

	if (m_kEnemyTargets.GetEnemyCount() > 0)
	{
		m_kEnemyTargets.Show();
	}
	`PRES.m_kWorldMessageManager.NotifyShotHudRaised();

	// This is for making it so the targeting unit can still animate when off screen enabling the unit 
	// to keep facing the cursor position.  See function definition for more info.  mdomowicz 2015_09_03
	GetTargetingMethod().EnableShooterSkelUpdatesWhenNotRendered(true);
	if(m_bEnemyInfoVisible)
	{
		SimulateEnemyMouseOver(true);
	}
}
simulated function HideAwayTargetSystemCosmetic()
{
	local XGUnit kUnit;

	kUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if (kUnit != none)
		kUnit.RemoveRangesOnSquad(kUnit.GetSquad());

	Invoke("ShowNonShotMode");
	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = m_kAbilityHUD.m_iCurrentIndex;
	m_kAbilityHUD.NotifyCanceled();

	//<workshop> SCI 2016/1/11
	//INS:
	if (`XPROFILESETTINGS.Data.m_bAbilityGrid)
	{
		m_kAbilityHUD.SetAlpha(0.36);
	}
	else
	{
		m_kAbilityHUD.SetAlpha(0.58);
	}
	//</workshop>

	XComPresentationLayer(Owner).m_kUnitFlagManager.ClearAbilityDamagePreview();

	m_isMenuRaised = false;
	XComTacticalController(PC).m_bInputInShotHUD = false;

	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();

	//<workshop> SCI 2016/5/17
	//INS:
	UpdateSkyrangerButton();
	//</workshop>

	m_kShotHUD.ResetDamageBreakdown(true);
	m_kEnemyTargets.RealizeTargets(-1);
	m_kShotInfoWings.Hide();

	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.DeactivateExtensionForTargetedUnit();
	GetTargetingMethod().EnableShooterSkelUpdatesWhenNotRendered(false);

	//<workshop> ENEMY_INFO_HANDLING - JTA 2016/1/6
	//INS:
	SimulateEnemyMouseOver(false);
	//</workshop>
}

simulated function LowerTargetSystem()
{	
	local XGUnit kUnit;
	local X2TargetingMethod TargetingMethod;

	kUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if (kUnit != none)
		kUnit.RemoveRangesOnSquad(kUnit.GetSquad());

	Invoke("ShowNonShotMode");
	m_kAbilityHUD.NotifyCanceled();
	m_kAbilityHUD.m_iPreviousIndexForSecondaryMovement = -1;
	m_kTargetReticle.SetTarget();

	XComPresentationLayer(Owner).m_kUnitFlagManager.ClearAbilityDamagePreview();

	m_isMenuRaised = false;
	XComTacticalController(PC).m_bInputInShotHUD = false;

	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();

	if( m_kMouseControls != none )
		m_kMouseControls.UpdateControls();
	UpdateSkyrangerButton();
	
	m_kShotHUD.ResetDamageBreakdown(true);
	m_kShotHUD.LowerShotHUD();
	m_kEnemyTargets.RealizeTargets(-1);
	m_kShotInfoWings.Hide();
	m_kObjectivesControl.Show();
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.DeactivateExtensionForTargetedUnit();
	TargetingMethod = GetTargetingMethod();
	if (TargetingMethod != none)
		TargetingMethod.EnableShooterSkelUpdatesWhenNotRendered(false);
	if( `ISCONTROLLERACTIVE )
		SimulateEnemyMouseOver(false);
}

simulated function UpdateNavHelp()
{
	local PlayerInput InputController; //used to detect the state
	local String LabelForInfoHelp; //pulls up info about the character/enemy
	
	if(!`ISCONTROLLERACTIVE)
		return;	

	//determine what type of info is displayed, if any
	InputController = `LEVEL.GetALocalPlayerController().PlayerInput; //using Input class because that is where the handling is located for the character info
	if(InputController != None && InputController.IsInState('ActiveUnit_Moving'))
	{
		LabelForInfoHelp = m_strNavHelpCharShow;
	}
	else if(m_isMenuRaised && m_bEnemyInfoVisible)
	{
		LabelForInfoHelp = m_strNavHelpEnemyHide;
	}
	//checks to see if there is an active enemy
	else if(m_isMenuRaised && !m_bEnemyInfoVisible && m_kEnemyTargets != none)
	{
		//checks to see if the target-able enemy has any info to show
		if(m_kEnemyTargets.TargetEnemyHasEffectsToDisplay() || ShotBreakdownIsAvailable())
		{
			LabelForInfoHelp = m_strNavHelpEnemyShow;
		}
	}
			
	//Sometimes the player can focus on 'enemies' that have extra info (explosive canisters)
	if(m_isMenuRaised && !(ShotBreakdownIsAvailable() || TargetEnemyHasEffectsToDisplay()))
	{
		LabelForInfoHelp = "";
	}

	//If the label was set, show the help icon
	if(LabelForInfoHelp != "")
	{
		CharInfoButton.SetText(LabelForInfoHelp);
	}	
}


//Simulates the mouse event that occurs when a player hovers their mouse over the enemy targets
//Purpose is to manually show the tooltips that are triggered bia button press when a mouse isn't available
//bIsHovering - simulate a MOUSE_IN command if 'true'
//returns 'true' if it attempts to simulate a mouse hover (can abort the process if there are no enemy targets to simulate)
simulated function bool SimulateEnemyMouseOver(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local String ActiveEnemyPath;
	local int MouseCommand;

	if(bIsHovering)
	{		
		//checks to see if current enemy has any information to display
		if(m_kEnemyTargets != None && m_kEnemyTargets.TargetEnemyHasEffectsToDisplay())
		{
			MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_IN;
			m_bEnemyInfoVisible = true;
		}
		else //if enemy does not have any effects to display, do not simulate a mouse-hover
		{
			//This used to simply "return false;", leaving the tooltip in its current state.
			//We need to handle the case where the user switches directly between enemies with LB/RB, though.
			//They may toggle away from an enemy that had buffs, and land on an enemy with no buffs.
			//Hide the tooltip in this case. -BET 2016-05-31
			MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;
		}
	}		
	else
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;
		m_bEnemyInfoVisible = false;
	}		

	//UITacticalHUD_BuffsTooltip uses the path to determine the enemy type, pulling directly from the 6th parsed section, after "icon" (this happens in 'RefreshData')
	//It will look something like this: "_level0.theInterfaceMgr.UITacticalHUD_0.theTacticalHUD.enemyTargets.Icon0"
	ActiveEnemyPath = string(m_kEnemyTargets.MCPath) $ ".icon" $ m_kEnemyTargets.GetCurrentTargetIndex();

	Mgr = Movie.Pres.m_kTooltipMgr;
	Mgr.OnMouse("", MouseCommand, ActiveEnemyPath); //The Tooltip Manager uses the 'arg' parameter to set the path instead of the 'path' parameter
	
	UpdateNavHelp();

	return true;
}
//Sets a "show details" boolean that will persist when switching view modes, switching targets, etc
simulated function ToggleEnemyInfo()
{
	local bool bShotBreakdownAvailable;

	bShotBreakdownAvailable = ShotBreakdownIsAvailable();

	if (!m_isMenuRaised || (bShotBreakdownAvailable || TargetEnemyHasEffectsToDisplay()))
	{
		m_bEnemyInfoVisible = !m_bEnemyInfoVisible;

		if (bShotBreakdownAvailable)
		{
			ShowShotWings(m_bEnemyInfoVisible);
		}

		SimulateEnemyMouseOver(m_bEnemyInfoVisible);
	}
}

//Grabs the 'shot breakdown' and returns true if there is added info available in the shot wings (UITacticalHUD_ShotWings)
simulated function bool ShotBreakdownIsAvailable()
{
	local ShotBreakdown Breakdown;
	local XComGameState_Ability AbilityState;

	AbilityState = m_kAbilityHUD.GetCurrentSelectedAbility();
	if(AbilityState != None)
	{
		AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, m_kEnemyTargets.GetSelectedEnemyStateObjectRef(), AbilityState.GetReference(), Breakdown);
		return !Breakdown.HideShotBreakdown;
	}

	return false;
}

simulated function bool TargetEnemyHasEffectsToDisplay()
{
	if (m_kEnemyTargets != none)
	{
		return m_kEnemyTargets.TargetEnemyHasEffectsToDisplay();
	}

	return false;
}

//Handles visibility for UITacticalHUD_ShotWings.uc (simulates player pressing the show/hide buttons available on PC)
simulated function ShowShotWings(bool bShow)
{
	if(m_kShotInfoWings != None)
	{
		//function called is a blind toggle, so this checks to make sure the desired effect is going to happen
		if(	(bShow && !m_kShotInfoWings.bLeftWingOpen && !m_kShotInfoWings.bRightWingOpen) ||
			(!bShow && m_kShotInfoWings.bLeftWingOpen && m_kShotInfoWings.bRightWingOpen))
		{
			m_kShotInfoWings.LeftWingMouseEvent(None, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
			m_kShotInfoWings.RightWingMouseEvent(None, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		}
	}
}

simulated function bool IsActionPathingWithTarget()
{
	//TODO:TARGETING
	/*
	local XGAction_Targeting kTargetingAction;

	kTargetingAction = XGAction_Targeting( XComTacticalController(PC).GetActiveUnit().GetAction() );
	if( kTargetingAction != none && kTargetingAction.GetPathAction() != none)
	{
		return true;
	}
	*/
	return false;
}

simulated function bool IsHidingForSecondaryMovement()
{
	return m_bIsHidingShotHUDForSecondaryMovement;
}

simulated function bool HideAwayTargetAction()
{
	HideAwayTargetSystemCosmetic();
	m_bIsHidingShotHUDForSecondaryMovement = true;
	return false;
}
simulated function bool CancelTargetingAction()
{
	LowerTargetSystem();
	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.ClearSelectedEnemy();
	PC.SetInputState('ActiveUnit_Moving');
	return true; // controller: return false ? bsteiner 
}

simulated function TargetEnemy( int TargetIndex )
{
	m_kAbilityHUD.UpdateAbilitiesArray();
	if(!IsHidingForSecondaryMovement())
		RealizeTargetingReticules( TargetIndex );
	m_kEnemyTargets.RefreshSelectedEnemy(true, true);
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit(  m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );
	m_kShotHUD.Update();


	if( `ISCONTROLLERACTIVE )
		SimulateEnemyMouseOver(m_bEnemyInfoVisible && ShotBreakdownIsAvailable());
}

simulated function RealizeTargetingReticules( optional int TargetIndex = 0 )
{
	local bool isDefensiveMode;

	//@TODO - jbouscher - add a field to AvailableAction, or provide a mechanism in the ability template that can tell if this is an offensive or defensive ability
	isDefensiveMode = false;

	if ( isDefensiveMode )
	{
		Invoke("ShowDefenseReticule");
	}
	else
	{
		//@TODO - jbouscher - the ability should be able to specify an overhead / overshoulder interface
		if ( !m_bForceOverheadView )
		{
			Invoke("ShowOffenseReticule");
		}
		else
		{
			Invoke("ShowOvershoulderReticule");
		}
	}

	//-----------------------------------------

	//Use the actual selected ability for reticle update, so that it uses the correct target. 
	UpdateReticle( m_kAbilityHUD.GetSelectedAction(), TargetIndex );
	
	//-----------------------------------------
	XComPresentationLayer(Owner).m_kUnitFlagManager.RealizeTargetedStates();
}


simulated function Update()
{
	InternalUpdate(false, -1);
}

simulated function ForceUpdate(int HistoryIndex)
{
	InternalUpdate(true, HistoryIndex);
}

simulated function InternalUpdate(bool bForceUpdate, int HistoryIndex)
{
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local StateObjectReference ActiveUnitRef;

	if ( !bIsInited )
	{
		`warn("Attempt to ResetActionHUD before it was initialized.");
		return;
	}

	Ruleset = `XCOMGAME.GameRuleset;	

	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	if( ActiveUnitRef.ObjectID > 0 )
	{
		Ruleset.GetGameRulesCache_Unit(ActiveUnitRef, UnitInfoCache);
	
		//TODO: change over to a watch variable. -bsteiner 
		// TODO: may need to force the update on clients when we get replicated data. -tsmith 
		m_kInventory.Update( True );
		m_kStatsContainer.UpdateStats();

		// Re-raise target system if an abilities update was requested.
		if ( m_isMenuRaised )
			//TargetEnemy( 0 );
			TargetHighestHitChanceEnemy();
		
		m_kAbilityHUD.UpdateAbilitiesArray();
		m_kEnemyTargets.RefreshTargetHoverData();
		m_kEnemyTargets.RefreshAllTargetsBuffs();

		// force visualizer sync
		RealizeConcealmentStatus(ActiveUnitRef.ObjectID, bForceUpdate, HistoryIndex);
	}

	m_bIgnoreShowUntilInternalUpdate = false;
	Show();
}

simulated function RealizeConcealmentStatus(int SelectedUnitID, bool bForceUpdate, int HistoryIndex)
{
	local eUI_ConcealmentMode DesiredConcealmentMode;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(SelectedUnitID, , HistoryIndex));

	if( !UnitState.IsConcealed() )
	{
		DesiredConcealmentMode = eUIConcealment_None;
	}
	else if( UnitState.IsSquadConcealed() )
	{
		DesiredConcealmentMode = eUIConcealment_Squad;
	}
	else
	{
		DesiredConcealmentMode = eUIConcealment_Individual;
	}

	if( DesiredConcealmentMode != ConcealmentMode )
	{
		ConcealmentMode = DesiredConcealmentMode;

		if( ConcealmentMode == eUIConcealment_None )
		{
			if( !bForceUpdate )
			{
				// when changing the selected unit ID, the transition should be instant
				MC.FunctionVoid("HideConcealmentHUD");
			}
			else
			{
				// when not changing the selected unit ID, the transition should display the concealment broken animation
				MC.FunctionString("ShowRevealedHUD", m_strRevealed);
			}
		}
		else
		{
			MC.BeginFunctionOp("ShowConcealmentHUD");
			MC.QueueBoolean(ConcealmentMode == eUIConcealment_Squad);
			MC.QueueString(ConcealmentMode == eUIConcealment_Squad ? m_strSquadConcealed : m_strConcealed);
			MC.EndOp();
		}
	}
}

// Should only be raised when switching abilities AFTER the initial raise.
simulated function OnAbilityChanged()
{
	local AvailableAction AvailableActionInfo;

	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;

	Ruleset = `XCOMGAME.GameRuleset;	
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	AvailableActionInfo = GetSelectedAction();
	if (AvailableActionInfo.AbilityObjectRef.ObjectID > 0)
	{
		return;
	}
	else 
	{
		RealizeTargetingReticules();
	}

	//XComPresentationLayer(Movie.Pres).m_kSightlineHUD.RefreshSelectedEnemy();
	
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit( m_kEnemyTargets.GetSelectedEnemyStateObjectRef() );
}

//Triggered in the ability container. 
simulated function OnFreeAimChange()
{
	//Update the reticles 
	UpdateReticle( m_kAbilityHUD.GetSelectedAction(), 0 );
	//Refresh the list of visible enemies (i.e. get rid of targeting icons for free-aiming abilities like grenades)
	m_kEnemyTargets.UpdateVisibleEnemies(-1);
}

function UpdateReticle( AvailableAction kAbility, int TargetIndex )
{	
	local XComGameState_BaseObject  TargetState;
	local XComGameState_Ability AbilityState;

	if( !kAbility.bFreeAim && TargetIndex < kAbility.AvailableTargets.Length )
	{
		TargetState = `XCOMHISTORY.GetGameStateForObjectID( kAbility.AvailableTargets[TargetIndex].PrimaryTarget.ObjectID );			
	}
	
	m_kTargetReticle.SetTarget(TargetState != None ? TargetState.GetVisualizer() : None);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID( kAbility.AbilityObjectRef.ObjectID ));
	if (AbilityState != none)
	{
		m_kTargetReticle.SetMode(AbilityState.GetUIReticleIndex());
	}
}

simulated function SetReticleMessages( string msg )
{
	m_kTargetReticle.SetCursorMessage( msg );
}

simulated function LockTheReticles( bool bLock )
{
	m_kTargetReticle.LockTheCursor( bLock );
}

simulated function SetReticleAimPercentages( float fPercent, float fCritical )
{
	m_kTargetReticle.SetAimPercentages( fPercent, fCritical );
}

simulated function AvailableAction GetSelectedAction()
{
	return m_kAbilityHUD.GetSelectedAction();
}

simulated function eUI_ReticleMode GetReticleMode() 
{ 
	return m_eReticleMode; 
}
simulated function SetReticleMode( eUI_ReticleMode eMode ) 
{
	m_eReticleMode = eMode; 
}

simulated function Show()
{
	local XComPresentationLayer Pres;

	if (m_bIgnoreShowUntilInternalUpdate)
	{
		return;
	}

	if(`TACTICALRULES.HasTacticalGameEnded())
	{
		// the match has ended, no need for this UI now as we are simply visualizing the rest of the match
		// from here on out
		Hide();
		return;
	}

	Pres = XComPresentationLayer(Movie.Pres);

	CharInfoButton.Show();
	if( !Pres.m_kTurnOverlay.IsShowingAlienTurn() 
	   && !Pres.m_kTurnOverlay.IsShowingOtherTurn()
	   && !Pres.m_kTurnOverlay.IsShowingReflexAction() 
	   && !Pres.m_kTurnOverlay.IsShowingSpecialTurn() ) //And don't show if the turn overlay is still active. -bsteiner 5/11/2015
		super.Show();
}
simulated function Hide()
{
	m_kAbilityHUD.NotifyCanceled();
	super.Hide();
}

simulated function InitializeMouseControls()
{
	Invoke("InitializeMouseControls");
}

simulated function bool IsMenuRaised() 
{ 
	if(WorldInfo.NetMode != NM_Client)
	{
		return m_isMenuRaised; 
	}
	else
	{
		return m_isMenuRaised || XComTacticalController(PC).m_bInputInShotHUD;
	}
}

//==============================================================================
//		TUTORIAL / SET-UP PHASE:
//==============================================================================

simulated function ShowTutorialHelp(string strHelpText, float DisplayTime)
{
	ClearTimer('HideTutorialHelp');

	if (DisplayTime > 0)
	{
		SetTimer(DisplayTime, false, 'HideTutorialHelp');
	}

	if (m_kTutorialHelpBox == none)
	{
		m_kTutorialHelpBox = Spawn(class'UIStrategyTutorialBox', self);
		m_kTutorialHelpBox.m_strHelpText = strHelpText; 
		m_kTutorialHelpBox.InitScreen(PC, Movie);
		`PRES.ScreenStack.Push( m_kTutorialHelpBox );
	}
	else
	{
		m_kTutorialHelpBox.SetNewHelpText(strHelpText);
		m_kTutorialHelpBox.Show();
	}
}

simulated function HideTutorialHelp()
{
	ClearTimer('HideTutorialHelp');

	if (m_kTutorialHelpBox != none)
	{
		m_kTutorialHelpBox.Hide();
	}
}

simulated function UpdateButtonHelp()
{
}

simulated function OnRemoved()
{
	XComPresentationLayer(Movie.Pres).DeactivateAbilityHUD();

	if (m_kEventNotices != none)
		m_kEventNotices.Uninit();
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theTacticalHUD";
	Package = "/ package/gfxTacticalHUD/TacticalHUD";

	m_isMenuRaised = false;
	bHideOnLoseFocus = false;
	bAnimateOnInit = false;

	m_bIsHidingShotHUDForSecondaryMovement = false;
	bProcessMouseEventsIfNotFocused = true;
}
