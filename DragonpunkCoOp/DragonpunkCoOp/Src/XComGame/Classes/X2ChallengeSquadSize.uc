//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSquadSize.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSquadSize extends X2ChallengeTemplate;

var int MinXCom;
var int MaxXCom;

var int MinAliens;
var int MaxAliens;

var delegate<ChallengeSquadSizeSelector> SelectSquadSizeFn;

delegate  ChallengeSquadSizeSelector( X2ChallengeSquadSize Selector, out int NumXcom, out int NumAlien );

static function DefaultSquadSizeSelection( X2ChallengeSquadSize Selector, out int NumXcom, out int NumAlien )
{
	NumXcom = `SYNC_RAND_STATIC( Selector.MaxXCom - Selector.MinXCom + 1 ) + Selector.MinXCom;
	NumAlien = `SYNC_RAND_STATIC( Selector.MaxAliens - Selector.MinAliens + 1 ) + Selector.MinAliens;
}

static function SelectSquadSize( X2ChallengeSquadSize Selector, out int NumXcom, out int NumAlien )
{
	Selector.SelectSquadSizeFn( Selector, NumXcom, NumAlien );
}

defaultproperties
{
	SelectSquadSizeFn = DefaultSquadSizeSelection;
}