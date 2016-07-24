/*     Firaxis 3/7/2012
 *	   Author: Jeremy Shopf
 *	   Purpose: An opacity value is calculated in script and passed to a Initially made specifically for the alien shield actors.
 */

class XComOpacityFadeLevelActor extends XComLevelActor
	  placeable;

/** The distance from the actor at which MinOpacity should be used */
var() float m_fFadeStartDistance;
/** The distance from the actor at which an opacity of 1.0 should be used */
var() float m_fFadeStopDistance;
/** The lowest opacity value that should be used, regardless of distance */
var() float m_fMinOpacity;
/** The highest opacity value that should be used, regardless of distance */
var() float m_fMaxOpacity;

/** The generated MIC for updating opacity on a per-actor basis */
var MaterialInstanceConstant m_kMIC;


simulated function PostBeginPlay()
{
	// Create an MIC
	m_kMIC = StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);

	// Set an initial opacity of 1
	m_kMIC.SetScalarParameterValue( 'OpacityParam', 1.0 );
	StaticMeshComponent.SetMaterial(0, m_kMIC);


}

simulated event Tick(float dt)
{
	local float fOpacity;
	local Vector CameraPosition;
	local Vector CameraDist;
	local float  CameraDistLength;

	local XComPlayerController kLocalPC;

	super.Tick(dt);

	// Calculate opacity

	// Get the player controller and camera
	foreach WorldInfo.LocalPlayerControllers( class 'XComPlayerController', kLocalPC )
	{
		if( kLocalPC.Player != none )
		{
			break;
		}
	}

	CameraPosition = kLocalPC.PlayerCamera.ViewTarget.POV.Location;
	CameraDist = CameraPosition - Location;
	CameraDistLength = VSize(CameraDist);

	fOpacity =  FClamp( ( CameraDistLength - m_fFadeStartDistance ) / (m_fFadeStopDistance - m_fFadeStartDistance), m_fMinOpacity, m_fMaxOpacity );

	// Update MIC
	m_kMIC.SetScalarParameterValue( 'OpacityParam', fOpacity );

	// Reenabled tick because the level actor tick will have disabled it
	SetTickIsDisabled(false);
}

defaultproperties
{
	bTickIsDisabled=false
	bWorldGeometry=false
	CollisionType=COLLIDE_TouchAllButWeapons

	m_fFadeStartDistance=2000.0;
	m_fFadeStopDistance=8000.0;
	m_fMinOpacity=0.01;
	m_fMaxOpacity=0.15;
	
}