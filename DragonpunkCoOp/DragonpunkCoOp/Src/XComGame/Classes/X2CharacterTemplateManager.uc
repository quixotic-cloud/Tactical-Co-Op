//---------------------------------------------------------------------------------------
//  FILE:    X2CharacterTemplateManager.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2CharacterTemplateManager extends X2DataTemplateManager
	native(Core);

var protectedwrite int StandardActionsPerTurn;
var name StandardActionPoint;
var name MoveActionPoint;
var name OverwatchReserveActionPoint, PistolOverwatchReserveActionPoint;
var name GremlinActionPoint;
var name RunAndGunActionPoint;
var name EndBindActionPoint;
var name GOHBindActionPoint;
var name CounterattackActionPoint;
var name UnburrowActionPoint;
var name ReturnFireActionPoint;
var name DeepCoverActionPoint;

var protectedwrite X2CommanderLookupTableManager  CommanderLookupTableManager;

native static function X2CharacterTemplateManager GetCharacterTemplateManager();

protected event ValidateTemplatesEvent()
{
	super.ValidateTemplatesEvent();

	CommanderLookupTableManager = new class'X2CommanderLookupTableManager';
	CommanderLookupTableManager.Init();
}

function bool AddCharacterTemplate(X2CharacterTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2CharacterTemplate FindCharacterTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2CharacterTemplate(kTemplate);
	return none;
}

function LoadAllContent()
{
	local X2DataTemplate Template;
	local X2CharacterTemplate CharacterTemplate;
	local XComContentManager ContentMgr;
	local int Index;

	ContentMgr = `CONTENT;
	foreach IterateTemplates(Template, none)
	{
		CharacterTemplate = X2CharacterTemplate(Template);
		for(Index = 0; Index < CharacterTemplate.strPawnArchetypes.Length; ++Index)
		{
			ContentMgr.RequestGameArchetype(CharacterTemplate.strPawnArchetypes[Index], none, none, true);
		}
	}
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2Character'
	StandardActionsPerTurn=2
	StandardActionPoint="standard"
	MoveActionPoint="move"
	OverwatchReserveActionPoint="overwatch"
	PistolOverwatchReserveActionPoint="pistoloverwatch"
	GremlinActionPoint="gremlin"
	RunAndGunActionPoint="runandgun"
	EndBindActionPoint="endbind"
	GOHBindActionPoint="gohbind"
	CounterattackActionPoint="counterattack"
	UnburrowActionPoint="unburrow"
	ReturnFireActionPoint="returnfire"
	DeepCoverActionPoint="deepcover"
}