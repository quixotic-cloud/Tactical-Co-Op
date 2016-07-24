class XComCoverSeed extends Actor
	native(Cover)
	hidecategories(Object,Display,Attachment,Actor,Collision,Physics,Advanced,Mobile)
	placeable;

var() bool bDiagonalCover;

var() const editconst StaticMeshComponent TileBoxComponent;

cpptext
{
#if WITH_EDITOR
	virtual void PostEditMove(UBOOL bFinished);
#endif
}

defaultproperties
{
	begin object class=StaticMeshComponent name=TileBoxComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.TileBox'
		HiddenGame=true
		HiddenEditor=false
	end object
	Components.Add(TileBoxComponent0);
	TileBoxComponent=TileBoxComponent0;
	CollisionComponent=TileBoxComponent0;
}
