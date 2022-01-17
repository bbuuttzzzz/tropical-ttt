-- buy menu rendering

local render = render
local surface = surface
local string = string
local player = player
local math = math

local SafeTranslate = LANG.TryTranslation
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

local color_darkened = Color(255,255,255, 80)
-- TODO: make set of global role colour defs, these are same as wepswitch
local color_slot = {
   [ROLE_TRAITOR]   = Color(180, 50, 40, 255),
   [ROLE_DETECTIVE] = Color(50, 60, 180, 255)
}

local function ItemIsWeapon(item) return not tonumber(item.id) end
local function CanCarryWeapon(item) return LocalPlayer():CanCarryType(item.kind) end

-- Creates tabel of labels showing the status of ordering prerequisites
local function PreqLabels(parent, x, y)
   local tbl = {}

   tbl.credits = vgui.Create("DLabel", parent)
   tbl.credits:SetTooltip(GetTranslation("equip_help_cost"))
   tbl.credits:SetPos(x, y)
   tbl.credits.Check = function(s, sel)
                          local credits = LocalPlayer():GetCredits()
                          return credits > 0, GetPTranslation("equip_cost", {num = credits})
                       end

   tbl.owned = vgui.Create("DLabel", parent)
   tbl.owned:SetTooltip(GetTranslation("equip_help_carry"))
   tbl.owned:CopyPos(tbl.credits)
   tbl.owned:MoveBelow(tbl.credits, y)
   tbl.owned.Check = function(s, sel)
                        if ItemIsWeapon(sel) and (not CanCarryWeapon(sel)) then
                           return false, GetPTranslation("equip_carry_slot", {slot = sel.slot})
                        elseif (not ItemIsWeapon(sel)) and LocalPlayer():HasEquipmentItem(sel.id) then
                           return false, GetTranslation("equip_carry_own")
                        else
                           return true, GetTranslation("equip_carry")
                        end
                     end

   tbl.bought = vgui.Create("DLabel", parent)
   tbl.bought:SetTooltip(GetTranslation("equip_help_stock"))
   tbl.bought:CopyPos(tbl.owned)
   tbl.bought:MoveBelow(tbl.owned, y)
   tbl.bought.Check = function(s, sel)
                         if sel.limited and LocalPlayer():HasBought(tostring(sel.id)) then
                            return false, GetTranslation("equip_stock_deny")
                         else
                            return true, GetTranslation("equip_stock_ok")
                         end
                      end

   for k, pnl in pairs(tbl) do
      pnl:SetFont("TabLarge")
   end

   return function(selected)
             local allow = true
             for k, pnl in pairs(tbl) do
                local result, text = pnl:Check(selected)
                pnl:SetTextColor(result and color_good or color_bad)
                pnl:SetText(text)
                pnl:SizeToContents()

                allow = allow and result
             end
             return allow
          end
end

local fieldstbl = {"name", "type", "desc"}

BUYMENU = {}

function BUYMENU.CreateMenu(dsheet, ply, closeEquipMenu)
   local w, h = dsheet:GetSize()
   local m = 5

   local dequip = vgui.Create("DPanel", dsheet)
   dequip:SetPaintBackground(false)
   dequip:StretchToParent(padding,padding,padding,padding)

   -- Determine if we already have equipment
   local owned_ids = {}
   for _, wep in ipairs(ply:GetWeapons()) do
      if IsValid(wep) and wep:IsEquipment() then
         table.insert(owned_ids, wep:GetClass())
      end
   end

   -- Stick to one value for no equipment
   if #owned_ids == 0 then
      owned_ids = nil
   end

   --- Construct icon listing
   local dlist = vgui.Create("EquipSelect", dequip)
   dlist:SetPos(0,0)
   dlist:SetSize(216, h - 75)
   dlist:EnableVerticalScrollbar(true)
   dlist:EnableHorizontal(true)
   dlist:SetPadding(4)

   local items = GetEquipmentForRole(ply:GetRole())

   local to_select = nil
   for k, item in pairs(items) do
      local ic = nil

      -- Create icon panel
      if item.material then
         if item.custom then
            -- Custom marker icon
            ic = vgui.Create("LayeredIcon", dlist)

            local marker = vgui.Create("DImage")
            marker:SetImage("vgui/ttt/custom_marker")
            marker.PerformLayout = function(s)
                                      s:AlignBottom(2)
                                      s:AlignRight(2)
                                      s:SetSize(16, 16)
                                   end
            marker:SetTooltip(GetTranslation("equip_custom"))

            ic:AddLayer(marker)

            ic:EnableMousePassthrough(marker)
         elseif not ItemIsWeapon(item) then
            ic = vgui.Create("SimpleIcon", dlist)
         else
            ic = vgui.Create("LayeredIcon", dlist)
         end

         -- Slot marker icon
         if ItemIsWeapon(item) then
            local slot = vgui.Create("SimpleIconLabelled")
            slot:SetIcon("vgui/ttt/slotcap")
            slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
            slot:SetIconSize(16)

            slot:SetIconText(item.slot)

            slot:SetIconProperties(COLOR_WHITE,
                                   "DefaultBold",
                                   {opacity=220, offset=1},
                                   {10, 8})

            ic:AddLayer(slot)
            ic:EnableMousePassthrough(slot)
         end

         ic:SetIconSize(64)
         ic:SetIcon(item.material)
      elseif item.model then
         ic = vgui.Create("SpawnIcon", dlist)
         ic:SetModel(item.model)
      else
         ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
      end

      ic.item = item

      local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
      ic:SetTooltip(tip)

      -- If we cannot order this item, darken it
      if ((not can_order) or
          -- already owned
          table.HasValue(owned_ids, item.id) or
          (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
          -- already carrying a weapon for this slot
          (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
          -- already bought the item before
          (item.limited and ply:HasBought(tostring(item.id)))) then

         ic:SetIconColor(color_darkened)
      end

      dlist:AddPanel(ic)
   end

   local dlistw = 216

   local bw, bh = 100, 25

   local dih = h - bh - m*5
   local diw = w - dlistw - m*6 - 2
   local dinfobg = vgui.Create("DPanel", dequip)
   dinfobg:SetPaintBackground(false)
   dinfobg:SetSize(diw, dih)
   dinfobg:SetPos(dlistw + m, 0)

   local dinfo = vgui.Create("ColoredBox", dinfobg)
   dinfo:SetColor(Color(90, 90, 95))
   dinfo:SetPos(0,0)
   dinfo:StretchToParent(0, 0, 0, dih - 135)

   local dfields = {}
   for _, k in ipairs(fieldstbl) do
      dfields[k] = vgui.Create("DLabel", dinfo)
      dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
      dfields[k]:SetPos(m*3, m*2)
   end

   dfields.name:SetFont("TabLarge")

   dfields.type:SetFont("DermaDefault")
   dfields.type:MoveBelow(dfields.name)

   dfields.desc:SetFont("DermaDefaultBold")
   dfields.desc:SetContentAlignment(7)
   dfields.desc:MoveBelow(dfields.type, 1)

   local iw, ih = dinfo:GetSize()

   local dhelp = vgui.Create("ColoredBox", dinfobg)
   dhelp:SetColor(Color(90, 90, 95))
   dhelp:SetSize(diw, dih - 205)
   dhelp:MoveBelow(dinfo, m)

   local update_preqs = PreqLabels(dhelp, m*3, m*2)

   local dconfirm = vgui.Create("DButton", dinfobg)
   dconfirm:SetPos(0, dih - bh*2)
   dconfirm:SetSize(diw, bh)
   dconfirm:SetDisabled(true)
   dconfirm:SetText(GetTranslation("equip_confirm"))

   -- couple panelselect with info
   dlist.OnActivePanelChanged = function(self, _, new)
      for k,v in pairs(new.item) do
         if dfields[k] then
            dfields[k]:SetText(SafeTranslate(v))
            dfields[k]:SizeToContents()
         end
      end

      -- Trying to force everything to update to
      -- the right size is a giant pain, so just
      -- force a good size.
      dfields.desc:SetTall(70)

      can_order = update_preqs(new.item)

      dconfirm:SetDisabled(not can_order)
   end

   dhelp:SizeToContents()

   dequip.OnOpened = function()
      can_order = update_preqs(dlist.SelectedPanel.item)
      dconfirm:SetDisabled(not can_order)
   end

   -- select first
   dlist:SelectPanel(to_select or dlist:GetItems()[1])

   -- prep confirm action
   dconfirm.DoClick = function()
      local pnl = dlist.SelectedPanel
      if not pnl or not pnl.item then return end
      local choice = pnl.item
      RunConsoleCommand("ttt_order_equipment", choice.id)
      closeEquipMenu()
   end

   can_order = update_preqs(dlist.SelectedPanel.item)
   dconfirm:SetDisabled(not can_order)

   return dequip
end
