//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIColorSelector.uc
//  AUTHOR:  Brittany Steiner 9/1/2014
//  PURPOSE: UIPanel to for a color selector grid. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIColorSelector extends UIPanel;

var float ITEM_PADDING;
var float EDGE_PADDING;
var float				ChipHeight; 
var float				ScrollbarPadding;
var UIScrollbar		Scrollbar;
var UIMask				Mask;
var UIPanel			ChipContainer;
var array<UIColorChip> ColorChips; 
var array<string>		Colors;
var int				InitialSelection; 

delegate OnPreviewDelegate(int iColorIndex);
delegate OnSetDelegate(int iColorIndex);

simulated function UIColorSelector InitColorSelector(optional name InitName, 
															 optional float initX = 500,
															 optional float initY = 500,
															 optional float initWidth = 500,
															 optional float initHeight = 500,
												 			 optional array<string> initColors,
												 			 optional delegate<OnPreviewDelegate> initPreviewDelegate,
															 optional delegate<OnSetDelegate> initSetDelegate,
															 optional int initSelection = 0,
															 optional array<string> iniSecondaryColors) //TODO: implement secondary chips
{
	InitPanel(InitName);

	width = initWidth;
	height = initHeight;
	SetPosition(initX, initY);
	
	ChipContainer = Spawn(class'UIPanel', self).InitPanel();
	ChipContainer.bCascadeFocus = false;
	ChipContainer.bAnimateOnInit = false;
	ChipContainer.SetY(5); // offset slightly so the highlight for the chips shows up in the masked area
	ChipContainer.SetSelectedNavigation();

	if( initColors.length == 0 )
		initColors = GenerateRandomColors(75);

	OnPreviewDelegate = initPreviewDelegate; 
	OnSetDelegate = initSetDelegate; 

	InitialSelection = initSelection;

	CreateColorChips(initColors);

	return self; 
}

simulated function CreateColorChips( array<string> _Colors )
{
	local UIColorChip Chip, LeftNavTargetChip, RightNavTargetChip, UpNavTargetChip, DownNavTargetChip; 
	local int iChip, iRow, iCol, iMaxChipsPerRow, iLastRowLength, iOffset; 
	
	Colors = _Colors;

	iMaxChipsPerRow = int( (width - ITEM_PADDING) / ( class'UIColorChip'.default.width + ITEM_PADDING ) );

	iRow = 0;
	iCol = -1; 

	// Create chips ----------------------------------------------------
	for( iChip = 0; iChip < Colors.Length; iChip++ )
	{
		iCol++; 
		if( iCol >= iMaxChipsPerRow )
		{
			iCol = 0;
			iRow++; 
		}

		Chip = Spawn( class'UIColorChip', ChipContainer);
		Chip.InitColorChip( '',
							iChip, 
							Colors[iChip], 
							string(iChip), 
							GetChipX(iCol), 
							GetChipY(iRow), 
							class'UIColorChip'.default.width, 
							iRow, 
							iCol,
							OnPreviewColor, 
							OnAcceptColor);
		Chip.OnMouseEventDelegate = OnChildMouseEvent;
		Chip.AnimateIn(iChip * (class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX / 2));
		ColorChips.AddItem(Chip);
	}
	//Save height to use for the mask/scrollbar comparison 
	ChipHeight = GetChipY(iRow) + class'UIColorChip'.default.height; 

	// Hook up navigation ---------------------------------------------
	for( iChip = 0; iChip < ColorChips.Length; iChip++ )
	{
		Chip = ColorChips[iChip];

		LeftNavTargetChip = none; 
		RightNavTargetChip = none; 
		UpNavTargetChip = none; 
		DownNavTargetChip = none; 

		iLastRowLength = ColorChips.length % iMaxChipsPerRow; 

		iOffset = iChip % iMaxChipsPerRow;

		// LEFT - RIGHT -------------------------------------------------
		if( Chip.Col == 0 ) // Left column
		{
			// In the last row, the left chip needs to wrap to the last chip, 
			// regardless of width of that last row which may be an incomplete row. 
			if( Chip.index >= ColorChips.Length - iMaxChipsPerRow ) 
				LeftNavTargetChip = ColorChips[ColorChips.length-1];
			else
				LeftNavTargetChip = ColorChips[iChip + iMaxChipsPerRow - 1];
		}
		else if( Chip.Col == iMaxChipsPerRow - 1 )// right column 
			RightNavTargetChip = ColorChips[iChip - iMaxChipsPerRow+1];
		else if( Chip.index == ColorChips.length-1 )
			RightNavTargetChip = ColorChips[iChip - iLastRowLength+1];

		
		if( LeftNavTargetChip == none )
			LeftNavTargetChip = ColorChips[iChip-1];
		if( RightNavTargetChip  == none )
			RightNavTargetChip = ColorChips[iChip+1];

		Chip.Navigator.AddNavTargetLeft( LeftNavTargetChip );
		Chip.Navigator.AddNavTargetRight( RightNavTargetChip );

		// UP - DOWN -------------------------------------------------
		
		if( Chip.Row == 0 ) // first row 
		{
			if( iOffset >= iLastRowLength )
				UpNavTargetChip = ColorChips[ ColorChips.Length - iLastRowLength - iMaxChipsPerRow + iOffset ];
			else
				UpNavTargetChip = ColorChips[ ColorChips.Length - iLastRowLength  + iOffset ];
		}
		else if( Chip.index >=ColorChips.Length - iMaxChipsPerRow) // last edge, may wrap row 
		{
			DownNavTargetChip = ColorChips[ iOffset ];
		}

		if( UpNavTargetChip == none )
			UpNavTargetChip = ColorChips[iChip-iMaxChipsPerRow];
		if( DownNavTargetChip == none )
			DownNavTargetChip = ColorChips[iChip+iMaxChipsPerRow];

		Chip.Navigator.AddNavTargetUp( UpNavTargetChip );
		Chip.Navigator.AddNavTargetDown( DownNavTargetChip );
		
	}

	RealizeMaskAndScrollbar();
	SetInitialSelection();
}

simulated function SetInitialSelection()
{
	if (ColorChips.Length > 0)
	{
		if (InitialSelection > -1 && InitialSelection < ColorChips.Length )
		{
				ChipContainer.Navigator.SetSelected(ColorChips[InitialSelection]);
		}
		else
		{
			ChipContainer.Navigator.SetSelected(ColorChips[0]);
		}
	}
}

simulated function float GetChipX( int iCol )
{
	return ((class'UIColorChip'.default.width + ITEM_PADDING) * iCol) + (EDGE_PADDING); 
}

simulated function float GetChipY( int iRow )
{
	return ((class'UIColorChip'.default.height + ITEM_PADDING) * iRow) + (EDGE_PADDING); 
}

simulated function array<string> GenerateRandomColors( int iNumColors )
{
	local array<string> Letters, NewColors; 
	local int i, j; 
	local string NewColor; 

	Letters = SplitString("0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F", ",");
	for( i = 0; i < iNumColors; i++ )
	{
		NewColor = "0x";
		for (j = 0; j < 6; j++ ) 
		{
			NewColor $= Letters[Round(Rand(15))];
		}
		NewColors.AddItem(NewColor);
	}
	return NewColors; 
}


simulated function OnPreviewColor(int iIndex)
{
	if(OnPreviewDelegate != none)
		OnPreviewDelegate( iIndex );
}

simulated function OnAcceptColor(int iIndex)
{
	if(OnSetDelegate != none)
		OnSetDelegate( iIndex );
}

simulated function OnCancelColor()
{
	if(OnSetDelegate != none)
		OnSetDelegate( InitialSelection );
}

simulated function RealizeMaskAndScrollbar()
{
	if(ChipHeight > height)
	{
		if(Mask == none)
			Mask = Spawn(class'UIMask', self).InitMask();

		Mask.SetMask(ChipContainer);
		Mask.SetSize(width, height - EDGE_PADDING * 2);
		Mask.SetPosition(0, EDGE_PADDING);

		if(Scrollbar == none)
			Scrollbar = Spawn(class'UIScrollbar', self).InitScrollbar();

		Scrollbar.SnapToControl(Mask, -scrollbarPadding);
		Scrollbar.NotifyValueChange(ChipContainer.SetY, 5, 0 - ChipHeight + height - (EDGE_PADDING * 2));
	}
	else
	{
		if(Mask != none)
		{
			Mask.Remove();
			Mask = none;
		}
		
		if(Scrollbar != none)
		{
			Scrollbar.Remove();
			Scrollbar = none;
		}
	}
}

simulated function OnChildMouseEvent( UIPanel control, int cmd )
{
	if(cmd == class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP)
		Scrollbar.OnMouseScrollEvent(-1);
	else if(cmd == class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN)
		Scrollbar.OnMouseScrollEvent(1);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UIPanel Chip;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	Chip = ChipContainer.Navigator.GetSelected();
	if (Chip != none && Chip.Navigator.OnUnrealCommand(cmd, arg))
	{
		return true;			
	}

	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	bIsNavigable = true;
	bAnimateOnInit = false;
	bCascadeFocus = false;

	ITEM_PADDING = 10;
	EDGE_PADDING = 20;
	ScrollbarPadding = 30; 
}
