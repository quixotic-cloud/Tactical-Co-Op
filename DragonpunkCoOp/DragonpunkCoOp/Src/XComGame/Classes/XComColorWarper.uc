class XComColorWarper extends Object
	native;

enum EColorAdjustType
{
	eColorAdj_Set,
	eColorAdj_Pulse
};

// The currently computed color using the variables below
var Color CurrentColor;
// The low color, when Time equals 0
var Color Color0;
// The high color, when Time equals 1
var Color Color1;

var EColorAdjustType ColorType;

cpptext
{
	UBOOL Frame (float CurrentPulseValue);
};

function SetColorImmediate (Color TheColor)
{
	CurrentColor = TheColor;
	Color0 = TheColor;
	Color1 = TheColor;
	ColorType = eColorAdj_Set;
}

// Fades from TheColor0 to TheColor1 and back to TheColor0 over TotalDuration (seconds) repeatedly
function PulseToColorRepeatedly (Color TheColor0, Color TheColor1, float TotalDuration)
{
	CurrentColor = TheColor0;
	Color0 = TheColor0;
	Color1 = TheColor1;
	ColorType = eColorAdj_Pulse;
}


defaultproperties
{
	CurrentColor        = (R=0,G=0,B=0,A=255);
	Color0              = (R=0,G=0,B=0,A=255);
	Color1              = (R=0,G=0,B=0,A=255);
	ColorType           = eColorAdj_Set;
}