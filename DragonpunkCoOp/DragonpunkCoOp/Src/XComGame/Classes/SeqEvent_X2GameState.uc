//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_X2GameState.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Base for all events that trigger gamestate based kismet
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
// Any and all events that needs to execute gamestate modifying kismet streams should derive from this class.
class SeqEvent_X2GameState extends SeqEvent_RemoteEvent
	native;

cpptext
{
public:
	// These events do not go through the usual kismet channels, activating one will cause it to
	// execute immediately, processing the entire stream in a single frame.
	virtual void ActivateEvent(AActor *InOriginator, AActor *InInstigator, TArray<INT> *ActivateIndices = NULL, UBOOL bPushTop = FALSE, UBOOL bFromQueued = FALSE);

#if WITH_EDITOR
	virtual void DrawExtraInfo(FCanvas* Canvas, const FVector& BoxCenter) {}
#endif
};

private event BuildContextForSeqOp(SequenceOp SeqOp)
{
	local XcomGameStateContext_Kismet KismetStateContext;

	if(SeqOp != none)
	{
		KismetStateContext = new class'XComGameStateContext_Kismet';
		KismetStateContext.SetSequenceOp(SeqOp);
		`XCOMGAME.GameRuleset.SubmitGameStateContext(KismetStateContext);
	}
}

defaultproperties
{
	VariableLinks.Empty

	bGameSequenceEvent=true
	ObjName="Remote Event X2 GameState"
	bConvertedForReplaySystem=true
}
