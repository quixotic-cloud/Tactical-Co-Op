/**
 * Checks if a unit is in the given volume
 */
class SeqAct_GetExtractionVolume extends SequenceAction;

var XComBuildingVolume ExtractionVolume;

event Activated()
{
	local XComTacticalGRI kTacticalGRI;

	kTacticalGRI = `TACTICALGRI;
	
	foreach kTacticalGRI.AllActors(class'XComBuildingVolume', ExtractionVolume)
	{
		if(ExtractionVolume.IsDropShip)
		{
			return;
		}
	}

	ExtractionVolume = none; // didn't find an extraction volume
}

defaultproperties
{
	ObjName="Get Extraction Volume"
	ObjCategory="Level"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="ExtractionVolume",PropertyName=ExtractionVolume,bWriteable=TRUE)
}
