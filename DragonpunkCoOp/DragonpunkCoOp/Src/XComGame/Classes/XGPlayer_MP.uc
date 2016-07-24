//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGPlayer_MP.uc
//  AUTHOR:  Todd Smith  --  12/12/2011
//  PURPOSE: This file is used for the following stuff..blah
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XGPlayer_MP extends XGPlayer;

const WAITING_FOR_GAME_OVER_TIMEOUT_SECONDS = 7.0f;

var privatewrite bool       m_bGameOver;
var privatewrite float      m_fWaitingForGameOverTimerSeconds;


// called on the very first turn of the game. this is not necessarily the first turn for the player, its the first global turn. -tsmith 
reliable client function ClientOnFirstGameTurn(bool bActivePlayer)
{
	local XCom3DCursor kCursor;
	local XGUnit kFirstUnitInSquad;
	local XComUnitPawn kUnitPawn;

	kCursor = m_kPlayerController.GetCursor();
	kFirstUnitInSquad = m_kSquad.GetMemberAt(0);
	`assert(kCursor != none);
	`assert(kFirstUnitInSquad != none);

	`log(self $ "::" $ GetFuncName() @ `ShowVar(bActivePlayer) @ `ShowVar(kCursor) @ `ShowVar(kFirstUnitInSquad) @ kFirstUnitInSquad.SafeGetCharacterFullName(), true, 'XCom_Net');

	if(!bActivePlayer)
	{
		//set the camera to track the cursor and to move the cursor to our first unit in the squad.
		//`CAMERAMGR.Track('TrackingCursor');
		kUnitPawn = kFirstUnitInSquad.GetPawn();
		kCursor.MoveToUnit(kUnitPawn);
	}
}

simulated function bool CheckAllSquadsIdle(bool bCountPathActionsAsIdle)
{
	local XGSquad     kSquad;
	local bool        bAllSquadsIdle;

	bAllSquadsIdle = true;
	foreach DynamicActors(class'XGSquad', kSquad)
	{
		bAllSquadsIdle = bAllSquadsIdle && kSquad.IsNetworkIdle(bCountPathActionsAsIdle);
	}

	return bAllSquadsIdle;
}

defaultproperties
{
	m_fWaitingForGameOverTimerSeconds=WAITING_FOR_GAME_OVER_TIMEOUT_SECONDS
}
