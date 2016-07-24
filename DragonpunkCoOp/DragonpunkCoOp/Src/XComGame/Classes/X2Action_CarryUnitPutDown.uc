//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CarryUnitPutDown extends X2Action_CarryUnitPickUp;

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	UnitPawn.CarryingUnit = None;
	UnitPawn.HideAllAttachments(false);

	AnimName = "ADD_NO_CarryBody";
	Params.AnimName = AppendMaleFemaleToAnim(AnimName);
	UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(Params);

	Params = default.Params;
	AnimName = "HL_CarryBodyStop";
	Params.AnimName = AppendMaleFemaleToAnim(AnimName);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		VisualizationMgr.SendInterTrackMessage(AbilityContext.InputContext.PrimaryTarget);
	}

	UnitPawn.UpdateAnimations();

	CompleteAction();
}

DefaultProperties
{
}
