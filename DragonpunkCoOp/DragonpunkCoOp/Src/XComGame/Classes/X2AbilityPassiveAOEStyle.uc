class X2AbilityPassiveAOEStyle extends Object
	abstract
	native(Core);

var protected transient XComInstancedMeshActor AOEMeshActor;

function SetupAOEActor(const XComGameState_Ability Ability)
{
	//Don't allow duplicates.
	DestroyAOEActor();

	AOEMeshActor = `BATTLE.spawn(class'XComInstancedMeshActor');
	if (Ability.GetMyTemplate().Hostility == eHostility_Offensive)
		AOEMeshActor.InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile", class'StaticMesh')));
	else
		AOEMeshActor.InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile_Neutral", class'StaticMesh')));
}

function DestroyAOEActor()
{
	if (AOEMeshActor != None)
		AOEMeshActor.Destroy();
}

native function DrawAOETiles(const XComGameState_Ability Ability, const vector Location);
