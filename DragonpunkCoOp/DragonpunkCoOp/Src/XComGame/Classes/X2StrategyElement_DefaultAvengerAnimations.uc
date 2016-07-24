//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultAvengerAnimations.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultAvengerAnimations extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Animations;

	// Build and Repair Ambient
	Animations.AddItem(CreateBuildingFacilityTemplate());
	Animations.AddItem(CreateRepairingRoomTemplate());

	// Staffing and Service Ambient
	Animations.AddItem(CreateLabIdleSoloTemplate());
	Animations.AddItem(CreateWorkshopIdleSoloTemplate());

	// HQ Ambient
	Animations.AddItem(CreateWeaponCareTemplate());
	Animations.AddItem(CreateWorkingOutWeightsTemplate());
	Animations.AddItem(CreateWorkingOutCalisthenicsTemplate());
	Animations.AddItem(CreateKnifeThrowingTemplate());
	Animations.AddItem(CreateHazingTemplate());
	Animations.AddItem(CreateHangingOutAtTheCoreTemplate());

	return Animations;
}

//####################################################################################
// BUILD AND REPAIR AMBIENT
//####################################################################################
static function X2DataTemplate CreateBuildingFacilityTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('BuildingFacility');
	Template.UsesBuildSlot = true;
	
	Character.CharacterType = eStaff_Engineer;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}
static function X2DataTemplate CreateRepairingRoomTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('RepairingRoom');
	Template.UsesRepairSlot = true;
	
	Character.CharacterType = eStaff_Engineer;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}

//####################################################################################
// STAFF AND SERVICE AMBIENT
//####################################################################################
static function X2DataTemplate CreateLabIdleSoloTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('LabIdleSolo');
	Template.EligibleFacilities.AddItem('Laboratory');
	Template.EligibleFacilities.AddItem('PowerCore');
	Template.UsesStaffSlot = true;
	
	Character.CharacterType = eStaff_Scientist;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Slot.CorrespondsToStaffingSlot = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}
static function X2DataTemplate CreateWorkshopIdleSoloTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('WorkshopIdleSolo');
	Template.EligibleFacilities.AddItem('Workshop');
	Template.EligibleFacilities.AddItem('Storage');
	Template.UsesStaffSlot = true;
	
	Character.CharacterType = eStaff_Engineer;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Slot.CorrespondsToStaffingSlot = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}

//####################################################################################
// HQ AMBIENT
//####################################################################################
static function X2DataTemplate CreateWeaponCareTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('WeaponCare');
	//Template.EligibleFacilities.AddItem('Hangar');
	Template.EligibleFacilities.AddItem('CIC');
	Template.Weight = 20;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}
static function X2DataTemplate CreateWorkingOutWeightsTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('WorkingOutWeights');
	Template.Weight = 25;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Template.CanUseEmptyRoom = true;

	return Template;
}
static function X2DataTemplate CreateWorkingOutCalisthenicsTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('WorkingOutCalisthenics');
	Template.EligibleFacilities.AddItem('OfficerTrainingSchool');
	Template.Weight = 25;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = false;
	Template.AnimationSlots.AddItem(Slot);

	Template.CanUseEmptyRoom = true;

	return Template;
}
static function X2DataTemplate CreateKnifeThrowingTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('KnifeThrowing');
	Template.EligibleFacilities.AddItem('BarMemorial');
	Template.EligibleFacilities.AddItem('Galley');
	Template.Weight = 15;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = false;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}
static function X2DataTemplate CreateHazingTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('Hazing');
	Template.EligibleFacilities.AddItem('OfficerTrainingSchool');
	//Template.EligibleFacilities.AddItem('Hangar');
	Template.Weight = 15;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Template.CanUseEmptyRoom = true;

	return Template;
}
static function X2DataTemplate CreateHangingOutAtTheCoreTemplate()
{
	local X2AvengerAnimationTemplate Template;
	local AvengerAnimationSlot Slot;
	local AvengerAnimationCharacter Character;

	Template = new class'X2AvengerAnimationTemplate';
	Template.SetTemplateName('HangingOutAtTheCore');
	Template.EligibleFacilities.AddItem('PowerCore');
	Template.Weight = 25;
	
	Character.CharacterType = eStaff_Soldier;
	Character.PercentChance = 100;

	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	Slot.EligibleCharacters.Length = 0;
	Slot.EligibleCharacters.AddItem(Character);
	Slot.IsMandatory = true;
	Template.AnimationSlots.AddItem(Slot);

	return Template;
}

