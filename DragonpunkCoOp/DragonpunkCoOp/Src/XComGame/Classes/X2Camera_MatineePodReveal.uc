//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_MatineePodReveal.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized Matinee camera that takes the reveal unit's motion into account and discards cameras that would
//           run them into a wall.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_MatineePodReveal extends X2Camera_Matinee
	dependson(X2MatineeInfo)
	native;

// traces the focus unit's animation path in the reveal matinee and tries to detect when they will
// walk into terrain or walls so we can reject those matinees
native function protected bool IsActorsMovementClear(SeqAct_Interp Matinee, Actor FocusActor, const out Rotator OldCameraLocation);

protected function bool IsMatineeValid(SeqAct_Interp Matinee, Actor FocusActor, Rotator OldCameraLocation)
{
	local XComTacticalCheatManager CheatManager;

	if(!super.IsMatineeValid(Matinee, FocusActor, OldCameraLocation))
	{
		return false;
	}

	CheatManager = `CHEATMGR;
	if (CheatManager.DisablePodRevealLeaderCollisionFail)
	{
		return true;
	}

	return IsActorsMovementClear(Matinee, FocusActor, OldCameraLocation);
}