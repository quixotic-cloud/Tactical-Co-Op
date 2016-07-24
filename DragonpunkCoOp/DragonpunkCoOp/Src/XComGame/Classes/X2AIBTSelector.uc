class X2AIBTSelector extends X2AIBTComposite
	native(AI);

protected function bt_status Update()
{
	local bool bRunning;
	local X2AIBTBehavior kActiveChild;
	local bt_status eChildStatus;
	// Early exit if this has already been evaluated.
	if (m_eStatus == BTS_SUCCESS || m_eStatus == BTS_FAILURE)
		return m_eStatus;

	bRunning = true;

	// Keep going until a child behavior says its running.
	while(bRunning)
	{
		kActiveChild = GetActiveChild();
		if (kActiveChild != None)
		{
			eChildStatus = kActiveChild.Run(m_kRef.ObjectID, m_iLastInit);
		}

		// If the child succeeds, or keeps running, do the same.
		if (eChildStatus != BTS_FAILURE)
		{
			return eChildStatus;
		}

		kActiveChild = AdvanceToNextChild();
		if (kActiveChild == None)
			bRunning = false;
	}

	// Got here means we reached the final child with no successes.
	return BTS_FAILURE;
}



//------------------------------------------------------------------------------------------------
defaultproperties
{
}