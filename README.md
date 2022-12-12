# TopPriorityAction
WoW addon to propose combat actions (spells, items). Implements combat action priority list (APL).\
Uses retail WoW UI Lua.

## Current state
- Game version: 10.0.2 (Dragonflight)
- Specs:
  - Active: assa (in progress 10.0.2)
  - Inactive: feral (9.2.7), guardian (9.2.7), fury (9.2.7)

## Description

### Limitations:
Made for personal use. Requests and issues are not accepted. Shared code might be usefull for other addon developers to find general hints and ideas.\
My APL is different from SimCraft and AskMrRobot to fit my playstyle and gear. Supports only talents I use.

No UI, no ingame description. To visualise a proposed `TopPriorityActionSharedData.CurrentAction` Key / Name / Icon requires other addons (e.g. WeakAuras, TellMeWhen).\
No examples (import strings) provided.

### Purpose:
Combined with third-party visualization and a visual spell tracker (e.g. TrufiGCD, Details module) can be used to compare suggested actions with your actual actions on recorded gameplay.\
Also may be used as real time combat adviser.

#### This addon does NOT execute any player action.
