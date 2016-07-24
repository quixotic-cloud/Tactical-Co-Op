/**
 * A wait condition that requires the cursor be at a specific location.
 */
class XComWaitCondtion_MovementCursorPos extends XComWaitCondition_DistanceCheck;

function Actor GetActor()
{
	local PlayerController Controller;

	if (Locator != none)
	{
		// In XCom there should only ever be one local player controller
		Controller = Locator.GetALocalPlayerController();
	}

	return (Controller != none)? Controller.Pawn : none;
}

function String GetActorName()
{
	return "Movement Cursor";
}

DefaultProperties
{
	ObjName="Wait for Movement Cursor Position"
}
