//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PlayAnimation extends X2Action;

var	public	CustomAnimParams	Params;
var public  bool                bFinishAnimationWait;
var private AnimNodeSequence    PlayingSequence;
var public  bool                bResetWeaponsToDefaultSockets; //If set, ResetWeaponsToDefaultSockets will be called on the unit before the animation is played.

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	if (UnitPawn.GetAnimTreeController().CanPlayAnimation(Params.AnimName))
	{
		//The current use-case for this is when a unit becomes stunned; they may get stunned by a counter-attack while they have a secondary weapon out, for example.
		if (bResetWeaponsToDefaultSockets)
			Unit.ResetWeaponsToDefaultSockets();

		if (Params.Additive)
		{
			UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(Params);
		}
		else
		{
			PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

			if (bFinishAnimationWait)
			{
				FinishAnim(PlayingSequence);
			}
		}
	}
	else
	{
		`RedScreen("Failed to play animation" @ Params.AnimName @ "on" @ UnitPawn @ "as part of" @ self);
	}

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

DefaultProperties
{
	bFinishAnimationWait=true
	bResetWeaponsToDefaultSockets=false
}
