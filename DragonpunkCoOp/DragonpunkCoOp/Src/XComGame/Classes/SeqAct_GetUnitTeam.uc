//-----------------------------------------------------------
//Gets the location of an xcom unit
//-----------------------------------------------------------
class SeqAct_GetUnitTeam extends SequenceAction;

var XComGameState_Unit Unit;

var() bool GetOriginalTeamIfMindControlled;

event Activated()
{
	local XComGameState_Player PlayerState;
	local ETeam TeamFlag;

	OutputLinks[0].bHasImpulse = false;
	OutputLinks[1].bHasImpulse = false;
	OutputLinks[2].bHasImpulse = false;

	if (Unit != none)
	{
		PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(Unit.GetAssociatedPlayerID()));
		TeamFlag = PlayerState.TeamFlag;
		if( GetOriginalTeamIfMindControlled && Unit.IsMindControlled() )
		{
			TeamFlag = Unit.GetPreviousTeam();
		}
		switch( TeamFlag )
		{
		case eTeam_XCom:
			OutputLinks[0].bHasImpulse = true;
			break;
		case eTeam_Alien:
			OutputLinks[1].bHasImpulse = true;
			break;
		case eTeam_Neutral:
			OutputLinks[2].bHasImpulse = true;
			break;
		}
	}
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Get Unit Team"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=false
	OutputLinks(0)=(LinkDesc="XCom")
	OutputLinks(1)=(LinkDesc="Alien")
	OutputLinks(2)=(LinkDesc="Civilian")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}
