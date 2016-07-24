//---------------------------------------------------------------------------------------
//  FILE:    X2CardManager.uc
//  AUTHOR:  David Burchanowski  --  12/9/2014
//  PURPOSE: Allows a common method whereby random selections can be done while maintaining
//           weighting towards selections that have not been made recently. It behaves as a sort of
//           cross between a shuffle bag and a card deck.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2CardManager extends Object
	native(Core);

/// <summary>
/// Defines a single card in a deck.
/// </summary>
struct native Card
{
	var string CardLabel; // Label of this card, and it's unique identifier.
	var int UseCount; // number of times this card has been MarkedAsUsed
	var float InitialWeight; // Initial weight of this card when it was added to the deck

	structcpptext
	{
		FCard() 
		{
			appMemzero(this, sizeof(FCard));
			InitialWeight = 1;
		}

		FCard(EEventParm)
		{
			appMemzero(this, sizeof(FCard));
			InitialWeight = 1;
		}
	}
};

/// <summary>
/// Defines a deck of cards
/// </summary>
struct native CardDeck
{
	var array<Card> Cards; // All cards in this deck
	var int ShuffleCount; // Number of times this deck as been shuffled (partially or in full)

	structcpptext
	{
		FCardDeck() 
		{
			appMemzero(this, sizeof(FCardDeck));
		}

		FCardDeck(EEventParm)
		{
			appMemzero(this, sizeof(FCardDeck));
		}
	}
};

/// <summary>
/// Special structure for saving a flat array of decks
/// </summary>
struct native SavedCardDeck
{
	var CardDeck Deck;
	var name DeckName;
};

cpptext
{
	/// <summary>
	/// Internal helper to actually mark cards as used. Allows us to skip milling the deck twice when
	/// immediately marking a card used after selecting it.
	/// </summary>
	void MarkCardUsedInternal(FCardDeck& Deck, INT CardIndex);
};

/// <summary>
/// Adds the specified card to the specified deck
/// </summary>
var private native Map_Mirror CardDecks { TMap<FName, FCardDeck> };

/// <summary>
/// Gets a reference to the global card manager instance
/// </summary>
static native function X2CardManager GetCardManager();

/// <summary>
/// Adds the specified card to the specified deck
/// </summary>
native function AddCardToDeck(name Deck, string CardLabel, optional float InitialWeight = 1);

/// <summary>
/// Removes the specified card from the specified deck
/// </summary>
native function RemoveCardFromDeck(name Deck, string CardLabel);

/// <summary>
/// Prototype for validation delegates to SelectNextCardFromDeck
/// </summary>
delegate bool CardValidateDelegate(string CardLabel, Object ValidationData);

/// <summary>
/// Selects the next card from the specified deck. If the optional validation function is provided,
/// will pick the next card that passes the validation check. If MarkAsUsed is set, will automatically
/// remove the card from the deck and place it at the bottom of the deck. Validation data is a user supplied datum
/// to make passing state into the validation delegate cleaner and easier.
/// </summary>
native function bool SelectNextCardFromDeck(name Deck, 
											out string CardLabel,
											optional delegate<CardValidateDelegate> Validator = none, 
											optional Object ValidationData, 
											optional bool MarkAsUsed = true);

/// <summary>
/// Returns all cards from the given deck in their current order
/// </summary>
native function GetAllCardsInDeck(name Deck, out array<string> CardLabels);

/// <summary>
/// Returns a list of all decks in the manager, by name
/// </summary>
native function GetAllDeckNames(out array<name> DeckNames);

/// <summary>
/// Marks the given card as "used" and returns it to the bottom of the deck.
/// </summary>
native function MarkCardUsed(name Deck, string CardLabel);

/// <summary>
/// Saves the contents of the deck manager to the given array
/// </summary>
native function SaveDeckData(out array<SavedCardDeck> SavedCardDecks);

/// <summary>
/// Restores the card manager from the contents of the given array
/// </summary>
native function LoadDeckData(const out array<SavedCardDeck> SavedCardDecks);

/// <summary>
/// Dumps the names of all decks to the debug console
/// </summary>
native function DebugDeckNames();

/// <summary>
/// Dumps the contents of the given deck to the debug console
/// </summary>
native function DebugDeck(name DeckName);