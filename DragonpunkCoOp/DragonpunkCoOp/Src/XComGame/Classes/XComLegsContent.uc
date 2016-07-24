class XComLegsContent extends Actor
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() SkeletalMesh SkeletalMesh;
var() MaterialInterface OverrideMaterial <ToolTip = "Allows a material override to specified for this body part. The material will be assigned to the skeletal mesh when the part is attached">;