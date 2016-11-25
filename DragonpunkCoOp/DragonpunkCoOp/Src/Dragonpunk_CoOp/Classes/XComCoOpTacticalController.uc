//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComCoOpTacticalController
//  AUTHOR:  Elad Dvash
//  PURPOSE: Manages control over characters and actions in tactical Co-op gameplay.
//---------------------------------------------------------------------------------------  
                                                                                                                      
Class XComCoOpTacticalController extends XComTacticalController;

var bool IsCurrentlyWaiting;

/*
* Changes the contolled unit to one that's under the control of the player, checks to see if server or client 
* So no one is controlling a character they dont "own"                                                                                                                
*/
simulated function bool Visualizer_SelectNextUnit()
{	
	local int CurrentSelectedIndex;
	local array<XComGameState_Unit> EligibleUnits,AllUnits;
	local XComGameState_Unit SelectNewUnit;	
	local XComGameState_Unit CurrentUnit;	
	local XComGameState_Unit TempUnit;	
	local bool bAllowedToSwitch;

	if (`TUTORIAL != none)
	{
		// Disable unit cycling in tutorial
		return false;
	}

	if( (`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
	{
		ControllingPlayerVisualizer.GetUnitsForAllPlayers(EligibleUnits);
	}
	else
	{
		ControllingPlayerVisualizer.GetUnitsWithMovesRemaining(EligibleUnits,,true);
		AllUnits=EligibleUnits;
		foreach AllUnits(TempUnit)
		{
			if(`XCOMNETMANAGER.HasServerConnection()!=(TempUnit.GetMaxStat(eStat_FlightFuel)!=10))
				EligibleUnits.RemoveItem(TempUnit);
		}
	}

	//Not allowed to switch if the currently controlled unit is being forced to take an action next
	bAllowedToSwitch = true;
	CurrentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ControllingUnit.ObjectID));
	if (CurrentUnit != none)
	{
		bAllowedToSwitch = bAllowedToSwitch && CurrentUnit.ReflexActionState != eReflexActionState_SelectAction;
	}

	while (EligibleUnits.Length > 0 && bAllowedToSwitch)
	{
		CurrentSelectedIndex = 0;
		if( EligibleUnits.Length > 1 )
		{
			for( CurrentSelectedIndex = 0; CurrentSelectedIndex < EligibleUnits.Length; ++CurrentSelectedIndex )
			{
				if( EligibleUnits[CurrentSelectedIndex].ObjectID == ControllingUnit.ObjectID )
				{
					break;
				}
			}

			CurrentSelectedIndex = (CurrentSelectedIndex + 1) % EligibleUnits.Length;
		}

		SelectNewUnit = EligibleUnits[CurrentSelectedIndex];

		if (Visualizer_SelectUnit(SelectNewUnit))
			return true;

		EligibleUnits.RemoveItem(SelectNewUnit);
	}

	return false;
}

/*
* Changes the contolled unit to one that's under the control of the player, checks to see if server or client 
* So no one is controlling a character they dont "own"                                                                                                                
*/
simulated function bool Visualizer_SelectPreviousUnit()
{
	local int CurrentSelectedIndex;
	local array<XComGameState_Unit> EligibleUnits,AllUnits;
	local XComGameState_Unit SelectNewUnit;
	local XComGameState_Unit CurrentUnit;	
	local XComGameState_Unit TempUnit;	

	if (`TUTORIAL != none)
	{
		// Disable unit cycling in tutorial
		return false;
	}

	if( (`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
	{
		ControllingPlayerVisualizer.GetUnitsForAllPlayers(EligibleUnits);
	}
	else
	{
		ControllingPlayerVisualizer.GetUnitsWithMovesRemaining(EligibleUnits,,true);
		AllUnits=EligibleUnits;
		foreach AllUnits(TempUnit)
		{
			if(`XCOMNETMANAGER.HasServerConnection()!=(TempUnit.GetMaxStat(eStat_FlightFuel)!=10)) //if this is true then the unit is not available for control.
				EligibleUnits.RemoveItem(TempUnit);
		}
	}

	//Not allowed to switch if the currently controlled unit is being forced to take an action next
	CurrentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ControllingUnit.ObjectID));

	while( EligibleUnits.Length > 0 && CurrentUnit.ReflexActionState != eReflexActionState_SelectAction )
	{
		CurrentSelectedIndex = 0;
		if( EligibleUnits.Length > 1 )
		{
			for( CurrentSelectedIndex = 0; CurrentSelectedIndex < EligibleUnits.Length; ++CurrentSelectedIndex )
			{
				if( EligibleUnits[CurrentSelectedIndex].ObjectID == ControllingUnit.ObjectID )
				{
					break;
				}
			}

			CurrentSelectedIndex = CurrentSelectedIndex - 1;
			if( CurrentSelectedIndex < 0 )
			{
				CurrentSelectedIndex = EligibleUnits.Length - 1;
			}
		}

		SelectNewUnit = EligibleUnits[CurrentSelectedIndex];

		if (Visualizer_SelectUnit(SelectNewUnit))
			return true;

		EligibleUnits.RemoveItem(SelectNewUnit);
	}

	return false;
}

/*
* Changes the contolled unit to one that's under the control of the player, checks to see if server or client 
* So no one is controlling a character they dont "own"                                                                                                                
*/
simulated function bool Visualizer_SelectUnit(XComGameState_Unit SelectedUnit)
{
	//local GameRulesCache_Unit OutCacheData;
	local XComGameState_Player PlayerState;
	local XGPlayer PlayerVisualizer;
	local XCom3DCursor kCursor;	

	if(IsCurrentlyWaiting)
	{
		SetInputState('BlockingInput');
		return false;
	}
	if(SelectedUnit.GetTeam()==eTeam_XCom && SelectedUnit.GetMaxStat(eStat_FlightFuel)==10 && !`XCOMNETMANAGER.HasClientConnection()) //Check for client unit when you're not the client
	{
		`log("This is a server trying to access a client unit with the name:"@SelectedUnit.GetFullName());
		return false;
	}
	if(SelectedUnit.GetTeam()==eTeam_XCom && SelectedUnit.GetMaxStat(eStat_FlightFuel)!=10 && !`XCOMNETMANAGER.HasServerConnection())
	{
		`log("This is a client trying to access a server unit with the name:"@SelectedUnit.GetFullName());
		return false;
	}
	`log((`XCOMNETMANAGER.HasClientConnection()? "client":"server") @"trying to get a unit which is his own:"@SelectedUnit.GetFullName());
	
	if (SelectedUnit.GetMyTemplate().bNeverSelectable) //Somewhat special-case handling Mimic Beacons, which need (for gameplay) to appear alive and relevant
		return false;

	if( SelectedUnit.GetMyTemplate().bIsCosmetic ) //Cosmetic units are not allowed to be selected
		return false;

	if (SelectedUnit.ControllingPlayerIsAI())
	{
		// Update concealment markers when AI unit is selected because the PathingPawn is hidden and concealment tiles won't update so it remains visible
		m_kPathingPawn.UpdateConcealmentMarkers();
	}

	if (SelectedUnit.bPanicked && !(`CHEATMGR != None && `CHEATMGR.bAllowSelectAll)) //Panicked units are not allowed to be selected
		return false;

	//Dead, unconscious, and bleeding-out units should not be selectable.
	if (SelectedUnit.IsDead() || SelectedUnit.IsIncapacitated())
		return false;

	if(!`TACTICALRULES.AllowVisualizerSelection())
		return false;

	/* jbouscher - allow free form clicks to select units with no moves remaining
	if( (`CHEATMGR == None || !`CHEATMGR.bAllowSelectAll) )
	{
		// verify that this unit has moves left
		`TACTICALRULES.GetGameRulesCache_Unit(SelectedUnit.GetReference(), OutCacheData);
		if(!OutCacheData.bAnyActionsAvailable)
		{
			return false;
		}
	}
	*/

	`PRES.ShowFriendlySquadStatistics();
	`PRES.UIHideAllHUD();

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SelectedUnit.ControllingPlayer.ObjectID));
	PlayerVisualizer = XGPlayer(PlayerState.GetVisualizer());

	//@TODO - rmcfall - twiddling the old game play code to make it behave. Should the visualizer have this state?
	if( ControllingUnitVisualizer != none )
	{
		ControllingUnitVisualizer.Deactivate();
	}

	//Set our local cache variables for tracking what unit is selected
	ControllingUnit = SelectedUnit.GetReference();
	ControllingUnitVisualizer = XGUnit(SelectedUnit.GetVisualizer());

	//Support legacy variables
	m_kActiveUnit = ControllingUnitVisualizer;

	//@TODO - rmcfall - evaluate whether XGPlayer should be involved with selection
	PlayerVisualizer.SetActiveUnit( XGUnit(SelectedUnit.GetVisualizer()) );

	//@TODO - rmcfall - the system here is twiddling the old game play code to make it behavior. Think about a better way to interact with the UI / Input.
	SetInputState('ActiveUnit_Moving'); //Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods		
	ControllingUnitVisualizer.GotoState('Active'); //The unit visualizer 'Active' state enables pathing ( adds an XGAction_Path ), displays cover icons, etc.	
	kCursor = XCom3DCursor( Pawn );
	kCursor.MoveToUnit( m_kActiveUnit.GetPawn() );
	kCursor.SetPhysics( PHYS_Flying );
	//kCursor.SetCollision( false, false );
	kCursor.bCollideWorld = false;
	if(GetStateName() != 'PlayerWalking' && GetStateName() != 'PlayerDebugCamera')
	{   
		GotoState('PlayerWalking');
	}

	// notify the visualization manager that the unit changed so that UI etc. listeners can update themselves.
	// all of the logic above us should eventually be refactored to operate off of this callback
	`XCOMVISUALIZATIONMGR.NotifyActiveUnitChanged(SelectedUnit);

	return true;
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	if(Command ~= "SwitchTurn")
	{
		`PRES.UIHideAllHUD();
		IsCurrentlyWaiting=false;
	}

	else if(Command ~= "DisableControls")
		IsCurrentlyWaiting=true;	
}
function SendRemoteCommand(string Command)
{
	local array<byte> EmptyParams;
	EmptyParams.Length = 0; // Removes script warning
	`XCOMNETMANAGER.SendRemoteCommand(Command, EmptyParams);
	`log("Command Sent:"@Command,,'Dragonpunk Tactical');
}

/*
* Overrides the default end turn function and only ends the specifics' player turn and not the whole turn for all the sides                                                                                                                                                                                                                                      
*/
simulated function bool PerformEndTurn(EPlayerEndTurnType eEndTurnType)
{
	if(`XCOMNETMANAGER.HasServerConnection())
	{
		X2TacticalCoOpGameRuleset(`TACTICALRULES).bServerEndedTurn=true;
		SendRemoteCommand("ServerRequestEndTurn");
		return true;
	}
	return super.PerformEndTurn(eEndTurnType);
}

/*
* Puts the players into the right input state on request and logs it.                                                                                                                                                                                                                                      
*/
simulated function SetInputState( name nStateName , optional bool bForce)
{
	local string CurrentState;
	CurrentState=string(nStateName);
	if(CurrentState~="ActiveUnit_Moving")
	{
		ScriptTrace();
		XComCoOpInput( PlayerInput ).GotoState( name(CurrentState),, true );
		CurrentState="ActiveUnit_Moving_Coop";
	}

	`log("Activating State:" @CurrentState @"Original Name:" @string(nStateName));
	if (!`REPLAY.bInReplay || `REPLAY.bInTutorial)
	{
		XComCoOpInput( PlayerInput ).GotoState( name(CurrentState),, true );
	}
}

defaultproperties
{
	InputClass=class'Dragonpunk_CoOp.XComCoOpInput'
}