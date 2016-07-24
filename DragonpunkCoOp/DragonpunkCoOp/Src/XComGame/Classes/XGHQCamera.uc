class XGHQCamera extends Actor;

var protected Actor			m_kTarget;
var protected vector2D		m_v2Target;
var protected vector		m_vSavedTarget;
var protected float			m_fZoomTarget;
var protected bool          m_bVerboseLogging;

simulated function XComHeadquartersCamera Camera()
{
	return XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera);
}

simulated function bool IsBusy()
{
	local bool bBusy;

	bBusy = !IsInState( 'Idle' );

	if( bBusy )
	{
        if( m_bVerboseLogging )
			`log( "Camera is working!!!" );
	}
	else
	{
        if( m_bVerboseLogging )
			`log( "Camera is NOT working!!!" );
	}

	return bBusy;
}

simulated function LookAtEarth( vector2D v2EarthCoords, optional float fZoom, optional bool bCut )
{

	if( IsBusy() )
	{
		if( v2EarthCoords == m_v2Target )
		{
			if( m_bVerboseLogging )
				`log( "Already Trying to LookAt:" @ v2EarthCoords.x @ v2EarthCoords.y );
			return;
		}
		else
		{
            if( m_bVerboseLogging )
				`log( "Abort LookAt of:" @ m_v2Target.x @ m_v2Target.y @ "New LookAt:" @ v2EarthCoords.x @ v2EarthCoords.y );
            PopState();
		}
	}

	if( fZoom != 0 )
		Camera().SetZoom( fZoom );

	if( bCut )
	{	
		//Camera().StartMissionView( v2EarthCoords, bCut );
	}
	else
	{
        m_v2Target = v2EarthCoords;
		PushState( 'LookingAtEarth' );
	}
}

simulated function LookAtHorizon( vector2D v2EarthCoords )
{
	//Camera().StartBriefingView( v2EarthCoords );
}

/*simulated function LookAt( vector vLocation, optional bool bCut )
{
	if( Camera().GetCurrentLookAt() == vLocation )
	{
        if( m_bVerboseLogging )
			`log( "Already LookingAt:" @ vLocation );
		return;
	}

	if( IsBusy() )
	{
		if( vLocation == m_vTarget )
		{
			if( m_bVerboseLogging )
				`log( "Already Trying to LookAt:" @ vLocation );
			return;
		}
		else
		{
            if( m_bVerboseLogging )
				`log( "Abort LookAt of:" @ m_vTarget @ "New LookAt:" @ vLocation );
            PopState();
		}
	}

	if( bCut )
	{
		Camera().LookAt( vLocation, bCut );
	}
	else
	{
        m_vTarget = vLocation;
		PushState( 'LookingAt' );
	}
}

reliable client function LookAtActor( Actor kActor, optional bool bCut )
{
	m_kTarget = kActor;
	LookAt( kActor.Location, bCut );
}*/

// 1.0f is normal game zoom
simulated function Zoom( float fZoom )
{
	Camera().SetZoom( fZoom );
	//m_fZoomTarget = fZoom;
	//PushState( 'Zooming' );
}

auto simulated state Idle
{
	simulated event PausedState()
	{
        if( m_bVerboseLogging )
			`log( "Camera is NOT Idle!" );
		//`GAME.Pause();
	}
	simulated event ContinuedState()
	{
        if( m_bVerboseLogging )
			`log( "Camera is Idle!" );
		//`GAME.Play();
	}
}

//--------------------------LOOK AT----------------------------
/*simulated state LookingAt
{
Begin:
	Camera().LookAt( m_vTarget );

	while( Camera().IsMoving() )
	{
		Sleep( 0.0f );
		if( m_bVerboseLogging )
			`log( "We're Moving to:" @ m_vTarget );
	}

	m_kTarget = none;
	PopState();
}*/

//--------------------------LOOK AT----------------------------
simulated state LookingAtEarth
{
Begin:
	//Camera().StartMissionView( m_v2Target );

	while( Camera().IsMoving() )
	{
		Sleep( 0.0f );
		if( m_bVerboseLogging )
			`log( "We're Moving to:" @ m_v2Target.x @ m_v2Target.y );
	}

	PopState();
}

//--------------------------ZOOM----------------------------
simulated state Zooming
{
Begin:
	Camera().SetZoom( m_fZoomTarget );
	
	while( Camera().IsMoving() )
	{
		Sleep( 0.0f );
		if( m_bVerboseLogging )
			`log( "Were Zooming to:" @ m_fZoomTarget );
	}

	PopState();
}

defaultproperties
{
	m_bVerboseLogging=false;
}
