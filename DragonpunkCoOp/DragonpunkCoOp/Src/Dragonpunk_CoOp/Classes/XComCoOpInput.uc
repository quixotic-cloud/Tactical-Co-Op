//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComCoOpInput
//  AUTHOR:  Elad Dvash
//  PURPOSE: Deals with the input from the player while in co-op needed
//  for blocking input in co-op and limiting unit control for the players                                                                       
//---------------------------------------------------------------------------------------                           
class XComCoOpInput extends XComTacticalInput;

state ActiveUnit_Moving_Coop extends ActiveUnit_Moving
{
	
	function bool NextUnit()
	{
		// Don't allow unit changes when the unit is locked.
		if( !IsManualUnitSwitchAllowed() )
		{
			return false;
		}
		// Change the selection function to one that knows who is allowed to select which soldiers.
		if (`XCOMVISUALIZATIONMGR.VisualizerBusy())
		{
			XComCoOpTacticalController(Outer).bManuallySwitchedUnitsWhileVisualizerBusy = true;
		}
		XComCoOpTacticalController(Outer).Visualizer_SelectNextUnit();

		return true;
	}

	function bool PrevUnit()
	{
		// Don't allow unit changes when the unit is locked.
		if( !IsManualUnitSwitchAllowed() )
		{
			return false;
		}
		// Change the selection function to one that knows who is allowed to select which soldiers.
		if (`XCOMVISUALIZATIONMGR.VisualizerBusy())
		{
			XComCoOpTacticalController(Outer).bManuallySwitchedUnitsWhileVisualizerBusy = true;
		}

		XComCoOpTacticalController(Outer).Visualizer_SelectPreviousUnit();
		
		return true; 
	}

		function bool ClickSoldier( IMouseInteractionInterface MouseTarget )
	{
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;
		local XComUnitPawnNativeBase kPawn; 
		local XGUnit kTargetedUnit;
		local bool bChangeUnitSuccess, bHandled;

		if(!IsManualUnitSwitchAllowed())
		{
			return false;
		}

		kPawn = XComUnitPawnNativeBase(MouseTarget);	
		if( kPawn == none ) return false; 

		//This is the next unit we want to set as active 
		kTargetedUnit = XGUnit(kPawn.GetGameUnit());
		if( kTargetedUnit == none ) return false; 

		bChangeUnitSuccess = false;
		bHandled = false;
		if( XComCoOpTacticalController(Outer).m_XGPlayer.m_eTeam == kTargetedUnit.m_eTeam ) 
		{
			//`log("Want to target: " $ kTargetedUnit.GetHumanReadableName(),,'uixcom');
			
			// Select the targeted unit
			if( GetActiveUnit() != kTargetedUnit && `TUTORIAL == none)
			{
				History = `XCOMHISTORY;
				// Change the selection function to one that knows who is allowed to select which soldiers.
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTargetedUnit.ObjectID));
				bChangeUnitSuccess = (UnitState != none) && XComCoOpTacticalController(Outer).Visualizer_SelectUnit(UnitState);
				kTargetedUnit.m_bClickActivated = bChangeUnitSuccess;
				bHandled = bChangeUnitSuccess;
			}
		} 
		return bHandled; 
	}

	/*
	* When clicking the back button instead of ending the turn if you're the server only end your turn.
	*/
	function bool Back_Button( int ActionMask )
	{
		if ( ButtonIsDisabled(class'UIUtilities_Input'.const.FXS_BUTTON_SELECT ) )
			return true;

		if( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 ) //Change the function for ending the turn to one that knows who you are and what to do next
		{
			if(WorldInfo.NetMode != NM_Client)
			{
				if( XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised() )
					XComTacticalController(Outer).GetPres().GetTacticalHUD().CancelTargetingAction();

				XComCoOpTacticalController(Outer).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
			}
			else
			{
				if(!XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised())
				{
					XComCoOpTacticalController(Outer).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
				}
			}
			return true;
		}
		return true;
	}

}
state BlockingInput
{
	// Kill all input
	simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
	{
		return false;
	}

	event PushedState()
	{
		`log("XComCoOpInput: Input is blocked");
	}

	event PoppedState()
	{
		`log("XComCoOpInput: Input is no longer blocked");
	}
}

