script_name "SAChess"

local import, modules
do
    function import(name)
        if modules[name] == nil then
            sampfuncsLog("{FF0000}SACHESS_DEBUG: {FFFFFF} attempting to import non-existent module: " .. name)
        else
            return modules[name]()
        end
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
