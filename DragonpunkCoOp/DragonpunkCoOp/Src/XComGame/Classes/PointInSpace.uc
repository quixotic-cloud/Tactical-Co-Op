//-----------------------------------------------------------
// Generic placeable actor to define some location and rotation
//-----------------------------------------------------------
class PointInSpace extends Actor
	placeable
	native;

var() SpriteComponent VisualizeSprite;
var() ArrowComponent VisualizeArrow;

var transient vector Forward;
var transient vector Right;
var transient vector Up;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	GetAxes( Rotation, Forward, Right, Up );
}

DefaultProperties
{
 	Begin Object Class=SpriteComponent NAME=Sprite
		Sprite=Texture2D'EditorResources.S_Alarm'
		HiddenGame=true
		HiddenEditor=false
	End Object
	Components.Add(Sprite)
	VisualizeSprite=Sprite;

	Begin Object Class=ArrowComponent Name=Arrow
		ArrowColor=(R=192,G=64,B=64)
		Translation=(X=20)
		ArrowSize=2.0
		HiddenGame=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Arrow)
	VisualizeArrow=Arrow

	bStatic=true
	bNoDelete=true
}
