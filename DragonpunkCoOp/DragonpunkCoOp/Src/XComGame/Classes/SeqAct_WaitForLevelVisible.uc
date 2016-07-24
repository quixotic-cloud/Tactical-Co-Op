class SeqAct_WaitForLevelVisible extends SeqAct_Latent
	native(Level);

var String LevelNameString;
var Name LevelName;

var() bool bShouldBlockOnLoad;

cpptext
{
	UBOOL UpdateOp(float DeltaTime);
};

event Activated() 
{
	LevelName = Name(LevelNameString);
}

DefaultProperties
{
	bShouldBlockOnLoad=true

	ObjName="Wait for a Level to be Visible"
	ObjCategory="Level"
	VariableLinks.Empty;
	OutputLinks.Empty;
	InputLinks(0)=(LinkDesc="Wait");
	OutputLinks(0)=(LinkDesc="Finished");

	VariableLinks(0)=(ExpectedType=class'SeqVar_String', LinkDesc="Level Name", PropertyName=LevelNameString)
}
