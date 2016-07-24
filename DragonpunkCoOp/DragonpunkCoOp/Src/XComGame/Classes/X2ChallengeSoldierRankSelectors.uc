//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSoldierRankSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSoldierRankSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateStandardRankSelector( ) );

	return Templates;
}

static function X2ChallengeSoldierRank CreateStandardRankSelector( )
{
	local X2ChallengeSoldierRank	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSoldierRank', Template, 'ChallengeStandardRank');

	Template.SelectSoldierRanksFn = StandardRankSelector;

	return Template;
}

static function StandardRankSelector( X2ChallengeSoldierRank Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit BuildUnit;
	local name ClassTemplateName;
	local SCATProgression Progress;
	local array<SCATProgression> SoldierProgression;
	local int RandSkillProgression, Index;

	foreach XComUnits( BuildUnit )
	{
		SoldierProgression.Length = 0;
		ClassTemplateName = BuildUnit.GetSoldierClassTemplateName( );

		// Determine skill selection
		RandSkillProgression = `SYNC_RAND_STATIC(3); // 0 - LeftTree, 1 - Right Tree, 2 - Random
		for (Index = 0; Index < 7; ++Index)
		{
			BuildUnit.RankUpSoldier( StartState, ClassTemplateName );

			Progress.iRank = Index;

			// Build a selected or randomized skill tree
			if (Index > 0)
			{
				switch (RandSkillProgression)
				{
					case 0: Progress.iBranch = 0;
						break;

					case 1: Progress.iBranch = 1;
						break;

					case 2: Progress.iBranch = `SYNC_RAND_STATIC(2);
						break;
				}

				SoldierProgression.AddItem( Progress );
			}
			else // Give both potential squaddie abilities
			{
				Progress.iBranch = 0;
				SoldierProgression.AddItem( Progress );

				Progress.iBranch = 1;
				SoldierProgression.AddItem( Progress );
			}
		}
		BuildUnit.SetSoldierProgression( SoldierProgression );
	}
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}