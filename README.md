
Perchance PSK Addon.

This addon tracks a "Main" and "Tier" list for KSK loot distribution standings.  

An instructional video can be seen here: https://youtu.be/l_ZgQ-IcoAU

Features:

<img width="894" alt="Main" src="https://github.com/user-attachments/assets/46850b26-311a-4786-aec0-b7810e839ba5" />

- "PSK" tab:
  - The Main/Tier PSK list is displayed on the left.  This is populated in the "Manage" tab.
    - You can toggle between the Main/Tier PSK list by clicking the toggle button above the list.
    - Move players up/down each list manually by left-clicking the player and clicking the ^ or v buttons.
  - The Loot Drops list is displayed in the center.
    - This list is auto-populated as the Loot Master views Epic/Legendary items in the loot bag.
    - Left-clicking an item will enable the "Start Bidding" button.
      - Once the "Start Bidding" button is clicked, bidding will begin.
          - The chat log will display the item being bid on and the time left.
  - The "Bids" list is displayed on the right.
      - While the bidding timer is counting down, bids can then be read from chat.
      - Any player may type "bid" into /say, /party, /raid, or /whisper (to the addon user) to submit a bid.
      - Any player may type "retract" into /say, /party, /raid, or /whisper (to the addon user) to retract their bid.
      - If there are no bids placed within the timeframe (20 seconds), a roll-off will begin:
                 - The chat log will display the item being rolled on, and the time left.
                 - Main Spec rolls will /roll 100.  Off Spec rolls will /roll 99.
                    - The addon will detect the highest rolls out of both MS and OS rolls.
                    - After the timer is finished, it will list the roll winner, with MS taking precedence over OS.
                    - In the event of a tie, the list of players who tied will be listed in chat.
                       - If that happens, I leave it to the tied players and the guild to decide on who gets the loot.
      - If there are bids placed within the timeframe (20 seconds), the bids will display in the Bids list, sorted by PSK standing.
        - Once the bid timer is finished, or bidding is stopped manually, the addon user can click the check mark next to a player to award loot.
        - Awarding loot will display who and what is being awarded to the chat log.
        - It will then perform sorting on the PSK list:
            - All active raid members will be moved up the PSK list.
            - The awarded player then gets moved to the bottom of the PSK list.
        - The Bids list is cleared, and the Loot Drop being bid on is removed from the Loot Drops list.

<img width="895" alt="Manage_Tab" src="https://github.com/user-attachments/assets/e5e510a2-c6ac-43d1-9629-fc939785cee3" />

- "Manage" Tab:
  - Two lists display here:
    - "Available Main" is a list of max-level guild members who are *not* currently in the Main PSK list.
    - "Available Tier" is a list of max-level guild members who are *not* currently in the Tier PSK list.
    - To add a player to either the Main or Tier PSK list, simply click the + icon to the left of their name.
      - A slight delay is added to prevent issues when the + button is clicked repeatedly.
      - The player will be added to the bottom of the selected list.

<img width="897" alt="Loot" src="https://github.com/user-attachments/assets/5ecdbfb8-5f2b-4337-89f6-dc1aaf838c04" />

- "Logs" tab:
  - This tab will display the player, their class, the loot they received, and the date and time they received it. 

<img width="893" alt="ImportExport" src="https://github.com/user-attachments/assets/114b7e27-64b3-4432-91f0-923efa7de821" />

- "Import/Export" tab:
  - To export data (for importing) from the addon, click the "Export (PSK)" button.
  - To import data (exported by PSK), click the "Import (PSK)" button after pasting in exported data.
  - To import a comma-separated list of names (older version of addon), paste/type them in, then click "Import (Old)".
  - To export lists for pasting into Discord (or elsewhere), click "Export (Discord)".
  

Commands:
- /psk
  - Opens the addon window.
- /pskhelp
  - Will show all commands available to the addon
- /pskadd <top|bottom> <main|tier> <playername>
  - /pskadd top main taurbucks = Adds the player "Taurbucks" to the top of the main KSK list.
  - /pskadd top tier taurbucks = Adds the player "Taurbucks" to the top of the tier KSK list.
- /pskclear
  - This will wipe both the Main and Tier lists in PSK.  This is IRREVERSIBLE!


Planned Features:
- Exporting in a Discord-friendly format for posting in Discord.
- Exporting/Importing in encoded JSON to safely transmit data between players.
    - It will also be used when transmitting data between master and client when those are built.
- Client addon to view the current PSK rankings, dropped loot, bids list, etc.
- Communication between client and loot master/guild officer to update the lists.

