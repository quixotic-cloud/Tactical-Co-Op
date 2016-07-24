
class UIPersonnel_DeceasedListItem extends UIPersonnel_ListItem
	dependson(X2StrategyGameRulesetDataStructures)
	dependson(XComPhotographer_Strategy);

var UIImage SoldierPictureControl;
var Texture2D SoldierPicture;

simulated function UpdateData()
{
	local XComGameState_Unit Unit;	
	local string DateStr;
	local X2ImageCaptureManager ImageCaptureMgr;
	local string TexturePath;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	DateStr = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Unit.GetKIADate(), true);

	ImageCaptureMgr = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	
	SoldierPicture = ImageCaptureMgr.GetStoredImage(UnitRef, name("UnitPictureSmall"$UnitRef.ObjectID));

	TexturePath = PathName(SoldierPicture);

	if( SoldierPicture == none )
	{
		if( !`GAME.StrategyPhotographer.HasPendingHeadshot(UnitRef, OnDeadSoldierHeadCaptureFinished) )
		{
			`GAME.StrategyPhotographer.AddHeadshotRequest(UnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Passport_Armory', 128, 128, OnDeadSoldierHeadCaptureFinished, class'X2StrategyElement_DefaultSoldierPersonalities'.static.Personality_ByTheBook());
		}
	}
	else
	{
		SoldierPictureControl = Spawn(class'UIImage', self).InitImage(, TexturePath);
		SoldierPictureControl.SetScale(0.25);
	}

	AS_UpdateDataSoldier(Unit.GetName(eNameType_FullNick),
						 Unit.GetNumKills(),
						 Unit.GetNumMissions(),
						 Unit.GetKIAOp(),
						 DateStr);
}

function OnDeadSoldierHeadCaptureFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local string TextureName;
	local X2ImageCaptureManager CaptureManager;

	// only want the callback for the smaller image
	if( ReqInfo.Height != 128 )
		return;

	CaptureManager = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());

	TextureName = "UnitPictureSmall"$ReqInfo.UnitRef.ObjectID;
	SoldierPicture = RenderTarget.ConstructTexture2DScript(CaptureManager, TextureName, false, false, false);
	CaptureManager.StoreImage(ReqInfo.UnitRef, SoldierPicture, name(TextureName));

	SoldierPictureControl = Spawn(class'UIImage', self).InitImage(, PathName(SoldierPicture));
	SoldierPictureControl.SetScale(0.25);
}

simulated function AS_UpdateDataSoldier(string UnitName,
								 int UnitKills, 
								 int UnitMissions, 
								 string UnitLastOp, 
								 string UnitDateOfDeath)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueNumber(UnitKills);
	MC.QueueNumber(UnitMissions);
	MC.QueueString(UnitLastOp);
	MC.QueueString(UnitDateOfDeath);
	MC.EndOp();
}

defaultproperties
{
	LibID = "DeceasedListItem";
	height = 40;
}