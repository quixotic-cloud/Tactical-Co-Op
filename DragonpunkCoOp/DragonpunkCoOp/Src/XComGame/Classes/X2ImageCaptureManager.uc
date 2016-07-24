//---------------------------------------------------------------------------------------
//  FILE:    X2ImageCaptureManager.uc
//  AUTHOR:  Ryan McFall  --  02/24/2015
//  PURPOSE: This manager is responsible for capturing and storing images related to objects
//			 registered with the game state system. We do not want to store the images within
//		     the game state objects themselves, so they are kept within this cache
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ImageCaptureManager extends Object native(Core);

var private{private} array<X2ImageCaptureElementBase> StoredImages; //Tracks per-state-object images
var private{private} native Map_Mirror StoredImageLookupMap{ TMap<INT, INT> }; //Maps ObjectIDs to array indices in StoredImages

cpptext
{
	void RefreshStoredImageLookupMap();
	void RefreshHeadsTexture();

	virtual void Serialize(FArchive& Ar);
}

//Called when the history is reset
event ClearStore()
{
	StoredImages.Length = 0;
}

function StoreImage(const out StateObjectReference ObjectRef, Texture2D ImageData, name ImageTag)
{
	local int StoredImageIndex;
	local int ImageIndex;
	local X2ImageCaptureElement StorageElement;
	local CapturedImage NewImageElement;

	StoredImageIndex = GetStoredImagesIndex(ObjectRef);	
	if(StoredImageIndex != INDEX_NONE)
	{
		StorageElement = X2ImageCaptureElement(StoredImages[StoredImageIndex]);

		ImageIndex = StorageElement.Images.Find('ImageTag', ImageTag);
		if(ImageIndex != INDEX_NONE)
		{
			StorageElement.Images[ImageIndex].StoredTexture = ImageData;
		}
		else
		{
			NewImageElement.ImageTag = ImageTag;
			NewImageElement.StoredTexture = ImageData;
			StorageElement.Images.AddItem(NewImageElement);
		}
	}
	else
	{
		IncrementalUpdateLookupMap(ObjectRef, StoredImages.Length);

		StorageElement = new(self) class'X2ImageCaptureElement';
		StorageElement.StateObjectRef = ObjectRef;

		//Create the new image struct and add it
		NewImageElement.ImageTag = ImageTag;
		NewImageElement.StoredTexture = ImageData;
		StorageElement.Images.AddItem(NewImageElement);

		StoredImages.AddItem(StorageElement);
	}
}

function bool HasStoredImage(const out StateObjectReference ObjectRef, name ImageTag)
{
	local Texture2D Image;
	Image = GetStoredImage(ObjectRef, ImageTag);
	return (Image != none);
}

function Texture2D GetStoredImage(const out StateObjectReference ObjectRef, name ImageTag)
{
	local int StoredImageIndex;
	local int ImageIndex;
	local X2ImageCaptureElement StorageElement;
	
	StoredImageIndex = GetStoredImagesIndex(ObjectRef);
	if(StoredImageIndex != INDEX_NONE)
	{
		StorageElement = X2ImageCaptureElement(StoredImages[StoredImageIndex]);
		ImageIndex = StorageElement.Images.Find('ImageTag', ImageTag);
		if(ImageIndex != INDEX_NONE)
		{
			return StorageElement.Images[ImageIndex].StoredTexture;
		}
	}

	return none;
}

native private function INT GetStoredImagesIndex(const out StateObjectReference ObjectRef);

native private function IncrementalUpdateLookupMap(const out StateObjectReference ObjectRef, int StoredImagesArrayIndex);