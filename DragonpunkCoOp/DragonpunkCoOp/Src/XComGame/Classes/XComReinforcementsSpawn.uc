class XComReinforcementsSpawn extends Actor
	  placeable;

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

	Begin Object Class=StaticMeshComponent Name=RadiusStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.EditorRadiusSphere'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=64,G=0,B=64,A=255)
		LightEnvironment=MyLightEnvironment
	End Object

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.reinforcements_spawn'
		HiddenGame=True
	End Object

	Components.Add(RadiusStaticMeshComponent)
	Components.Add(Sprite);

	bEdShouldSnap=true

	Layer=Markup

	DrawScale3D=(X=8.0,Y=8.0,Z=2.0)
	DrawScale=0.5
}