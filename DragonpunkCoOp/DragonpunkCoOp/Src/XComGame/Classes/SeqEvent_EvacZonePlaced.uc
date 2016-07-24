class SeqEvent_EvacZonePlaced extends SeqEvent_GameEventTriggered;

var Vector EvacLocation;

function EventListenerReturn EventTriggered(Object EventData, Object EventSource, XComGameState GameState, Name InEventID)
{
	local XComGameState_EvacZone EvacZone;

	EvacZone = XComGameState_EvacZone(EventSource);

	if(EvacZone == none)
	{
		`Redscreen("The event was changed without updating this class!");
	}
	else
	{
		EvacLocation = `XWORLD.GetPositionFromTileCoordinates(EvacZone.CenterLocation);
		CheckActivate(`BATTLE, none); // the actor isn't used for game state events, so any old actor will do 
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	ObjName="Evac Zone Placed"
	EventID="EvacZonePlaced"

	VariableLinks(0)=(ExpectedType=class'SeqVar_Vector',LinkDesc="EvacLocation",PropertyName=EvacLocation,bWriteable=TRUE)
}