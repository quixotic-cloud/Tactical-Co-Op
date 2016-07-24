//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierIntroCinematic.uc
//  AUTHOR:  Brian Whitman
//  PURPOSE: Class to control showing soldier intro matinee. 
//           This isn't really a screen, meaning there is no UI,
//           but we need to consume the input to handle skipping the cinematic
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UISoldierIntroCinematic extends UIScreen;

var string StartEventBase;
var name FinishedEventName;
var name SoldierClassVarName;
var name GremlinClassVarName;
var name StopAfterAction;
var name RestartAfterAction;
var string ArmoryCineBaseTag;

var name StartClassIntro;
var UIPawnMgr PawnMgr;
var XComHQPresentationLayer HQPres;
var XComUnitPawn SoldierPawn;
var XComUnitPawn GremlinPawn;
var Actor ExistingPawn;
var StateObjectReference SoldierRef;
var delegate<AfterCinematic> AfterCinematicFunctor;

delegate AfterCinematic ( StateObjectReference SoldRef, optional bool bInstantTransition );

simulated function InitCinematic(name SoldierClass, StateObjectReference SoldRef, optional delegate<AfterCinematic> Func )
{
	HQPres = `HQPRES;
	if (SoldierClass != '')
	{
		StartClassIntro = name(StartEventBase $ SoldierClass);
	}
	else
	{
		StartClassIntro = name(StartEventBase);
	}

	SoldierRef = SoldRef;
	AfterCinematicFunctor = Func;

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers

	WorldInfo.RemoteEventListeners.AddItem(self);
	
	PawnMgr = Spawn(class'UIPawnMgr', self);

	SpawnSoldierPawn();
}

simulated function SpawnSoldierPawn()
{
	SoldierPawn = PawnMgr.RequestPawnByID(self, SoldierRef.ObjectID);
	SoldierPawn.CreateVisualInventoryAttachments(PawnMgr, XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierRef.ObjectID)));
	GremlinPawn = PawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, SoldierRef.ObjectID);

	//Keep dangly bits from wigging out when the character is teleported into the matinee
	if(XComHumanPawn(SoldierPawn) != none)
	{
		XComHumanPawn(SoldierPawn).FreezePhysics();
		SetTimer(1.0f, false, 'WakePhysics', XComHumanPawn(SoldierPawn));
	}

	SetTimer(0.035, false, 'SetSoldierMatineeVariable');
}

simulated function SetSoldierMatineeVariable()
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.RebuildVariableMap();
	WorldInfo.MyKismetVariableMgr.GetVariable(SoldierClassVarName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(SoldierPawn);
		}
	}

	if (GremlinPawn != none)
	{
		WorldInfo.MyKismetVariableMgr.GetVariable(GremlinClassVarName, OutVariables);
		foreach OutVariables(SeqVar)
		{
			SeqVarPawn = SeqVar_Object(SeqVar);
			if(SeqVarPawn != none)
			{
				SeqVarPawn.SetObjectValue(None);
				SeqVarPawn.SetObjectValue(GremlinPawn);
			}
		}
	}

	SetTimer(0.035, false, 'RebaseSoldierToCinema');
}

simulated function RebaseSoldierToCinema()
{
	local SkeletalMeshActor CineDummy;
	local SkeletalMeshActor IterateActor;
	local name CineBaseTag;

	CineBaseTag = name(ArmoryCineBaseTag);
	foreach AllActors(class'SkeletalMeshActor', IterateActor)
	{
		if(IterateActor.Tag == CineBaseTag)
		{
			CineDummy = IterateActor;
			break;
		}
	}

	if (CineDummy == none)
	{
		`Redscreen("Armory map is missing CineDummy with tag of \"AVG_Armory_A_Anim.CineDummy\"!");
	}

	SoldierPawn.SetupForMatinee(CineDummy, true, true, false);
	if (GremlinPawn != none)
	{
		GremlinPawn.SetupForMatinee(CineDummy, true, true, false);
	}

	HideExistingPawn();

	SetTimer(0.035, false, 'StartPawnMatinee');
}

simulated function StartPawnMatinee()
{	
	`XCOMGRI.DoRemoteEvent('PreM_Stop');
	`XCOMGRI.DoRemoteEvent(StopAfterAction);
	`XCOMGRI.DoRemoteEvent(StartClassIntro);
}

simulated function RestoreAfterAction()
{
	local UIScreen CurrentScreen;
	local UIAfterAction AfterActionScreen;

	CurrentScreen = `SCREENSTACK.GetFirstInstanceOf(class'UIAfterAction');

	AfterActionScreen = UIAfterAction(CurrentScreen);
	if (AfterActionScreen != none)
	{
		AfterActionScreen.RestoreCamera();
		`XCOMGRI.DoRemoteEvent(RestartAfterAction);
	}
}

simulated function HideExistingPawn()
{
	local UIScreen CurrentScreen;
	local UIArmory ArmoryScreen;

	CurrentScreen = `SCREENSTACK.GetFirstInstanceOf(class'UIArmory');
	ArmoryScreen = UIArmory(CurrentScreen);

	if (ArmoryScreen == none)
		return;
	
	ExistingPawn = ArmoryScreen.ActorPawn;
	if (ExistingPawn == none)
		return;

	ExistingPawn.SetVisible(false);
}

simulated function ShowExistingPawn()
{
	if (ExistingPawn == none)
		return;

	ExistingPawn.SetVisible(true);
}

event OnRemoteEvent(name RemoteEventName)
{
	super.OnRemoteEvent(RemoteEventName);

	if (RemoteEventName == FinishedEventName)
	{
		DismissScreen();
	}
}

simulated function DismissScreen()
{
	local bool GermanVOIsTooLong;

	WorldInfo.RemoteEventListeners.RemoveItem(self);
	PawnMgr.ReleasePawn(self, SoldierRef.ObjectID);

	// last minute fix for the Rage Suit German localization. They recorded audio that was too long,
	// so don't cut it off. Everything else can be cut off - dburchanowski
	GermanVOIsTooLong = (GetLanguage() == "DEU" || GetLanguage() == "ITA" || GetLanguage() == "ESN")
		&& (StartEventBase == "CIN_ArmorIntro_RageSuit" || StartEventBase == "CIN_ArmorIntro_IcarusSuit");
	if(!GermanVOIsTooLong)
	{
		`HQPRES.m_kNarrativeUIMgr.EndCurrentConversation();
	}
		
	ShowExistingPawn();
	RestoreAfterAction();

	//Don't need to un hide armory staff, this is handled by exiting the armory

	`SCREENSTACK.Pop(self);
	
	if (AfterCinematicFunctor != none)
	{
		AfterCinematicFunctor(SoldierRef);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// swallow any form of skip cinematic input. the cinematic will fire off its complete event and that will clean us up
	return true;
}

defaultproperties
{
	StartEventBase = "CIN_ClassIntro_";
	FinishedEventName = "CIN_ClassIntro_Done";
	SoldierClassVarName = "ClassIntroSoldier";
	GremlinClassVarName = "Gremlin";
	StopAfterAction = "CIN_StopForPromotion";
	RestartAfterAction = "CIN_RestartAfterPromotion";
	ArmoryCineBaseTag = "AVG_Armory_A_Anim.CineDummy";
}
