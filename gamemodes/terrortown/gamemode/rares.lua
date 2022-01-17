GM.tRareSpawnTable = {}

function GM:RegisterRare(sClassName, iWeight)
    local tEntry = {
        sClassName = sClassName,
        iWeight = iWeight
    }
    table.insert(self.tRareSpawnTable, tEntry)
end

GM:RegisterRare("weapon_ttt_knife", 1)
GM:RegisterRare("weapon_ttt_wtester", 1)
GM:RegisterRare("weapon_zm_awp", 2)
GM:RegisterRare("weapon_ttt_radio", 2)

function GM:PickRare()
    local iTotalWeight = 0
    for _, v in ipairs(self.tRareSpawnTable) do
        iTotalWeight = iTotalWeight + v.iWeight
    end

    local iRolledWeight = math.random(iTotalWeight)
    local iPassedWeight = 0
    for _, v in ipairs(self.tRareSpawnTable) do
        iPassedWeight = iPassedWeight + v.iWeight
        if iRolledWeight <= iPassedWeight then
            return v.sClassName
        end
    end
end
