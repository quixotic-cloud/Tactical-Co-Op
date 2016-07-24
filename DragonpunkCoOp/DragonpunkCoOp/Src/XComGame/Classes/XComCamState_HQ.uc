//-----------------------------------------------------------
// Base class for headquarters camera state classes
//-----------------------------------------------------------
class XComCamState_HQ extends XComCameraState
	abstract;

var() float						ViewDistance;

DefaultProperties
{
	ViewDistance=2300.0f
}
