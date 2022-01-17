---- Traitor equipment menu

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

-- Buyable weapons are loaded automatically. Buyable items are defined in
-- equip_items_shd.lua

local Equipment = nil
function GetEquipmentForRole(role)
   -- need to build equipment cache?
   if not Equipment then
      -- start with all the non-weapon goodies
      local tbl = table.Copy(EquipmentItems)

      -- find buyable weapons to load info from
      for k, v in pairs(weapons.GetList()) do
         if v and v.CanBuy then
            local data = v.EquipMenuData or {}
            local base = {
               id       = WEPS.GetClass(v),
               name     = v.PrintName or "Unnamed",
               limited  = v.LimitedStock,
               kind     = v.Kind or WEAPON_NONE,
               slot     = (v.Slot or 0) + 1,
               material = v.Icon or "vgui/ttt/icon_id",
               -- the below should be specified in EquipMenuData, in which case
               -- these values are overwritten
               type     = "Type not specified",
               model    = "models/weapons/w_bugbait.mdl",
               desc     = "No description specified."
            };

            -- Force material to nil so that model key is used when we are
            -- explicitly told to do so (ie. material is false rather than nil).
            if data.modelicon then
               base.material = nil
            end

            table.Merge(base, data)

            -- add this buyable weapon to all relevant equipment tables
            for _, r in pairs(v.CanBuy) do
               table.insert(tbl[r], base)
            end
         end
      end

      -- mark custom items
      for r, is in pairs(tbl) do
         for _, i in pairs(is) do
            if i and i.id then
               i.custom = not table.HasValue(DefaultEquipment[r], i.id)
            end
         end
      end

      Equipment = tbl
   end

   return Equipment and Equipment[role] or {}
end

local color_bad = Color(220, 60, 60, 255)
local color_good = Color(0, 200, 0, 255)

-- quick, very basic override of DPanelSelect
local PANEL = {}
local function DrawSelectedEquipment(pnl)
   surface.SetDrawColor(255, 200, 0, 255)
   surface.DrawOutlinedRect(0, 0, pnl:GetWide(), pnl:GetTall())
end

function PANEL:SelectPanel(pnl)
   self.BaseClass.SelectPanel(self, pnl)
   if pnl then
      pnl.PaintOver = DrawSelectedEquipment
   end
end
vgui.Register("EquipSelect", PANEL, "DPanelSelect")


local SafeTranslate = LANG.TryTranslation

local eqframe = nil
local function TraitorMenuPopup()
   local ply = LocalPlayer()
   if not IsValid(ply) or (not ply:IsActiveSpecial() and not ply:HasInnocentMenu()) then
      return
   end

   local w, h = 570, 412
   local m = 5
   local bw, bh = 100, 25

   -- Close any existing traitor menu
   if eqframe and IsValid(eqframe) then eqframe:Close() end

   local credits = ply:IsActiveSpecial() and ply:GetCredits() or 0
   local can_order = credits > 0

   local dframe = vgui.Create("DFrame")
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(GetTranslation("equip_title"))
   dframe:SetVisible(true)
   dframe:ShowCloseButton(true)
   dframe:SetMouseInputEnabled(true)
   dframe:SetDeleteOnClose(true)
   local closeEquipMenu = function() dframe:Close() end

   local dsheet = vgui.Create("DPropertySheet", dframe)

   -- Add a callback when switching tabs
   local oldfunc = dsheet.SetActiveTab
   dsheet.SetActiveTab = function(self, new)
      if self.m_pActiveTab != new and self.OnTabChanged then
         self:OnTabChanged(self.m_pActiveTab, new)
      end
      oldfunc(self, new)
   end

   dsheet:SetPos(0,0)
   dsheet:StretchToParent(m,m + 25,m,m)
   local padding = dsheet:GetPadding()

   if ply:IsActiveSpecial() then
      local dequip = BUYMENU.CreateMenu(dsheet, ply, closeEquipMenu)
      dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, GetTranslation("equip_tooltip_main"))
   end

   -- Item control
   if ply:HasEquipmentItem(EQUIP_RADAR) then
      local dradar = RADAR.CreateMenu(dsheet, dframe)
      dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false, false, GetTranslation("equip_tooltip_radar"))
   end

   if ply:HasEquipmentItem(EQUIP_DISGUISE) then
      local ddisguise = DISGUISE.CreateMenu(dsheet)
      dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false, false, GetTranslation("equip_tooltip_disguise"))
   end

   -- Weapon/item control
   if ply:HasRadio() then
      local dradio = TRADIO.CreateMenu(dsheet)
      dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false, false, GetTranslation("equip_tooltip_radio"))
   end

   -- Credit transferring
   if credits > 0 then
      local dtransfer = CreateTransferMenu(dsheet)
      dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false, false, GetTranslation("equip_tooltip_xfer"))
   end

   hook.Run("TTTEquipmentTabs", dsheet)

   dsheet.OnTabChanged = function(s, old, new)
      if not IsValid(new) then return end

      local panel = new:GetPanel()
      if panel.OnTabChanged then
         panel.OnTabChanged()
      end
   end

   local dcancel = vgui.Create("DButton", dframe)
   dcancel:SetPos(16, h - bh - 16)
   dcancel:SetSize(bw, bh)
   dcancel:SetDisabled(false)
   dcancel:SetText(GetTranslation("close"))
   dcancel.DoClick = closeEquipMenu

   dframe:MakePopup()
   dframe:SetKeyboardInputEnabled(false)

   eqframe = dframe
end
concommand.Add("ttt_cl_traitorpopup", TraitorMenuPopup)

local function ForceCloseTraitorMenu(ply, cmd, args)
   if IsValid(eqframe) then
      eqframe:Close()
   end
end
concommand.Add("ttt_cl_traitorpopup_close", ForceCloseTraitorMenu)

function GM:OnContextMenuOpen()
   local r = GetRoundState()
   if r == ROUND_ACTIVE and not (LocalPlayer():GetTraitor() or LocalPlayer():GetDetective() or LocalPlayer():HasInnocentMenu()) then
      return
   elseif r == ROUND_POST or r == ROUND_PREP then
      CLSCORE:Toggle()
      return
   end

   if IsValid(eqframe) then
      eqframe:Close()
   else
      RunConsoleCommand("ttt_cl_traitorpopup")
   end
end

local function ReceiveEquipment()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.equipment_items = net.ReadUInt(16)
end
net.Receive("TTT_Equipment", ReceiveEquipment)

local function ReceiveCredits()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.equipment_credits = net.ReadUInt(8)
end
net.Receive("TTT_Credits", ReceiveCredits)

local r = 0
local function ReceiveBought()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.bought = {}
   local num = net.ReadUInt(8)
   for i=1,num do
      local s = net.ReadString()
      if s != "" then
         table.insert(ply.bought, s)
      end
   end

   -- This usermessage sometimes fails to contain the last weapon that was
   -- bought, even though resending then works perfectly. Possibly a bug in
   -- bf_read. Anyway, this hack is a workaround: we just request a new umsg.
   if num != #ply.bought and r < 10 then -- r is an infinite loop guard
      RunConsoleCommand("ttt_resend_bought")
      r = r + 1
   else
      r = 0
   end
end
net.Receive("TTT_Bought", ReceiveBought)

-- Player received the item he has just bought, so run clientside init
local function ReceiveBoughtItem()
   local is_item = net.ReadBit() == 1
   local id = is_item and net.ReadUInt(16) or net.ReadString()

   -- I can imagine custom equipment wanting this, so making a hook
   hook.Run("TTTBoughtItem", is_item, id)
end
net.Receive("TTT_BoughtItem", ReceiveBoughtItem)
