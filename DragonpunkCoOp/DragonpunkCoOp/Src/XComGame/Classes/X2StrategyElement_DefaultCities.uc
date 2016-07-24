//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultCities.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultCities extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Cities;

	// U.S.A. Cities
	Cities.AddItem(CreateNewYorkTemplate());
	Cities.AddItem(CreateMiamiTemplate());
	Cities.AddItem(CreateBaltimoreTemplate());
	Cities.AddItem(CreateLosAngelesTemplate());
	Cities.AddItem(CreateSeattleTemplate());
	Cities.AddItem(CreateSanFransiscoTemplate());
	Cities.AddItem(CreateChicagoTemplate());
	Cities.AddItem(CreateHoustonTemplate());
	Cities.AddItem(CreateDallasTemplate());
	Cities.AddItem(CreateKansasCityTemplate());

	// CANADA Cities
	Cities.AddItem(CreateMontrealTemplate());
	Cities.AddItem(CreateEdmontonTemplate());
	Cities.AddItem(CreateTorontoTemplate());
	Cities.AddItem(CreateVancouverTemplate());
	Cities.AddItem(CreateCalgaryTemplate());
	Cities.AddItem(CreateOttawaTemplate());
	Cities.AddItem(CreateStJohnsTemplate());

	// MEXICO Cities
	Cities.AddItem(CreateMexicoCityTemplate());
	Cities.AddItem(CreateChihuahuaTemplate());
	Cities.AddItem(CreateTijuanaTemplate());
	Cities.AddItem(CreateAcapulcoTemplate());
	Cities.AddItem(CreateGuadalajaraTemplate());
	Cities.AddItem(CreateLeonTemplate());

	// COLUMBIA Cities
	Cities.AddItem(CreateBogotaTemplate());

	// ARGENTINA Cities
	Cities.AddItem(CreateBuenosAiresTemplate());
	Cities.AddItem(CreateCordobaTemplate());
	Cities.AddItem(CreateMendozaTemplate());
	Cities.AddItem(CreateRosarioTemplate());

	// BRAZIL Cities
	Cities.AddItem(CreateSaoPauloTemplate());
	Cities.AddItem(CreateRioDeJaneiroTemplate());
	Cities.AddItem(CreateSalvadorTemplate());
	Cities.AddItem(CreateBrasiliaTemplate());
	Cities.AddItem(CreateManausTemplate());
	Cities.AddItem(CreateFortalezaTemplate());

	// U.K. Cities
	Cities.AddItem(CreateLondonTemplate());
	Cities.AddItem(CreateBirminghamTemplate());
	Cities.AddItem(CreateGlasgowTemplate());
	Cities.AddItem(CreateLiverpoolTemplate());
	Cities.AddItem(CreateManchesterTemplate());
	Cities.AddItem(CreateLeedsTemplate());

	// FRANCE Cities
	Cities.AddItem(CreateParisTemplate());
	Cities.AddItem(CreateLyonsTemplate());
	Cities.AddItem(CreateMarseilleTemplate());
	Cities.AddItem(CreateLilleTemplate());

	// GERMANY Cities
	Cities.AddItem(CreateBerlinTemplate());
	Cities.AddItem(CreateHamburgTemplate());
	Cities.AddItem(CreateMunichTemplate());
	Cities.AddItem(CreateCologneTemplate());

	// RUSSIA Cities
	Cities.AddItem(CreateMoscowTemplate());
	Cities.AddItem(CreateNovgorodTemplate());
	Cities.AddItem(CreateVolgogradTemplate());
	Cities.AddItem(CreateSaintPetersburgTemplate());

	// INDIA Cities
	Cities.AddItem(CreateMumbaiTemplate());
	Cities.AddItem(CreateDelhiTemplate());
	Cities.AddItem(CreateBangaloreTemplate());
	Cities.AddItem(CreateKolkataTemplate());

	// JAPAN Cities
	Cities.AddItem(CreateTokyoTemplate());
	Cities.AddItem(CreateOsakaTemplate());
	Cities.AddItem(CreateNagoyaTemplate());
	Cities.AddItem(CreateSapporoTemplate());
	Cities.AddItem(CreateFukuokaTemplate());

	// AUSTRALIA Cities
	Cities.AddItem(CreateSydneyTemplate());
	Cities.AddItem(CreateMelbourneTemplate());
	Cities.AddItem(CreateBrisbaneTemplate());
	Cities.AddItem(CreatePerthTemplate());

	// CHINA Cities
	Cities.AddItem(CreateHongKongTemplate());
	Cities.AddItem(CreateBeijingTemplate());
	Cities.AddItem(CreateShanghaiTemplate());
	Cities.AddItem(CreateGuangzhouTemplate());
	Cities.AddItem(CreateChongqingTemplate());

	// NIGERIA Cities
	Cities.AddItem(CreateLagosTemplate());
	Cities.AddItem(CreateKanoTemplate());
	Cities.AddItem(CreateIbadanTemplate());
	Cities.AddItem(CreateKadunaTemplate());
	Cities.AddItem(CreatePortHarcourtTemplate());
	Cities.AddItem(CreateBeninCityTemplate());

	// SOUTH AFRICA Cities
	Cities.AddItem(CreateJohannesburgTemplate());
	Cities.AddItem(CreatePretoriaTemplate());
	Cities.AddItem(CreateDurbanTemplate());
	Cities.AddItem(CreateCapeTownTemplate());
	Cities.AddItem(CreatePortElizabethTemplate());
	Cities.AddItem(CreateBloemfonteinTemplate());

	// EGYPT Cities
	Cities.AddItem(CreateCairoTemplate());
	Cities.AddItem(CreateAlexandriaTemplate());
	Cities.AddItem(CreatePortSaidTemplate());

	return Cities;
}
// #######################################################################################
// -------------------- U.S.A. Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateNewYorkTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'NewYork');

	Template.Location.x = 0.298;
	Template.Location.y = 0.270;

	return Template;
}
static function X2DataTemplate CreateMiamiTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Miami');

	Template.Location.x = 0.277;
	Template.Location.y = 0.357;

	return Template;
}
static function X2DataTemplate CreateBaltimoreTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Baltimore');
	
	Template.Location.x = 0.287;
	Template.Location.y = 0.283;

	return Template;
}
static function X2DataTemplate CreateLosAngelesTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'LosAngeles');
	
	Template.Location.x = 0.17;
	Template.Location.y = 0.310;

	return Template;
}
static function X2DataTemplate CreateSeattleTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Seattle');
	
	Template.Location.x = 0.160;
	Template.Location.y = 0.231;

	return Template;
}
static function X2DataTemplate CreateSanFransiscoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'SanFransisco');
	
	Template.Location.x = 0.158;
	Template.Location.y = 0.284;

	return Template;
}
static function X2DataTemplate CreateChicagoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Chicago');
	
	Template.Location.x = 0.257;
	Template.Location.y = 0.267;

	return Template;
}
static function X2DataTemplate CreateHoustonTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Houston');
	
	Template.Location.x = 0.231;
	Template.Location.y = 0.340;

	return Template;
}
static function X2DataTemplate CreateDallasTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Dallas');
	
	Template.Location.x = 0.228;
	Template.Location.y = 0.324;

	return Template;
}
static function X2DataTemplate CreateKansasCityTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'KansasCity');
	
	Template.Location.x = 0.237;
	Template.Location.y = 0.293;

	return Template;
}
// #######################################################################################
// -------------------- CANADA Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateMontrealTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Montreal');
	
	Template.Location.x = 0.299;
	Template.Location.y = 0.245;

	return Template;
}
static function X2DataTemplate CreateEdmontonTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Edmonton');
	
	Template.Location.x = 0.183;
	Template.Location.y = 0.183;

	return Template;
}
static function X2DataTemplate CreateTorontoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Toronto');
	
	Template.Location.x = 0.28;
	Template.Location.y = 0.256;

	return Template;
}
static function X2DataTemplate CreateVancouverTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Vancouver');
	
	Template.Location.x = 0.157;
	Template.Location.y = 0.223;
	
	return Template;
}
static function X2DataTemplate CreateCalgaryTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Calgary');
	
	Template.Location.x = 0.182;
	Template.Location.y = 0.212;

	return Template;
}
static function X2DataTemplate CreateOttawaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Ottawa');
	
	Template.Location.x = 0.288;

	return Template;
}
static function X2DataTemplate CreateStJohnsTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'StJohns');
	
	Template.Location.x = 0.353;
	Template.Location.y = 0.236;

	return Template;
}
// #######################################################################################
// -------------------- MEXICO Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateMexicoCityTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'MexicoCity');
	
	Template.Location.x = 0.221;
	Template.Location.y = 0.388;

	return Template;
}
static function X2DataTemplate CreateChihuahuaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Chihuahua');
	
	Template.Location.x = 0.209;
	Template.Location.y = 0.340;

	return Template;
}
static function X2DataTemplate CreateTijuanaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Tijuana');
	
	Template.Location.x = 0.176;
	Template.Location.y = 0.319;

	return Template;
}
static function X2DataTemplate CreateAcapulcoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Acapulco');
	
	Template.Location.x = 0.221;
	Template.Location.y = 0.404;

	return Template;
}
static function X2DataTemplate CreateGuadalajaraTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Guadalajara');
	
	Template.Location.x = 0.212;
	Template.Location.y = 0.385;

	return Template;
}
static function X2DataTemplate CreateLeonTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Leon');
	
	Template.Location.x = 0.217;
	Template.Location.y = 0.379;

	return Template;
}
// #######################################################################################
// -------------------- COLUMBIA Cities --------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateBogotaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Bogota');
	
	Template.Location.x = 0.294;
	Template.Location.y = 0.470;

	return Template;
}
// #######################################################################################
// -------------------- ARGENTINA Cities -------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateBuenosAiresTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'BuenosAires');
	
	Template.Location.x = 0.337;
	Template.Location.y = 0.694;

	return Template;
}
static function X2DataTemplate CreateCordobaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Cordoba');
	
	Template.Location.x = 0.324;
	Template.Location.y = 0.673;

	return Template;
}
static function X2DataTemplate CreateMendozaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Mendoza');
	
	Template.Location.x = 0.312;
	Template.Location.y = 0.680;

	return Template;
}
static function X2DataTemplate CreateRosarioTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Rosario');
	
	Template.Location.x = 0.333;
	Template.Location.y = 0.681;

	return Template;
}
// #######################################################################################
// -------------------- BRAZIL Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateSaoPauloTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'SaoPaulo');
	
	Template.Location.x = 0.367;
	Template.Location.y = 0.632;

	return Template;
}
static function X2DataTemplate CreateRioDeJaneiroTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'RioDeJaneiro');
	
	Template.Location.x = 0.379;
	Template.Location.y = 0.627;

	return Template;
}
static function X2DataTemplate CreateSalvadorTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Salvador');
	
	Template.Location.x = 0.391;
	Template.Location.y = 0.570;

	return Template;
}
static function X2DataTemplate CreateBrasiliaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Brasilia');
	
	Template.Location.x = 0.370;
	Template.Location.y = 0.579;

	return Template;
}
static function X2DataTemplate CreateManausTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Manaus');
	
	Template.Location.x = 0.340;
	Template.Location.y = 0.516;

	return Template;
}
static function X2DataTemplate CreateFortalezaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Fortaleza');
	
	Template.Location.x = 0.392;
	Template.Location.y = 0.519;

	return Template;
}
// #######################################################################################
// -------------------- U.K. Cities ------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateLondonTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'London');
	
	Template.Location.x = 0.501;
	Template.Location.y = 0.215;

	return Template;
}
static function X2DataTemplate CreateBirminghamTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Birmingham');
	
	Template.Location.x = 0.494;
	Template.Location.y = 0.210;

	return Template;
}
static function X2DataTemplate CreateGlasgowTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Glasgow');
	
	Template.Location.x = 0.489;
	Template.Location.y = 0.191;

	return Template;
}
static function X2DataTemplate CreateLiverpoolTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Liverpool');
	
	Template.Location.x = 0.492;
	Template.Location.y = 0.201;

	return Template;
}
static function X2DataTemplate CreateManchesterTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Manchester');
	
	Template.Location.x = 0.494;
	Template.Location.y = 0.200;

	return Template;
}
static function X2DataTemplate CreateLeedsTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Leeds');
	
	Template.Location.x = 0.495;
	Template.Location.y = 0.198;

	return Template;
}
// #######################################################################################
// -------------------- FRANCE Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateParisTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Paris');
	
	Template.Location.x = 0.504;
	Template.Location.y = 0.230;

	return Template;
}
static function X2DataTemplate CreateLyonsTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Lyons');
	
	Template.Location.x = 0.512;
	Template.Location.y = 0.246;

	return Template;
}
static function X2DataTemplate CreateMarseilleTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Marseille');
	
	Template.Location.x = 0.514;
	Template.Location.y = 0.258;

	return Template;
}
static function X2DataTemplate CreateLilleTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Lille');
	
	Template.Location.x = 0.507;
	Template.Location.y = 0.222;

	return Template;
}
// #######################################################################################
// -------------------- GERMANY Cities ---------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateBerlinTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Berlin');
	
	Template.Location.x = 0.536;
	Template.Location.y = 0.208;

	return Template;
}
static function X2DataTemplate CreateHamburgTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Hamburg');
	
	Template.Location.x = 0.527;
	Template.Location.y = 0.201;

	return Template;
}
static function X2DataTemplate CreateMunichTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Munich');
	
	Template.Location.x = 0.532;
	Template.Location.y = 0.231;

	return Template;
}
static function X2DataTemplate CreateCologneTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Cologne');
	
	Template.Location.x = 0.521;
	Template.Location.y = 0.218;

	return Template;
}
// #######################################################################################
// -------------------- RUSSIA Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateMoscowTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Moscow');
	
	Template.Location.x = 0.6;
	Template.Location.y = 0.180;

	return Template;
}
static function X2DataTemplate CreateNovgorodTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Novgorod');
	
	Template.Location.x = 0.621;
	Template.Location.y = 0.178;

	return Template;
}
static function X2DataTemplate CreateVolgogradTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Volgograd');
	
	Template.Location.x = 0.624;
	Template.Location.y = 0.226;

	return Template;
}
static function X2DataTemplate CreateSaintPetersburgTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'SaintPetersburg');
	
	Template.Location.x = 0.582;
	Template.Location.y = 0.169;

	return Template;
}
// #######################################################################################
// -------------------- INDIA Cities ----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateMumbaiTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Mumbai');
	
	Template.Location.x = 0.703;
	Template.Location.y = 0.390;

	return Template;
}
static function X2DataTemplate CreateDelhiTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Delhi');
	
	Template.Location.x = 0.713;
	Template.Location.y = 0.339;

	return Template;
}
static function X2DataTemplate CreateBangaloreTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Bangalore');
	
	Template.Location.x = 0.716;
	Template.Location.y = 0.433;

	return Template;
}
static function X2DataTemplate CreateKolkataTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Kolkata');
	
	Template.Location.x = 0.744;
	Template.Location.y = 0.372;

	return Template;
}
// #######################################################################################
// -------------------- JAPAN Cities -----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateTokyoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Tokyo');
	
	Template.Location.x = 0.888;
	Template.Location.y = 0.300;

	return Template;
}
static function X2DataTemplate CreateOsakaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Osaka');
	
	Template.Location.x = 0.877;
	Template.Location.y = 0.309;

	return Template;
}
static function X2DataTemplate CreateNagoyaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Nagoya');
	
	Template.Location.x = 0.880;
	Template.Location.y = 0.304;

	return Template;
}
static function X2DataTemplate CreateSapporoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Sapporo');
	
	Template.Location.x = 0.893;
	Template.Location.y = 0.260;

	return Template;
}
static function X2DataTemplate CreateFukuokaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Fukuoka');
	
	Template.Location.x = 0.862;
	Template.Location.y = 0.313;

	return Template;
}
// #######################################################################################
// -------------------- AUSTRALIA Cities -------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateSydneyTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Sydney');
	
	Template.Location.x = 0.920;
	Template.Location.y = 0.684;

	return Template;
}
static function X2DataTemplate CreateMelbourneTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Melbourne');
	
	Template.Location.x = 0.903;
	Template.Location.y = 0.707;

	return Template;
}
static function X2DataTemplate CreateBrisbaneTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Brisbane');
	
	Template.Location.x = 0.924;
	Template.Location.y = 0.648;

	return Template;
}
static function X2DataTemplate CreatePerthTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Perth');
	
	Template.Location.x = 0.823;
	Template.Location.y = 0.678;

	return Template;
}
// #######################################################################################
// -------------------- CHINA Cities -----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateHongKongTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'HongKong');
	
	Template.Location.x = 0.817;
	Template.Location.y = 0.374;

	return Template;
}
static function X2DataTemplate CreateBeijingTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Beijing');
	
	Template.Location.x = 0.825;
	Template.Location.y = 0.276;

	return Template;
}
static function X2DataTemplate CreateShanghaiTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Shanghai');
	
	Template.Location.x = 0.837;
	Template.Location.y = 0.328;

	return Template;
}
static function X2DataTemplate CreateGuangzhouTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Guangzhou');
	
	Template.Location.x = 0.814;
	Template.Location.y = 0.371;

	return Template;
}
static function X2DataTemplate CreateChongqingTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Chongqing');
	
	Template.Location.x = 0.798;
	Template.Location.y = 0.341;

	return Template;
}
// #######################################################################################
// -------------------- NIGERIA Cities ---------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateLagosTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Lagos');
	
	Template.Location.x = 0.509;
	Template.Location.y = 0.463;

	return Template;
}
static function X2DataTemplate CreateKanoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Kano');
	
	Template.Location.x = 0.525;
	Template.Location.y = 0.433;

	return Template;
}
static function X2DataTemplate CreateIbadanTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Ibadan');
	
	Template.Location.x = 0.512;
	Template.Location.y = 0.456;

	return Template;
}
static function X2DataTemplate CreateKadunaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Kaduna');
	
	Template.Location.x = 0.521;
	Template.Location.y = 0.442;

	return Template;
}
static function X2DataTemplate CreatePortHarcourtTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'PortHarcourt');
	
	Template.Location.x = 0.519;
	Template.Location.y = 0.473;

	return Template;
}
static function X2DataTemplate CreateBeninCityTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'BeninCity');
	
	Template.Location.x = 0.516;
	Template.Location.y = 0.465;

	return Template;
}
// #######################################################################################
// -------------------- SOUTH AFRICA Cities ----------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateJohannesburgTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Johannesburg');
	
	Template.Location.x = 0.578;
	Template.Location.y = 0.644;

	return Template;
}
static function X2DataTemplate CreatePretoriaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Pretoria');
	
	Template.Location.x = 0.579;
	Template.Location.y = 0.642;

	return Template;
}
static function X2DataTemplate CreateDurbanTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Durban');
	
	Template.Location.x = 0.584;
	Template.Location.y = 0.669;

	return Template;
}
static function X2DataTemplate CreateCapeTownTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'CapeTown');
	
	Template.Location.x = 0.552;
	Template.Location.y = 0.688;

	return Template;
}
static function X2DataTemplate CreatePortElizabethTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'PortElizabeth');
	
	Template.Location.x = 0.570;
	Template.Location.y = 0.687;

	return Template;
}
static function X2DataTemplate CreateBloemfonteinTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Bloemfontein');
	
	Template.Location.x = 0.570;
	Template.Location.y = 0.660;

	return Template;
}
// #######################################################################################
// -------------------- EGYPT Cities -----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateCairoTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Cairo');
	
	Template.Location.x = 0.586;
	Template.Location.y = 0.340;

	return Template;
}
static function X2DataTemplate CreateAlexandriaTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'Alexandria');
	
	Template.Location.x = 0.584;
	Template.Location.y = 0.328;

	return Template;
}
static function X2DataTemplate CreatePortSaidTemplate()
{
	local X2CityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2CityTemplate', Template, 'PortSaid');
	
	Template.Location.x = 0.591;
	Template.Location.y = 0.328;

	return Template;
}