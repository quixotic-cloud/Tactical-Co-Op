class XComAmbientDestructibleActor extends XComDestructibleActor;

var() editinlineuse array<DestructibleActorEvent> AmbientEvents<ToolTip="List of actions to perform until this actor is damaged or destroyed">;

auto simulated state _Pristine
{
	//ignores Tick;

	simulated event BeginState(Name PreviousStateName)
	{
		SetTickIsDisabled(false);
		bCurrentStateRequiresTick=true;
		//TriggerEvents(DamagedEvents);

	}

	simulated function Tick(float DeltaTime)
	{
		//super.Tick();
		TimeInState += DeltaTime;
		TurnsInState = `TACTICALGRI.GetCurrentPlayerTurn() - FirstTurnInState;

		TriggerEvents(AmbientEvents);
		TickEvents(AmbientEvents, DeltaTime);
	}
	
	simulated event EndState(Name PreviousStateName)
	{
		CleanupEvents(AmbientEvents);

	}

}
event PreBeginPlay()
{
	super.PreBeginPlay();
	SetTickIsDisabled(false);
	bCurrentStateRequiresTick=true;
	TriggerEvents(AmbientEvents);
}
simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTickIsDisabled(false);
	bCurrentStateRequiresTick=true;
	TriggerEvents(AmbientEvents);
}

event Spawned()
{
	super.PostBeginPlay();
	SetTickIsDisabled(false);
	bCurrentStateRequiresTick=true;
	TriggerEvents(AmbientEvents);
}

event PostLoad()
{
	super.PostBeginPlay();
	SetTickIsDisabled(false);
	bCurrentStateRequiresTick=true;
	TriggerEvents(AmbientEvents);
}

	

DefaultProperties
{

}
