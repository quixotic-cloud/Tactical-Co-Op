class XComTacticalSoundInfo extends Object
    editinlinenew
	hidecategories(Object);

var(BackgroundAmbience) bool PlayBackgroundAmbience<ToolTip="If NO, then NO overlay ambience will play, even if overridden.">;
var(BackgroundAmbience) SoundCue BackgroundAmbience<ToolTip="Overrides the engine-selected ambience with this one">;

var(OverlayAmbience) bool PlayOverlayAmbience<ToolTip="If NO, then NO overlay ambience will play, even if overridden.">;
var(OverlayAmbience) SoundCue OverlayAmbience<ToolTip="Overrides the engine-selected ambience with this one">;

defaultproperties
{
    PlayBackgroundAmbience=true
    PlayOverlayAmbience=true
}