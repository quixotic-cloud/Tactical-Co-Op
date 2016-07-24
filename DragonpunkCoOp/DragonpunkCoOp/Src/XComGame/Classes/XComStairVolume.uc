class XComStairVolume extends Volume
	placeable
	native(Level);

var() const ArrowComponent Arrow;
var vector ArrowDirection;

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation, Vector HitNormal)
{
	local XComUnitPawn Pawn;

	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	
	Pawn = XComUnitPawn(Other);
	if (Pawn != none) 
	{
		Pawn.SetStairVolume(self);
	}
}

simulated event Untouch(Actor Other)
{
	local XComUnitPawn Pawn;

	super.UnTouch(Other);

	Pawn = XComUnitPawn(Other);
	if (Pawn != none) 
	{
		Pawn.SetStairVolume(none);
	}
}

DefaultProperties
{
	Begin Object Class=ArrowComponent Name=AC
		ArrowColor=(R=150,G=100,B=150)
		ArrowSize=5.0
		AbsoluteRotation=true
	End Object
	Components.Add(AC)
	Arrow=AC
}