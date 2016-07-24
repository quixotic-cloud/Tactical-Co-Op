//---------------------------------------------------------------------------------------
//  FILE:    SeqVar_GameUnit.uc
//  AUTHOR:  David Burchanowski  --  1/23/2014
//  PURPOSE: Stores a handle to a game unit in kismet
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqVar_GameUnit extends SeqVar_Int
	native;

cpptext
{
	virtual FString GetValueStr()
	{
		return TEXT("Game Unit");
	}

	virtual UBOOL SupportsProperty(UProperty *Property)
	{
		return FALSE;
	}

	virtual void PublishValue(USequenceOp *Op, UProperty *Property, FSeqVarLink &VarLink);
	virtual void PopulateValue(USequenceOp *Op, UProperty *Property, FSeqVarLink &VarLink);
}

defaultproperties
{
	ObjName="Game Unit"
	ObjCategory=""
	ObjColor=(R=255,G=165,B=0,A=255)
}