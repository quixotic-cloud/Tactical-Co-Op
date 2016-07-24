//-----------------------------------------------------------
// Script access to a player's sceneview
//-----------------------------------------------------------
class ScriptSceneView extends Component
	native(Graphics);

var protected transient const native Matrix				ProjectionMatrix, ViewMatrix;
var transient const native float				X, Y, SizeX, SizeY;
var transient const native float              RenderTargetSizeX, RenderTargetSizeY;
var transient const native float              BackBufferSizeX, BackBufferSizeY;

cpptext
{
	void				UpdateFromSceneView( FSceneView* SceneView );
}

final native function GetWorldOrientationForScreenPoint( vector2d ScreenPoint, optional out vector WorldLocation, optional out vector WorldDirection );
final native function GetWorldOrientationForPixelPoint( vector2d PixelPoint, optional out vector WorldLocation, optional out vector WorldDirection );

final native function vector GetScreenPointForWorldLocation( vector WorldLocation, optional float fYPlaneOffest = 0.0f  );
final native function vector GetPixelPointForWorldLocation( vector WorldLocation);

final native function TestUpdateViewMatrix( vector Location, rotator Rotation );

final function Vector2D GetSceneResolution()
{
	local Vector2D res;
	
	res.X = SizeX;
	res.Y = SizeY;

	return res;
}

final function vector GetScreenEdge( vector ScreenSpacePoint )
{
	local vector ScreenSpaceDir;
	local vector ScreenEdge;
	
	// convert to a direction
	ScreenSpaceDir = Normal(ScreenSpacePoint * vect(1,1,0));
	
	// decide if we're going to intersect with the top/bottom edges or
	// with the left/right edges
	if ( Abs(Slope(ScreenSpaceDir.X,ScreenSpaceDir.Y)) > 1 )
	{
		// get top or bottom edge
		if( ScreenSpaceDir.Y == 0 )
			ScreenEdge = vect( 0, 0, 0 );
		else
			ScreenEdge = ScreenSpaceDir * 1.0f / Abs(ScreenSpaceDir.Y);
	}
	else
	{
        // get left or right edge
        if( ScreenSpaceDir.X == 0 )
			ScreenEdge = vect( 0, 0, 0 );
		else
			ScreenEdge = ScreenSpaceDir * 1.0f / Abs(ScreenSpaceDir.X);
	}
	
	return ScreenEdge;
}

final function float Slope( float InX, float InY )
{
	if ( InX == 0 )
		return 10000000;

	return InY / InX;
}

DefaultProperties
{

}
