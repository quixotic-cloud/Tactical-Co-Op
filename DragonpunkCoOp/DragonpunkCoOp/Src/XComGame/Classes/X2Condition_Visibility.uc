//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Visibility.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_Visibility extends X2Condition native(Core);

var bool bNoEnemyViewers;       //Condition will fail if the target can be seen by any enemies

//Require a specific cover type
var bool bRequireMatchCoverType;
// Require that a specific cover type is not being used
var bool bRequireNotMatchCoverType;
var ECoverType TargetCover; //Cover type to match

//Require that the shooter can shoot from their 'default' tile ( no peeking )
var bool bCannotPeek; //Requires bVisibleFromDefault to be FALSE

//Require a specific visibility settings
var bool bRequireLOS;
var bool bRequireBasicVisibility; //LOS + in range
var bool bRequireGameplayVisible; //LOS + in range + meets situational conditions in interface method UpdateGameplayVisibility
var bool bAllowSquadsight;        //LOS + any squadmate can see the target, if unit has Squadsight (overrides bRequireGameplayVisible)
var bool bActAsSquadsight;        //LOS + any squadmate can see the target, regardless of if the unit has Squadsight (overrides bRequireGameplayVisible)
var bool bVisibleToAnyAlly;       //any squadmate can see the target, regardless of if the unit has Squadsight (overrides bRequireGameplayVisible)
var bool bDisablePeeksOnMovement; //If TRUE, peeks cannot be used if bTargetMoved is true in the vis info
var bool bExcludeGameplayVisible; //condition will FAIL if there is GameplayVisibility FROM the target TO the source

//GameplayVisibleTags are contextual flags that can be added to the visibility info during UpdateGameplayVisibility. They give context to the 
//state of bGameplayVisible, ie. 'stealthed', 'concealed', 'kismetseqact', etc.
var init array<name> RequireGameplayVisibleTags; 

native function name MeetsCondition(XComGameState_BaseObject kTarget);
native function name MeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource);

DefaultProperties
{
	RequiredOnlyForActivation=true
	bDisablePeeksOnMovement=false //For most abilities, this is allowed. Exceptions are, for example, over watch.
}