//-----------------------------------------------------------
//Gets a unit in an encounter group
//-----------------------------------------------------------
class SeqAct_GetEncounterUnit extends SequenceAction;

var XComGameState_Unit Unit;
var Name EncounterID;
var int UnitIndex;

private function ShowRedscreen(string Message)
{
	local string FullObjectName;

	FullObjectName = PathName(self);
	`Redscreen(FullObjectName $ ":\n " $ Message $ "\n Show this to the LDs! David B. added the assert.");
}

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
	{
		if (GroupState.EncounterID == EncounterID)
		{
			if (UnitIndex >= GroupState.m_arrMembers.Length)
			{
				ShowRedscreen("Unit Index is out of range!");

			}
			else
			{
				Unit = XComGameState_Unit(History.GetGameStateForObjectID(GroupState.m_arrMembers[UnitIndex].ObjectID));
				if (Unit == none)
				{
					ShowRedscreen("Could not find unit state for object ID " $ GroupState.m_arrMembers[UnitIndex].ObjectID);
				}
			}

			return;
		}
	}

	ShowRedscreen("Could not find AI encounter!");
	Unit = none;
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Get Encounter Unit"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit, bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Name',LinkDesc="EncounterID",PropertyName=EncounterID)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="Unit Index",PropertyName=UnitIndex)
}
