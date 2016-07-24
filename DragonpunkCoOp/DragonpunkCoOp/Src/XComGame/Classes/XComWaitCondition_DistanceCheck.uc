/**
 * Base class for wait conditions that check for an actor's distance to a location.
 */
class XComWaitCondition_DistanceCheck extends SeqAct_XComWaitCondition
	abstract;

/** The location the Actor should be */
var() Actor Locator;

/** The distance the Actor can be from the Locator */
var() float Radius;

/** Gets the Actor whose  position we're testing */
function Actor GetActor();

/** Gets a user friendly name for the Actor whose position we're testing */
function String GetActorName();

/**
 * @return True if the actor is within the radius of the locator actor.
 */
event bool CheckCondition()
{
	local Actor Actor;
	local float RadiusSquared;
	local float DistSquared;

	Actor = GetActor();
	if (Locator == none || Actor == none)
		return false;

	RadiusSquared = Radius * Radius;
	DistSquared = VSizeSq(Actor.Location - Locator.Location);

	// Return true if DistSquared <= RadiusSquared.
	// I'm using ~= here to deal with floating point error.
	return DistSquared < RadiusSquared || DistSquared ~= RadiusSquared;
}

event string GetConditionDesc()
{
	local String ActorNameString;
	local String LocatorNameString;

	ActorNameString = GetActorName();

	if (Locator != none)
		LocatorNameString = String(Locator.Name);
	else
		LocatorNameString = "Locator";

	if (bNot)
		return ActorNameString $ " is not at " $ LocatorNameString;
	else
		return ActorNameString $ " is at " $ LocatorNameString;
}

DefaultProperties
{
	Radius=96 // This was chosen because it is the XCom grid size

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Locator", PropertyName=Locator)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Float', LinkDesc="Radius", PropertyName=Radius)
}
