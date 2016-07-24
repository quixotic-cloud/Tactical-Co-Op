//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_AbilityPerkEnd extends X2Action;

var private XComGameStateContext_Ability EndingAbility;
var private XGUnit TrackUnit;

event bool BlocksAbilityActivation()
{
	return false;
}

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	EndingAbility = XComGameStateContext_Ability(StateChangeContext);
	TrackUnit = XGUnit(Track.TrackActor);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		local int x;
		local XComUnitPawnNativeBase CasterPawn;
		local array<XComPerkContent> Perks;

		CasterPawn = XGUnit( `XCOMHISTORY.GetVisualizer( EndingAbility.InputContext.SourceObject.ObjectID ) ).GetPawn( );

		class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, EndingAbility.InputContext.AbilityTemplateName );
		for (x = 0; x < Perks.Length; ++x)
		{
			Perks[x].OnPerkDeactivation( );
		}

		TrackUnit.CurrentPerkAction = none;
	}

Begin:

	CompleteAction();
}

