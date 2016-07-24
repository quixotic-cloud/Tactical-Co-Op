//---------------------------------------------------------------------------------------
//  FILE:    X2Action_AnimSetTransition.uc
//  AUTHOR:  Alex Cheng  --  3/12/2015
//  PURPOSE: Visualization of transition between two anim sets.  Extends PlayAnimation action, 
//           with an additional UpdateAnimations call after transition is played
//			 to update the pawn's animset.
//           Initially created for Gatekeeper Open / Closed anim sets, extended to be
//			 used with the Sectopod for its High / Low anim sets.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_AnimSetTransition extends X2Action_PlayAnimation;

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	
	// Unit plays the transition, followed by a change from one animset to 
	// the next.
	UnitPawn.UpdateAnimations();

	CompleteAction();
}

DefaultProperties
{
}
