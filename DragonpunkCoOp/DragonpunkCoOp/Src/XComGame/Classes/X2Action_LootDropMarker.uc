//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_LootDropMarker extends X2Action;

//*************************************
var int	LootDropObjectID;
var bool SetVisible;
var int LootExpirationTurnsRemaining;
var TTile LootLocation;

//*************************************

function Init(const out VisualizationTrack InTrack)
{
}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function UpdateLootDrop()
	{
		local XComLootDropActor LootDropActor;

		LootDropActor = XComLootDropActor(`XCOMHISTORY.GetVisualizer(LootDropObjectID));

		LootDropActor.SetLootMarker(SetVisible, LootExpirationTurnsRemaining, LootLocation);
	}

Begin:
	UpdateLootDrop();

	CompleteAction();
}

defaultproperties
{
	SetVisible=true
	LootExpirationTurnsRemaining=-1
}

