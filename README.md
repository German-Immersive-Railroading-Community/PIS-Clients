# PIS-Clients
The OC clients of the Passenger-Information-System

## Template folder
All files in the template folder, except for `template.lua`, `example.lua` and [json.lua](https://github.com/rxi/json.lua), are taken from the [OC Emulator](https://github.com/zenith391/OCEmu) or from the files ingame on the computers. These are just for autocomplete and some error checking while writing code and are not needed ingame, since they are native on every PC from OC.

## URL formatting
The URL needs to be URL/URI encoded, otherwise the programm will fail because of an `Error 400 (Bad Request)`. Characters such as `ß` have to be encoded correctly. I recommend using an URL encoder such as [this one](https://fusionauth.io/learn/expert-advice/dev-tools/url-encoder-decoder).

## OC screen size
The layout is tested on 3x2 (wxh), so the text can be seen hanging in a height of 4 blocks (from ground: 3 blocks air, then first row screen blocks) without OptiFine or clicking on the screen.