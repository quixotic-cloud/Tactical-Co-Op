class XComDestructibleSkeletalMeshActor extends XComDestructibleActor
	native(Destruction)
	abstract;

cpptext
{
	// Interface_NavMeshPathObstacle
	virtual UBOOL GetBoundingShape(TArray<FVector>& out_PolyShape);

	virtual void ApplyAOEDamageMaterial();
	virtual void RemoveAOEDamageMaterial();

	virtual UMaterialInterface* GetDefaultAOEMaterial(AXComTacticalGRI* Tactical);
}

simulated native function SetStaticMesh(StaticMesh NewMesh, optional Vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D);

simulated native function SetSkeletalMesh(SkeletalMesh InSkeletalMesh);

defaultproperties
{
	
}