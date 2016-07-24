//---------------------------------------------------------------------------------------
//  FILE:    XComPhotographer_Strategy.uc
//  AUTHOR:  Ryan McFall  --  02/24/2015
//  PURPOSE: This actor is responsible for capturing images of strategy moments for storage
//		     and display later.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComPhotographer_Strategy extends Actor
	config(GameCore);

struct CameraDistanceMapping
{
	var name UnitTemplateName;
	var float DistanceToCamera;
};

var config array<CameraDistanceMapping> UnitToCameraDistanceMapping;
var config float DefaultDistanceToCamera;

struct HeadshotRequestInfo
{
	var StateObjectReference UnitRef;
	var name LocationTag;
	var name CaptureTag;
	var int Height;
	var int Width;
	var float DistanceFromCamera;
};

struct HeadshotRequest
{
	var HeadshotRequestInfo RequestInfo;
	var array <delegate<OnPhotoRequestFinished> > FinishedDelegates;
	var X2SoldierPersonalityTemplate Personality;
	var XComUnitPawn PicturePawn;
    var bool bArchetypeIsLoaded;
    var bool bArchetypeIsRequested;
};

struct RenderTargetInfo
{
	var int Height;
	var int Width;
	var TextureRenderTarget2D UseRenderTarget;
};

var private SceneCapture2DComponent CurrentCaptureActor;
var private int StoredHeight;
var private int StoredWidth;
var private bool bChangedSize;

var private array<RenderTargetInfo> UseRenderTargets;
var private array<HeadshotRequest> PendingHeadshotRequests;
var private HeadshotRequest ExecutingRequest;
var private bool bHeadshotInProgress;

delegate OnPhotoRequestFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget);

function bool HasPendingHeadshot(const out StateObjectReference UnitRef, optional delegate<OnPhotoRequestFinished> Callback, optional bool bHighPriority=false)
{
	local int idx;
	local bool HasPending; 
	local HeadshotRequest TmpRequest;
	HasPending = false;

	for (idx=0; idx < PendingHeadshotRequests.Length; ++idx)
	{
		if (PendingHeadshotRequests[idx].RequestInfo.UnitRef.ObjectID == UnitRef.ObjectID)
		{
			if (Callback != none)
			{
				PendingHeadshotRequests[idx].FinishedDelegates.AddItem(Callback);
			}

			if( bHighPriority )
			{
				TmpRequest = PendingHeadshotRequests[idx];
				PendingHeadshotRequests.Remove(idx, 1);
				PendingHeadshotRequests.InsertItem(0, TmpRequest);
			}

			HasPending = true;
		}
	}

	return HasPending;
}

function AddHeadshotRequest(const out StateObjectReference UnitRef, name LocTag, name CapTag, int ImgWidth, int ImgHeight, delegate<OnPhotoRequestFinished> FinishedDelegate, optional X2SoldierPersonalityTemplate Personality, optional bool bFlushPendingRequests, optional bool bHighPriority)
{
	local HeadshotRequest NewRequest;
	local XComGameState_Unit Unit;
	local CameraDistanceMapping UnitMapping;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if (Personality == none)
	{
		Personality = Unit.GetPhotoboothPersonalityTemplate();
	}

	NewRequest.RequestInfo.UnitRef = UnitRef;
	NewRequest.RequestInfo.LocationTag = LocTag;
	NewRequest.RequestInfo.CaptureTag = CapTag;
	NewRequest.RequestInfo.Height = ImgHeight;
	NewRequest.RequestInfo.Width = ImgWidth;
	NewRequest.Personality = Personality;

	NewRequest.RequestInfo.DistanceFromCamera = DefaultDistanceToCamera;
	foreach UnitToCameraDistanceMapping(UnitMapping)
	{
		if (UnitMapping.UnitTemplateName == Unit.GetMyTemplateName())
		{
			NewRequest.RequestInfo.DistanceFromCamera = UnitMapping.DistanceToCamera;
			break;
		}
	}

	if (FinishedDelegate != none)
	{
		NewRequest.FinishedDelegates.AddItem(FinishedDelegate);
	}

	if( bFlushPendingRequests )
	{
		PendingHeadshotRequests.Length = 0;
	}
	

	if( bHighPriority )
	{
		PendingHeadshotRequests.InsertItem(0, NewRequest);
	}
	else
	{
		PendingHeadshotRequests.AddItem(NewRequest);
	}

	`log( "Adding headshot Request " $ UnitRef.ObjectID );

	if(!bHeadshotInProgress)
	{
		StartHeadshot();
	}
}

private function OnPawnLoaded(XComGameState_Unit Unit)
{
    local int i;

    `log( 'Pawn is Loaded' $ Unit.ObjectID);

    for( i=0; i< PendingHeadshotRequests.Length; i++ )
	{
        if( PendingHeadshotRequests[i].RequestInfo.UnitRef.ObjectID == Unit.ObjectID)
        {
            PendingHeadshotRequests[i].bArchetypeIsLoaded = true;
		    `log( 'Request found' $ Unit.ObjectID) ;
        }
	}

	
}

private function StartHeadshot()
{
    local XComUnitPawn Pawn;
	local HeadshotRequestInfo RequestInfo;
	local name PictureTakingAnimationName;

	`assert(PendingHeadshotRequests.Length > 0);

	bHeadshotInProgress = true;

	//Make and place the pawn
	ExecutingRequest = PendingHeadshotRequests[0];
	RequestInfo = ExecutingRequest.RequestInfo;

    if( ExecutingRequest.bArchetypeIsLoaded )
    {
        Pawn = CreateUnitPawn(RequestInfo.LocationTag, RequestInfo.UnitRef, false);
	    Pawn.GotoState('PortraitCapture');	
        ExecutingRequest.PicturePawn = Pawn;

		PictureTakingAnimationName = ExecutingRequest.Personality.IdleAnimName;
		if (!ExecutingRequest.PicturePawn.GetAnimTreeController().CanPlayAnimation(PictureTakingAnimationName))
		{
			//We couldn't play the personality anim specified, try pod idles, which aliens and civilians should have
			PictureTakingAnimationName = 'POD_Idle';
		}

		ExecutingRequest.PicturePawn.PlayFullBodyAnimOnPawn(PictureTakingAnimationName, true);

        SetTimer(0.25f, false, nameof(StartHeadshotCapture));

    }
    else
    {
        if( ! ExecutingRequest.bArchetypeIsRequested)
        {
            CreateUnitPawn(RequestInfo.LocationTag, RequestInfo.UnitRef, true);
            ExecutingRequest.bArchetypeIsRequested = true;
        }
    

        // if it's not ready we wait a quarter of a second and try again
	    SetTimer(0.25f, false, nameof(StartHeadshot));
    }

	
}

private function TextureRenderTarget2D AcquireRenderTarget(int ImgWidth, int ImgHeight)
{
	local RenderTargetInfo RenderTarget;
	foreach UseRenderTargets(RenderTarget)
	{
		if (RenderTarget.Width == ImgWidth && RenderTarget.Height == ImgHeight)
		{
			return RenderTarget.UseRenderTarget;
		}
	}

	RenderTarget.Width = ImgWidth;
	RenderTarget.Height = ImgHeight;
	RenderTarget.UseRenderTarget = class'TextureRenderTarget2D'.static.Create(ImgWidth, ImgHeight);
	UseRenderTargets.AddItem(RenderTarget);
	return RenderTarget.UseRenderTarget;
}

private function StartHeadshotCapture()
{
	local SceneCapture2DActor CaptureActor;
	local TextureRenderTarget2D RenderTarget;
	local SceneCapture2DComponent ActorSceneCapture;
	local vector CapLocation;

	`assert(PendingHeadshotRequests.Length > 0);

	RenderTarget = AcquireRenderTarget(ExecutingRequest.RequestInfo.Width, ExecutingRequest.RequestInfo.Height);

	//Capture an image of the newly created pawn
	foreach WorldInfo.AllActors(class'SceneCapture2DActor', CaptureActor)
	{
		if(CaptureActor.Tag == ExecutingRequest.RequestInfo.CaptureTag)
		{
			CapLocation = CaptureActor.Location;
			CapLocation = ExecutingRequest.PicturePawn.GetHeadLocation();
			CapLocation.Y = CapLocation.Y - ExecutingRequest.RequestInfo.DistanceFromCamera;

			ActorSceneCapture = SceneCapture2DComponent(CaptureActor.SceneCapture);
			`assert(ActorSceneCapture != none);
			CurrentCaptureActor = ActorSceneCapture;

			if ((ActorSceneCapture.TargetWidth != 0 && ActorSceneCapture.TargetWidth != RenderTarget.SizeX ) ||
				(ActorSceneCapture.TargetHeight != 0 && ActorSceneCapture.TargetHeight != RenderTarget.SizeY))
			{		
				bChangedSize = true;				
				StoredWidth = CurrentCaptureActor.TargetWidth;
				StoredHeight = CurrentCaptureActor.TargetHeight;
				ActorSceneCapture.SetCaptureParameters(ActorSceneCapture.TextureTarget,
													   ActorSceneCapture.FieldOfView, ActorSceneCapture.NearPlane,
													   ActorSceneCapture.FarPlane, ActorSceneCapture.OrthoWidth,
													   ActorSceneCapture.OrthoHeight, 0, 0,
													   RenderTarget.SizeX, RenderTarget.SizeY);
				//`Redscreen("Capture actor target for photograph request doesn't match the dimensions of the requested "$string(ExecutingRequest.RequestInfo.CaptureTag)$" photograph");
			}

			CaptureActor.SetLocation(CapLocation);
			CaptureActor.CaptureByTag(ExecutingRequest.RequestInfo.CaptureTag, RenderTarget, OnSoldierHeadCaptureFinished, 0);
		}
	}
}

private function OnSoldierHeadCaptureFinished(TextureRenderTarget2D RenderTarget)
{	
	local delegate<OnPhotoRequestFinished> CallDelegate;

	`assert(PendingHeadshotRequests.Length > 0);

	if(bChangedSize)
	{		
		CurrentCaptureActor.SetCaptureParameters(CurrentCaptureActor.TextureTarget,
												 CurrentCaptureActor.FieldOfView, CurrentCaptureActor.NearPlane,
												 CurrentCaptureActor.FarPlane, CurrentCaptureActor.OrthoWidth,
												 CurrentCaptureActor.OrthoHeight, 0, 0,
												 StoredWidth, StoredHeight);
		CurrentCaptureActor = none;
	}

	// Only complete the currently executing headshot if it matches the latest pending request, otherwise discard it and start again
	if(PendingHeadshotRequests[0].RequestInfo.UnitRef.ObjectID == ExecutingRequest.RequestInfo.UnitRef.ObjectID)
	{
		PendingHeadshotRequests.Remove(0, 1);

		foreach ExecutingRequest.FinishedDelegates(CallDelegate)
		{
			if (CallDelegate != none)
			{
				CallDelegate(ExecutingRequest.RequestInfo, RenderTarget);
			}
		}
	}

	ExecutingRequest.PicturePawn.Destroy();

	//If another headshot is in the queue, start it	
	if(PendingHeadshotRequests.Length > 0)
	{
		StartHeadshot();
	}
	else
	{
		bHeadshotInProgress = false;
	}
}

private function XComUnitPawn CreateUnitPawn(name PawnPlacementActorTag, const out StateObjectReference UnitRef, bool bAsync = false)
{
    local XComUnitPawn UnitPawn;
	local Rotator PawnRotation;
	local PointInSpace PlacementActor;
	local XComGameState_Unit UnitStateObject;
	local name PrevPawnType;

	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if(PlacementActor != none && PlacementActor.Tag == PawnPlacementActorTag)
			break;
	}

	UnitStateObject = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	PawnRotation.Yaw = -16384;
	
	//Hacky, but force the pawn to be a soldier pawn so that the unit will have the soldier personality animations
	if(!UnitStateObject.IsAlien())
	{
		PrevPawnType = UnitStateObject.kAppearance.nmPawn;

		if (UnitStateObject.GetMyTemplate().GetPhotographerPawnNameFn != none)
		{
			UnitStateObject.kAppearance.nmPawn = UnitStateObject.GetMyTemplate().GetPhotographerPawnNameFn();
		}
		else
		{
			if (UnitStateObject.kAppearance.iGender == 1)
			{
				UnitStateObject.kAppearance.nmPawn = 'XCom_Soldier_M';
			}
			else
			{
				UnitStateObject.kAppearance.nmPawn = 'XCom_Soldier_F';
			}
		}
	}

    `log( "Requesting Unit Pawn Creation" $ UnitStateObject.ObjectID);

    if( bAsync )
    {
	    UnitStateObject.CreatePawnAsync(self, PlacementActor.Location, PawnRotation, OnPawnLoaded);	
	    UnitStateObject.kAppearance.nmPawn = PrevPawnType;
    }
    else
    {
	    UnitPawn = UnitStateObject.CreatePawn(self, PlacementActor.Location, PawnRotation);	
    }

    return UnitPawn;

}