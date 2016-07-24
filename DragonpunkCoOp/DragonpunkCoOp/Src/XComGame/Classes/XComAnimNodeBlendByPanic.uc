//-----------------------------------------------------------
// MHU - Used to handle 'constantcombat when panicked' anims
//-----------------------------------------------------------
class XComAnimNodeBlendByPanic extends AnimNodeBlendList;

enum ECCPanic
{
	eECCP_Start,
	eECCP_Loop1,
	eECCP_Loop2,
	eECCP_Stop,
};

DefaultProperties
{
	Children(eECCP_Start)=(Name="Panic Start")
	Children(eECCP_Loop1)=(Name="Panic Loop1")
	Children(eECCP_Loop2)=(Name="Panic Loop2 (reserved)")
	Children(eECCP_Stop)=(Name="Panic Stop")

	bFixNumChildren=true
	bPlayActiveChild=true
}
