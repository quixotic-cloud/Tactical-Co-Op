//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComLocomotionUnitPawn.uc
//  AUTHOR:  Todd Smith  --  11/5/2009
//  PURPOSE: A base class for unit pawns that use our custom, client friendly locomotion.
//           It is to differentiate XComUnitPawn and XComPathingPawns natively so that we
//           can override Pawn behavior for our locomoted pawns (soldiers, sectoids, etc)
//           and not have it affect the PathingPawn yet still have them both derive from
//           the same base class.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComLocomotionUnitPawn extends XComUnitPawnNativeBase
	native(Unit);

cpptext
{
	// unreal interface methods -tsmith  	
	virtual void TickSimulated( FLOAT DeltaSeconds );
	virtual void TickSpecial( float DeltaSeconds );
	virtual void CalcVelocity(FVector &AccelDir, FLOAT DeltaTime, FLOAT MaxSpeed, FLOAT Friction, INT bFluid, INT bBrake, INT bBuoyant);
	virtual void processHitWall(FCheckResult const& Hit, FLOAT TimeSlice=0.f);
	virtual void rotateToward(FVector FocalPoint);
	/** If TRUE, bypass simulated client physics, and run owned/server physics instead. Do not perform simulation/correction. */
	virtual UBOOL ShouldBypassSimulatedClientPhysics();
	virtual void physRMAInteract(FLOAT deltaTime, INT Iterations);
	virtual void physicsRotation(FLOAT deltaTime, FVector OldVelocity);
	virtual void physFlying(FLOAT deltaTime, INT Iterations);
	virtual void physWalking(FLOAT deltaTime, INT Iterations);
	virtual UBOOL IgnoreBlockingBy(const AActor* Other) const;

	// xcom specific methods -tsmith 
	virtual FRotator SetRotationRate(FLOAT deltaTime);
}

//These variable support the 'WeaponDown' nodes in the animation tree. These nodes are an additive blend that lets the unit
//lower their weapon when in an idle with no cover or stationary pose. The purpose for this is to avoid clipping of the weapon
//through obstacles in front of the unit ( such as doors ).
//****************************************
var vector LastLocation_WeaponDownCheck;
var rotator LastRotation_WeaponDownCheck;
//****************************************

/**
 * Called when the local player controller's m_eTeam variable has replicated.
 */
simulated function OnLocalPlayerTeamTypeReceived(ETeam eLocalPlayerTeam)
{
	super.OnLocalPlayerTeamTypeReceived(eLocalPlayerTeam);
	SetVisibleToTeams(m_eTeamVisibilityFlags);
}

defaultproperties
{	
	bRunPhysicsWithNoController=true;

	// network variables -tsmith 
	bReplicateMovement=false;
}