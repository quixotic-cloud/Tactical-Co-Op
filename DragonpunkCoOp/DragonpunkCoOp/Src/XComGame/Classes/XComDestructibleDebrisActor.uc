class XComDestructibleDebrisActor extends XComDestructibleActor
	placeable
	native(Destruction);


simulated function ApplyDamageToMe(XComGameState_EnvironmentDamage DamageEvent)
{
	if( WorldInfo.NetMode != NM_Client )
	{
		super.ApplyDamageToMe(DamageEvent);
	}
}

simulated event PostBeginPlay()
{
	local XComBuildingVolume BuildingVolume;
	local Floor CurrentFloor;
	local XComFloorVolume CurrentFloorVolume;
	local FloorActorInfo FAI;
	local int CurrentFloorIdx;
	local int CurrentVolumeIdx;

	super.PostBeginPlay();

	foreach WorldInfo.AllActors(class'XComBuildingVolume', BuildingVolume)
	{
		for( CurrentFloorIdx = 0; CurrentFloorIdx < BuildingVolume.Floors.Length; CurrentFloorIdx++ )
		{
			CurrentFloor = BuildingVolume.Floors[CurrentFloorIdx];
			for( CurrentVolumeIdx = 0; CurrentVolumeIdx < CurrentFloor.FloorVolumes.Length; CurrentVolumeIdx++ )
			{
				CurrentFloorVolume = CurrentFloor.FloorVolumes[CurrentVolumeIdx];

				if( CurrentFloorVolume.IsOverlapping(self) )
				{
					FAI.ResidentActor = self;
					FAI.CutdownFloor = 0;
					BuildingVolume.Floors[CurrentFloorIdx].m_aCachedActors.AddItem(FAI);
					return;
				}
			}
		}
	}
}

defaultproperties
{	
	bNetInitialRotation=true
}
