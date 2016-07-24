//----------XComShellInput.uc-------------------------------------------------
// ~khirsch
//----------------------------------------------------------------------------

class XComShellInput extends XComInputBase;

//-----------------------------------------------------------
// Input raised from controller
//  cmd,    Input command to act on (see UIUtilities_Input for values)
//
// Return false if the input is consumed in preprocessing; else return true and input continues down the waterfall. 
simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
{
	//`log("??? XComShellInput.PreProcessCheckGameLogic('" $ cmd $ "', " $ ActionMask $ ")",,'uixcom');

	// If an interface manager exists, send input to it.
	if( GetScreenStack() != none && Get2DMovie() != none && Get2DMovie().bIsInited )
	{
		return true;
	}
	return false;
}

simulated function bool PostProcessCheckGameLogic( float DeltaTime )
{
	return true;
}

state BlockingInput
{
	// Kill all input
	simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
	{
		return false;
	}

	event PushedState()
	{
		`log("XComShellInput: Input is blocked");
	}

	event PoppedState()
	{
		`log("XComShellInput: Input is no longer blocked");
	}
}

defaultproperties
{
}

