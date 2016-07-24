//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAuthorRegions
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: A screen to help create the textures that the regions use 
//			 in XCom 2's strategy game
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIAuthorRegions extends UIScreen native(UI);

var XComPresentationLayer   Pres;

//UI controls
var UIPanel		m_kAllContainer;
var UIBGBox		m_kMouseHitBG;
var UIButton	m_kStopButton;
var UIButton	m_kExportButton;
var UIDropdown	m_kRegionDropdown;

enum EProcessClickTypeRegions
{
	EProcessClickType_Click,
	EProcessClickType_ShiftClick,
	EProcessClickType_None
};

//Click processing
var EProcessClickTypeRegions	ProcessClickType;
var int							LastClickTypeIndex;


var vector						AuthorRegionPos;

var int							TextureSize;
var vector						GridStartPos;
var vector						GridStepSize;

var array<Color>				ColorValues;

var StaticMesh RegionMesh;
var StaticMeshComponent RegionComponent;
var Texture2D RegionTexture;
var Vector2D LookAtLocation;
var Vector2D CameraOffset;
var float RegionScale;

var array<X2StrategyElementTemplate> RegionDefinitions;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	local int XIndex;
	local int YIndex;
	local Color SetColor;	
	local X2WorldRegionTemplate RegionTemplate;

	//Create Regions	
	RegionDefinitions = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2WorldRegionTemplate');

	super.InitScreen(InitController, InitMovie, InitName);

	m_kAllContainer = Spawn(class'UIPanel', self);
	m_kMouseHitBG = Spawn(class'UIBGBox', m_kAllContainer);

	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.SetPosition(50, 50);
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	m_kMouseHitBG.InitBG('mouseHit', 0, 0, Movie.UI_RES_X, Movie.UI_RES_Y);
	m_kMouseHitBG.SetAlpha(0.00001f);
	m_kMouseHitBG.ProcessMouseEvents(OnMouseHitLayerCallback);

	m_kStopButton = Spawn(class'UIButton', m_kAllContainer);
	m_kStopButton.InitButton('stopButton', "Stop", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kStopButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kStopButton.SetX(325);
	m_kStopButton.SetY(25);

	m_kExportButton = Spawn(class'UIButton', m_kAllContainer);
	m_kExportButton.InitButton('exportButton', "Export Texture (to Logs)", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kExportButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kExportButton.SetX(500);
	m_kExportButton.SetY(25);

	m_kRegionDropdown = Spawn(class'UIDropdown', m_kAllContainer);
	m_kRegionDropdown.InitDropdown('selectRegionDropdown', "", OnSelectRegion);
	m_kRegionDropdown.AddItem("None");
	for(XIndex = 0; XIndex < RegionDefinitions.Length; ++XIndex)
	{
		RegionTemplate = X2WorldRegionTemplate(RegionDefinitions[XIndex]);
		m_kRegionDropdown.AddItem(string(RegionTemplate.DataName));
	}
	m_kRegionDropdown.SetSelected(0);
	m_kRegionDropdown.SetX(700);
	m_kRegionDropdown.SetY(10);
		
	GridStartPos = vect(64, 64, 0);
	GridStepSize = vect(15, 15, 0);
	RegionScale = 1.0f;
	CameraOffset.X = 0.025f;
	CameraOffset.Y = 0.06f;

	//We set the blue channel because the utility method we use to convert this into a texture2d imports color as BGRA
	for(XIndex = 0; XIndex < TextureSize; ++XIndex)
	{
		for(YIndex = 0; YIndex < TextureSize; ++YIndex)
		{
			if( (XIndex >(TextureSize / 4) && XIndex < (TextureSize - (TextureSize / 4))) &&
			    (YIndex >(TextureSize / 4) && YIndex < (TextureSize - (TextureSize / 4))) )
			{
				SetColor.B = 255; 
				ColorValues.AddItem(SetColor);
			}
			else
			{
				SetColor.B = 0;
				ColorValues.AddItem(SetColor);
			}
			
		}
	}

	XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(LookAtLocation + CameraOffset, 1.0f, 0.0f);

	RefreshRegion();

	AddHUDOverlayActor();
}

simulated function OnRemoved()
{
	super.OnRemoved();
}

simulated function OnSelectRegion(UIDropdown dropdown)
{
	local int SelectedIndex;
	local X2WorldRegionTemplate RegionTemplate;	
	local Object TextureObject;

	SelectedIndex = dropdown.selectedItem - 1;
	RegionTemplate = X2WorldRegionTemplate(RegionDefinitions[SelectedIndex]);
	TextureObject = `CONTENT.RequestGameArchetype(RegionTemplate.RegionTexturePath);
	if(TextureObject == none || !TextureObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load region texture" @ RegionTemplate.RegionTexturePath);
		return;
	}
	RegionTexture = Texture2D(TextureObject);
	UpdateColorValuesFromTexture(RegionTexture);
	RefreshRegion();
}

simulated function OnButtonClicked(UIButton button)
{
	if(button == m_kStopButton)
	{
		Movie.Stack.Pop(self);

		RemoveHUDOverlayActor();
	}
	else if(button == m_kExportButton)
	{
		ExportRegionTexture();
	}
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local float DetailMoveMultiplier;
	local bool bScaleMode;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	bScaleMode = `HQINPUT.PressedKeys.Find('LeftControl') != INDEX_NONE;

	if(`HQINPUT.PressedKeys.Find('LeftShift') != INDEX_NONE)
	{
		DetailMoveMultiplier = 0.2f;
	}
	else
	{
		DetailMoveMultiplier = 1.0f;
	}

	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:	
			if(!bScaleMode)
			{
				LookAtLocation.Y -= 0.05f * DetailMoveMultiplier;
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(LookAtLocation + CameraOffset, 1.0f, 0.0f);
			}
			else
			{
				RegionScale += 0.1f;
			}			
			RefreshRegion();
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
			if(!bScaleMode)
			{
				LookAtLocation.Y += 0.05f * DetailMoveMultiplier;
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(LookAtLocation + CameraOffset, 1.0f, 0.0f);
			}
			else
			{
				RegionScale -= 0.1f;
			}
			RefreshRegion();
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			LookAtLocation.X -= 0.05f * DetailMoveMultiplier;
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(LookAtLocation + CameraOffset, 1.0f, 0.0f);
			RefreshRegion();
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			LookAtLocation.X += 0.05f * DetailMoveMultiplier;
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(LookAtLocation + CameraOffset, 1.0f, 0.0f);
			RefreshRegion();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseHitLayerCallback(UIPanel control, int cmd)
{
	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
			if(`HQINPUT.PressedKeys.Find('LeftShift') != INDEX_NONE)
			{
				ProcessClickType = EProcessClickType_ShiftClick;
			}
			else
			{
				ProcessClickType = EProcessClickType_Click;
			}
			break;
	}
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{	
	local Vector2D v2MousePosition;
	local Vector RectPos;	
	local int XIndex;
	local int YIndex;
	local int ColorIndex;	
	local Color PickedColor;

	if(ProcessClickType != EProcessClickType_None)
	{
		// Grab the current mouse location.
		v2MousePosition = LocalPlayer(GetALocalPlayerController().Player).ViewportClient.GetMousePosition();

		ColorIndex = 0;
		for(YIndex = 0; YIndex < TextureSize; ++YIndex)
		{
			for(XIndex = 0; XIndex < TextureSize; ++XIndex)
			{
				RectPos = GridStartPos;
				RectPos.X += (GridStepSize.X * XIndex);
				RectPos.Y += (GridStepSize.Y * YIndex);
												
				if((v2MousePosition.X > RectPos.X) && (v2MousePosition.X < (RectPos.X + GridStepSize.X)) &&
				   (v2MousePosition.Y > RectPos.Y) && (v2MousePosition.Y < (RectPos.Y + GridStepSize.Y)))
				{
					PickedColor = ColorValues[ColorIndex];
					if(PickedColor.B != 0)
					{
						ColorValues[ColorIndex].B = 0;
					}
					else
					{
						ColorValues[ColorIndex].B = 255;
					}
				}				

				++ColorIndex;
			}
		}

		if(ProcessClickType == EProcessClickType_ShiftClick)
		{
			ColorIndex = 0;
			for(YIndex = 0; YIndex < TextureSize; ++YIndex)
			{
				for(XIndex = 0; XIndex < TextureSize; ++XIndex)
				{
					RectPos = GridStartPos;
					RectPos.X += (GridStepSize.X * XIndex);
					RectPos.Y += (GridStepSize.Y * YIndex);
					
					if((v2MousePosition.X >(RectPos.X - GridStepSize.X)) && (v2MousePosition.X < (RectPos.X + (GridStepSize.X * 2))) &&
					   (v2MousePosition.Y >(RectPos.Y - GridStepSize.Y)) && (v2MousePosition.Y < (RectPos.Y + (GridStepSize.Y * 2))))
					{
						ColorValues[ColorIndex].B = PickedColor.B;						
					}

					++ColorIndex;
				}
			}
		}			

		RefreshRegion();
		ProcessClickType = EProcessClickType_None;
	}
	
	kCanvas.SetDrawColor(0, 255, 0, 255);

	//Directions
	kCanvas.SetPos(GridStartPos.X, GridStartPos.Y - 16);
	kCanvas.DrawText("Region Grid: LMB to toggle single texels, LMB+Shift to set block of 9 texels      |      Positioning: Arrow keys to move region, +Shift for fine tuning      |      Scale: Ctrl + Up/Down arrow to change scale");
	
	//Values to make note of for setting into the region data
	kCanvas.SetPos(GridStartPos.X + (GridStepSize.X * TextureSize + 1), GridStartPos.Y + 16);
	kCanvas.DrawText("Region Location: X:"@LookAtLocation.X@"Y:"@LookAtLocation.Y@"   Scale:"@RegionScale);

	ColorIndex = 0;
	for(YIndex = 0; YIndex < TextureSize; ++YIndex)
	{
		for(XIndex = 0; XIndex < TextureSize; ++XIndex)
		{
			RectPos = GridStartPos;
			RectPos.X += (GridStepSize.X * XIndex) + 1;
			RectPos.Y += (GridStepSize.Y * YIndex) + 1;

			/*
			if(XIndex % 2 == 0)
			{
				RectPos.Y -= (GridStepSize.Y / 2);
			}
			*/

			if(ColorValues[ColorIndex].B != 0)
			{
				kCanvas.SetDrawColor(255, 255, 255, 200);
			}
			else
			{
				kCanvas.SetDrawColor(155, 155, 155, 200);
			}			

			kCanvas.SetPos(RectPos.X, RectPos.Y);
			kCanvas.DrawRect(GridStepSize.X - 2, GridStepSize.Y - 2);

			++ColorIndex;
		}
	}
}

function native UpdateColorValuesFromTexture(Texture2D FromTexture);

function native UpdateRegionTexture();

function native ExportRegionTexture();

function RefreshRegion(bool bInitialUpdate=false)
{
	local MaterialInstanceConstant NewMaterial;

	UpdateRegionTexture();	
	RegionMesh = class'Helpers'.static.ConstructRegionActor(RegionTexture);

	RegionComponent.SetStaticMesh(RegionMesh);
	RegionComponent.SetTranslation(`EARTH.ConvertEarthToWorld(LookAtLocation));
	RegionComponent.SetScale(RegionScale);

	if(bInitialUpdate)
	{
		NewMaterial = new(self) class'MaterialInstanceConstant';
		NewMaterial.SetParent(RegionComponent.GetMaterial(0));
		RegionComponent.SetMaterial(0, NewMaterial);

		NewMaterial = new(self) class'MaterialInstanceConstant';
		NewMaterial.SetParent(RegionComponent.GetMaterial(1));
		RegionComponent.SetMaterial(1, NewMaterial);
	}

	ReattachComponent(RegionComponent);
}

//==============================================================================

defaultproperties
{	
	Begin Object Class=StaticMeshComponent Name=RegionMeshComponent
	AbsoluteTranslation = true
	AbsoluteRotation = true
	AbsoluteScale = true
	End Object
	Components.Add(RegionMeshComponent)
	RegionComponent = RegionMeshComponent

	TextureSize=32	
}
