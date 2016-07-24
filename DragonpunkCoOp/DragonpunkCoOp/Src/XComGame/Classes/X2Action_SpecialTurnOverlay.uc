class X2Action_SpecialTurnOverlay extends X2Action;

var bool bHideOverlay;

simulated state Executing
{
Begin:
	if (bHideOverlay)
	{
		`PRES.UIHideSpecialTurnOverlay();
	}
	else
	{
		`PRES.UIShowSpecialTurnOverlay();
	}

	CompleteAction();
}