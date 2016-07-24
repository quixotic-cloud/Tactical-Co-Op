class XComDamageVolume extends Volume
	placeable
	native;

simulated event PreBeginPlay()
{		
	if(self.CollisionType != COLLIDE_NoCollision)
	{
		UpdateWorldData(true);
	}
	else
	{
		UpdateWorldData(false);
	}
}

native simulated function UpdateWorldData(bool bSetFire);


DefaultProperties
{
	bColored=true
	BrushColor=(R=255,G=255,B=20,A=255)
}