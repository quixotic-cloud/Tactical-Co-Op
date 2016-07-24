class XComCivilian extends XComHumanPawn;
var() SoundCue FemaleOffscreenCue; // Added to civilian package to ensure it gets loaded with civilians.
var string m_strFemaleOffscreenDeath;
var() SoundCue MaleOffscreenCue;   // "
var string m_strMaleOffscreenDeath;

var int ColorIdx;

simulated event PostBeginPlay ()
{
	super.PostBeginPlay();
	if (FemaleOffscreenCue == none)
		FemaleOffscreenCue = SoundCue(DynamicLoadObject(m_strFemaleOffscreenDeath, class'SoundCue'));
	if (MaleOffscreenCue == None)
		MaleOffscreenCue = SoundCue(DynamicLoadObject(m_strMaleOffscreenDeath, class'SoundCue'));
}

function DelayedDeathSound()
{
	local vector vLoc;
	vLoc = Location;//`CAMERAMGR.m_kVisibilityLoc;
	if (self.bIsFemale)
	{
		PlaySound(FemaleOffscreenCue,,,,vLoc);
		`Log("Called PlaySound for female offscreen death.");
	}
	else
	{
		PlaySound(MaleOffscreenCue,,,,vLoc);
		`Log("Called PlaySound for male offscreen death.");
	}
}

simulated function UpdateCivilianBodyMaterial(MaterialInstanceConstant MIC)
{
	local XComLinearColorPalette Palette;
	local LinearColor ParamColor;

	Palette = `CONTENT.GetColorPalette(BodyContent.PantsPalette);

	if( ColorIdx == -1 )
		ColorIdx = Rand(Palette.Entries.Length);

	ParamColor = Palette.Entries[ColorIdx].Primary;
	MIC.SetVectorParameterValue('PantsColor', ParamColor);

	Palette = `CONTENT.GetColorPalette(BodyContent.ShirtPalette);
	ParamColor = Palette.Entries[ColorIdx].Primary;
	MIC.SetVectorParameterValue('ShirtColor', ParamColor);

	if (HeadContent != none) // civilian skin color
	{
		Palette = `CONTENT.GetColorPalette(HeadContent.SkinPalette);
		ParamColor = Palette.Entries[m_kAppearance.iSkinColor].Primary;
		MIC.SetVectorParameterValue('SkinColor', ParamColor);
	}
}

defaultproperties
{
	// DO NOT SET ASSETS HERE, instead put them in the archetype in the editor so they work with dynamic loading.
	RagdollFlag=ERagDoll_Always
	m_strFemaleOffscreenDeath="SoundCivilianFemaleScreams.CivFemaleScreamsOffscreenCue"
	m_strMaleOffscreenDeath="SoundCivilianMaleScreams.CivMaleScreamsOffscreenCue"

	// Don't use SH light on civilians to save render time in Terror maps.. also they hardly ever move
	//      so don't update them frequently
	Begin Object Name=MyLightEnvironment
		bSynthesizeSHLight=false
		MinTimeBetweenFullUpdates=3.0
	End Object

	// Civilians don't need accurate bounds - save on bounds update
	Begin Object Name=SkeletalMeshComponent
		bComponentUseFixedSkelBounds=TRUE;
		AnimationLODDistanceFactor=0.2f;
		AnimationLODFrameRate=3;
	End Object

	ColorIdx=-1
}
