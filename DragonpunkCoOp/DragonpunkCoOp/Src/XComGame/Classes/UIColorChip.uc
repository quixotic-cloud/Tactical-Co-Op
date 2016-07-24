//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIColorChip.uc
//  AUTHOR:  Brittany Steiner 9/1/2014
//  PURPOSE: UIPanel to for a color chip in the color selector grid. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIColorChip extends UIPanel;

var UIBGBox BG;  
var UIBGBox LabelBG;  
var UIBGBox Highlight;  
var UIText Label;  
var int index; 
var int Row; 
var int Col; 
var int PADDING_HIGHLIGHT;

delegate OnSelectDelegate(int iColorIndex);
delegate OnAcceptDelegate(int iColorIndex);

simulated function UIColorChip InitColorChip( optional name InitName, 
											optional int initIndex = -1,
											optional string initHTMLColor,
											optional string initLabel = "",
											optional float initX = 0,
											optional float initY = 0,
											optional float initSize = 0,
											optional float initRow = -1,
											optional float initCol = -1,
											optional delegate<OnSelectDelegate> initSelectDelegate,
											optional delegate<OnAcceptDelegate> initAcceptDelegate)
{
	InitPanel(InitName);

	Highlight = Spawn(class'UIBGBox', self);
	Highlight.bAnimateOnInit = false;
	Highlight.InitBG();
	Highlight.SetColor(class'UIUtilities_Colors'.const.HILITE_HTML_COLOR);
	Highlight.Hide();

	BG = Spawn(class'UIBGBox', self);
	BG.bAnimateOnInit = false;
	BG.InitBG();

	LabelBG = Spawn(class'UIBGBox', self);
	LabelBG.bAnimateOnInit = false;
	LabelBG.InitBG();
	LabelBG.SetColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);

	Label = Spawn(class'UIText', self); 
	Label.bAnimateOnInit = false;
	Label.InitText(); 

	SetPosition(initX, initY);
	
	if( initSize != 0 )
		SetSize(initSize, initSize);
	else
		SetSize( class'UIColorChip'.default.width, class'UIColorChip'.default.height);

	SetColor(initHTMLColor);
	SetText(initLabel); 

	index = initIndex;
	Row = initRow;
	Col = initCol; 

	OnSelectDelegate = initSelectDelegate;
	OnAcceptDelegate = initAcceptDelegate;

	Navigator.OnSelectedIndexChanged = OnSelectDelegate;

	return self; 
}

simulated function UIPanel SetSize(float newWidth, float newHeight)
{
	SetWidth(newWidth);
	SetHeight(newHeight);

	Label.SetWidth(newWidth);
	Label.SetPosition(0, newHeight - Label.height);

	return self; 
}
simulated function SetWidth(float newWidth)
{
	width = newWidth;
	BG.SetWidth(width);
	LabelBG.SetWidth(width * 0.5);
	LabelBG.SetX(LabelBG.width);
	Highlight.SetWidth( PADDING_HIGHLIGHT + width );
	Highlight.SetX( BG.X - (PADDING_HIGHLIGHT * 0.5) );
}
simulated function SetHeight(float newHeight)
{
	height = newHeight;
	BG.SetHeight(height);
	Highlight.SetHeight( PADDING_HIGHLIGHT + height );
	Highlight.SetY( BG.Y - (PADDING_HIGHLIGHT * 0.5) );
	LabelBG.SetHeight(Label.height);
	LabelBG.SetY(height - LabelBG.height);
}

simulated function UIPanel SetColor(string hexColor)
{
	BG.SetColor(hexColor);
	return self; 
}

simulated function UIPanel SetText( string newText )
{
	Label.SetHTMLText( class'UIUtilities_Text'.static.AlignRight( newText ) );
	return self; 
}

simulated function OnReceiveFocus()
{
	Highlight.Show();
		if(OnSelectDelegate != none)
			OnSelectDelegate( index );
}

simulated function OnLoseFocus()
{
	Highlight.Hide();
}

//------------------------------------------------------

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch(cmd)
	{
		//TODO: this control BG doesn't get in and out calls yet, so these don't trigger. 
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnReceiveFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnLoseFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if(OnAcceptDelegate != none)
			OnAcceptDelegate( index );
		break;
	}
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if(OnAcceptDelegate != none)
			{
				OnAcceptDelegate( index );
			}
			return true;
		default:
			if (Navigator.OnUnrealCommand(cmd, arg))
			{
				return true;
			}
			break;
	}

	return false;
}

//------------------------------------------------------


defaultproperties
{
	bIsNavigable = true;
	bAnimateOnInit = false;
	bProcessesMouseEvents = true;

	width = 64; 
	height = 64;

	PADDING_HIGHLIGHT = 6; 
}
