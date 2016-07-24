class XComBodyContent extends Actor
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() SkeletalMesh SkeletalMesh;
var deprecated EGender      Gender;
var() array<MaterialInterface> Materials;
var deprecated Texture2D    ColorPalette;
var() EColorPalette ShirtPalette;
var() EColorPalette PantsPalette;

defaultproperties
{
}
