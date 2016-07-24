//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeJetpack extends AnimNodeBlendList
	native(Animation);

enum EAnimJetpack
{
 	eAnimJetpack_Closed,
 	eAnimJetpack_Closing,
 	eAnimJetpack_Open,
 	eAnimJetpack_Opening,
};

cpptext 
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

defaultproperties
{
	Children(eAnimJetpack_Closed)=(Name="Closed")
	Children(eAnimJetpack_Closing)=(Name="Closing")
	Children(eAnimJetpack_Open)=(Name="Open")
	Children(eAnimJetpack_Opening)=(Name="Opening")

	bPlayActiveChild=true
	NodeName = "Jetpack"
}
