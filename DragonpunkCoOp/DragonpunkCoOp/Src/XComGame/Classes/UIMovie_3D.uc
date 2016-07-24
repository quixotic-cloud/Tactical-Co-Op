//----------------------------------------------------------------------------
//  Copyright 2011, Firaxis Games
//
//  A 3D movie on the curved screens. 
//

class UIMovie_3D extends UIMovie
	native(UI);

var public int MouseX;
var public int MouseY;

var UIMouseCursor m_kUIMouseCursor;

//----------------------------------------------------------------------------
// METHODS
//

simulated function InitMovie(XComPresentationLayerBase InitPres)
{
	super.InitMovie(InitPres);
	SetViewScaleMode(SM_ExactFit);
}

simulated function OnInit() 
{
	local UIDisplay_LevelActor UIDisplay;
	local MaterialInstanceConstant UIDisplayMIC;
	local MaterialInterface BaseMaterial;

	super.OnInit();

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'UIDisplay_LevelActor', UIDisplay)
	{
		BaseMaterial = UIDisplay.StaticMeshComponent.GetMaterial(0);
		UIDisplayMIC = MaterialInstanceConstant(BaseMaterial);
		if (UIDisplayMIC == none)
		{
			UIDisplayMIC = UIDisplay.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
		}

		UIDisplayMIC.SetScalarParameterValue('Visibility', 0.0f);
		UIDisplayMIC.SetTextureParameterValue('Movie', RenderTexture );
	}

	// Initialize initial user interface screen.
	Pres.Init3DUIScreens();
}

//----------------------------------------------------------------------------
//  CALLBACK from Flash
//  Occurs when Flash sends an "OnInit" fscommand. 
//

simulated function ShowDisplay( Name ActorOrBlueprintTag, optional UIDisplay_LevelActor UIDisplay)
{
	HideAllDisplays();
	
	if (UIDisplay != none)
	{
		ShowDisplayByInst(UIDisplay);
	}
	else
	{
		ShowDisplayByTag(ActorOrBlueprintTag);
	}
}

simulated function HideAllDisplays()
{
	local UIDisplay_LevelActor UIDisplay;

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'UIDisplay_LevelActor', UIDisplay)
	{
		HideDisplayByInst(UIDisplay);
	}
}

simulated function HideDisplay( Name ActorOrBlueprintTag, optional UIDisplay_LevelActor UIDisplay )
{
	if (UIDisplay != none)
	{
		HideDisplayByInst(UIDisplay);
	}
	else
	{
		HideDisplayByTag(ActorOrBlueprintTag);
	}
}

simulated function ShowDisplayByInst( UIDisplay_LevelActor UIDisplay )
{
	local MaterialInstanceConstant UIDisplayMIC;
	local MaterialInterface BaseMaterial;
	`assert(UIDisplay != none);
		
	//Let the actor know that we are the current movie beiung shown
	UIDisplay.m_kMovie = self;
	UIDisplay.StaticMeshComponent.SetHidden(FALSE);
	UIDisplay.SetCollisionType(COLLIDE_BlockAll);

	BaseMaterial = UIDisplay.StaticMeshComponent.GetMaterial(0);
	UIDisplayMIC = MaterialInstanceConstant(BaseMaterial);
		
	// Check to make sure Material is set properly on 3D display, show error if not - sbatista 6/6/2013
	if (UIDisplayMIC == none)
		Pres.PopupDebugDialog("UI ERROR:", "UI Display '" $ UIDisplay.Tag $ "' set to parent material. Please use instance material on all UI displays.");

	UIDisplayMIC.SetTextureParameterValue('Movie', RenderTexture );
}

simulated function ShowDisplayByTag( Name ActorOrBlueprintTag )
{
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;
	local UIDisplay_LevelActor UIDisplay;

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'UIDisplay_LevelActor', UIDisplay)
	{
		if (UIDisplay.Tag == ActorOrBlueprintTag)
		{
			ShowDisplayByInst(UIDisplay);
		}
	}

	// Look for displays within blueprints (oder matters, do this after iterating through all UIDisplay_LevelActors
	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'XComBlueprint', Blueprint)
	{
		if (Blueprint.Tag == ActorOrBlueprintTag)
		{
			Blueprint.GetLoadedLevelActors(Actors);
			foreach Actors(TmpActor)
			{
				UIDisplay = UIDisplay_LevelActor(TmpActor);
				if(UIDisplay != none)
				{
					ShowDisplayByInst(UIDisplay);
					break;
				}
			}
		}
	}
}

simulated function HideDisplayByTag( Name ActorOrBlueprintTag )
{
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;
	local UIDisplay_LevelActor UIDisplay;

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'UIDisplay_LevelActor', UIDisplay)
	{
		if (UIDisplay.Tag == ActorOrBlueprintTag)
		{
			HideDisplayByInst(UIDisplay);
			// There might be displays with the same tag - don't break here - sbatista 6/6/2013
			//break;
		}
	}

	// Look for displays within blueprints (oder matters, do this after iterating through all UIDisplay_LevelActors
	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'XComBlueprint', Blueprint)
	{
		if (Blueprint.Tag == ActorOrBlueprintTag)
		{
			Blueprint.GetLoadedLevelActors(Actors);
			foreach Actors(TmpActor)
			{
				UIDisplay = UIDisplay_LevelActor(TmpActor);
				if(UIDisplay != none)
				{
					HideDisplayByInst(UIDisplay);
					break;
				}
			}
		}
	}
}

simulated function HideDisplayByInst( UIDisplay_LevelActor UIDisplay )
{
	`assert(UIDisplay != none);

	//Clear the reference to us as the movie
	UIDisplay.m_kMovie = none;
	UIDisplay.StaticMeshComponent.SetHidden(TRUE);
	UIDisplay.SetCollisionType(COLLIDE_NoCollision);
}

simulated function ScaleUVs(name ActorTag, Vector UVScale)
{
	local UIDisplay_LevelActor UIDisplay;
	local MaterialInstanceConstant UIDisplayMIC;
	local MaterialInterface BaseMaterial;
	local LinearColor UVScaleColor;

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'UIDisplay_LevelActor', UIDisplay)
	{
		if (UIDisplay.Tag == ActorTag)
		{
			//Clear the reference to us as the movie 
			UIDisplay.m_kMovie = none; 

			BaseMaterial = UIDisplay.StaticMeshComponent.GetMaterial(0);
			UIDisplayMIC = MaterialInstanceConstant(BaseMaterial);

			// Check to make sure Material is set properly on 3D display, show error if not - sbatista 6/6/2013
			if (UIDisplayMIC == none)
				Pres.PopupDebugDialog("UI ERROR:", "UI Display '" $ ActorTag $ "' set to parent material. Please use instance material on all UI displays.");

			UVScaleColor.R = UVScale.X;
			UVScaleColor.G = UVScale.Y;
			UIDisplayMIC.SetVectorParameterValue('UVAdjust', UVScaleColor);
			UIDisplayMIC.SetTextureParameterValue('Movie', RenderTexture );
			break;
		}
	}
}

simulated function SetMouseLocation( Vector2D kVector2D )
{
	local Vector2D v2UI; 

	// Stop bleed through from 2d to 3d
	if ( XComInputBase( XComPlayerController(Pres.Owner).PlayerInput ).TestMouseConsumedByFlash() )
	{
		v2UI.X = -1;
		v2UI.Y = -1;
	}
	else
		v2UI = ConvertUVToUICoords(kVector2D);

	MouseX = v2UI.X;
	MouseY = v2UI.Y;
}

simulated function FlashRaiseMouseEvent( string strPath, int cmd, string arg )
{
	// Don't raise mouse events on 3D movie if the mouse is currently hitting anything in 2D movie.
	if(!XComInputBase(XComPlayerController(Pres.Owner).PlayerInput).TestMouseConsumedByFlash())
		super.FlashRaiseMouseEvent(strPath, cmd, arg);
}

//----------------------------------------------------------------------------

defaultproperties
{
}
