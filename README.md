# NPC-System
## 0.1.0
**Additions**
- Added in points near the non-humanoid target. NPC's wil now run to a point with the least amount of NPC's at it instead of running to the non-humanoid target. This allows less grouping, but the grouping issue has not been fully resolved yet.

## 1.0.6
#### Additions
- Added in a defeat sound if the non-humanoid target is destroyed.
- Made NPC move directly to the target if it is in its direct line of sight. 
#### Changes
- Changed update delay to 0.5 sec. 

## 1.0.7
#### Additions
- Added an optional distance argument to the check sight function.  Added a line of sight distance setting. Changed detection distance and attack delay settings.
- Made the NPC face the non-humanoid target if near it.
- Added in update delay and color settings in the stats UI as well as variables for the remotes. Added in other threads and parts stats as well as renamed count to NPC.
#### Changes
- Disconnected events that were no longer in use so they won't cause performance issues and clug up the memory.
- Combined the new thread and round function into a module.
- Changed the touched event for the attack listener to the hands instead of just the root.
#### Fixes
- Fixed the non-humanoid defeat music to not immediately stop after playing.
#### Removals
- Removed the pistol

## 1.0.8
#### Additions
- Added in TargetLineOFSightDist in settings & removed AttackDist.
#### Changes
- Instead of two same functions for two different events, I combined the two functions for less lines of code.
- If the remote function did not return in the Stats UI, the stats text would be displayed as "N/A."
#### Removals
- Removed the round function from the helper module as it was only used in one script. Readded it to the NPC handler. Therefore making that module a function for a new thread..
- Removed some useless code in some scripts as well as reorganized.

## 1.1.0
#### Changes
- Changed UpdateDelay from 0.5 to 0.1 sec.
#### Fixes
- Fixed some typos.
#### Removals
- Removed custom animation script because when NPC's run into each other, they clog each other's animations. Roblox's legacy script allows the NPC's to smoothly animate, even when cogged
