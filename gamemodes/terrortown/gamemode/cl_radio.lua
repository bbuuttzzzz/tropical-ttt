--- Traitor radio controls

TRADIO = {}

local sound_names = {
   scream   ="radio_button_scream",
   explosion="radio_button_expl",
   pistol   ="radio_button_pistol",
   m16      ="radio_button_m16",
   deagle   ="radio_button_deagle",
   mac10    ="radio_button_mac10",
   shotgun  ="radio_button_shotgun",
   rifle    ="radio_button_rifle",
   huge     ="radio_button_huge",
   beeps    ="radio_button_c4",
   burning  ="radio_button_burn",
   footsteps="radio_button_steps"
};

local smatrix = {
   {"scream", "burning", "explosion", "footsteps"},
   {"pistol", "shotgun", "mac10", "deagle"},
   {"m16", "rifle", "huge", "beeps"}
};

local function PlayRadioSound(snd, url)
   local r = LocalPlayer().radio
   if IsValid(r) then
      RunConsoleCommand("ttt_radio_play", tostring(r:EntIndex()), snd, url)
   end
end

local function ButtonClickPlay(s) PlayRadioSound(s.snd) end

local function CreateSoundBoard(parent)
   local b = vgui.Create("DPanel", parent)

   --b:SetPaintBackground(false)

   local bh, bw = 50, 100
   local m = 5
   local ver = #smatrix
   local hor = #smatrix[1]

   local x, y = 0, 0
   for ri, row in ipairs(smatrix) do
      local rj = ri - 1 -- easier for computing x,y
      for rk, snd in ipairs(row) do
         local rl = rk - 1
         y = (rj * m) + (rj * bh)
         x = (rl * m) + (rl * bw)

         local but = vgui.Create("DButton", b)
         but:SetPos(x, y)
         but:SetSize(bw, bh)
         but:SetText(LANG.GetTranslation(sound_names[snd]))
         but.snd = snd
         but.DoClick = ButtonClickPlay
      end
   end

   b:SetSize(bw * hor + m * (hor - 1), bh * ver + m * (ver - 1))
   b:SetPos(m, 25)
   b:CenterHorizontal()

   return b
end

local function SpawnURLPlayPopup()

      local w, h = 300, 100

      local dframe = vgui.Create("DFrame")
      dframe:SetSize(w, h)
      dframe:Center()
      dframe:SetTitle(LANG.GetTranslation("radio_url_popup_title"))
      dframe:SetVisible(true)
      dframe:SetMouseInputEnabled(true)

      local textEntry = vgui.Create("DTextEntry", dframe)
      textEntry:StretchToParent(5, 25, 5, 45)
      textEntry:SetPlaceholderText("https://example.com/file.mp3")
      textEntry.OnEnter = function(self)
         PlayRadioSound("url", self:GetValue())
         dframe:Close()
      end

      local bw, bh = 75, 25
      local cancel = vgui.Create("DButton", dframe)
      cancel:SetPos(10, h - 40)
      cancel:SetSize(bw, bh)
      cancel:SetText(LANG.GetTranslation("radio_urlpop_cancel"))
      cancel.DoClick = function() dframe:Close() end

      local playButton = vgui.Create("DButton", dframe)
      playButton:SetPos(w - 185, h - 40)
      playButton:SetSize(175, bh)
      playButton:SetText(LANG.GetTranslation("radio_urlpop_accept"))
      playButton.DoClick = function()
         PlayRadioSound("url", textEntry:GetValue())
         dframe:Close()
      end

      dframe:MakePopup()
end

local function CreateURLPlayButton(parent, board)
   local b = vgui.Create("DPanel", parent)

   local width, boardHeight = board:GetSize()
   local boardX, _ = board:GetPos()
   local height = 30
   local m = 5

   b:SetSize(width, height)
   b:SetPos(boardX, 25 + boardHeight + m)

   local button = vgui.Create("DButton", b)
   button:StretchToParent(0,0,0,0)
   button:SetText(LANG.GetTranslation("radio_button_url"))
   button.DoClick = function() SpawnURLPlayPopup() end
end

function TRADIO.CreateMenu(parent)
   local w, h = parent:GetSize()

   local client = LocalPlayer()

   local wrap = vgui.Create("DPanel", parent)
   wrap:SetSize(w, h)
   wrap:SetPaintBackground(false)

   local dhelp = vgui.Create("DLabel", wrap)
   dhelp:SetFont("TabLarge")
   dhelp:SetText(LANG.GetTranslation("radio_help"))
   dhelp:SetTextColor(COLOR_WHITE)

   if IsValid(client.radio) then

      local board = CreateSoundBoard(wrap)
      local urlplaybutton = CreateURLPlayButton(wrap, board)

   elseif client:HasWeapon("weapon_ttt_radio") then
      dhelp:SetText(LANG.GetTranslation("radio_notplaced"))
   end

   dhelp:SizeToContents()
   dhelp:SetPos(10, 5)
   dhelp:CenterHorizontal()

   return wrap
end
