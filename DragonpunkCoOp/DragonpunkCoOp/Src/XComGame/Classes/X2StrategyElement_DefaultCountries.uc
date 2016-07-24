//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultCountries.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultCountries extends X2StrategyElement
	dependson(X2CountryTemplate, XGCharacterGenerator);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Countries;
	
	Countries.AddItem(CreateUSATemplate());
	Countries.AddItem(CreateRussiaTemplate());
	Countries.AddItem(CreateChinaTemplate());
	Countries.AddItem(CreateUKTemplate());
	Countries.AddItem(CreateGermanyTemplate());
	Countries.AddItem(CreateFranceTemplate());
	Countries.AddItem(CreateJapanTemplate());
	Countries.AddItem(CreateIndiaTemplate());
	Countries.AddItem(CreateAustraliaTemplate());
	Countries.AddItem(CreateItalyTemplate());
	Countries.AddItem(CreateSouthKoreaTemplate());
	Countries.AddItem(CreateTurkeyTemplate());
	Countries.AddItem(CreateIndonesiaTemplate());
	Countries.AddItem(CreateSpainTemplate());
	Countries.AddItem(CreatePakistanTemplate());
	Countries.AddItem(CreateCanadaTemplate());
	Countries.AddItem(CreateIranTemplate());
	Countries.AddItem(CreateIsraelTemplate());
	Countries.AddItem(CreateEgyptTemplate());
	Countries.AddItem(CreateBrazilTemplate());
	Countries.AddItem(CreateArgentinaTemplate());
	Countries.AddItem(CreateMexicoTemplate());
	Countries.AddItem(CreateSouthAfricaTemplate());
	Countries.AddItem(CreatePolandTemplate());
	Countries.AddItem(CreateUkraineTemplate());
	Countries.AddItem(CreateNigeriaTemplate());
	Countries.AddItem(CreateVenezuelaTemplate());
	Countries.AddItem(CreateGreeceTemplate());
	Countries.AddItem(CreateColumbiaTemplate());
	Countries.AddItem(CreatePortugalTemplate());
	Countries.AddItem(CreateSwedenTemplate());
	Countries.AddItem(CreateIrelandTemplate());
	Countries.AddItem(CreateScotlandTemplate());
	Countries.AddItem(CreateNorwayTemplate());
	Countries.AddItem(CreateNetherlandsTemplate());
	Countries.AddItem(CreateBelgiumTemplate());

	return Countries;
}

static function X2DataTemplate CreateUSATemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_USA');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAmMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAmFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateRussiaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Russia');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrRsMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrRsFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrRsMLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrRsFLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateChinaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_China');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrChMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrChFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrChLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrChLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateUKTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_UK');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrEnMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrEnFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrEnLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrEnLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateGermanyTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Germany');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrGmMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrGmFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrGmLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrGmLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateFranceTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_France');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrFrMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrFrFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrFrLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrFrLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateJapanTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Japan');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrJpMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrJpFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrJpLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrJpLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateIndiaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_India');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrInMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrInFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrInLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrInLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateAustraliaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Australia');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAuMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAuFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAuLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAuLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateItalyTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Italy');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrItMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrItFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrItLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrItLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateSouthKoreaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_SouthKorea');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrSkMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrSkFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrSkLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrSkLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateTurkeyTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Turkey');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAmMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAmFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateIndonesiaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Indonesia');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAmMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAmFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateSpainTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Spain');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrEsMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrEsFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrEsLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrEsLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreatePakistanTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Pakistan');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrInMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrInFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrInLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrInLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateCanadaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct, EmptyNames;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Canada');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAmMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAmFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAmLastNames;
	NameStruct.PercentChance = 75;
	Template.Names.AddItem(NameStruct);

	NameStruct = EmptyNames;
	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrFrMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrFrFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrFrLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrFrLastNames;
	NameStruct.PercentChance = 25;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateIranTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Iran');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAbMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAbFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAbLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAbLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateIsraelTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Israel');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrIsMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrIsFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrIsLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrIsLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateEgyptTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Egypt');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAbMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAbFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAbLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAbLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateBrazilTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Brazil');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrMxMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrMxFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateArgentinaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Argentina');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrMxMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrMxFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateMexicoTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Mexico');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrMxMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrMxFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateSouthAfricaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct, EmptyNames;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_SouthAfrica');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAfMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAfFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAfLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAfLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	NameStruct = EmptyNames;
	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrDuMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrDuFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrDuLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrDuLastNames;
	NameStruct.PercentChance = 50;
	NameStruct.bRaceSpecific = true;
	NameStruct.Race = eRace_Caucasian;
	Template.Names.AddItem(NameStruct);

	NameStruct = EmptyNames;
	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrEnMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrEnFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrEnLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrEnLastNames;
	NameStruct.PercentChance = 50;
	NameStruct.bRaceSpecific = true;
	NameStruct.Race = eRace_Caucasian;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreatePolandTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Poland');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrPlMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrPlFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrPlMLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrPlFLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateUkraineTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Ukraine');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrRsMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrRsFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrRsMLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrRsFLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateNigeriaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Nigeria');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrAfMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrAfFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrAfLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrAfLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateVenezuelaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Venezuela');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrMxMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrMxFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateGreeceTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Greece');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrGrMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrGrFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrGrLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrGrLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateColumbiaTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Columbia');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrMxMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrMxFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrMxLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreatePortugalTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Portugal');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrEsMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrEsFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrEsLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrEsLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateSwedenTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Sweden');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrNwMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrNwFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrNwLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrNwLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateIrelandTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Ireland');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrIrMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrIrFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrIrLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrIrLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateScotlandTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Scotland');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrScMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrScFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrScLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrScLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateNorwayTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Norway');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrNwMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrNwFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrNwLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrNwLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateNetherlandsTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Netherlands');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrDuMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrDuFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrDuLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrDuLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}

static function X2DataTemplate CreateBelgiumTemplate()
{
	local X2CountryTemplate Template;
	local CountryNames NameStruct;

	`CREATE_X2TEMPLATE(class'X2CountryTemplate', Template, 'Country_Belgium');

	NameStruct.MaleNames = class'XGCharacterGenerator'.default.m_arrBgMFirstNames;
	NameStruct.FemaleNames = class'XGCharacterGenerator'.default.m_arrBgFFirstNames;
	NameStruct.MaleLastNames = class'XGCharacterGenerator'.default.m_arrBgLastNames;
	NameStruct.FemaleLastNames = class'XGCharacterGenerator'.default.m_arrBgLastNames;
	NameStruct.PercentChance = 100;
	Template.Names.AddItem(NameStruct);

	return Template;
}