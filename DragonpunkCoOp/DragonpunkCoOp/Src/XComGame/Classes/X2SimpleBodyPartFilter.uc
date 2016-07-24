//---------------------------------------------------------------------------------------
//  FILE:    X2BodyPartFilter.uc
//  AUTHOR:  Ned Way
//  PURPOSE: Unified way to sort body parts for all the systems that need that functionality
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SimpleBodyPartFilter extends X2BodyPartFilter;

var protectedwrite EGender Gender;
var protectedwrite ECharacterRace Race;
var protectedwrite X2BodyPartTemplate TorsoTemplate;
var protectedwrite name ArmorName;
var protectedwrite name CharacterName;
var protectedwrite array<name> DLCNames;
var protectedwrite bool bCivilian;
var protectedwrite bool bVeteran;
var protectedwrite bool bAllowAllDLCContent;

//Used for initial torso selection
var protectedwrite name MatchCharacterTemplateForTorso;
var protectedwrite name MatchArmorTemplateForTorso;

function Set(EGender inGender, ECharacterRace inRace, name inTorsoTemplateName, bool bIsCivilian = false, bool bIsVeteran = false, optional array<name> SetDLCNames)
{
	Gender = inGender;
	Race = inRace;
	bCivilian = bIsCivilian;
	bVeteran = bIsVeteran;

	if (inTorsoTemplateName != '')
	{
		TorsoTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().FindUberTemplate("Torso", inTorsoTemplateName);
		ArmorName = TorsoTemplate.ArmorTemplate;
	}
	else
	{
		ArmorName = '';
	}

	DLCNames.Length = 0;
	DLCNames = SetDLCNames;	
}

function AddDLCPackFilter(name DLCPackName)
{
	DLCNames.AddItem(DLCPackName);	
}

function SetTorsoSelection(name InMatchCharacterTemplateForTorso, name InMatchArmorTemplateForTorso)
{
	MatchCharacterTemplateForTorso = InMatchCharacterTemplateForTorso;
	MatchArmorTemplateForTorso = InMatchArmorTemplateForTorso;
}

function AddCharacterFilter(Name InCharacterName)
{
	CharacterName = InCharacterName;
}

function bool FilterAny( X2BodyPartTemplate Template )
{
	return true;
}

// Specialized filter method for building a character from scratch
function bool FilterTorso(X2BodyPartTemplate Template)
{
	return	FilterByGenderAndNonSpecialized(Template) &&
		    (Template.ArmorTemplate == MatchArmorTemplateForTorso || Template.CharacterTemplate == MatchCharacterTemplateForTorso);
}

function bool FilterByGender(X2BodyPartTemplate Template)
{
	return Template.Gender == eGender_None || Template.Gender == Gender;
}

function bool FilterByRace(X2BodyPartTemplate Template)
{
	return Template.Race == ECharacterRace(Race);
}

function bool FilterByNonSpecialized(X2BodyPartTemplate Template)
{
	local int Index;
	local bool bDLCNameValid;

	bDLCNameValid = DLCNames.Length == 0 || Template.DLCName == '';
	if(!bDLCNameValid)
	{
		//The template is part of a pack, see if the pack is in our list
		for(Index = 0; Index < DLCNames.Length; ++Index)
		{
			if(DLCNames[Index] == Template.DLCName)
			{
				bDLCNameValid = true;
				break;
			}
		}
	}
	
	return Template.SpecializedType == false && (!Template.bVeteran || bVeteran) && bDLCNameValid;
}

function bool FilterByCivilian(X2BodyPartTemplate Template)
{
	return !bCivilian || Template.bCanUseOnCivilian;
}

function bool FilterByArmor(X2BodyPartTemplate Template)
{
	return Template.ArmorTemplate == '' || Template.ArmorTemplate == ArmorName;
}

function bool FilterByCharacter(X2BodyPartTemplate Template)
{
	return Template.CharacterTemplate == '' || Template.CharacterTemplate == CharacterName;
}

function bool FilterByTech(X2BodyPartTemplate Template)
{
	local X2TechTemplate TechTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2StrategyElementTemplateManager StratMgr;	
	
	//Automatically pass if no tech is specified
	if (Template.Tech != '')
	{
		//Fetch the tech required
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(Template.Tech));
		if (TechTemplate != none)
		{
			//See if it has been researched
			History = `XCOMHISTORY;
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none)
			{
				if (XComHQ.IsTechResearched(TechTemplate.DataName))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false; //No HQ, no tech and no body part allowed
			}
		}
	}
	
	return true;
}

function bool FilterByGenderAndRace(X2BodyPartTemplate Template)
{
	return	FilterByGender(Template) && FilterByRace(Template) && FilterByNonSpecialized(Template);
}

function bool FilterByGenderAndRaceAndCharacter(X2BodyPartTemplate Template)
{
	return FilterByGenderAndRace(Template) && FilterByCharacter(Template);
}

function bool FilterByGenderAndRaceAndCharacterAndTech(X2BodyPartTemplate Template)
{
	return FilterByGenderAndRaceAndCharacter(Template) && FilterByTech(Template);
}

function bool FilterByGenderAndNonSpecialized(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template);
}

function bool FilterByGenderAndCharacterAndNonSpecialized(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByCharacter(Template) && FilterByNonSpecialized(Template);
}

function bool FilterByGenderAndNonSpecializedCivilian(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template) && FilterByCivilian(Template);
}

function bool FilterByGenderAndCharacterAndNonSpecializedAndTech(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByCharacter(Template) && FilterByNonSpecialized(Template) && FilterByTech(Template);
}

function bool FilterByGenderAndNonSpecializedAndTechAndArmor(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template) && FilterByTech(Template) && FilterByArmor(Template);
}

function bool FilterByGenderAndRaceAndArmor(X2BodyPartTemplate Template)
{
	return FilterByGenderAndRace(Template) && FilterByArmor(Template);
}

function bool FilterByTorsoAndArmorMatch(X2BodyPartTemplate Template)
{
	local bool bMatched;
	local int Index;

	if (Template == None || TorsoTemplate == None)
		return false;

	bMatched = FilterByGenderAndNonSpecialized(Template) &&
		(TorsoTemplate.bVeteran == Template.bVeteran) &&
		(TorsoTemplate.ArmorTemplate == Template.ArmorTemplate) &&		
		(TorsoTemplate.CharacterTemplate == Template.CharacterTemplate);

	//Don't iterate the sets unless we have to...
	if(bMatched && Template.PartType != "Torso")
	{
		//Body part templates with set names can match to torsos with none, but not the other way around ( due to asset construction of the original content )
		if( TorsoTemplate.SetNames.Length > 0 && Template.SetNames.Length == 0 )
		{
			bMatched = false;
		}
		else if(TorsoTemplate.SetNames.Length > 0 && Template.SetNames.Length > 0) //Attempt to find a set match unless both templates have no set
		{
			bMatched = false;
			for(Index = 0; Index < Template.SetNames.Length; ++Index)
			{
				//Since the torso is the key, it should only ever belong to one set
				if(TorsoTemplate.SetNames[0] == Template.SetNames[Index])
				{
					bMatched = true;
					break;
				}
			}
		}
	}

	return bMatched;
}

function bool FilterByGenderAndArmor( X2BodyPartTemplate Template )
{
	//  Note: TorsoTemplate will always be none here, this is when we are SELECTING a torso
	//  As the function  name states, we only want to check gender and armor.

	if (Template == None || ArmorName == '')
		return false;

	return  (Template.Gender == Gender) &&
			(Template.ArmorTemplate == ArmorName);
}

function string DebugString_X2SimpleBodyPartFilter()
{
	return `ShowEnum(EGender, Gender, Gender) @ `ShowEnum(ECharacterRace, Race, Race) @ ((TorsoTemplate != None) ? `ShowVar(TorsoTemplate.ArchetypeName) : "TorsoTemplate == None") @ `ShowVar(ArmorName);
}