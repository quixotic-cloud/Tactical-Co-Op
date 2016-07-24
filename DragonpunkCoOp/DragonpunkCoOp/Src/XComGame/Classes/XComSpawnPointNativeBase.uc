// needs to be here for some native code to find spawn points

class XComSpawnPointNativeBase extends Actor
	placeable
	native(Level);

static simulated native final function int GetSpawnGroupIndex(int iMapPlayCount);
static simulated native final function FindSpawnGroup(ETeam Team, out array<XComSpawnPointNativeBase> SpawnPoints, optional out name SearchTag, optional int SpawnIndex);

simulated event EUnitType GetUnitType()
{
	return UNIT_TYPE_Player;
}


defaultproperties
{	
	Begin Object Class=SpriteComponent Name=Sprite
	Sprite=Texture2D'EditorResources.S_Player'
	HiddenGame=True
	AlwaysLoadOnClient=False
	AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	bEdShouldSnap=True
}