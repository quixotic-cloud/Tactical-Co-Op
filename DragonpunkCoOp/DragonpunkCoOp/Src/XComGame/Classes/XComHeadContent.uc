class XComHeadContent extends Actor
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() SkeletalMesh SkeletalMesh;
/** Assign a material to the head that will override the skeletal mesh's material */
var() MaterialInterface HeadMaterial;
/** The anim set containing the additive animation that morphs the reference head for males */
var() AnimSet      AdditiveAnimSet;
/** The additive animation within AdditiveAnimSet that morphs the reference head */
var() name         AdditiveAnim;
var() EColorPalette SkinPalette;
var() EColorPalette EyePalette;

var LinearColor BodyTint;

defaultproperties
{
	
}
