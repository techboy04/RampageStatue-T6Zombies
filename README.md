# Rampage Statue
Inspired by the Rampage Inducer and the concept from [ps9s Rampage Inducer mod](https://forum.plutonium.pw/topic/24383/release-zombies-rampage-inducer?_=1665077522772) (Their download link was broken at the time of making this mod)
I decided to try making one myself.

Simply interact near the statues that are located near the spawn locations.
When the statue is activated zombies will run and be given zero respawn delay for a specified amount of rounds (Customizable but default is Round 20)

There are two different versions, the mod version (Recommended for the full experience) and the script only version.

# Using the Mod version (Recommended)
## zm_rampagestatue.zip

## Installation
Download zm_rampagestatue zip and put it in your Plutonium T6 mods folder

```%localappdata%\Plutonium\storage\t6\mods\```

(if the folder isnt there create them)

# Using the Scripts version
## rampage_statue.gsc

## Installation
Download rampage_statue.gsc and put it in your Plutonium T6 scripts folder

```%localappdata%\Plutonium\storage\t6\scripts\zm\```

(if the folder isnt there create them)

There are configurable options which can be changed via the **Custom Games** menu instead of the console on the MOD version! (You can still do it in the console)
The values also save after you set them so they load when coming back!

``set rampage_max_round #`` - Choose how long the Rampage Statue would be activated. Once the max round is finished, the statue will deactivate giving players a reward.
- **Default:** ``20``

``set enable_rampage_vox 0/1/2/3`` - Choose how you want the subtitles and audio handled. MOD ONLY!
- 0 - Disabled
- 1 - Both Audio and Subtitles
- 2 - Only Audio
- 3 - Only Subtitles
- **Default:** ``1``
