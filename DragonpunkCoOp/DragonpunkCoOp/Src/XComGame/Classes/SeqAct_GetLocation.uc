//-----------------------------------------------------------
//Gets the location of an xcom unit
//-----------------------------------------------------------
class SeqAct_GetLocation extends SequenceAction;

var Vector Location;
var XComGameState_Unit Unit;

event Activated()
{
	local TTile Tile;

	if (Unit != none)
	{
		Tile =  Unit.TileLocation;
		Location = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(Tile);
	}
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Get Unit Location"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=Location,bWriteable=TRUE)
}
