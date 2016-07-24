//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionSet.uc
//  AUTHOR:  Brian Whitman --  4/3/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionSet extends X2Mission config(GameCore);

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2MissionTemplate> Templates;

    Templates.AddItem(AddMissionTemplate('RecoverItem'));
    Templates.AddItem(AddMissionTemplate('RecoverItemADV'));
    Templates.AddItem(AddMissionTemplate('RecoverItemTrain'));
    Templates.AddItem(AddMissionTemplate('RecoverItemVehicle'));
    Templates.AddItem(AddMissionTemplate('RecoverFlightDevice'));
    Templates.AddItem(AddMissionTemplate('HackWorkstation'));
    Templates.AddItem(AddMissionTemplate('HackWorkstationADV'));
    Templates.AddItem(AddMissionTemplate('HackWorkstationTrain'));
    Templates.AddItem(AddMissionTemplate('Eradicate'));
    Templates.AddItem(AddMissionTemplate('SupplyLineRaidATT'));
    Templates.AddItem(AddMissionTemplate('SupplyLineRaidTrain'));
    Templates.AddItem(AddMissionTemplate('SupplyLineRaidConvoy'));
    Templates.AddItem(AddMissionTemplate('DestroyRelay'));
    Templates.AddItem(AddMissionTemplate('ProtectDevice'));
    Templates.AddItem(AddMissionTemplate('ExtractVIP'));
    Templates.AddItem(AddMissionTemplate('RescueVIP'));
    Templates.AddItem(AddMissionTemplate('RescueVIPVehicle'));
    Templates.AddItem(AddMissionTemplate('NeutralizeTarget'));
    Templates.AddItem(AddMissionTemplate('NeutralizeTargetVehicle'));
    Templates.AddItem(AddMissionTemplate('AdventFacilityBLACKSITE'));
    Templates.AddItem(AddMissionTemplate('AdventFacilityFORGE'));
    Templates.AddItem(AddMissionTemplate('AdventFacilityPSIGATE'));
    Templates.AddItem(AddMissionTemplate('CentralNetworkBroadcast'));
    Templates.AddItem(AddMissionTemplate('AssaultAlienFortress'));
    Templates.AddItem(AddMissionTemplate('SecureUFO'));
    Templates.AddItem(AddMissionTemplate('SabotageAlienFacility'));
    Templates.AddItem(AddMissionTemplate('SabotageAdventMonument'));
    Templates.AddItem(AddMissionTemplate('SeizeFacility'));
    Templates.AddItem(AddMissionTemplate('Terror'));
    Templates.AddItem(AddMissionTemplate('AvengerDefense'));
    Templates.AddItem(AddMissionTemplate('TutorialRescueCommander'));
    Templates.AddItem(AddMissionTemplate('DemoRescueMajTanaka'));
    Templates.AddItem(AddMissionTemplate('TestingMission'));
    Templates.AddItem(AddMissionTemplate('DefeatHumanOpponent'));

    return Templates;
}

static function X2MissionTemplate AddMissionTemplate(name missionName)
{
    local X2MissionTemplate Template;
	`CREATE_X2TEMPLATE(class'X2MissionTemplate', Template, missionName);
    return Template;
}
