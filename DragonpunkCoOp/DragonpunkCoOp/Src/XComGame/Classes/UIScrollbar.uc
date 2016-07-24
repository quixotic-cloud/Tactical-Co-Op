
class UIScrollbar extends UIPanel; 

//var UIPanel targetControl; 
var float percent; 
var float minValue; 
var float maxValue; 
var bool bIsVertical; 

var delegate<OnPercentChangeCallback> onPercentChangeDelegate;
var delegate<OnCalculatedValueChangeCallback> onCalculatedValueChangeDelegate;
delegate OnPercentChangeCallback( float newPercent );
delegate OnCalculatedValueChangeCallback( float newValue );

simulated function UIScrollbar InitScrollbar(optional name InitName, optional UIPanel snapToControlTarget = none, 
													 optional float startX = -1.0, optional float startY = -1.0,
													 optional float startWidth = -1.0, optional float startHeight = -1.0)
{
	InitPanel(InitName);

	if( snapToControlTarget != none ) 
		SnapToControl( snapToControlTarget );

	if( startX != -1.0 && startY != -1.0 )	
		SetPosition(startX, startY);
	if( startWidth != -1.0 && startHeight != -1.0 )
		SetSize(startWidth, startHeight);

	return self;
}

simulated function UIScrollbar SnapToControl( UIPanel kTarget, optional float padding = 10, optional bool bVertical = true )
{
	if( bVertical )
	{
		SetVertical( bVertical ); 
		SetPosition( kTarget.x + kTarget.width + padding, kTarget.y ); 
		SetHeight( kTarget.height ); 
	}
	else
	{
		SetVertical( true ); 
		SetPosition( kTarget.x, kTarget.y + kTarget.height + padding ); 
		SetHeight( kTarget.width );
		SetVertical( bVertical ); 
	}
	return self;
}

simulated function UIScrollbar SetVertical(bool bVertical)
{
	if(bIsVertical != bVertical)
	{
		bIsVertical = bVertical;

		if( bIsVertical )
			SetRotationDegrees(0);
		else
			SetRotationDegrees(-90);

		RealizeLocation(); 
	}
	return self;
}

simulated function UIScrollbar SetThumbAtPercent( float newPercent )
{
	if( newPercent < 0.0 || newPercent > 1.0 )
	{
		`log( "UIScrollbar.SetThumbAtPercent() You're trying to set the percentage out of range. (0.0 to 1.0) You're trying to set: " $ string(newPercent),,'uixcom');
	}

	if(percent != newPercent)
	{
		SetPercent(newPercent);
		mc.FunctionNum("SetThumbAtPercent", percent);
	}
	return self;
}

simulated function UIScrollbar NotifyPercentChange( delegate<OnPercentChangeCallback> onPercentChange )
{
	onPercentChangeDelegate = onPercentChange;
	return self;
}

simulated function UIScrollbar NotifyValueChange( delegate<OnCalculatedValueChangeCallback> onCalculatedValueChange, optional float minVal = 0.0, optional float maxVal = 1.0 )
{
	minValue = minVal;
	maxValue = maxVal;
	onCalculatedValueChangeDelegate = onCalculatedValueChange;
	return self;
}

simulated function UIScrollbar SetThumbSize(float newSize)
{
	MC.FunctionNum("SetThumbHeight", newSize);
	return self;
}

simulated function SetHeight( float newHeight )
{
	if(height != newHeight)
	{
		height = newHeight;

		//Call a specialized resizing function for the scrollbar. 
		mc.FunctionNum("SetScrollbarHeight", height);
	}
}

simulated function OnMouseScrollEvent( int delta ) // -1 for up, 1 for down
{
	Movie.ActionScriptVoid(MCPath $ ".OnChildMouseScrollEvent");
}

simulated function OnCommand( string cmd, string arg )
{
	local float newPercent; 

	if( cmd == "NotifyPercentChanged" )
	{
		newPercent = float(arg); 

		if( newPercent != percent )
			SetPercent(newPercent);
	}
}

simulated function SetPercent( float newPercent )
{
	percent = newPercent;
	if( onPercentChangeDelegate != none )
		onPercentChangeDelegate(percent);
	if( onCalculatedValueChangeDelegate != none )
		onCalculatedValueChangeDelegate( percent * (maxValue - minValue) + minValue ); 
}

// resets the scrolled object
simulated function Reset()
{
	SetPercent(percent);
}

defaultproperties
{
	LibID = "ScrollbarControl";
	bIsNavigable = false;

	minValue = 0.0;
	maxValue = 1.0;

	bIsVertical = true; 
}
