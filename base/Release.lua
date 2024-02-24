--- This file is compiled from the SAChess source using Clue compiler.
---
--- ClueLang:           https://github.com/ClueLang/Clue
--- SAChess Repository: https://github.com/defaultzone/SAChess
--- License:            GPLv3
---
--- SAChess - MoonLoader script that implements Lichess API.
--- Copyright (C) 2024 defaultzone.
---
--- This program is free software: you can redistribute it and/or modify
--- it under the terms of the GNU General Public License as published by
--- the Free Software Foundation, either version 3 of the License, or
--- (at your option) any later version.
---
--- This program is distributed in the hope that it will be useful,
--- but WITHOUT ANY WARRANTY; without even the implied warranty of
--- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--- GNU General Public License for more details.
---
--- You should have received a copy of the GNU General Public License
--- along with this program.  If not, see <https://www.gnu.org/licenses/>.
---
--- SDPX-License-Identifier: GPL-3.0-only
---

script_name     "SAChess"
script_author   "defaultzone"
script_url      "https://github.com/defaultzone/SAChess"

local import, modules
do
    function import(name)
        return modules[name]()
    end
end

---! BEGIN_AUTO_GENERATED_CONTENT

--STATICS

modules = {§}

---! END_AUTO_GENERATED_CONTENT

import("Main")
for moduleName, _ in pairs(modules) do
    if string.find(moduleName, "^interface%.windows%.[A-Z]") then
        import(moduleName)
    end
end
