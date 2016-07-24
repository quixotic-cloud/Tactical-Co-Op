class X2Ability_SquadCohesion extends X2Ability 
	config(GameCore);

var name CohesionUnitValue;
var config float COHESION_BASE;
var config float COHESION_TURNS;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.Length = 0;
	//Templates.AddItem(Cohesion());            - deprecated

	return Templates;
}

static function X2AbilityTemplate Cohesion()
{
	local X2AbilityTemplate             Template;
	local X2Condition_UnitProperty      UnitProperty;
	local X2Condition_UnitValue         UnitValue;
	local X2AbilityTrigger_EventListener  EventListener;
	local X2Effect_GrantActionPoints    GrantPoints;
	local X2AbilityCost_ActionPoints    ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Cohesion');

	Template.AbilityToHitCalc = default.DeadEye;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeDead = true;
	UnitProperty.ExcludeFriendlyToSource = false;
	UnitProperty.ExcludeHostileToSource = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue(default.CohesionUnitValue, 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValue);

	Template.AbilityTargetStyle = default.SelfTarget;

	GrantPoints = new class'X2Effect_GrantActionPoints';
	GrantPoints.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	GrantPoints.NumActionPoints = 1;
	GrantPoints.ApplyChanceFn = CohesionCheck;
	Template.AddShooterEffect(GrantPoints);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'ExhaustedActionPoints';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.BuildNewGameStateFn = Cohesion_BuildGameState;
	//NOTE: no visualization

	return Template;
}

simulated function XComGameState Cohesion_BuildGameState( XComGameStateContext Context )
{
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;

	NewGameState = TypicalAbility_BuildGameState(Context);
	AbilityContext = XComGameStateContext_Ability(Context);
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (UnitState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.SetUnitFloatValue(default.CohesionUnitValue, 1);
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
		if (PlayerState != none && PlayerState.TurnsSinceCohesion > 0)
		{
			PlayerState = XComGameState_Player(NewGameState.CreateStateObject(PlayerState.Class, PlayerState.ObjectID));
			PlayerState.TurnsSinceCohesion = 0;
			NewGameState.AddStateObject(PlayerState);
		}
	}

	return NewGameState;
}

static function name CohesionCheck(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Player PlayerState;
	local XComGameState_Unit UnitState;
	local float Chance, RandRoll;

	UnitState = XComGameState_Unit(kNewTargetState);
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	Chance = float(PlayerState.SquadCohesion) * (default.COHESION_BASE + (default.COHESION_TURNS * float(PlayerState.TurnsSinceCohesion)));
	if (Chance > 0)
	{
		RandRoll = class'Engine'.static.GetEngine().SyncFRand(string(GetFuncName()));
		`log("SquadCohesion check chance" @ Chance @ "rolled" @ RandRoll);
		if (RandRoll < Chance)
		{
			`log("Success!");
			return 'AA_Success';
		}
		`log("Failed.");
	}	
	return 'AA_EffectChanceFailed';
}

DefaultProperties
{
	CohesionUnitValue = "CohesionUsedThisTurn"
}