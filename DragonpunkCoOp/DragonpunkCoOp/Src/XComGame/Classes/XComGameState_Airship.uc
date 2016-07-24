//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Airship.uc
//  AUTHOR:  Dan Kaplan  --  10/21/2014
//  PURPOSE: This object represents the base instance data for all flying airships which exist 
//           on the X-Com 2 strategy game map.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Airship extends XComGameState_GeoscapeEntity 
	native(Core)
	abstract;

// The location where this Airship last launched from.
var() Vector2D				  SourceLocation;

// The Geoscape Entity that this Airship is flying towards.
var() StateObjectReference    TargetEntity;

// The total distance the ship will travel during its flight
var() protected float		  TotalFlightDistance;

// The direction the Airship should move in to reach the TargetEntity
var() protected Rotator		  FlightDirection;

// True while this airship needs to update its movement and rotation to simulate flight.
var() protected bool		  CurrentlyInFlight;

// True while the airship is lifting off the ground, before it starts moving
var() public bool			  LiftingOff;

// True while the airship is flying to its destination
var() public bool			  Flying;

// True while the airship is landing, after it has reached its target destination
var() public bool			  Landing;

// Tracking the current roll turbulence value for this airship
var() protected float		  CurrentTurbulenceRoll;

// These are unique for the airship, and do not relate to physics engine simulation since this is not an Actor
var() protected Vector		  Velocity;

// Used to calculate acceleration
var() protected Vector		  OldVelocity; // The velocity the last timestep
var() protected float		  OldDeltaT; // The timestep last update

// The preset acceleration values for the ship
var() config Vector			  Acceleration;

// The height above the geoscape which the Airship will fly at
var() config float			  FlightHeight;

// How does the time scale while the ship is flying
var() config float			  InFlightTimeScale;

// The maximum speed of the ship when it is flying to its destination target, in UU/s
var() config float			  MaxSpeedFlying;

// The maximum speed of the ship when it is lifting off or landing, in UU/s
var() config float			  MaxSpeedVertical;

// The speed at which the ship rotates
var() config float			  RotationSpeed;

// The maximum pitch angle while lifting off or landing
var() config float			  MaxLiftOffLandPitch; 

// The maximum pitch angle while flying
var() config float			  MaxFlightPitch;

// The maximum roll angle while turning in flight
var() config float			  MaxFlightTurnRoll;

// The maximum angle for the amount of roll turbulence the ship will undergo
var() config float			  MaxTurbulenceRoll;

// The radial distance from the target destination which the ship should land at
var() config float			  LandingRadius;


//#############################################################################################
//----------------   FLIGHT STATES   ----------------------------------------------------------
//#############################################################################################

function FlyTo(XComGameState_GeoscapeEntity InTargetEntity, optional bool bInstantCamInterp = false)
{
	local XComGameState NewGameState;
	local XComGameState_Airship NewAirshipState;
	local Vector2D RadialAdjustedTarget;
	
	`assert(InTargetEntity.ObjectID > 0);
	
	if( TargetEntity.ObjectID != InTargetEntity.ObjectID )
	{
		// set new target location - course change!
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Airship Course Change");
		NewAirshipState = XComGameState_Airship(NewGameState.CreateStateObject(Class, ObjectID));

		RadialAdjustedTarget = class'X2StrategyGameRulesetDataStructures'.static.AdjustLocationByRadius(InTargetEntity.Get2DLocation(), LandingRadius);

		NewAirshipState.TargetEntity.ObjectID = InTargetEntity.ObjectID;
		NewAirshipState.SourceLocation = Get2DLocation();
		NewAirshipState.FlightDirection = GetFlightDirection(NewAirshipState.SourceLocation, GetClosestWrappedCoordinate(NewAirshipState.SourceLocation, RadialAdjustedTarget));
		NewAirshipState.TotalFlightDistance = GetDistance(NewAirshipState.SourceLocation, GetClosestWrappedCoordinate(NewAirshipState.SourceLocation, RadialAdjustedTarget));
		NewAirshipState.Velocity = vect(0.0, 0.0, 0.0);
		NewAirshipState.CurrentlyInFlight = true;
		NewAirshipState.LiftingOff = true;
		NewAirshipState.Flying = false;
		NewAirshipState.Landing = false;

		NewGameState.AddStateObject(NewAirshipState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		OnTakeOff(bInstantCamInterp);
	}
	else if( IsFlightComplete() )
	{
		// already at the specified destination entity
		OnLanded();
	}
}

function ProcessFlightBegin()
{
	local XComGameState NewGameState;
	local XComGameState_Airship NewAirshipState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Airship Flight Beginning");
	NewAirshipState = XComGameState_Airship(NewGameState.CreateStateObject(Class, ObjectID));
	NewAirshipState.CurrentlyInFlight = true;
	NewAirshipState.LiftingOff = false;
	NewAirshipState.Flying = true;
	NewAirshipState.Landing = false;
	NewGameState.AddStateObject(NewAirshipState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//This may be called externally to instantly move an airship
function ProcessFlightComplete()
{
	local XComGameState NewGameState;
	local XComGameState_Airship NewAirshipState;
	
	// mark this airship as no longer in flight
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Airship Flight Completed");
	NewAirshipState = XComGameState_Airship(NewGameState.CreateStateObject(Class, ObjectID));
	NewAirshipState.CurrentlyInFlight = false;
	NewAirshipState.LiftingOff = false;
	NewAirshipState.Flying = false;
	NewAirshipState.Landing = false;
	NewAirshipState.CurrentTurbulenceRoll = 0;
	NewGameState.AddStateObject(NewAirshipState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	OnLanded();
}

function OnTakeOff(optional bool bInstantCamInterp = false)
{
	// Should be implemented in subclasses if needed
}

function OnLanded()
{
	// Should be implemented in subclasses if needed
}

//#############################################################################################
//----------------   MOVEMENT UPDATES   ---=---------------------------------------------------
//#############################################################################################

function UpdateMovement(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		if (LiftingOff)
		{
			UpdateMovementLiftOff(fDeltaT);
		}
		else if (Flying)
		{
			`GAME.GetGeoscape().m_fTimeScale = InFlightTimeScale; // Speed up the time scale
			UpdateMovementFly(fDeltaT);
		}
		else if (Landing)
		{
			UpdateMovementLand(fDeltaT);
		}
	}
}

function UpdateMovementLiftOff(float fDeltaT)
{
	local float DistanceRemaining;

	DistanceRemaining = FlightHeight - Location.Z;

	if (DistanceRemaining < 0.001)
	{
		ProcessFlightBegin();
	}
	else //Otherwise continuing lifting off
	{
		if (DistanceRemaining <= GetDistanceNeededToDecelerate(Velocity.Z, Acceleration.Z)) //Start decelerating after passing the threshold
		{
			Velocity.Z -= Acceleration.Z * fDeltaT;
		}
		else if (Velocity.Z < MaxSpeedVertical) //Otherwise accelerate up to the max lift off speed
		{
			Velocity.Z += Acceleration.Z * fDeltaT;
		}

		//Advance our location in the direction towards the target
		Location.Z += Velocity.Z * fDeltaT;
	}
}

function UpdateMovementFly(float fDeltaT)
{	
	local Vector DirectionVector;
	local float DistanceRemaining, Speed;
		
	DirectionVector = -1.0 * Vector(FlightDirection); //Multiplying by -1.0 since the conversion from FlightDirection Rotator to Vector gives the opposite of what we need
	DistanceRemaining = TotalFlightDistance - GetDistance(Get2DLocation(), SourceLocation);
	Speed = VSize2D(Velocity);
			
	//If we have traveled farther than our intended distance, we have reached our target so stop and land
	if (DistanceRemaining < 0.001)
	{
		TransitionFlightToLand();
	}
	else //Otherwise move towards the target
	{		
		if (DistanceRemaining <= GetDistanceNeededToDecelerate(Speed, VSize2D(Acceleration))) //Start decelerating after passing the threshold
		{
			Velocity.X -= Acceleration.X * fDeltaT;
			Velocity.Y -= Acceleration.Y * fDeltaT;
		}		
		else if (Speed < MaxSpeedFlying) //Otherwise accelerate up to the max flying speed
		{
			Velocity.X += Acceleration.X * fDeltaT;
			Velocity.Y += Acceleration.Y * fDeltaT;
		}

		//Advance our location in the direction towards the target
		Location.X += DirectionVector.X * Velocity.X * fDeltaT;
		Location.Y += DirectionVector.Y * Velocity.Y * fDeltaT;
	}
}

function TransitionFlightToLand()
{
	`GAME.GetGeoscape().m_fTimeScale = `GAME.GetGeoscape().ONE_MINUTE; // Slow down the time scale for landing
	Flying = false;
	Landing = true; // start landing
}

function UpdateMovementLand(float fDeltaT)
{
	if (Location.Z < 0.001)
	{
		ProcessFlightComplete();
	}
	else //Otherwise continuing lifting off
	{
		if (Location.Z <= GetDistanceNeededToDecelerate(Velocity.Z, Acceleration.Z)) //Start decelerating after passing the threshold
		{
			Velocity.Z -= Acceleration.Z * fDeltaT;
		}
		else if (Velocity.Z < MaxSpeedVertical) //Otherwise accelerate up to the max landing speed
		{
			Velocity.Z += Acceleration.Z * fDeltaT;
		}

		//Advance our location towards the ground
		Location.Z -= Velocity.Z * fDeltaT;
	}
}

//#############################################################################################
//----------------   ROTATION UPDATES   ---=---------------------------------------------------
//#############################################################################################

function UpdateRotation(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		if (LiftingOff)
		{
			UpdateRotationLiftOff(fDeltaT);
		}
		else if (Flying)
		{
			UpdateRotationFly(fDeltaT);
		}
		else if (Landing)
		{
			UpdateRotationLand(fDeltaT);
		}
	}
}

function UpdateRotationLiftOff(float fDeltaT)
{
	local Rotator TargetRotation;
	local float LiftOffPercentComplete;

	TargetRotation = Rotation; //stay facing the same direction when lifting off
		
	//The avenger should tilt backwards as it lifts off since it has such heavy jets up front
	LiftOffPercentComplete = Location.Z / FlightHeight;
	if (LiftOffPercentComplete <= 0.5)
	{
		TargetRotation.Roll = UpdateTurbulence(CurrentTurbulenceRoll, Rotation.Roll, MaxTurbulenceRoll, 0.025, 5) * (LiftOffPercentComplete * 2.0);
		TargetRotation.Pitch = MaxLiftOffLandPitch * DegToUnrRot * (LiftOffPercentComplete * 2.0);
	}
	else
	{
		TargetRotation.Roll = UpdateTurbulence(CurrentTurbulenceRoll, Rotation.Roll, MaxTurbulenceRoll, 0.025, 5);
		TargetRotation.Pitch = MaxLiftOffLandPitch * DegToUnrRot * (1.0 - ((LiftOffPercentComplete - 0.5) * 2.0));
	}	
		
	Rotation = RInterpTo(Rotation, TargetRotation, fDeltaT, RotationSpeed * 2.0);
}

function UpdateRotationFly(float fDeltaT)
{
	local Rotator TargetRotation;
	local float AngleToTarget;

	TargetRotation = FlightDirection; //face towards our target
	
	AngleToTarget = (TargetRotation.Yaw - Rotation.Yaw) * UnrRotToDeg;
	if (Abs(AngleToTarget) < 30)
	{
		TargetRotation.Roll = 0;
	}
	else if (AngleToTarget > 0)
	{
		TargetRotation.Roll = MaxFlightTurnRoll * DegToUnrRot;
	}
	else
	{
		TargetRotation.Roll = -1 * MaxFlightTurnRoll * DegToUnrRot;
	}
	
	//Provide some random extra roll variations while flying
	TargetRotation.Roll += UpdateTurbulence(CurrentTurbulenceRoll, Rotation.Roll, MaxTurbulenceRoll, 0.075, 5);

	//Pitch at each timestep = MaxPitchAngle * (Speed / MaxSpeed) so when flying at max speed pitch angle will be full
	TargetRotation.Pitch = MaxFlightPitch * (VSize2D(Velocity) / MaxSpeedFlying) * DegToUnrRot;
			
	Rotation = RInterpTo(Rotation, TargetRotation, fDeltaT, RotationSpeed);
}

function UpdateRotationLand(float fDeltaT)
{
	local Rotator TargetRotation;
	local float LandingPercentComplete;

	TargetRotation = FlightDirection; //stay facing the same direction as our flight path when landing	
	
	//The avenger should tilt backwards as it lands since it has such heavy jets up front
	LandingPercentComplete = 1.0 - Location.Z / FlightHeight;
	if (LandingPercentComplete <= 0.5)
	{
		TargetRotation.Roll = UpdateTurbulence(CurrentTurbulenceRoll, Rotation.Roll, MaxTurbulenceRoll, 0.025, 5) * (LandingPercentComplete * 2.0);
		TargetRotation.Pitch = MaxLiftOffLandPitch * DegToUnrRot * (LandingPercentComplete * 2.0);
	}
	else
	{
		//start fading pitch and roll to 0 as approaching the ground
		TargetRotation.Roll = UpdateTurbulence(CurrentTurbulenceRoll, Rotation.Roll, MaxTurbulenceRoll, 0.025, 5) * (1.0 - ((LandingPercentComplete - 0.5) * 2.0));
		TargetRotation.Pitch = MaxLiftOffLandPitch * DegToUnrRot * (1.0 - ((LandingPercentComplete - 0.5) * 2.0));
	}

	Rotation = RInterpTo(Rotation, TargetRotation, fDeltaT, RotationSpeed * 2.0);
}

//#############################################################################################
//----------------   HELPER FUNCTIONS   -------------------------------------------------------
//#############################################################################################

final function bool IsFlightComplete()
{
	return !IsCurrentlyInFlight();
}

final function bool IsCurrentlyInFlight()
{
	return CurrentlyInFlight;
}

final function Rotator GetFlightDirection(Vector2D From, Vector2D To)
{
	local Vector2D FlightVector2D;
	local Vector FlightVector;

	FlightVector2D = From - To;
	FlightVector.X = FlightVector2D.X;
	FlightVector.Y = FlightVector2D.Y;

	return Rotator(Normal(FlightVector));
}

final function float GetDistance(Vector2D From, Vector2D To)
{
	local Vector2D FlightVector2D;

	FlightVector2D = From - To;

	return V2DSize(FlightVector2D);
}

final function Vector GetAnimNodeVelocity()
{
	local Vector AnimVelocity;
	
	// Based on Stewie's animation tree for Aircraft
	// X should be a % of max turning angle, -1 to 1 (will do a slight pitch of the ship and tilt engines)
	// Y should be a % of max speed, -1 to 1 (will pitch slightly and tilt the engines in the appropriate direction)
	
	AnimVelocity.X = (Rotation.Roll * UnrRotToDeg) / MaxFlightTurnRoll;
	AnimVelocity.Y = VSize2D(Velocity) / MaxSpeedFlying;

	return AnimVelocity;
}

final function Vector GetAnimNodeAcceleration()
{
	local Vector CalcAcceleration;

	// Based on Stewie's animation tree for Aircraft
	// X should be a % of max turning angle (will roll the whole body of the ship)
	// Y should be a % of max speed (will pitch the whole body of the ship)
	 
	// NOT USED RIGHT NOW: Effect feels too dramatic and causes glitchy behavior. Needs better values for inputs.

	if (OldDeltaT > 0)
	{
		CalcAcceleration = (Velocity - OldVelocity) / OldDeltaT;

		CalcAcceleration.X /= Acceleration.X; // Return acceleration as a percentage of the maximum
		CalcAcceleration.Y /= Acceleration.Y;
	}
	else
	{
		CalcAcceleration = vect(0.0, 0.0, 0.0);
	}

	return CalcAcceleration;
}

function float GetDistanceNeededToDecelerate(float Speed, float Deceleration)
{
	local float TimeNeededToDecelerate, DistanceNeededToDecelerate;

	//Use kinematic equations to calculate the distance where the ship should start decelerating based on current speed.
	TimeNeededToDecelerate = Speed / Deceleration; //From Vf = Vi + a * t, where Vf = 0.0
	DistanceNeededToDecelerate = Speed * TimeNeededToDecelerate - 0.5 * Deceleration * TimeNeededToDecelerate * TimeNeededToDecelerate; //From D = Vi*t + 0.5 * a * t^2

	return DistanceNeededToDecelerate;
}

function float UpdateTurbulence(out float CurrentTurbulence, float CurrentAngle, float MaxTurbulenceAngle, float PercentChance, float AcceptanceThreshold)
{
	local float RandomCheck;

	//If no current turbulence set, get a random number and if within percentages set a new value
	if (CurrentTurbulence == 0)
	{
		RandomCheck = `SYNC_FRAND();

		//The percentage chance is actually the individual chance to go positive or negative
		if (RandomCheck > (1.0 - PercentChance))
		{
			CurrentTurbulence = MaxTurbulenceAngle * DegToUnrRot;
		}
		else if (RandomCheck < PercentChance)
		{
			CurrentTurbulence = -1.0 * MaxTurbulenceAngle * DegToUnrRot;
		}
	}
	else //Turbulence value has been set
	{
		//When we have almost reached the target angle, set to 0 to start moving back the other direction
		if ((Abs(CurrentAngle - CurrentTurbulence) * UnrRotToDeg) < (MaxTurbulenceAngle - AcceptanceThreshold))
		{
			CurrentTurbulence = 0.0;
		}
	}

	return CurrentTurbulence;
}

DefaultProperties
{
}
