//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeTemplateManager.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeTemplateManager extends X2DataTemplateManager
	native(Core);

native static function X2ChallengeTemplateManager GetChallengeTemplateManager( );

function X2ChallengeTemplate FindChallengeTemplate( name DataName )
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate( DataName );
	if (kTemplate != none)
	{
		return X2ChallengeTemplate( kTemplate );
	}
	return none;
}

function array<X2ChallengeTemplate> GetAllTemplatesOfClass( class<X2ChallengeTemplate> TemplateClass )
{
	local array<X2ChallengeTemplate> arrTemplates;
	local X2DataTemplate Template;

	foreach IterateTemplates( Template, none )
	{
		if (ClassIsChildOf( Template.Class, TemplateClass ))
		{
			arrTemplates.AddItem( X2ChallengeTemplate( Template ) );
		}
	}

	return arrTemplates;
}

function X2ChallengeTemplate GetRandomChallengeTemplateOfClass( class<X2ChallengeTemplate> TemplateClass )
{
	local array<X2ChallengeTemplate> AllClass;
	local X2ChallengeTemplate Template;
	local int TotalWeight;
	local int RandomWeight;

	AllClass = GetAllTemplatesOfClass( TemplateClass );

	TotalWeight = 0;
	foreach AllClass( Template )
	{
		TotalWeight += Template.Weight;
	}

	RandomWeight = `SYNC_RAND_STATIC(TotalWeight);

	foreach AllClass( Template )
	{
		if (RandomWeight < Template.weight)
		{
			return Template;
		}

		RandomWeight -= Template.Weight;
	}
}

DefaultProperties
{
	TemplateDefinitionClass = class'X2ChallengeElement';
}