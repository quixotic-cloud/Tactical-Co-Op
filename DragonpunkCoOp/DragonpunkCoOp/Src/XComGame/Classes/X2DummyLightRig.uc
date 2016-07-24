class X2DummyLightRig extends Actor
	native
	placeable; 

cpptext
{
	virtual UBOOL PlayerControlled() { return TRUE; }
}

defaultproperties
{
	Begin Object Class=CharacterLightRigComponent Name=MyLightRig
	End Object
	Components.Add(MyLightRig)

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Crowd.T_Crowd_Destination'
		Scale=0.04  // we are using 128x128 textures so we need to scale them down
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	bStatic=FALSE
	bTickIsDisabled=FALSE
}
