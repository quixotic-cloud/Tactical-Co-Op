class XComSteamControllerManager extends Object
	native;

var native bool m_bInitialized;
var native qword m_currentActiveController;

// Is the player using the controller this session?
native function bool IsSteamControllerActive();

// If in Big Picture, opens the overlay to the binding screen to that the player can inspect and mofify bindings
// Returns FALSE if not in Big Picture or Overlay disabled so that you can show an error popup prompting them
// to make sure to run in Big Picture
native function bool ShowSteamControllerBindings();

// Given a KeybindCategories and a GeneralBindableCommands / TacticalBindableCommands / AvengerBindableCommands,
// returns the image name within the Steam Controller Glyphs where the action is bound to
native function string GetSteamControllerActionOrigin(BYTE actionCategory, BYTE action);

cpptext
{
	virtual void Init();
	virtual void PreExit();

	virtual void Tick(FLOAT DeltaSeconds);

	void ProcessSteamController(ULocalPlayer* LocalPlayer, unsigned long long handle);

	bool ActivateActionSet(BYTE actionSet);

	static void TacticalCameraHandler(ULocalPlayer* LocalPlayer, float X, float Y);
	static void GeoscapeGlobeRotationHandler(ULocalPlayer* LocalPlayer, float X, float Y);
	static void GeoscapeGlobeZoomHandler(ULocalPlayer* LocalPlayer, float X, float Y);
}