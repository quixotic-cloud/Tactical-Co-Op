//-----------------------------------------------------------
// MHU - Used to handle 'constantcombat when flanked' anims
//       CRITICAL: Do NOT inherit from XComAnimNodeBlendlist,
//                 mirroring should always be disabled when playing
//                 these anims.
//-----------------------------------------------------------
class XComAnimNodeBlendBySelfFlanked extends AnimNodeBlendList;

enum ECCSelfFlanked
{
	eECCSF_Begin,
	eECCSF_Start,
	eECCSF_Fire,            // Loopable
	eECCSF_Reload,          // Loopable
	eECCSF_FlinchA,         // Loopable
	eECCSF_FlinchB,         // Loopable
	eECCSF_Idle,            // Loopable
	eECCSF_Stop
};

DefaultProperties
{
	Children(eECCSF_Begin)=(Name="SelfFlanked Begin")
	Children(eECCSF_Start)=(Name="SelfFlanked Start")
	Children(eECCSF_Fire)=(Name="SelfFlanked Fire (Loopable)")
	Children(eECCSF_Reload)=(Name="SelfFlanked Reload (Loopable)")
	Children(eECCSF_FlinchA)=(Name="SelfFlanked FlinchA (Loopable)")
	Children(eECCSF_FlinchB)=(Name="SelfFlanked FlinchB (Loopable)")
	Children(eECCSF_Idle)=(Name="SelfFlanked Idle (Loopable)")
	Children(eECCSF_Stop)=(Name="SelfFlanked Stop")

	bFixNumChildren=true
	bPlayActiveChild=true
}
