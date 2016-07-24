class X2DataSet extends Object 
	native(Core) 
	dependson(X2GameRuleset, XComGameStateVisualizationMgr);

var protectedwrite bool bShouldCreateDifficultyVariants;

/// <summary>
/// Native accessor for CreateTemplates. Used by the engine object and template manager
/// to automatically pick up new templates.
/// </summary>
static event array<X2DataTemplate> CreateTemplatesEvent()
{
	local array<X2DataTemplate> BaseTemplates, NewTemplates;
	local X2DataTemplate CurrentBaseTemplate;
	local int Index;

	BaseTemplates = CreateTemplates();

	for( Index = 0; Index < BaseTemplates.Length; ++Index )
	{
		CurrentBaseTemplate = BaseTemplates[Index];

		if( default.bShouldCreateDifficultyVariants )
		{
			CurrentBaseTemplate.bShouldCreateDifficultyVariants = true;
		}

		if( CurrentBaseTemplate.bShouldCreateDifficultyVariants )
		{
			CreateDifficultyVariantsForTemplate(CurrentBaseTemplate, NewTemplates);
		}
		else
		{
			NewTemplates.AddItem(CurrentBaseTemplate);
		}
	}

	return NewTemplates;
}

/// <summary>
/// Override this method in sub classes to create new templates by creating new X2<Type>Template
/// objects and filling them out.
/// </summary>
static function array<X2DataTemplate> CreateTemplates();

/// <summary>
/// Helper function to construct Difficulty variants for each difficulty.
/// </summary>
static function CreateDifficultyVariantsForTemplate(X2DataTemplate BaseTemplate, out array<X2DataTemplate> NewTemplates)
{
	local int DifficultyIndex;
	local X2DataTemplate NewTemplate;
	local string NewTemplateName;

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
	{
		NewTemplateName = BaseTemplate.DataName $ "_Diff_" $ DifficultyIndex;
		NewTemplate = new(None, NewTemplateName) BaseTemplate.Class (BaseTemplate);
		NewTemplate.SetDifficulty(DifficultyIndex);
		NewTemplates.AddItem(NewTemplate);
	}
}