//---------------------------------------------------------------------------------------
//  FILE:    X2Action_DropshipIntro.uc
//  AUTHOR:  David Burchanowski  --  6/8/2016
//  PURPOSE: Starts and controls the drop ship intro sequence when starting a tactical mission.
//           For modding: if you want to add new character types to an intro, do this:
//           1) Create a new matinee package with the matinees to want to add.
//           2) Add an line to AdditionalMissionIntroPackages in your xcommission.ini so that the game knows to load the package.
//           3) Set the BaseMatineeComment field in the new matinees to match the comment tag of the matinee you are adding to.   
//           4) If not already set, set the strIntroMatineeSlotPrefix value in the character template of the character types that
//              should populate your matinee.
//           5) That's it! You've now modded in more intro slots!
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_DropshipIntro extends X2Action_PlayMatinee config(GameData);

var config float ShowMissionIntroUITime;
var const config int DropshipSlotCount;

var private AkEvent TextScrollSound_Start;
var private AkEvent TextScrollSound_Stop;
var private bool bStoppedIntroSound;
var private bool bDefaultIntro;

// Index of the sequence in the intro definition that we want to play.
var private int MatineeSequenceIndex;

// Each dropship intro can be comprised of a list of sub-matinees. This keeps track of the one we are playing
var private int MatineeIndex;

function Init(const out VisualizationTrack InTrack)
{
	local XComTacticalMissionManager MissionManager;
	local MissionIntroDefinition IntroDefinition;

	super.Init(InTrack);

	if( ShowMissionIntroUITime == 0.0 )
	{
		ShowMissionIntroUITime = 12.0;
	}

	// pick our sequence
	MissionManager = `TACTICALMISSIONMGR;
	IntroDefinition = MissionManager.GetActiveMissionIntroDefinition();
	bDefaultIntro = IntroDefinition == MissionManager.DefaultMissionIntroDefinition;
	MatineeSequenceIndex = `SYNC_RAND(MissionManager.GetActiveMissionIntroDefinition().MatineeSequences.Length);
}

private function GetAllIntroSlotPrefixes(out array<string> IntroPrefixes)
{
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;

	foreach class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().IterateTemplates(DataTemplate, none)
	{
		CharacterTemplate = X2CharacterTemplate(DataTemplate);
		if(CharacterTemplate != none 
			&& CharacterTemplate.strIntroMatineeSlotPrefix != ""
			&& IntroPrefixes.Find(CharacterTemplate.strIntroMatineeSlotPrefix) == INDEX_NONE)
		{
			IntroPrefixes.AddItem(CharacterTemplate.strIntroMatineeSlotPrefix);
		}
	}
}

private function AddUnitsToMatinee()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;
	local XComGameState_Unit GameStateUnit;
	local array<name> UsedSlots;
	local array<string> IntroPrefixes;
	local string IntroPrefix;
	local int UnitIndex;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if(XComHQ != none)
	{
		// normally, we can grab the xcom squad and add just those soldiers. This prevents VIPS and others from being added to the dropship
		UnitIndex = 1;
		foreach XComHQ.Squad(UnitRef)
		{
			if (UnitRef.ObjectID != 0) //Empty slots may be present in the squad as a 0 entry.
			{
				GameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
				if (GameStateUnit != none)
				{
					UsedSlots.AddItem(name(GameStateUnit.GetMyTemplate().strIntroMatineeSlotPrefix $ UnitIndex));
					AddUnitToMatinee(UsedSlots[UsedSlots.Length - 1], GameStateUnit);
					UnitIndex++;
				}
				else
				{
					`Redscreen("X2Action_DropshipIntro::AddUnitsToMatinee:\n" $
						" Unit with ObjectID " $ UnitRef.ObjectID $ " is in the squad but does not exist in the history. This is very bad!\n" $
						" Talk to David B.");
				}
			}
		}
	}
	else
	{
		// fallback, just add all xcom units. Should happen in PIE
		UnitIndex = 1;
		foreach History.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
		{
			if( GameStateUnit.GetTeam() == eTeam_XCom )
			{	
				AddUnitToMatinee(name(GameStateUnit.GetMyTemplate().strIntroMatineeSlotPrefix $ UnitIndex), GameStateUnit);
				UnitIndex++;
			}
		}
	}

	// check to see if we have any vips to add to the matinee
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(BattleData != none)
	{
		UnitIndex = 0;
		foreach BattleData.RewardUnits(UnitRef)
		{
			GameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (GameStateUnit != none)
			{
				AddUnitToMatinee(name("VIP" $ UnitIndex), GameStateUnit);
				UnitIndex++;
			}
		}
	}

	// now set all unused intro slots to none, so that any preview characters in them aren't playing sounds invisibly
	GetAllIntroSlotPrefixes(IntroPrefixes);
	foreach IntroPrefixes(IntroPrefix)
	{
		for(UnitIndex = 1; UnitIndex <= DropshipSlotCount; UnitIndex++)
		{
			if(UsedSlots.Find(name(IntroPrefix $ UnitIndex)) == INDEX_NONE)
			{
				AddUnitToMatinee(name(IntroPrefix $ UnitIndex), none);
			}
		}
	}
}

//We never time out
function bool IsTimedOut()
{
	return false;
}

private function FindDropshipMatinee()
{
	local XComTacticalMissionManager MissionManager;
	local string MatineePrefix;

	MissionManager = `TACTICALMISSIONMGR;

	MatineePrefix = MissionManager.GetActiveMissionIntroDefinition().MatineeSequences[MatineeSequenceIndex].MatineeCommentPrefixes[MatineeIndex];
	SelectMatineeByTag(MatineePrefix);
}

simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);
		
		`BATTLE.SetFOW(false);
		`PRES.UIMissionIntro(true);

		WorldInfo.PlayAkEvent(TextScrollSound_Start);
		SetTimer(ShowMissionIntroUITime, false, nameof(StopUIMissionIntroSound));

		SetTimer(1.0f, false, nameof(ClearCameraFade));

		//!bDefaultIntro is a hack because NONE of the override intros have the correct kismet and Audio can't fix it before ZBR
		`XTACTICALSOUNDMGR.StartAllAmbience(!bDefaultIntro); 
	}

	simulated event EndState(name NextStateName)
	{
		super.EndState(NextStateName);

		`BATTLE.SetFOW(true);

		StopUIMissionIntroSound();

		`PRES.UIMissionIntro(false);
	}

	function bool HasMoreMatinees()
	{
		local XComTacticalMissionManager MissionManager;
		local MissionIntroDefinition MissionIntro;

		MissionManager = `TACTICALMISSIONMGR;
		MissionIntro = MissionManager.GetActiveMissionIntroDefinition();
		
		return MatineeIndex < MissionIntro.MatineeSequences[MatineeSequenceIndex].MatineeCommentPrefixes.Length
				&& MissionIntro.MatineeSequences[MatineeSequenceIndex].MatineeCommentPrefixes[MatineeIndex] != "";
	}

	function SetupMatineeBase()
	{
		local XComTacticalMissionManager MissionManager;
		local XComParcelManager ParcelManager;

		// move the matinee to play right on top of the soldier spawn
		MissionManager = `TACTICALMISSIONMGR;
		ParcelManager = `PARCELMGR;

		SetMatineeLocation(ParcelManager.SoldierSpawn.Location, ParcelManager.SoldierSpawn.Rotation);
		SetMatineeBase(MissionManager.GetActiveMissionIntroDefinition().MatineeBaseTag);
	}

Begin:
	// since this just adds things to a mapping array, it's safe to call before the actual matinee has
	// been chosen
	AddUnitsToMatinee();

	// play each of the dropship matinees in order
	while(HasMoreMatinees()) // if the matinee was skipped, skip the rest of them too
	{
		FindDropshipMatinee();

		SetupMatineeBase();

		PlayMatinee();

		// just wait for the matinee to complete playback. Note that if we skip one, we still need to start and complete each of the rest
		// so that any audio/camera/setup events in their completed blocks have a chance to fire
		do
		{
			Sleep(0.0f);
		}
		until(Matinees.Length == 0 || MatineeSkipped); // the matinee list will be cleared when they are finished

		EndMatinee();

		MatineeIndex++;
	}
	
	CompleteAction();
}

function ClearCameraFade()
{
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false);
}

function StopUIMissionIntroSound()
{
	if( !bStoppedIntroSound )
	{
		bStoppedIntroSound = true;
		WorldInfo.PlayAkEvent(TextScrollSound_Stop);		
	}
}

DefaultProperties
{
	TextScrollSound_Start=AkEvent'SoundTacticalUI.TacticalUI_TextScrollStart'
	TextScrollSound_Stop=AkEvent'SoundTacticalUI.TacticalUI_TextScrollStop'

	bRebaseNonUnitVariables=false
}
