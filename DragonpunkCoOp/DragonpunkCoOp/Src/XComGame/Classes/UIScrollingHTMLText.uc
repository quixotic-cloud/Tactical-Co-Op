//--    --------------------------------------------------------------------------
//  FILE:    UIScrollingHTMLText.uc
//  AUTHOR:  Jake Akemann
//  PURPOSE: Used to extend the UIScrollingText class for added functionality
//----------------------------------------------------------------------------

class UIScrollingHTMLText extends UIScrollingText;

//only useful if words are short enough not to scroll
simulated function UIScrollingText SetCenteredText(string NewText)
{
	local String CenterFormattedString;

	CenterFormattedString = class'UIUtilities_Text'.static.AlignCenter(NewText);

	return SetText(CenterFormattedString);
}

//overriding here because parent class does not call "setHTMLText" in actionscript
simulated function UIScrollingText SetHTMLText(optional string txt, optional bool bForce = false)
{
	if(htmlText != txt)
	{
		htmlText = txt;
		mc.FunctionString("setHTMLText", htmlText);
	}
	return self;
}

defaultproperties
{
	LibID = "ScrollingTextControl";
}
