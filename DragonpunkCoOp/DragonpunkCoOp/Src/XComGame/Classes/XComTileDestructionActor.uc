/**
 * XComTileDestructionActor
 * Author: Scott Boeckmann
 * Description: Actor used to indicate tiles that need to be destroyed on tactical start.
 */
class XComTileDestructionActor extends XComTileDestructionActorInterface
	native;

var array<vector> PositionsToDestroy;


var const transient StaticMesh SelectedMesh;
var transient InstancedStaticMeshComponent TileVisualComponent;

var transient Material TileMaterial;

cpptext
{
	virtual void PostLoad();

	virtual void AddTile(const FVector& Position);
	virtual void RemoveTile(const FVector& Position);

	virtual void SetCompHidden(UBOOL bNewHidden)
	{
		if (TileVisualComponent)
		{
			TileVisualComponent->SetHiddenEditor(bNewHidden);
		}
	}

	virtual void UpdateTileVisuals();

	static void TriggerDestruction();

	virtual INT GetNumOfDestructionTiles() { return PositionsToDestroy.Num(); }
	TArray<FTTile> GatherDestructionTiles();
}

defaultproperties
{
	bStatic=true
	bMovable=false

	TileMaterial = Material'EngineDebugMaterials.LevelColorationLitMaterial'

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedComponent0
		CastShadow = false
		BlockNonZeroExtent = false
		BlockZeroExtent = false
		BlockActors = false
		CollideActors = false
		StaticMesh = StaticMesh'SimpleShapes.ASE_UnitCube'
		HiddenGame = true
		HiddenEditor = true		
	End Object
	TileVisualComponent = InstancedComponent0
	Components.Add(InstancedComponent0)
}