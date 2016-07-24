//---------------------------------------------------------------------------------------
//  FILE:    X2Character.uc
//  AUTHOR:  Joshua Bouscher  --  12/13/2013
//  PURPOSE: Interface for adding new characters to X-Com 2. Extend this class and then
//           implement CreateCharacterTemplates to produce one or more character templates
//           definining new characters.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Character extends X2DataSet;

static event array<X2DataTemplate> CreateCharacterTemplatesEvent()
{
	return CreateCharacterTemplates();
}

static function array<X2DataTemplate> CreateCharacterTemplates();