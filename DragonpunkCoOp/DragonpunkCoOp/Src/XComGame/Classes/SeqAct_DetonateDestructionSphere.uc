//-----------------------------------------------------------
//Gets the location of an xcom unit
//-----------------------------------------------------------
class SeqAct_DetonateDestructionSphere extends SequenceAction;

var() XComDestructionSphere DestructionSphereActor;
var() Vector DestructionSphereLocation;

event Activated()
{
	if (DestructionSphereActor == none)
	{
		// user didn't give us a destruction sphere, so find one based on location
		GetDestructionSphereByLocation();
	}

	if(DestructionSphereActor != none)
	{
		// we have a valid actor, explodify it
		DestructionSphereActor.Explode();
	}
}

// gets the closest sphere to the desired location, within a certain threshhold
function GetDestructionSphereByLocation()
{
	local XComDestructionSphere SphereActor;
	local float DistanceSq;
	local float BestDistanceSq;

	BestDistanceSq = class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_StepSize * 9; // 3 tiles max distance (3x3 = 9)
	foreach `BATTLE.AllActors(class'XComDestructionSphere', SphereActor)
	{
		DistanceSq = VSizeSq(SphereActor.Location - DestructionSphereLocation);
		if(DistanceSq < BestDistanceSq)
		{
			BestDistanceSq = DistanceSq;
			DestructionSphereActor = SphereActor;
		}
	}
}

defaultproperties
{
	ObjCategory="Destruction"
	ObjName="Detonate Destruction Sphere"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Actor",PropertyName=DestructionSphereActor)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=DestructionSphereLocation)
}
