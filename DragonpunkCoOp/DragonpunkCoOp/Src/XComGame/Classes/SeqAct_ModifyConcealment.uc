//-----------------------------------------------------------
// Modify the concealment state of the entire squad or a particular unit. 
//-----------------------------------------------------------
class SeqAct_ModifyConcealment extends SequenceAction;

var XComGameState_Unit Unit;
var() bool bSquadConcealment;

event Activated()
{
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	
	if( bSquadConcealment )
	{
		History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == eTeam_XCom )
			{
				break;
			}
		}

		if( InputLinks[0].bHasImpulse )
		{
			PlayerState.SetSquadConcealment(true);
		}
		else if( InputLinks[1].bHasImpulse )
		{
			PlayerState.SetSquadConcealment(false);
		}
		else if( InputLinks[2].bHasImpulse )
		{
			PlayerState.SetSquadConcealment(!PlayerState.bSquadIsConcealed);
		}
	}
	else if( Unit != None )
	{
		if( InputLinks[0].bHasImpulse )
		{
			if( !Unit.IsConcealed() )
			{
				Unit.EnterConcealment();
			}
		}
		else if( InputLinks[1].bHasImpulse )
		{
			if( Unit.IsConcealed() )
			{
				Unit.BreakConcealment();
			}
		}
		else if( InputLinks[2].bHasImpulse )
		{
			if( Unit.IsConcealed() )
			{
				Unit.BreakConcealment();
			}
			else
			{
				Unit.EnterConcealment();
			}
		}
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Modify Unit or Squad Concealment"
	bCallHandler = false
	
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Conceal")
	InputLinks(1)=(LinkDesc="Reveal")
	InputLinks(2)=(LinkDesc="Toggle")

	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}

