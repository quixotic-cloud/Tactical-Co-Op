//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComLocalPlayer extends LocalPlayer
	native(Core);
	
var ScriptSceneView					SceneView;

cpptext
{

		// FExec interface.
	virtual UBOOL Exec(const TCHAR* Cmd,FOutputDevice& Ar);
}

defaultproperties
{
	Begin Object class=ScriptSceneView name=ScriptSceneView0
	End Object
	SceneView=ScriptSceneView0
}
