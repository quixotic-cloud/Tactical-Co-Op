class X2Action_DestroyTempFOWViewer extends X2Action;

simulated state Executing
{
Begin:
	if (Unit != none && Unit.TempFOWViewer != none)
	{
		`XWORLD.DestroyFOWViewer(Unit.TempFOWViewer);
		Unit.TempFOWViewer = none;
	}

	CompleteAction();
}