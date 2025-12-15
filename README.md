All scripts can be found in the luas folder.
You can use all or only one depending on the use case you are looking for, please note to only use doorChime or doorChimeWithAutoPark not both
as they will interfere with each other and likely cause game errors

If you use this for a mod and plan to publish it, please give credit to StrictBark for using the scripts even if modified


- In the art folder there is a chimeOff.wav in a sample folder, you could keep it in there and not change the path in the luas or you can put it
into a directory made specifically for your vehicle which is where the other Chime WAV files should go. It is recommended to use WAV files.
- When making the chimes, please use a 1 second sample where the sound is played ONCE for the BEST results.
- When naming the sound files please create unique names or it may interfere with other vehicles and their chimes.
- lua folder contains a script that checks for the type of market where the vehicle comes for example Japan = JDM. Use this to your advantage however you see fit, it pulls information from the info.json file of a vehicle, so there are many opportunities to use different information

All instructions and modifications you can make to timing and sounds are listed in comments on each LUA file.

For further instructions and an in-depth tutorial for using these scripts please check out my YouTube Video: 
https://youtu.be/YvwgMC46GPU (skip to 5:53)

**marketCheck.lua must be placed in VehicleModDir\lua\vehicle\extensions\auto**


TURN SIGNALS READ ME
**When doing this you will need to modify the vehicles main interior jbeam, the jbeam file that includes the "soundscapes" section needs to be modified, remove the lines called indLoop 1 and indLoop2 completely from the jbeam file, otherwise you will get an overlap in sounds.**

-There is an included Samples Folder if you wish to use a sound from it place it inside of your vehicles sound path in the "art" folder (rename the file to something relate to your vehicle ex. ChargerSRT_on and ChargerSRT_off)
-Similar to the door chimes each sound effect should only be a second or less long
-You will need to sound effect files, 1 for the on (plays when the light blinks on) and 1 for the off (plays when the light blinks off)
-You should name them properly for on and off so the sounds don't get mix matched when put in game
-LUA file has comments explaining each function and how to modify it
