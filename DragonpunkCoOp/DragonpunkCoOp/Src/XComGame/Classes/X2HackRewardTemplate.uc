//---------------------------------------------------------------------------------------
//  FILE:    X2HackRewardTemplate.uc
//  AUTHOR:  Dan Kaplan - 11/11/2014
//           Joshua Bouscher - 4/8/2015 - gutted and reimplemented for latest design.
//  PURPOSE: Template defining a Hack Reward in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2HackRewardTemplate extends X2DataTemplate
	native(Core)
	config(GameCore);

var private localized string	FriendlyName;       // Player facing name of this reward.
var private localized string    Description;        // Player facing description of what this reward does when selected.
var config string				RewardImagePath;    // The URL to the image that should be displayed for this hack reward when presented to the player as an option.

var config int					MinHackSuccess;     // Amount of success required in hack attempt to acquire this reward.
var config int					HackSuccessVariance;// The total hack success required is MinHackSuccess +/- HackSuccessVariance.

var config bool                 bRandomReward;      // Indicates this reward should be grouped with other RandomRewards with the same MinHackSuccess number and chosen from randomly.
var config bool					bBadThing;			// If true, this reward is a bad thing to get, and the hacking UI should display it as such.
var config bool					bResultsInHackFailure;	// If false, when this reward is acquired, the object being hacked will be marked as bHasBeenHacked.

var config bool					bDisplayOnSource;	// If true, this hack reward should be displayed on the hacker.

var config int					MinIntelCost;		// This reward will cost at least this much to purchase.
var config int					MaxIntelCost;		// If nonzero, this reward should be considered part of the Intel Purchased reward deck, and will cost at most this much to purchase.
var config array<name>			MutuallyExclusiveRewards; // If this reward cannot be given when another reward is present
var config bool					bGuaranteedIntelReward; // If this reward should be added to the deck of guaranteed rewards

var config bool					bIsNegativeTacticalReward;	// If true, this reward should be considered part of the Negative Tactical reward deck.
var config bool					bIsNegativeStrategyReward;	// If true, this reward should be considered part of the Negative Strategy reward deck.
var config bool					bIsTacticalReward;	// If true, this reward should be considered part of the Tactical reward deck (if bIsTier1Reward or bIsTier2Reward).
var config bool					bIsStrategyReward;	// If true, this reward should be considered part of the Strategy reward deck (if bIsTier1Reward or bIsTier2Reward).
var config bool					bIsTier1Reward;		// If true, this reward can be selected to fill a Tier 1 tactical slot.
var config bool					bIsTier2Reward;		// If true, this reward can be selected to fill a Tier 2 tactical slot.
var config Name					LinkedReward;		// The associated hack reward that is a variant of this reward (and therefore must be paired with this reward when this reward is made available).
var config bool					bPairWithLinkedReward;	// If true, the LinkedReward must be selected to partner up with this reward.  If false, the LinkedReward is invalidated by selection of this reward.

var config Name					HackAbilityTemplateRestriction;		// This reward is only granted when performing a hack using the matching ability.

enum HackAbilitySourceSelection
{
	EHASS_Hacker,	// Ability will be added to the hacker
	EHASS_XCom,		// Ability will be added to all XCom squad members
	EHASS_Enemies,	// Ability will be added to all enemies of the hacker
};

var config name					AbilityTemplateName; // Ability is added to the Hacker/XComSquad.  If the ability specifies an activation trigger, that is called.
var config HackAbilitySourceSelection AbilitySource;

var config int					MinTurnsUntilExpiration;
var config int					MaxTurnsUntilExpiration;
var transient private int		TurnsUntilExpiration; // If >0, this specifies the number of turns until the Ability (and any persistent effect it creates) is removed after being awarded.

var config name					Reinforcements;     // Designation of enemies to be summoned. Must correspond to a configured ReinforcementEncounters ID.
var config Name					LootTemplateName;	// The item template name of a loot item to be awarded to the player


var Delegate<ApplyHackReward> ApplyHackRewardFn;

delegate ApplyHackReward(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState);



function int GetTurnsUntilExpiration()
{
	if( TurnsUntilExpiration == -10 )
	{
		TurnsUntilExpiration = `SYNC_RAND(MaxTurnsUntilExpiration - MinTurnsUntilExpiration) + MinTurnsUntilExpiration;
	}

	return TurnsUntilExpiration;
}

function bool ValidateTemplate(out string strError)
{
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local ConfigurableEncounter Encounter;

	if (MinHackSuccess > 100)
	{
		strError = "MinHackSuccess is" @ MinHackSuccess @ "but the max possible is 100.";
		return false;
	}

	AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if( AbilityTemplateName != '' )
	{
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityTemplateName);
		if (AbilityTemplate == none)
		{
			strError = "specifies an unknown ability for AbilityTemplateName:" @ AbilityTemplateName;
			return false;
		}
	}
	if (Reinforcements != '')
	{
		`TACTICALMISSIONMGR.GetConfigurableEncounter(Reinforcements, Encounter);
		if (Encounter.EncounterID != Reinforcements)
		{
			strError = "specifies unknown ReinforcementsEncounter ID:" @ Reinforcements;
			return false;
		}
	}

	return super.ValidateTemplate(strError);
}

function bool IsHackRewardCurrentlyPossible()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplate LootTemplate;

	// this reward template now must check to make sure the reward it offers is valid
	if( LootTemplateName != '' )
	{
		LootTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(LootTemplateName);
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if( XComHQ != None && !XComHQ.MeetsAllStrategyRequirements(LootTemplate.Requirements) )
		{
			return false;
		}
	}

	return true;
}

function OnHackRewardAcquired(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Item NewItemState;
	local X2ItemTemplate ItemTemplate;

	`COMBATLOG("HackReward earned:" @ GetFriendlyName());

	// negative hack rewards should automatically break concealment
	if( bBadThing )
	{
		if( Hacker.IsConcealed() )
		{
			Hacker.BreakConcealmentNewGameState(NewGameState);
		}
	}

	SetupRewardAbility(Hacker, HackTarget, NewGameState, AbilityTemplateName, AbilitySource);
	SummonReinforcements(Hacker, HackTarget, NewGameState);

	if( ApplyHackRewardFn != None )
	{
		ApplyHackRewardFn(Hacker, HackTarget, NewGameState);
	}

	if( LootTemplateName != '' )
	{
		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
		NewGameState.AddStateObject(BattleData);

		if( LootTemplateName != '' )
		{
			// create the loot item and add it to the hacker's inventory
			ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(LootTemplateName);
			NewItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(NewItemState);
			Hacker.AddLoot(NewItemState.GetReference(), NewGameState);
		}
	}
}

protected function SetupRewardAbility(XComGameState_Unit Shooter, XComGameState_BaseObject Target, XComGameState NewGameState, Name AbilityName, HackAbilitySourceSelection HackSourceSelection)
{
	local X2AbilityTemplate SourceAbilityTemplate, AbilityTemplate;
	local array<X2AbilityTemplate> AllAbilityTemplates;
	local StateObjectReference AbilityRef;
	local XComGameState_Ability AbilityState;
	local X2EventManager EventMan;
	local array<StateObjectReference> AbilitySourceRefs;
	local XComGameState_Unit AbilitySourceUnitState;
	local XComGameState_Unit OtherUnitState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;
	local Name AdditionalAbilityName;

	if (AbilityName != '')
	{
		SourceAbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
		if( SourceAbilityTemplate != none )
		{
			AllAbilityTemplates.AddItem(SourceAbilityTemplate);
			foreach SourceAbilityTemplate.AdditionalAbilities(AdditionalAbilityName)
			{
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AdditionalAbilityName);
				if( AbilityTemplate != none )
				{
					AllAbilityTemplates.AddItem(AbilityTemplate);
				}
			}
		}
	}

	History = `XCOMHISTORY;
	EventMan = `XEVENTMGR;


	// select source(s)
	switch( HackSourceSelection )
	{
	case EHASS_Hacker:
		AbilitySourceRefs.AddItem(Shooter.GetReference());
		break;
	case EHASS_XCom:
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		foreach XComHQ.Squad(UnitRef)
		{
			AbilitySourceRefs.AddItem(UnitRef);
		}
		break;
	case EHASS_Enemies:
		foreach History.IterateByClassType(class'XComGameState_Unit', OtherUnitState)
		{
			if( OtherUnitState.IsInPlay() && OtherUnitState.IsAlive() && OtherUnitState.IsEnemyUnit(Shooter) )
			{
				AbilitySourceRefs.AddItem(OtherUnitState.GetReference());
			}
		}
		break;
	default:
		`assert(FALSE); // unhandled enum value
		break;
	}

	foreach AbilitySourceRefs(UnitRef)
	{
		AbilitySourceUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		NewGameState.AddStateObject(AbilitySourceUnitState);

		if( bDisplayOnSource )
		{
			AbilitySourceUnitState.CurrentHackRewards.AddItem(DataName);
		}

		foreach AllAbilityTemplates(AbilityTemplate)
		{
			AbilityRef = AbilitySourceUnitState.FindAbility(AbilityTemplate.DataName);
			if( AbilityRef.ObjectID == 0 )
			{
				AbilityRef = `TACTICALRULES.InitAbilityForUnit(AbilityTemplate, AbilitySourceUnitState, NewGameState);
				if( AbilityRef.ObjectID == 0 )
				{
					continue;
				}
			}

			// if the ability template specifies an event listener, trigger it now
			AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityRef.ObjectID));
			NewGameState.AddStateObject(AbilityState);

			if( GetTurnsUntilExpiration() > 0 )
			{
				AbilityState.TurnsUntilAbilityExpires = TurnsUntilExpiration;
			}

			EventMan.TriggerEvent(class'X2HackRewardTemplateManager'.default.HackAbilityEventName, Target, AbilityState, NewGameState);
		}
	}

	// reset the transient in case this hack reward needs to be reused in the same game session
	TurnsUntilExpiration = -10;
}

protected function SummonReinforcements(XComGameState_Unit Shooter, XComGameState_BaseObject Target, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_InteractiveObject ObjectState;
	local TTile TargetTile;
	local vector SummonPos;

	if (Reinforcements != '')
	{
		UnitState = XComGameState_Unit(Target);
		if (UnitState != none)
		{
			TargetTile = UnitState.TileLocation;
		}
		else
		{
			ObjectState = XComGameState_InteractiveObject(Target);
			ObjectState.GetKeystoneVisibilityLocation(TargetTile);
		}
		SummonPos = `XWORLD.GetPositionFromTileCoordinates(TargetTile);
		class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(Reinforcements, /*OverrideCountdown*/, true, SummonPos, 4, NewGameState);
	}
}

function string GetFriendlyName()
{
	return FriendlyName;
}

function string GetDescription(XComGameState_BaseObject HackTarget)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion WorldRegion;
	local string Desc;
	local XGParamTag ParamTag;


	Desc = Description;
	
	if( DataName == 'FacilityLead' )
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		WorldRegion = XComHQ.GetRegionByName(XComHQ.NextAvailableFacilityLeadRegion);
		if( WorldRegion != None )
		{
			Desc = Desc $ WorldRegion.GetMyTemplate().DisplayName;
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = GetTurnsUntilExpiration();

	return `XEXPAND.ExpandString(Desc);
}

defaultproperties
{
	TurnsUntilExpiration = -10
}