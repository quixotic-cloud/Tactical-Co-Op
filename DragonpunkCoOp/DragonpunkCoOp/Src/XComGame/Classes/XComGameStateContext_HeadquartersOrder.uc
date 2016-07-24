//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_HeadquartersOrder.uc
//  AUTHOR:  Ryan McFall  --  11/22/2013
//  PURPOSE: Meta data for an order given in the headquarters. Examples of orders are
//           Hiring soldiers, Changing research priorities, building items, constructing
//           facilities. This context exists for prototyping purposes, and at some point 
//           will be dismantled and made mod-friendly like the ability context. In the 
//           meantime, this context will make that process easier
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_HeadquartersOrder extends XComGameStateContext;

//These enums will eventually be converted into a template system like abilities 
enum HeadquartersOrderType
{
	eHeadquartersOrderType_HireStaff,
	eHeadquartersOrderType_HireStaffExplicit,
	eHeadquartersOrderType_FireStaff,
	eHeadquartersOrderType_ResearchCompleted,
	eHeadquartersOrderType_FacilityConstructionCompleted,
	eHeadquartersOrderType_CancelFacilityConstruction,
	eHeadquartersOrderType_StartFacilityRepair,
	eHeadquartersOrderType_FacilityRepairCompleted,
	eHeadquartersOrderType_AddResource,
	eHeadquartersOrderType_ItemConstructionCompleted,
	eHeadquartersOrderType_CancelItemConstruction,
	eHeadquartersOrderType_ClearRoomCompleted,
	eHeadquartersOrderType_CancelClearRoom,
	eHeadquartersOrderType_StartUnitHealing,
	eHeadquartersOrderType_UnitHealingCompleted,
	eHeadquartersOrderType_UpgradeFacilityCompleted,
	eHeadquartersOrderType_CancelUpgradeFacility,
	eHeadquartersOrderType_TrainRookieCompleted,
	eHeadquartersOrderType_CancelTrainRookie,
	eHeadquartersOrderType_RespecSoldierCompleted,
	eHeadquartersOrderType_CancelRespecSoldier,
	eHeadquartersOrderType_PsiTrainingCompleted,
	eHeadquartersOrderType_CancelPsiTraining,
};

struct HeadquartersOrderInputContext
{	
	var HeadquartersOrderType OrderType;

	//These context vars are used for orders that involve trading a resource for a quantity of something. Ie. Hiring staff, buying mcguffins
	//***************************
	var name AquireObjectTemplateName;
	var int Quantity;
	var int Cost;
	var int CostResourceType;
	var StateObjectReference AcquireObjectReference;
	var StateObjectReference FacilityReference;
	//***************************
};

var HeadquartersOrderInputContext InputContext;

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_HeadquartersOrder NewGameStateContext;
	local int Index;

	History = `XCOMHISTORY;

	//Make the new game state
	NewGameState = History.CreateNewGameState(true, self);
	NewGameStateContext = XComGameStateContext_HeadquartersOrder(NewGameState.GetContext());

	//Add new or updated state objects
	switch(InputContext.OrderType)
	{
	case eHeadquartersOrderType_HireStaff:
		for( Index = 0; Index < NewGameStateContext.InputContext.Quantity; ++Index )
		{			
			BuildNewUnit(NewGameState, InputContext.AquireObjectTemplateName);
		}
		break;
	case eHeadquartersOrderType_HireStaffExplicit:
		RecruitUnit(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_FireStaff:
		FireUnit(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_ResearchCompleted:
		CompleteResearch(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_FacilityConstructionCompleted:
		CompleteFacilityConstruction(NewGameState, InputContext.AcquireObjectReference, InputContext.FacilityReference);
		break;
	case eHeadquartersOrderType_CancelFacilityConstruction:
		CancelFacilityConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_StartFacilityRepair:
		break;
	case eHeadquartersOrderType_FacilityRepairCompleted:
		break;
	case eHeadquartersOrderType_AddResource:
		AddResource(NewGameState, InputContext.AquireObjectTemplateName, InputContext.Quantity);
		break;
	case eHeadquartersOrderType_ItemConstructionCompleted:
		CompleteItemConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelItemConstruction:
		CancelItemConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_ClearRoomCompleted:
		CompleteClearRoom(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelClearRoom:
		CancelClearRoom(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_StartUnitHealing:
		StartUnitHealing(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_UnitHealingCompleted:
		CompleteUnitHealing(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_UpgradeFacilityCompleted:
		CompleteUpgradeFacility(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelUpgradeFacility:
		CancelUpgradeFacility(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_TrainRookieCompleted:
		CompleteTrainRookie(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelTrainRookie:
		CancelTrainRookie(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_RespecSoldierCompleted:
		CompleteRespecSoldier(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelRespecSoldier:
		CancelRespecSoldier(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_PsiTrainingCompleted:
		CompletePsiTraining(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelPsiTraining:
		CancelPsiTraining(NewGameState, InputContext.AcquireObjectReference);
		break;
		
	}

	//@TODO Deduct resources
	if( InputContext.Cost > 0 )
	{
		
	}

	return NewGameState;
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{	
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local string OutputString;
	OutputString = string(InputContext.OrderType);
	OutputString = OutputString @ "( Type:" @ InputContext.AquireObjectTemplateName @ "Qty:" @ InputContext.Quantity @ ")";
	return OutputString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
function string ToString()
{
	return "";
}
//***************************************************

private function BuildNewUnit(XComGameState AddToGameState, name UseTemplate)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item BuildItem;
	local XGCharacterGenerator CharGen;
	local TSoldier CharacterGeneratorResult;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplateManager SoldierClassTemplateManager;
	local array<name> aTemplateNames;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;


	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(UseTemplate);
	`assert(CharacterTemplate != none);

	//Make the unit from a template
	//*************************
	NewUnitState = CharacterTemplate.CreateInstanceFromTemplate(AddToGameState);
	
	//Fill in the unit's stats and appearance
	NewUnitState.RandomizeStats();	
	CharGen = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);	
	`assert(CharGen != none);
	CharacterGeneratorResult = CharGen.CreateTSoldier(UseTemplate);
	NewUnitState.SetTAppearance(CharacterGeneratorResult.kAppearance);
	NewUnitState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
	NewUnitState.SetCountry(CharacterGeneratorResult.nmCountry);
	if(!NewUnitState.HasBackground())
		NewUnitState.GenerateBackground();

	AddToGameState.AddStateObject(NewUnitState);
	//*************************

	//If we added a soldier, give the soldier default items. Eventually we will want to be pulling items from the armory...
	//***************
	if( UseTemplate == 'Soldier' )
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);			
		BuildItem.ItemLocation = eSlot_None;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_Armor, AddToGameState);
		AddToGameState.AddStateObject(BuildItem);

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('AssaultRifle_CV'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);			
		BuildItem.ItemLocation = eSlot_RightHand;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_PrimaryWeapon, AddToGameState);
		AddToGameState.AddStateObject(BuildItem);

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('Pistol'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);				
		BuildItem.ItemLocation = eSlot_RightThigh;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_SecondaryWeapon, AddToGameState);
		AddToGameState.AddStateObject(BuildItem);


		SoldierClassTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		SoldierClassTemplateManager.GetTemplateNames(aTemplateNames);

		NewUnitState.SetSoldierClassTemplate(aTemplateNames[`SYNC_RAND(aTemplateNames.Length)]);
		NewUnitState.BuySoldierProgressionAbility(AddToGameState, 0, 0); // Setup the first rank ability
	}
	//***************

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.AddToCrew(AddToGameState, NewUnitState);
		AddToGameState.AddStateObject(XComHQ);
	}
}

private function RecruitUnit(XComGameState AddToGameState, StateObjectReference UnitReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		AddToGameState.AddStateObject(XComHQ);
		NewUnitState = XComGameState_Unit(AddToGameState.GetGameStateForObjectID(UnitReference.ObjectID));
		if (NewUnitState == none)
			NewUnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitReference.ObjectID));
		`assert(NewUnitState != none);
		XComHQ.AddToCrew(AddToGameState, NewUnitState);
		AddToGameState.AddStateObject(NewUnitState);
	}

	if(ResistanceHQ != none)
	{
		ResistanceHQ = XComGameState_HeadquartersResistance(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		ResistanceHQ.Recruits.RemoveItem(UnitReference);
		AddToGameState.AddStateObject(ResistanceHQ);
	}
}

private function FireUnit(XComGameState AddToGameState, StateObjectReference UnitReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	AddToGameState.AddStateObject(XComHQ);
	XComHQ.RemoveFromCrew(UnitReference);
		
	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		if(XComHQ.Squad[idx] == UnitReference)
		{
			XComHQ.Squad[idx] = EmptyRef;
			break;
		}
	}

	// REMOVE FIRED UNIT?
	AddToGameState.RemoveStateObject(UnitReference.ObjectID);
}

private function CompleteResearch(XComGameState AddToGameState, StateObjectReference TechReference)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_Tech TechState, AvailableTechState;
	local X2TechTemplate TechTemplate;
	local array<StateObjectReference> AvailableTechRefs;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.TechsResearched.AddItem(TechReference);
		for(idx = 0; idx < XComHQ.Projects.Length; idx++)
		{
			ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
			ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
			
			if (ProvingGroundProject != None && ProvingGroundProject.ProjectFocus == TechReference)
			{
				FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProvingGroundProject.AuxilaryReference.ObjectID));

				if (FacilityState != none)
				{
					FacilityState = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
					AddToGameState.AddStateObject(FacilityState);
					FacilityState.BuildQueue.RemoveItem(ProvingGroundProject.GetReference());
				}
			}

			if(ResearchProject != none && ResearchProject.ProjectFocus == TechReference)
			{
				XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
				AddToGameState.RemoveStateObject(ResearchProject.GetReference().ObjectID);

				if (ResearchProject.bShadowProject)
				{
					XComHQ.EmptyShadowChamber(AddToGameState);
				}

				break;
			}
		}
		AddToGameState.AddStateObject(XComHQ);
	}

	TechState = XComGameState_Tech(AddToGameState.CreateStateObject(class'XComGameState_Tech', TechReference.ObjectID));
	AddToGameState.AddStateObject(TechState);
	TechState.TimesResearched++;
	TechState.TimeReductionScalar = 0;

	TechState.OnResearchCompleted(AddToGameState);

	TechTemplate = TechState.GetMyTemplate(); // Get the template for the completed tech
	if (!TechState.IsInstant() && !TechTemplate.bShadowProject && !TechTemplate.bProvingGround)
	{
		AvailableTechRefs = XComHQ.GetAvailableTechsForResearch();
		for (idx = 0; idx < AvailableTechRefs.Length; idx++)
		{
			AvailableTechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[idx].ObjectID));
			if (AvailableTechState.GetMyTemplate().bCheckForceInstant && 
				XComHQ.MeetsAllStrategyRequirements(AvailableTechState.GetMyTemplate().InstantRequirements) &&
				!XComHQ.HasPausedProject(AvailableTechRefs[idx]))
			{
				AvailableTechState = XComGameState_Tech(AddToGameState.CreateStateObject(class'XComGameState_Tech', AvailableTechState.ObjectID));
				AddToGameState.AddStateObject(AvailableTechState);
				AvailableTechState.bForceInstant = true;
			}
		}
	}
	
	if (TechState.GetMyTemplate().bProvingGround)
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_ProvingGroundProjectsCompleted');
	else
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_TechsCompleted');

	`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, TechState, AddToGameState);
}

private function CompleteFacilityConstruction(XComGameState AddToGameState, StateObjectReference RoomReference, StateObjectReference FacilityReference)
{
	local XComGameState_HeadquartersRoom Room, NewRoom;
	local XComGameState_FacilityXCom Facility, NewFacility;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomReference.ObjectID));
	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityReference.ObjectID));

	if(Room != none && Facility != none)
	{
		NewRoom = XComGameState_HeadquartersRoom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
		AddToGameState.AddStateObject(NewRoom);
	
		NewFacility = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', Facility.ObjectID));
		AddToGameState.AddStateObject(NewFacility);

		NewFacility.Room = NewRoom.GetReference();   
		NewFacility.ConstructionDateTime = `STRATEGYRULES.GameTime;
		NewFacility.bPlayFlyIn = true;

		NewRoom.Facility = NewFacility.GetReference();
		NewRoom.UpdateRoomMap = true;
		NewRoom.UnderConstruction = false;

		if (NewRoom.GetBuildSlot().IsSlotFilled())
		{
			NewFacility.Builder = NewRoom.GetBuildSlot().GetAssignedStaffRef();
			NewRoom.GetBuildSlot().EmptySlot(AddToGameState);
		}
		
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Facilities.AddItem(FacilityReference);

			for(idx = 0; idx < XComHQ.Projects.Length; idx++)
			{
				FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
				
				if(FacilityProject != none)
				{
					if(FacilityProject.ProjectFocus == FacilityReference)
					{
						XComHQ.Projects.RemoveItem(FacilityProject.GetReference());
						AddToGameState.RemoveStateObject(FacilityProject.ObjectID);
						break;
					}
				}
			}
			AddToGameState.AddStateObject(XComHQ);
		}

		`XEVENTMGR.TriggerEvent('FacilityConstructionCompleted', NewFacility, XComHQ, AddToGameState);
	}
}

private function CancelFacilityConstruction(XComGameState AddToGameState, StateObjectReference ProjectReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility ProjectState;
	local XComGameState_HeadquartersRoom Room, NewRoom;
	local XComGameStateHistory History;
	local X2FacilityTemplate FacilityTemplate;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(ProjectReference.ObjectID));
	
	if(ProjectState != none)
	{
		FacilityTemplate = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID)).GetMyTemplate();
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
		if(Room != none)
		{
			NewRoom = XComGameState_HeadquartersRoom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
			NewRoom.UpdateRoomMap = true;
			NewRoom.UnderConstruction = false;
			AddToGameState.AddStateObject(NewRoom);
			
			if (NewRoom.GetBuildSlot().IsSlotFilled())
			{
				NewRoom.GetBuildSlot().EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.RefundStrategyCost(AddToGameState, FacilityTemplate.Cost, XComHQ.FacilityBuildCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectReference);
			AddToGameState.RemoveStateObject(ProjectState.ProjectFocus.ObjectID);
			AddToGameState.RemoveStateObject(ProjectReference.ObjectID);
		}
	}
}

static function AddResource(XComGameState AddToGameState, name ResourceTemplateName, int iQuantity)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Resource, NewResource;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Inventory.Length; idx++)
	{
		Resource = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));

		if(Resource != none)
		{
			if(Resource.GetMyTemplateName() == ResourceTemplateName)
			{
				NewResource = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item', Resource.ObjectID));
				AddToGameState.AddStateObject(NewResource);
				NewResource.Quantity += iQuantity;
				
				if(NewResource.Quantity < 0)
				{
					NewResource.Quantity = 0;
				}
			}
		}
	}
}

static function CompleteItemConstruction(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXcom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectBuildItem ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectBuildItem(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if(FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			AddToGameState.AddStateObject(NewFacilityState);
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
			//if(NewFacilityState.RefundPercent > 0)
			//{
			//	XComHQ.AddResource(AddToGameState, 'Supplies', Round(float(ItemState.GetMyTemplate().SupplyCost) * 
			//		class'X2StrategyGameRulesetDataStructures'.default.BuildItemProject_CostScalar * (float(NewFacilityState.RefundPercent)/100.0)));
			//}
			
			ItemState.OnItemBuilt(AddToGameState);

			XComHQ.PutItemInInventory(AddToGameState, ItemState);
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);

			`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', ItemState, ItemState, AddToGameState);
		}
	}
}

static function CancelItemConstruction(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectBuildItem ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if(FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
			AddToGameState.AddStateObject(NewFacilityState);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.RefundStrategyCost(AddToGameState, ItemState.GetMyTemplate().Cost, XComHQ.ItemBuildCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ProjectFocus.ObjectID);
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CancelProvingGroundProject(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectProvingGround ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if (FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
			AddToGameState.AddStateObject(NewFacilityState);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.RefundStrategyCost(AddToGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CompleteClearRoom(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersRoom RoomState, NewRoomState;
	local XComGameState_HeadquartersProjectClearRoom ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		AddToGameState.AddStateObject(XComHQ);
	}

	if(ProjectState != none)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(RoomState != none)
		{
			NewRoomState = XComGameState_HeadquartersRoom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
			AddToGameState.AddStateObject(NewRoomState);
			NewRoomState.ClearingRoom = false;
			NewRoomState.ClearRoomProject = EmptyRef;
			NewRoomState.bSpecialRoomFeatureCleared = true;
			NewRoomState.UpdateRoomMap = true;

			if (NewRoomState.HasStaff())
			{
				NewRoomState.EmptyAllBuildSlots(AddToGameState);;
			}

			NewRoomState.GetSpecialFeature().OnClearFn(AddToGameState, NewRoomState);
			if(NewRoomState.GetSpecialFeature().bRemoveOnClear)
			{
				NewRoomState.SpecialFeature = '';
			}

			XComHQ.UnlockAdjacentRooms(AddToGameState, NewRoomState);
		}

		XComHQ.Projects.RemoveItem(ProjectState.GetReference());
		AddToGameState.RemoveStateObject(ProjectState.ObjectID);		
	}
}

static function CancelClearRoom(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersRoom RoomState, NewRoomState;
	local XComGameState_HeadquartersProjectClearRoom ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(RoomState != none)
		{
			NewRoomState = XComGameState_HeadquartersRoom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
			NewRoomState.UpdateRoomMap = true;
			NewRoomState.ClearingRoom = false;
			AddToGameState.AddStateObject(NewRoomState);
			
			if (NewRoomState.GetBuildSlot().IsSlotFilled())
			{
				NewRoomState.GetBuildSlot().EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function StartUnitHealing(XComGameState AddToGameState, StateObjectReference UnitRef)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if(UnitState != none)
	{
		NewUnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		AddToGameState.AddStateObject(NewUnitState);
		
		ProjectState = XComGameState_HeadquartersProjectHealSoldier(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
		AddToGameState.AddStateObject(ProjectState);
		ProjectState.SetProjectFocus(UnitRef);

		NewUnitState.SetStatus(eStatus_Healing);

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.AddItem(ProjectState.GetReference());

			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
		}
	}
}

static function CompleteUnitHealing(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local StaffUnitInfo UnitInfo;
	local int SlotIndex;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectHealSoldier(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(UnitState != none)
		{
			NewUnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			AddToGameState.AddStateObject(NewUnitState);
			NewUnitState.SetCurrentStat(eStat_HP, NewUnitState.GetBaseStat(eStat_HP));
			NewUnitState.SetStatus(eStatus_Active);

			`XEVENTMGR.TriggerEvent( 'UnitHealCompleted', UnitState, ProjectState, AddToGameState );
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
			
			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
		}
		
		// If the unit is a Psi Operative who was training an ability before they got hurt, continue the training automatically
		if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		{
			PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
			if (PsiProjectState != none) // A paused Psi Training project was found for the unit
			{
				// Get the Psi Chamber facility and staff the unit in it if there is an open slot
				FacilityState = XComHQ.GetFacilityByName('PsiChamber');
				SlotIndex = FacilityState.GetEmptySoldierStaffSlotIndex();
				if (SlotIndex >= 0)
				{
					// Restart the paused training project
					PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
					AddToGameState.AddStateObject(PsiProjectState);
					PsiProjectState.bForcePaused = false;

					UnitInfo.UnitRef = UnitState.GetReference();
					FacilityState.GetStaffSlot(SlotIndex).FillSlot(AddToGameState, UnitInfo);
				}
			}
		}
	}
}

static function CompleteUpgradeFacility(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXcom FacilityState, NewFacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
		UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(FacilityState != none && UpgradeState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));			
			NewFacilityState.Upgrades.AddItem(ProjectState.ProjectFocus);
			AddToGameState.AddStateObject(NewFacilityState);

			UpgradeState.OnUpgradeAdded(AddToGameState, NewFacilityState);
		}
		
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		`XEVENTMGR.TriggerEvent('UpgradeCompleted', UpgradeState, FacilityState, AddToGameState);
	}
}

static function CancelUpgradeFacility(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if (FacilityState != none)
		{
			RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(FacilityState.Room.ObjectID));

			if (RoomState != none)
			{
				if (RoomState.GetBuildSlot().IsSlotFilled())
				{
					RoomState.GetBuildSlot().EmptySlot(AddToGameState);		
				}
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CompleteTrainRookie(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up to their new class
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetXPForRank(1);
			UnitState.StartingRank = 1;
			UnitState.RankUpSoldier(AddToGameState, ProjectState.NewClassName); // The class template name was set when the project began
			UnitState.ApplySquaddieLoadout(AddToGameState, XComHQ);
			UnitState.ApplyBestGearLoadout(AddToGameState); // Make sure the squaddie has the best gear available
			UnitState.SetStatus(eStatus_Active);
			AddToGameState.AddStateObject(UnitState);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function CancelTrainRookie(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetStatus(eStatus_Active);
			AddToGameState.AddStateObject(UnitState);
		
			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{				
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CompleteRespecSoldier(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectRespecSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectRespecSoldier(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up to their new class
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.ResetSoldierAbilities(); // First clear all of the current abilities
			for (i = 0; i < UnitState.GetSoldierClassTemplate().GetAbilityTree(0).Length; ++i) // Then give them their squaddie ability back
			{
				UnitState.BuySoldierProgressionAbility(AddToGameState, 0, i);
			}
			UnitState.SetStatus(eStatus_Active);
			//UnitState.EquipOldItems(AddToGameState);
			AddToGameState.AddStateObject(UnitState);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function CancelRespecSoldier(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectRespecSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectRespecSoldier(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetStatus(eStatus_Active);
			AddToGameState.AddStateObject(UnitState);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CompletePsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up as a squaddie Psi Operative
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			// Rank up the solder. Will also apply class if they were a Rookie.
			UnitState.RankUpSoldier(AddToGameState, 'PsiOperative');
			
			// Teach the soldier the ability which was associated with the project
			UnitState.BuySoldierProgressionAbility(AddToGameState, ProjectState.iAbilityRank, ProjectState.iAbilityBranch);

			if (UnitState.GetRank() == 1) // They were just promoted to Initiate
			{
				UnitState.ApplyBestGearLoadout(AddToGameState); // Make sure the squaddie has the best gear available
			}

			UnitState.SetStatus(eStatus_Active);
			AddToGameState.AddStateObject(UnitState);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
			
			`XEVENTMGR.TriggerEvent('PsiTrainingCompleted', UnitState, UnitState, AddToGameState);
		}		
	}
}

static function CancelPsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetStatus(eStatus_Active);
			AddToGameState.AddStateObject(UnitState);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			AddToGameState.AddStateObject(XComHQ);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function IssueHeadquartersOrder(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrder'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}