
class UIDebugGrid extends UIScreen;

var private int NumHorizontalLines;
var private int NumVerticalLines;

var private int HorizontalPixels;
var private int VerticalPixels;

var private float HorizontalPercent;
var private float VerticalPercent;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function DrawGridPixel(int horizontalSpacing, int verticalSpacing)
{
	if( horizontalSpacing == 0.0 || verticalSpacing == 0.0)
	{
		`log( "UIDebugGrid.DrawGridPixel(): You can't divide by zero! Insanity. Bailing out of here.");
		return; 
	}

	HorizontalPixels = horizontalSpacing;
	VerticalPixels = verticalSpacing;

	NumHorizontalLines = Movie.m_v2ScaledDimension.Y / verticalSpacing;
	NumVerticalLines = Movie.m_v2ScaledDimension.X / horizontalSpacing; 

	HorizontalPercent = HorizontalPixels / Movie.m_v2ScaledDimension.X;
	VerticalPercent = VerticalPixels / Movie.m_v2ScaledDimension.Y;

	DrawGrid();
}

simulated function DrawGridPercent(float horizontalSpacing, float verticalSpacing)
{
	if( horizontalSpacing <= 0.0 || verticalSpacing <= 0.0)
	{
		`log( "UIDebugGrid.DrawGridPercent(): You can't divide by zero! What kind of heathen are you? Bailing out of here.");
		return; 
	}

	if( horizontalSpacing > 100.0 || verticalSpacing > 100.0 )
	{
		`log( "UIDebugGrid.DrawGridPercent(): No percents greater than 100 allowed in this tree fort. Bailing out of here.");
		return; 
	}

	//Let's make this 100-based, but let user type whatever in. 
	if( horizontalSpacing < 1.0 ) horizontalSpacing *= 100;
	if( verticalSpacing < 1.0 ) verticalSpacing *= 100;

	HorizontalPercent = horizontalSpacing;
	VerticalPercent = verticalSpacing;

	NumHorizontalLines = 100 / verticalSpacing;
	NumVerticalLines = 100 / horizontalSpacing; 

	HorizontalPixels = Movie.m_v2ScaledDimension.X / NumVerticalLines;
	VerticalPixels = Movie.m_v2ScaledDimension.Y / NumHorizontalLines;

	DrawGrid();
}


private function DrawGrid()
{
	local UIPanel kLine;
	local UIText kText; 
	local string strInfo; 
	local int i; 

	for( i=0; i <= NumHorizontalLines; i++ )
	{
		kLine = Spawn(class'UIPanel', self);
		kLine.InitPanel(Name( "debugGridline_Horizontal" $ i), class'UIUtilities_Controls'.const.MC_GenericPixel);
		kLine.SetPosition(0, VerticalPixels * i);
		kLine.SetSize(Movie.m_v2ScaledDimension.X, 2);
		kLine.bAnimateOnInit = false;

		strInfo = "";
		strInfo $= int(VerticalPercent * i * 100) @ "%";
		strInfo $= "\n";
		strInfo $= (VerticalPixels * i) @ "px";
		strInfo $= "\n";

		kText = Spawn(class'UIText', self);
		kText.InitText(Name("debugGridText_Horizontal" $ i));
		kText.SetText(strInfo).SetWidth(200);
		kText.SetPosition(2, 2 + VerticalPixels * i);
		kText.bAnimateOnInit = false;
	}

	for( i=0; i <= NumVerticalLines; i++ )
	{
		kLine = Spawn(class'UIPanel', self);
		kLine.InitPanel(Name( "debugGridline_Vertical" $ i), class'UIUtilities_Controls'.const.MC_GenericPixel);
		kLine.SetPosition(HorizontalPixels * i, 0);
		kLine.SetSize(Movie.m_v2ScaledDimension.Y, 2);
		kLine.SetRotationDegrees(90);
		kLine.bAnimateOnInit = false;

		strInfo = "";
		strInfo $= int(HorizontalPercent * i * 100) @ "%";
		strInfo $= "\n";
		strInfo $= (HorizontalPixels * i) @ "px";
		strInfo $= "\n";

		kText = Spawn(class'UIText', self);
		kText.InitText(Name("debugGridText_Vertical" $ i));
		kText.SetText(strInfo).SetWidth(200);
		kText.SetPosition( 2 + HorizontalPixels * i, 2);
		kText.bAnimateOnInit = false;
	}
}

//==============================================================================

defaultproperties
{
}
