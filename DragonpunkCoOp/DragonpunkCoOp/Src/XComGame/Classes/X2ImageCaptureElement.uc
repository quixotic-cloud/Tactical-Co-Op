//---------------------------------------------------------------------------------------
//  FILE:    X2ImageCaptureElement.uc
//  AUTHOR:  Ryan McFall  --  02/24/2015
//  PURPOSE: Stores data for the Image Capture system in X-Com 2. This system stores 
//			 textures associated with state objects in the game, such as head shots
//			 for the soldiers.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ImageCaptureElement extends X2ImageCaptureElementBase native(Core);

struct native CapturedImage
{
	var name ImageTag;				//Tag used to identify and retrieve this image
	var array<byte> RawImage;		//The texture in a form that is easily serialized, set by the serializer when the image capture mgr is saved / loaded
	var int SizeX;					//Horizontal dimension of the text - stored when saving
	var int SizeY;					//Vertical dimension of the texture - stored when saving
	var transient Texture2D StoredTexture;	//The texture in a form that is easily consumed by the engine at runtime, NULL in the saved data
	
};

var array<CapturedImage> Images;