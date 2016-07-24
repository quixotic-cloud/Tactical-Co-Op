class X2Ability_AndromedonRobot extends X2Ability
	config(GameData_SoldierSkills);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateImmunitiesAbility());
	Templates.AddItem(CreateAcidTrailAbility());
	Templates.AddItem(PurePassive('AndromedonRobotAcidTrail_Passive', "img:///UILibrary_PerkIcons.UIPerk_andromedon_poisoncloud"));
	Templates.AddItem(CreateRebootAbility());
	return Templates;
}

static function X2AbilityTemplate CreateImmunitiesAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_UnitPostBeginPlay Trigger;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AndromedonRobotImmunities');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_robotbattlesuit"; // TODO: This needs to be changed

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	DamageImmunity.ImmuneTypes.AddItem('Fire');
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.ImmuneTypes.AddItem('Acid');
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	DamageImmunity.ImmuneTypes.AddItem('Unconscious');
	DamageImmunity.ImmuneTypes.AddItem('Panic');

	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

//The Andromedon Robot leaves a trail of Acid pools when it moves
static function X2AbilityTemplate CreateAcidTrailAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AndromedonRobotAcidTrail');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_poisoncloud"; // TODO: This needs to be changed

	Template.AdditionalAbilities.AddItem('AndromedonRobotAcidTrail_Passive');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	//This ability fires as part of game states where the Andromedon robot moves
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitMoveFinished';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = BuildAcidTrail_Self;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the Andromedon unit so it can be replaced by the andromedon robot;
	Template.AbilityTargetStyle = default.SelfTarget;

	//NOTE: This ability does not require a build game state or visualization function because this is handled
	//      by the event listener and associated functionality when creating world tile effects
	Template.BuildNewGameStateFn = Empty_BuildGameState;

	return Template;
}

function XComGameState Empty_BuildGameState( XComGameStateContext Context )
{
	return none;
}

//Responds when the Andromedon robot has finished moving and creates a Acid trail along its path
//Must be static, because the event listener source will be an XComGameState_Ability, not the X2Ability_AndromedonRobot.
static function EventListenerReturn BuildAcidTrail_Self(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability MoveContext;
	local int TileIndex;	
	local XComGameState NewGameState;
	local float AbilityRadius;
	local XComWorldData WorldData;
	local vector TargetLocation;
	local array<TilePosPair> OutTiles;
	local TTile MovementTile;
	local XComGameState_Unit UnitStateObject;
	local XComGameStateHistory History;

	MoveContext = XComGameStateContext_Ability(GameState.GetContext());

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	//Define how wide the Acid will spread
	AbilityRadius = class'XComWorldData'.const.WORLD_StepSize * 0.5f;

	//These branches define different situations for which we should generate tile effects. Our first step is to 
	//see what tiles we will be affecting
	if( MoveContext.InputContext.MovementPaths[0].MovementTiles.Length > 0 )
	{		
		//If this move was uninterrupted, or we do not have a resume
		if( MoveContext.InterruptionStatus == eInterruptionStatus_None || MoveContext.ResumeHistoryIndex < 0 )
		{
			//Build the list of tiles that will be affected by the Acid and set it into our tile update game state object			
			for(TileIndex = 0; TileIndex < MoveContext.InputContext.MovementPaths[0].MovementTiles.Length; ++TileIndex)
			{
				MovementTile = MoveContext.InputContext.MovementPaths[0].MovementTiles[TileIndex];
				TargetLocation = WorldData.GetPositionFromTileCoordinates(MovementTile);				
				WorldData.CollectTilesInSphere( OutTiles, TargetLocation, AbilityRadius );
			}
		}
	}
	else
	{
		//This may occur during teleports, spawning, or other instaneous modes of travel
		UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(MoveContext.InputContext.SourceObject.ObjectID));
		
		UnitStateObject.GetKeystoneVisibilityLocation(MovementTile);
		TargetLocation = WorldData.GetPositionFromTileCoordinates(MovementTile);		
		
		WorldData.CollectTilesInSphere( OutTiles, TargetLocation, AbilityRadius );
	}
		
	//If we will be adding Acid to any tiles, do the rest of the set up
	if( OutTiles.Length > 0 )
	{
		//Build the game state for the Acid trail update
		NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

		if( UnitStateObject == none )
		{
			//This may occur during teleports, spawning, or other instaneous modes of travel
			UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(MoveContext.InputContext.SourceObject.ObjectID));
		}
		class'X2Effect_ApplyAcidToWorld'.static.AddAcidToTilesShared('X2Effect_ApplyAcidToWorld', NewGameState, OutTiles, UnitStateObject);
	
		//Submit the new game state to the rules engine
		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

static function X2AbilityTemplate CreateRebootAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RobotReboot');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bCausesCheckFirstSightingOfEnemyGroup = true;

	// This ability fires when the Andromedon dies
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'AndromedonToRobot';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the Andromedon unit so it can be replaced by the andromedon robot;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = RobotReboot_BuildVisualization;
	Template.CinescriptCameraType = "Andromedon_RobotBattlesuit";

	return Template;
}

simulated function RobotReboot_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability Context;
	local XComGameStateHistory History;
	local VisualizationTrack RobotUnitTrack;
	local XComGameState_Unit RobotUnit;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	History = `XCOMHISTORY;

	RobotUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	`assert(RobotUnit != none);

	// The Spawned unit should appear and play its change animation
	RobotUnitTrack.StateObject_OldState = History.GetGameStateForObjectID(RobotUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	RobotUnitTrack.StateObject_NewState = RobotUnit;
	RobotUnitTrack.TrackActor = History.GetVisualizer(RobotUnit.ObjectID);

	class'X2Action_RebootRobot'.static.AddToVisualizationTrack(RobotUnitTrack, Context);

	OutVisualizationTracks.AddItem(RobotUnitTrack);
}