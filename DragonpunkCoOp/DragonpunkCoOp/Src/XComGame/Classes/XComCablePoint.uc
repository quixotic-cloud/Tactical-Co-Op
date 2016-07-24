
class XComCablePoint extends Actor
	placeable
	native(Level);

cpptext
{
	virtual void PostEditMove(UBOOL bFinished);
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EXT_PROP_Powerlines.Textures.S_CableIcon'
		HiddenGame=True
		HiddenEditor=False
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	bStatic = true
}
