//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHUD extends HUD
	native(UI);

var privatewrite Vector CachedCameraWorldOrigin;
var privatewrite Vector CachedCameraWorldDirection;
var privatewrite Vector CachedMouseWorldOrigin;
var privatewrite Vector CachedMouseWorldDirection;
var protectedwrite Vector CachedHitLocation; 
var privatewrite IMouseInteractionInterface CachedMouseInteractionInterface; 

var privatewrite MaterialInstanceConstant GammaLogo;
var privatewrite bool bEnableGammaLogoDrawing;

var public bool bEnableLoadingTexture;
var privatewrite bool bGameWindowHasFocus;

event PostBeginPlay()
{
	super.PostBeginPlay();

	GammaLogo = new(self) class'MaterialInstanceConstant';
	GammaLogo.SetParent(Material'XComEngineMaterials.GammaLogo_MAT');
}

function SetGammaLogoDrawing(bool bDrawLogo)
{
	bEnableGammaLogoDrawing = bDrawLogo;
}

function DrawHUD()
{
	local Texture2D emblem;
`if(`notdefined(FINAL_RELEASE))
	local   XComMPTacticalGRI   kMPGRI;
`endif
	local Vector2D TopLeft;
	local Vector2d Extent;

	super.DrawHUD();

	if( bEnableLoadingTexture )
	{
		emblem = Texture2D'gfxComponents.emblem';
		Canvas.SetPos(Canvas.SizeX - 125, Canvas.SizeY - 150);
		Canvas.DrawTile(emblem, emblem.GetSurfaceWidth()*0.21, emblem.GetSurfaceHeight()*0.27, 0, 0, emblem.GetSurfaceWidth(), emblem.GetSurfaceHeight());
	}

	// This is kind of a hack to insert the gamma logo for gamma adjustment into the UI.
	if( bEnableGammaLogoDrawing )
	{
		XComPlayerController(WorldInfo.GetALocalPlayerController()).Pres.Get2DMovie().GetGammaLogoDimensions(TopLeft, Extent);
		TopLeft.X = TopLeft.X * Canvas.SizeX;
		TopLeft.Y = TopLeft.Y * Canvas.SizeY;

		Extent.X = Extent.X * Canvas.SizeX;
		Extent.Y = Extent.Y * Canvas.SizeY;

		GammaLogo.SetScalarParameterValue('GammaValue', 1.0f / class'Engine'.static.GetEngineGamma());

		Canvas.SetPos(TopLeft.X, TopLeft.Y);
		Canvas.DrawMaterialTile(GammaLogo, Extent.X, Extent.Y, 0.0f, 0.0f, 1.0f, 1.0f);
	}

`if(`notdefined(FINAL_RELEASE))
	if(WorldInfo.GRI != none && (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Client))
	{
		kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);
		if(kMPGRI != none)
		{
			Canvas.SetDrawColor(0, 255, 0, 255);
			Canvas.SetPos(Canvas.ClipX * 0.45, Canvas.ClipY * 0.05);
			// disabling shitty green text so we can FRAPS for MP vidz -tsmith 7.5.2012
			//if(WorldInfo.NetMode == NM_Client)
			//{
			//	Canvas.DrawText("Client");
			//}
			//else
			//{
			//	Canvas.DrawText("Server");
			//}
		}
	}
`endif
}

event PostRender()
{
	local XComPlayerController kPlayerController;
	local XComPresentationLayerBase kPres;
	local IMouseInteractionInterface kPickedMouseInterface;

	// Some debugging code happens in the super.PostRender, hence moving it to the top so it doesn't get short circuited.
	super.PostRender();

	CalculateCameraVectors();

	kPlayerController = XComPlayerController(PlayerOwner);
	if(kPlayerController == none) return;

	kPres = kPlayerController.Pres;
	if(kPres == none) return;

	// only do mouse picks if not modal and mouse is active.
	if( kPres.Get2DMovie().IsMouseActive() && !kPres.IsBusy())
	{
		kPickedMouseInterface = GetMousePickActor();
	}
	else
	{
		kPickedMouseInterface = none;
	}

	// if this interface is different than the last one, send the mouseout event
	if(CachedMouseInteractionInterface != none && CachedMouseInteractionInterface != kPickedMouseInterface)
	{
		CachedMouseInteractionInterface.OnMouseEvent( class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT,  
													class'UIUtilities_Input'.const.FXS_ACTION_RELEASE, 
													CachedMouseWorldOrigin, 
													CachedMouseWorldDirection);
	}

	// if we have a new interface, decide if we are mousing into it, or hovering over it
	if(kPickedMouseInterface != none )
	{
		if (CachedMouseInteractionInterface != kPickedMouseInterface) // different interface, mouse in event
		{
			kPickedMouseInterface.OnMouseEvent( class'UIUtilities_Input'.const.FXS_L_MOUSE_IN,  
														class'UIUtilities_Input'.const.FXS_ACTION_RELEASE, 
														CachedMouseWorldOrigin, 
														CachedMouseWorldDirection);	
		}
		else // same as last frame, hover event
		{
			kPickedMouseInterface.OnMouseEvent( class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER,  
													class'UIUtilities_Input'.const.FXS_ACTION_RELEASE, 
													CachedMouseWorldOrigin, 
													CachedMouseWorldDirection);	
		}
	}

	CachedMouseInteractionInterface = kPickedMouseInterface;
}

private function CalculateCameraVectors()
{
	local XComPlayerController kPlayerController;
	local XComPresentationLayerBase kPres;
	local XComInputBase kPlayerInput;
	local UIMouseCursor kCursor;
	local Vector2D v2MousePosition;
	local Vector2D v2ScreenCenter;

	kPlayerController = XComPlayerController(PlayerOwner);
	if(kPlayerController == none) return;

	kPres = kPlayerController.Pres;
	if(kPres == none) return;

	kCursor = kPres.m_kUIMouseCursor;
	if(kCursor == none) return;

	kPlayerInput = XComInputBase(kPlayerController.PlayerInput);
	if(kPlayerInput == none) return;

	// Grab the current mouse location.
	v2MousePosition = LocalPlayer(kPlayerController.Player).ViewportClient.GetMousePosition();

	// Deproject the mouse position and store it in the cached vectors
	Canvas.DeProject(v2MousePosition, CachedMouseWorldOrigin, CachedMouseWorldDirection);

	// Deproject the center of the screen and store it in the cached vectors
	v2ScreenCenter.X = Canvas.SizeX * 0.5;
	v2ScreenCenter.Y = Canvas.SizeY * 0.5;
	Canvas.DeProject(v2ScreenCenter, CachedCameraWorldOrigin, CachedCameraWorldDirection);
}

protected function IMouseInteractionInterface GetMousePickActor()
{
	local IMouseInteractionInterface kNewMouseInteractionInterface;
	local Actor             kHitActor;
	local TraceHitInfo      kMouseHitInfo;
	local bool             	bDebugTrace;
	local Vector            vHitLocation, vHitNormal; 

	// Ensure that we have a valid canvas and player owner
	if (Canvas == None) return None;
	
	bDebugTrace = false;
	if(PlayerOwner.CheatManager != none 
		&& XComCheatManager(PlayerOwner.CheatManager) != none 
		&& XComCheatManager(PlayerOwner.CheatManager).bDebugMouseTrace)
	{
		bDebugTrace = true;
	}

	ForEach TraceActors(class'Actor', 
						kHitActor, 
						vHitLocation, 
						vHitNormal, 
						CachedMouseWorldOrigin + CachedMouseWorldDirection * 165536.f, 
						CachedMouseWorldOrigin, 
						vect(0,0,0), 
						kMouseHitInfo, 
						TRACEFLAG_Bullet)
	{
		kNewMouseInteractionInterface = IMouseInteractionInterface(kHitActor);
		if ( kNewMouseInteractionInterface != None )
		{
			// Filter out objects that aren't supposed to intercept mouse picks
			if( XComLevelActor(kHitActor) != none && XComLevelActor(kHitActor).bIgnoreFor3DCursorCollision )
				continue;
			// Filter out objects that aren't supposed to intercept mouse picks
			if( XComHumanPawn(kHitActor) != none && XComHumanPawn(kHitActor).bIgnoreFor3DCursorCollision )
				continue;

			// Allow us to click through a 3D UI display if it's hidden ( hidden = (movie == none)). 
			if( UIDisplay_LevelActor(kHitActor) != none && UIDisplay_LevelActor(kHitActor).m_kMovie == none ) 
				continue; 

			CachedHitLocation = vHitLocation;

			if( bDebugTrace ) DrawDebugSphere(vHitLocation, 16, 12, 255, 0, 0, false);

			return kNewMouseInteractionInterface;
		}
	}

	return none;
}

/**
 *	Pauses or unpauses the game due to main window's focus being lost.
 *	@param Enable tells whether to enable or disable the pause state
 */
event OnLostFocusPause(bool bEnable)
{
	super.OnLostFocusPause(bEnable);
}

event OnWindowFocusChanged(bool bHasFocus)
{
	super.OnWindowFocusChanged(bHasFocus);

	bGameWindowHasFocus = bHasFocus;
}

defaultproperties
{
	bGameWindowHasFocus=true
	bEnableGammaLogoDrawing=false
}
