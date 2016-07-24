/**
 * XCom3DCursorMouse
 *
 * 
 * Copyright 2012 Firaxis
 * @owner dburchanowski
 */

class XCom3DCursorMouse extends XCom3DCursor; 

simulated function CursorSearchResult CursorSnapToFloor(int iDesiredFloor, optional CursorSearchDirection eSearchType = eCursorSearch_Down)
{
	local CursorSearchResult kResult;
	
	// the mouse is the honey badger of input devices. It doesn't care, it just does what it wants.
	// so don't bother with snapping, just fill out the current floor bottom value so the camera knows
	// where to go and then let it go to whatever floor it requests.

	m_fLogicalCameraFloorHeight = WorldZFromFloor(m_iRequestedFloor);
	m_fBuildingCutdownHeight = WorldZFromFloor(m_iRequestedFloor + 1);
	m_iLastEffectiveFloorIndex = m_iRequestedFloor;

	kResult.m_kLocation = Location;
	kResult.m_iEffectiveFloor = m_iRequestedFloor;
	kResult.m_fFloorBottom = m_fLogicalCameraFloorHeight;
	kResult.m_fFloorTop = m_fBuildingCutdownHeight;
	kResult.m_bOnGround = true;
	return kResult;
}

state CursorMode_NoCollision
{
	function AscendFloor()
	{
		local CursorSearchResult kResult;

		if(DisableFloorChanges()) return;

		if(Role < ROLE_Authority)
		{
			ServerAscendFloor();
		}

		m_iRequestedFloor = min(m_iRequestedFloor + 1, GetMaxFloor());

		kResult = CursorSnapToFloor(m_iRequestedFloor, eCursorSearch_ExactFloor);
		m_bCursorLaunchedInAir = !kResult.m_bOnGround;

		class'Engine'.static.GetCurrentWorldInfo().WorldCascadeZ = kResult.m_kLocation.Z;
	}


	function DescendFloor()
	{
		local CursorSearchResult kResult;

		if(DisableFloorChanges()) return;

		if(Role < ROLE_Authority)
		{
			ServerDescendFloor();
		}

 		m_iRequestedFloor = max(m_iRequestedFloor - 1, 0);

		kResult = CursorSnapToFloor(m_iRequestedFloor, eCursorSearch_ExactFloor);
		m_bCursorLaunchedInAir = !kResult.m_bOnGround;

		class'Engine'.static.GetCurrentWorldInfo().WorldCascadeZ = kResult.m_kLocation.Z;
	}

	event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
	{
		super.Touch(Other, OtherComp, HitLocation, HitNormal);
	}
	event UnTouch(Actor Other)
	{
		super.UnTouch(Other);
	}
}