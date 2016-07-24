//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ViperGetOverHere extends X2Action_Fire;

//Cached info for the unit performing the action
//*************************************
var private CustomAnimParams Params;
var bool		ProjectileHit;
var XGWeapon	UseWeapon;
var XComWeapon	PreviousWeapon;
var XComUnitPawn FocusUnitPawn;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		UseWeapon = XGWeapon(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ).GetVisualizer());
	}	
}

function bool CheckInterrupted()
{
	return VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt;
}

function NotifyTargetsAbilityApplied()
{
	super.NotifyTargetsAbilityApplied();
	ProjectileHit = true;
}

simulated state Executing
{
	function StartTargetFaceViper()
	{
		local Vector FaceVector;
		
		FocusUnitPawn = XGUnit(PrimaryTarget).GetPawn();

		FaceVector = UnitPawn.Location - FocusUnitPawn.Location;
		FaceVector = Normal(FaceVector);

		FocusUnitPawn.m_kGameUnit.IdleStateMachine.ForceHeading(FaceVector);
	}

Begin:
	PreviousWeapon = XComWeapon(UnitPawn.Weapon);
	UnitPawn.SetCurrentWeapon(XComWeapon(UseWeapon.m_kEntity));

	Unit.CurrentFireAction = self;
	Params.AnimName = 'NO_StrangleStart';
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	//Make the target face us
	StartTargetFaceViper();
	Sleep(0.1f);

	//Wait for our turn to complete so that we are facing mostly the right direction when the target's RMA animation starts
	while(FocusUnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance())
	{
		Sleep(0.01f);
	}

	while (!ProjectileHit)
	{
		Sleep(0.01f);
	}

	Params.AnimName = 'NO_StrangleStop';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	FocusUnitPawn.m_kGameUnit.IdleStateMachine.CheckForStanceUpdateOnIdle();

	UnitPawn.SetCurrentWeapon(PreviousWeapon);

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return true;
}

DefaultProperties
{
}
