/**
 * A wait condition that requires an actor be at a specific location.
 */
class XComWaitCondition_ActorPos extends XComWaitCondition_DistanceCheck;

/** The Actor whose position we're testing */
var() Actor Actor;

/** The name used to look up the Actor if none is provided. */
var() Name ActorName;

function Actor GetActor()
{
	if (Actor == none && Locator != none)
		Locator.FindActorByName(ActorName, Actor);

	return Actor;
}

function String GetActorName()
{
	if (Actor != none)
		return String(Actor.Name);
	else if (ActorName != '')
		return String(ActorName);
	else
		return "Actor";
}

DefaultProperties
{
	ObjName="Wait for Actor Position"
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Actor", PropertyName=Actor)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object', LinkDesc="Locator", PropertyName=Locator)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Float', LinkDesc="Radius", PropertyName=Radius)
}
