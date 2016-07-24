class XComTorsoContent extends Actor
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() SkeletalMesh SkeletalMesh;
var() MaterialInterface OverrideMaterial <ToolTip = "Allows a material override to specified for this body part. The material will be assigned to the skeletal mesh when the part is attached">;
var() name AkEventSwitch<ToolTip = "Optional wWise switch to be set on units using this torso content (ie. for alternate foley)">;
var() Array<AnimSet> UnitPawnAnimSets<"Animation Sets to add to the UnitPawn this torso is added to">;
var() Array<XComBodyPartContent> DefaultAttachments<ToolTip = "XComBodyPartContent archetypes in this array will be automatically attached to the character when it is equipped">;
