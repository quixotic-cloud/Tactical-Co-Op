//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_GremlinFlyToPlayAnim extends X2Action;

//Cached info for performing the action
//*************************************
var CustomAnimParams            Params;
var XComUnitPawn				TargetPawn;

var XComGameStateContext_Ability AbilityContext;
var vector                      OriginalHeading;
var vector                      ToTargetActor;

var XComAnimatedWeapon			GremlinWeapon;
var vector						GremlinDesiredLocation;
var Rotator						GremlinDesiredRotation;
var vector						GremlinStartingLocation;
var Rotator						GremlinStartingRotation;
var float						GremlinMoveDuration;
var float						GremlinMovePercent;
var float						GremlinMoveTime;
var Vector						GremlinLocationOffset;
var Rotator						GremlinRotationOffset;
var vector						GremlinPreviousLocation;
var float						GremlinDistanceFromDestinationSquared;
var const float					GremlinSettleDistance;
var Name						GremlinAnimName;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;	
	local XComGameState_Unit UnitState;

	super.Init(InTrack);
	
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	`assert(UnitState != none);

	OriginalHeading = vector(UnitPawn.Rotation);
	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		TargetPawn = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID).GetVisualizer()).GetPawn();

		ToTargetActor = TargetPawn.Location - UnitPawn.Location;
		ToTargetActor.Z = 0;
		ToTargetActor = Normal(ToTargetActor);
	}

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		GremlinWeapon = XComAnimatedWeapon(XGWeapon(History.GetVisualizer(AbilityContext.InputContext.ItemObject.ObjectID)).m_kEntity);
	}

	assert(GremlinWeapon != None);
}

function SetGremlinAnim(Name AnimName)
{
	GremlinAnimName = AnimName;
}

function PrepareGremlinMoveVaraiables()
{
	// Make sure we are our own person with our desired location
	GremlinLocationOffset = GremlinWeapon.Location;
	GremlinRotationOffset = GremlinWeapon.Rotation;

	GremlinWeapon.AttachComponent(GremlinWeapon.Mesh);
	GremlinWeapon.SetLocation(GremlinDesiredLocation + GremlinLocationOffset);
	GremlinWeapon.SetRotation(GremlinDesiredRotation + GremlinRotationOffset);
	GremlinWeapon.SetHidden(false);

	// Now setup the variables to go from our currecnt desiredlocation to our new desired location
	GremlinStartingLocation = GremlinWeapon.Location;
	GremlinStartingRotation = GremlinWeapon.Rotation;
	GremlinPreviousLocation = GremlinWeapon.Location;
	GremlinMoveTime = 0.f;
	GremlinMoveDuration = 5.0f * GetDelayModifier(); // 5 Seconds of travel time
	GremlinMovePercent = 0.f;
}


//------------------------------------------------------------------------------------------------
simulated state Executing
{
	event Tick(float DeltaTime)
	{
		GremlinMoveTime += DeltaTime;
		GremlinMovePercent = FClamp(GremlinMoveTime / GremlinMoveDuration, 0.0f, 1.0f);
	}

Begin:

	Unit.IdleStateMachine.ForceHeading(ToTargetActor);
	while(Unit.IdleStateMachine.IsEvaluatingStance())
	{
		Sleep(0.0f);
	}

	Params.AnimName = 'HL_SendGremlin';
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	UnitPawn.m_kGameUnit.IdleStateMachine.PlayIdleAnim();
	
 	///////////////////////////////////////////////////////////////////////////////////////////////////
 	// Begin Gremlin anims
 	Params.AnimName = GremlinAnimName;
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	FinishAnim(GremlinWeapon.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	// Once the gremlin is finished playing its animation follow the unit's animation
	TargetPawn.GetAnimTreeController().AttachChildController(GremlinWeapon.GetAnimTreeController());
 	////////////////////////////////////////////////////////////////////////////////////////////////////
	
	Unit.IdleStateMachine.ForceHeading(OriginalHeading);
	while(Unit.IdleStateMachine.IsEvaluatingStance())
	{
		Sleep(0.0f);
	}

	CompleteAction();
}

defaultproperties
{
	GremlinSettleDistance = 192.0f;
}

