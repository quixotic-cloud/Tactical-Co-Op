class XComMegaBuildingVolume extends XComBuildingVolume
	native(Level)
	dependson(XComModularBuildingVolume)
	placeable;

native function InitInLevelNative(out array<XComModularBuildingVolume> kInternalVolumes);

simulated function InitInLevel()
{
	local XComModularBuildingVolume kVolume;
	local array<XComModularBuildingVolume> kInternalVolumes;

	foreach WorldInfo.AllActors(class 'XComModularBuildingVolume', kVolume)
	{
		if (kVolume != none)
		{
			if (Encompasses(kVolume))
			{
				kInternalVolumes.AddItem(kVolume);
			}
		}
	}

	if (kInternalVolumes.Length == 0)
		return;

	InitInLevelNative(kInternalVolumes);
}

defaultproperties
{
	BrushColor = (R = 128, G = 0, B = 0, A = 255)
}