![Screenshot_20250501-095628](https://github.com/user-attachments/assets/2a244b28-2a96-45ad-bb37-474372a386a4)

Perchance PSK Addon.

This addon tracks a "Main" and "Tier" list for KSK loot distribution standings.

Features:
- Manage Tab
- - Two lists display here:
  - - "Available Main" is a list of max-level guild members who are *not* currently in the Main PSK list.
  - - "Available Tier" is a list of max-level guild members who are *not* currently in the Tier PSK list.
    - To add a player to either the Main or Tier PSK list, simply click the + icon to the left of their name.
    - A slight delay is added to prevent issues when the + button is clicked repeatedly.


- Main addon used by the raid Loot Master (required, for now).
  - Convenient minimap button of my dog, Mimic, opens/closes the addon.
- KSK Main and Tier list are viewable in the left scroll list.
  - Switching between lists is done by clicking the "Switch Main/Tier" button.
- Dropped loot is presented in the center scroll list.
- Current bids for loot are presented in the right scroll list.
- To start bidding, click a piece of loot, and click "Start Bidding"!
  - Players can type "bid" into /say, /party, /raid, or /whisper (to the loot master) to log a bid.
  - Players with bids in the right scroll list will show two buttons: Award, and Pass.
  - Clicking "Award" will open a confirmation dialog, and upon confirming, notify the raid/party that that loot was won by the selected player.

Commands:
- /psk
  - Opens the addon window.
- /psk help
  - Will show all commands available to the addon
- /pskadd <top|bottom> <main|tier> <playername>
  - /pskadd top main taurbucks = Adds the player "Taurbucks" to the top of the main KSK list.
  - /pskadd top tier taurbucks = Adds the player "Taurbucks" to the top of the tier KSK list.
- /pskremove <playername>
  - /pskremove "taurbucks" = removes the player "Taurbucks" from the currently viewed list in the addon (Main or Tier)
- /pskremove all <playername>
  - /pskremove all "taurbucks" = removes the player "Taurbucks" from both the Main and Tier lists.
- /psk list
  - Will show all players in the currently viewed list in the addon (Main or Tier).


Planned Features:
- Awarding loot will actually give the loot to the awarded player.
- Loot thresholds: uncommon, rare, epic, legendary.
- UI option for adding/removing players.
- UI option for exporting lists.
- UI options for settings.
- /pskexport <main|tier|all> command.
  - Will export the selected (or both) lists in CVS format.
- Client addon to view the current Main and Tier lists.
- Communication between client and loot master/guild officer to update the lists.
  - Done by a "Request Update" button, a timestamp for last update, and which player it was updated from.
