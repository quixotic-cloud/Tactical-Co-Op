
class RedScreenManager 
	extends Object 
	native
	config(Game);


var config bool bDisabled;
var config bool bCrashOnScriptError;

var bool bActivated;
var string m_currentErrors;

native function AddRedScreen(string ErrorString );
native function AddRedScreenOnce(string ErrorString);

function XComPresentationLayerBase GetPresentationLayer()
{
	return XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
}

event bool IsPresLayerReady()
{
	return GetPresentationLayer() != none && GetPresentationLayer().IsPresentationLayerReady();
}

event ActivateRedScreen()
{
	local XComPresentationLayerBase Pres;

	if( !bDisabled )
	{
		Pres = GetPresentationLayer();

		if( Pres != none )
			Pres.UIRedScreen(); 
	}
}

event bool IsRedScreenActive()
{
	local UIRedScreen RedScreen;
	local XComPresentationLayerBase Pres;

	Pres = GetPresentationLayer();
	
	if( Pres != none )
	{
		RedScreen = Pres.m_RedScreen;

		if( RedScreen != none && RedScreen.bIsInited )
		{
			SetRedScreenText(m_currentErrors);
			return true;
		}
	}

	return false;
}


event SetRedScreenText(string Errors)
{
	local UIRedScreen RedScreen;
	local XComPresentationLayerBase Pres;

	if( !bDisabled )
	{
		m_currentErrors = Errors;

		Pres = GetPresentationLayer();
	
		if( Pres != none )
		{
			RedScreen = Pres.m_RedScreen;

			if( RedScreen != None )
				RedScreen.SetErrorText(Errors);
		}
	}
}

defaultproperties
{
}