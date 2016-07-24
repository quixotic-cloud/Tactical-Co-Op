
//---------------------------------------------------------------------------------------
//  FILE:    X2BodyPartFilter.uc
//  AUTHOR:  Ned Way
//  PURPOSE: 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2BodyPartFilter extends Object native;

struct native BodyPartFilterCallback
{
	var function CallbackFunction;
	var Object   CallbackOwner;

	structcpptext
	{	
		FBodyPartFilterCallback() : 
			CallbackFunction(NULL),
			CallbackOwner(NULL)
		{}

		UBOOL operator== (const FBodyPartFilterCallback& Other) const
		{
			return Other.CallbackFunction == CallbackFunction && Other.CallbackOwner == CallbackOwner;
		}
	}
};


var Object      WatchOwner;
var Object      CallbackOwner;

var delegate<FilterCallback> CallbackFn;
delegate bool FilterCallback( X2BodyPartTemplate Template);