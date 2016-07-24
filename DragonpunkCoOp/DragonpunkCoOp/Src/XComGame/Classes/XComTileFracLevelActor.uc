class XComTileFracLevelActor extends XComDecoFracLevelActor
		dependson(XComDecoFracLevelActor)
		native(Destruction);

/** This is here just to allow for flexible experimentation. Take out later if not needed. See Steve Jameson */
var() XComDecoFracFXDefinition DecoFXDefinition;

var XComTileFracMeshComponent TileFracMeshComponent; // Cache the ptr

var vector PrimaryAxisWS;
var vector SecondaryAxisWS;

native function BuildDecoInstances();

simulated event PostBeginPlay()
{
	local XComWorldData WorldData;
	if( DecoFXDefinition == none )
	{
		DecoFXDefinition = XComDecoFracFXDefinition(`CONTENT.RequestGameArchetype("FX_Destruction_Fracture_Data.DecoFX_Default"));
	}

	if( DecoMeshes.Length == 0 )
	{
		WorldData = `XWORLD;
		if(WorldData.DefaultFractureActor != none)
		{
			DecoMeshes = XComDecoFracLevelActor(WorldData.DefaultFractureActor).DecoMeshes;
		}
		else
		{
			`RedScreenOnce("XComTileFracLevelActor without any DecoMeshes! Please Fix. (" @ ObjectArchetype @ ")");
		}
	}

	super.PostBeginPlay();
}

cpptext
{
	virtual void  GetNearbyTileFracActors( TArray<AXComTileFracLevelActor*>& NearbyActors );


	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostEditMove(UBOOL bFinished);
	virtual void PostProcessDamage(const FStateObjectReference &Dmg);
	virtual void PreSave();
	void GenerateVisibleInstances();
}

defaultproperties
{
	Begin Object Class=XComTileFracMeshComponent Name=TileFracMeshComponent0
		bUseVertexColorDestruction=true;
	End Object

	PrimaryAxisWS=(X=0.0,Y=0.0,Z=1.0)
	SecondaryAxisWS=(X=-1.0,Y=0.0,Z=0.0)

	Components.Remove(FracturedStaticMeshComponent0);
	FracturedStaticMeshComponent=TileFracMeshComponent0;
	Components.Add(TileFracMeshComponent0);

	CollisionComponent=TileFracMeshComponent0;
	TileFracMeshComponent=TileFracMeshComponent0;
}