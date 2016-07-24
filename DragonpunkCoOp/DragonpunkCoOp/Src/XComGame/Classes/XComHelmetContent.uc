class XComHelmetContent extends XComBodyPartContent
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() bool bHideUpperFacialProps<ToolTip = "Indicates whether this helmet should hide upper facial props">;
var() bool bHideLowerFacialProps<ToolTip = "Indicates whether this helmet should hide lower facial props">;
var() bool bUseDefaultHead<ToolTip = "Forces the default head onto the character when this helmet is worn">;
var() int  FallbackHairIndex<ToolTip = "If set to -1, indicates that this helmet should hide hair. Other settings request a specific index of fall-back hair as defined in the current selected hair">;

defaultproperties
{	
	FallbackHairIndex = -1
}