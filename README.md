<center><img src="https://github.com/defaultzone/sachess/assets/98385732/cd520e06-b315-4ade-9f13-b266b81b765f"/></center>


# SAChess - implementation of the Lichess API for GTA: San Andreas with ImGui.

**SAChess is a free and open souce** implementation of the Lichess API in Lua dialect - Clue. You can
play it directly in the game with ImGui interface. It features board streaming, seek creating,
draw handling, resigning or aborting games.

> [!NOTE]  
> You can play only rapid and classical games due lichess Board API limits.

SAChess is using some **public assets** for different purposes: 
- [sunfish.lua](https://github.com/soumith/sunfish.lua) to generate moves without bitboards on 32-bits;
- [cburnett](https://github.com/lichess-org/lila/tree/master/public/piece/cburnett) icons;
- colors from [Prettier Lichess](https://prettierlichess.github.io/) extension for SAChess board.
- [Cantarell Fonts](https://cantarell.gnome.org/) in ImGui interface;
- assets from the [GAdmin](https://github.com/Vadim-Kamalov/GAdmin) project (animations, etc.).
  
**Thanks!**

## Compilation

SAChess is using Lua dialect called [Clue](https://github.com/ClueLang/Clue): all files from `src/` directory will be
compiled to the one Lua script. You can use next command to compile all source code:

```bash
clue -t=luajit --base base/Release.lua src/
```

Compiled file will be in the root directory of the repository. It called as `main.lua`.

## Installation

To inject Lua script in game proccess we using MoonLoader and it's default library. So, you can just put compiled file in `moonloader/` directory and it will work
(only if you have all libraries installed, there listed below).

Libraries that used in this project:

- mimgui
- effil
- requests

You can install all of them [here](https://www.blast.hk/threads/190033/). Put each library in `moonloader/lib/` directory.

After you finally installed all dependencies and script - type `/sachess.open` command (or press `F2`) to open board.
You will be prompted to enter the Lichess API token in it.  

## License

SAChess is licensed under the terms of the GNU General Public License v3.