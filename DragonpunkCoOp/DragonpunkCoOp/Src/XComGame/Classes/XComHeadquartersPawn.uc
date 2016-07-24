//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersPawn extends Pawn;

function DropToGround();

defaultproperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius=+040.000000
		CollisionHeight=+0015.000000
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder

	bCollideActors=false
	bBlockActors=false
	bCollideWorld=false
	bProjTarget=false

    Health=10000000
	HealthMax=10000000

	AccelRate=16000.0f
	AirSpeed=3600.0f
	GroundSpeed=600.0f
}
