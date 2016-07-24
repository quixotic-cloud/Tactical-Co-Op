class SeqVar_StrategyTimeOfDay extends SeqVar_int
	native(Strategy);

cpptext
{
	virtual int* GetRef()
	{
		eventGetTimeOfDay();
		return &IntValue;
	}

	FString GetValueStr()
	{
		eventGetTimeOfDay();
		return FString::Printf(TEXT("%d"),IntValue);
	}
}

event GetTimeOfDay()
{
	IntValue = int(`GAME.GetGeoscape().m_kDateTime.m_fTime);
}

defaultproperties
{
	ObjCategory="Avenger"
	ObjName="Strategy Time Of Day"
	ObjColor=(R=0,G=128,B=0,A=255)			// dark green
}