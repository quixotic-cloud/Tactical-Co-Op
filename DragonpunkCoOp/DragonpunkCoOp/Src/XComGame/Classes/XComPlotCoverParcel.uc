class XComPlotCoverParcel extends Actor
	  placeable
	  native(Core)
	  dependson(XComParcelManager);
	  //hidecategories(Display, Attachment, Collision, Physics, Advanced, Mobile, Debug);

const MAX_PARCEL_ENTRANCES = 8;

var() StaticMeshComponent ParcelMesh; // (visible only in EDITOR).

var() int SizeX;
var() int SizeY;

var() string strPCPType;
var() string strTurnType;

var() int iWidth;
var() int iLength;

var() bool bIsPeriphery;
var() bool bCanBeObjective;
var() array<XComPlotCoverParcel> arrPCPsToBlockOnObjectiveSpawn; // list of PCPs that should be blocked from spawning if this PCP is spawned as the objective.
																 // This allows for special setups such as convoys that need to straddle multiple ground plates.

var() array<string> arrLevelNames; // (only needed for PERIPHERY PCPs)

var string strLevelName;

var array<string> arrRequiredLayers;

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);

	virtual void PostLoad();
}


defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	Begin Object Class=StaticMeshComponent Name=ParcelStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.PCP_Periph'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
	End Object

	ParcelMesh=ParcelStaticMeshComponent;
	Components.Add(ParcelStaticMeshComponent)

	bCollideWhenPlacing=false
	bCollideActors=false
	bStaticCollision=true
	bCanStepUpOn=false
	bEdShouldSnap=true
}