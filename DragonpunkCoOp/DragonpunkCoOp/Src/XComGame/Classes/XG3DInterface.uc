//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XG3DInterface extends Actor;

simulated function DrawSound( Vector vSoundStart, vector vSoundEnd )
{
}

simulated function DrawRange( vector vCenter, float fRadius, LinearColor clrRange )
{
	local Vector vCenterTop;

	vCenterTop = vCenter;
	vCenterTop.Z += 1;

	`SHAPEMGR.DrawCylinder( vCenter, vCenterTop, fRadius, clrRange );
}
/*
simulated function DrawAimingCone( XGShot kShot )
{
	local TAimCone kCone;
	local Vector vStart, vTarget, vDir;
	local float fTheta;

	vStart = kShot.m_kShooter.GetLocation();
	vStart.Z = Max( 5, vStart.z - 128 );
	vTarget = kShot.m_vTarget;
	if( kShot.m_kTarget != none )
		vTarget.Z -= 128;
	vTarget.Z = Max( 10, vTarget.z );
	vDir = Normal(vTarget - vStart);
	
	kCone = kShot.BuildAimCone();

	fTheta = DegToRad * kCone.fAngle;      // Angle of the cones

	`SHAPEMGR.DrawMultiCone( vStart, vStart + vDir*kCone.fDist, fTheta, kCone.afTransitions, kCone.aColors, true, 0.01f );
}*/

simulated function DrawControlCone( Vector vStart, vector vDir, float fDist, float fAngle, LinearColor kColor )
{
	vStart.Z = 10;//Max( 1, vStart.z - 64 );
	vDir.Z = 0;
	`SHAPEMGR.DrawCone( vStart, vStart + vDir*fDist, DegToRad * fAngle, kColor, 0.01f, false, true );
}

simulated function DrawPinningCone( Vector vStart, XGUnit kPinnedUnit, LinearColor kColor )
{
	local Vector vEnd;

	vEnd = kPinnedUnit.GetLocation();

	vStart.Z = 10;
	vEnd.Z = 10;

	//vDir = Normal( vEnd - vStart );
	
	`SHAPEMGR.DrawCone( vStart, vEnd, DegToRad * 15, kColor, 0.01f, false, true );
}

simulated function DrawExplosiveRange( Vector vTarget, XGWeapon kWeapon, int iAddedTime )
{
}

DefaultProperties
{
}
