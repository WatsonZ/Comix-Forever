ComixVersion = "v8.2.5.4-forever";
ComixOptionsHeader = "Comix Options "..ComixVersion;

-- ---------------------------------------------------------------------------
-- Compatibility layer: lets the same code run on old and new WoW clients.
-- ---------------------------------------------------------------------------

-- SendChatMessage moved to C_ChatInfo in newer clients.
local Comix_SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

-- GetSpellInfo was removed in favour of C_Spell.GetSpellName.
local function Comix_GetSpellName(spellID)
  if not spellID then return nil end
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(spellID)
  elseif GetSpellInfo then
    return (GetSpellInfo(spellID))
  end
end

-- Newer clients hand out "secret" values in combat that cannot be compared.
local function Comix_IsSecret(v)
  return issecretvalue ~= nil and issecretvalue(v)
end

-- Some clients no longer let addons read the combat log.
Comix_CombatLogAvailable = false

-- /comix debug: print why events do or don't fire (not saved).
Comix_Debug = false
function Comix_Dbg(...)
  if not Comix_Debug then return end
  local parts = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if Comix_IsSecret(v) then
      parts[#parts+1] = "秘"
    else
      parts[#parts+1] = tostring(v)
    end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff999999[Comix调试]|r "..table.concat(parts, " "))
end

-- The XML <Backdrop> tag was removed; frames inherit BackdropTemplate and
-- pick up these tables through a "backdropInfo" KeyValue.
COMIX_BACKDROP_DIALOG = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
COMIX_BACKDROP_PLAIN = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  tile = true, tileSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
COMIX_BACKDROP_SLIDER = {
  bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
  edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 3, right = 3, top = 6, bottom = 6 },
}

function Comix_OnLoad()

  -- Registering Events --

  -- The combat log may be restricted for addons on newer clients; don't let
  -- that stop the rest of the addon from loading.
  if CombatLogGetCurrentEventInfo then
    Comix_CombatLogAvailable = pcall(Comix_Frame.RegisterEvent, Comix_Frame, "COMBAT_LOG_EVENT_UNFILTERED")
  end
  if not Comix_CombatLogAvailable then
    -- Fallback: UNIT_COMBAT still reports the hit type (CRITICAL) and school,
    -- but not who dealt it and the amount is secret.
    Comix_Frame:RegisterEvent("UNIT_COMBAT")
    Comix_Dbg("战斗日志不可用，已改用 UNIT_COMBAT")
  end

  Comix_Frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  Comix_Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  Comix_Frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
  Comix_Frame:RegisterEvent("CHAT_MSG_EMOTE")
  Comix_Frame:RegisterEvent("CHAT_MSG_YELL")
  Comix_Frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
  Comix_Frame:RegisterEvent("UNIT_HEALTH")
  Comix_Frame:RegisterEvent("UNIT_SPELLCAST_SENT")
  Comix_Frame:RegisterEvent("RESURRECT_REQUEST")
  Comix_Frame:RegisterEvent("PLAYER_ALIVE")
  Comix_Frame:RegisterEvent("PLAYER_UNGHOST")
  Comix_Frame:RegisterEvent("PLAYER_DEAD")
  Comix_Frame:RegisterEvent("READY_CHECK")
  Comix_Frame:RegisterEvent("PLAYER_LOGIN")


  -- Saying Hello --

  SlashCmdList["ComixJoke"] = Comix_BadJoke;
  SLASH_ComixJoke1 = "/badjoke";

  SlashCmdList["ComixFail"] = Comix_Fail;
  SLASH_ComixFail1 = "/fail";

  SlashCmdList["ComixAwesome"] = Comix_Awesome;
  SLASH_ComixAwesome1 = "/awesome";

  SlashCmdList["ComixDrama"] = Comix_Drama;
  SLASH_ComixDrama1 = "/drama";

  SlashCmdList["ComixReload"] = Comix_ReloadUI;
  SLASH_ComixReload1 = "/rl";

  dontfireonalive = false;
  loaded = false;
  unghosted = false;
  dead = false;

  -- Setting variables --
  Comix_ShakeEnabled = false;
  Comix_ShakeDuration = 1;
  Comix_ShakeIntensity = 70;
  Comix_ShakeOffset = 1;
  Comix_x_coord = 0;
  Comix_y_coord = 0;
  Comix_Max_Scale = 2;
  ComixCurrentFrameCt = 1;
  ComixCritCount = 0;
  ComixBuffCount = 0;
  ComixAniSpeed = 1;
  ComixMaxCrits = 3;
  ComixKillCount = 0;
  Comix_CritPercent = 100;
  Comix_CritGap = 0;
  Comix_FinishHimGap = 20;
  Comix_Overkill = 75;
  Comix_CurrentImage = nil;

  Comix_Frames = {};
  Comix_FramesScale = {}
  Comix_FramesVisibleTime = {}
  Comix_FramesStatus = {}
  Comix_textures = {};
  Comix_CritSoundsEnabled = true;
  Comix_CritHealsEnabled = true;
  Comix_SpecialsEnabled = true;
  Comix_KillCountEnabled = true;
  Comix_DeathSoundEnabled = true;
  ComixKillCountSoundPlayed = false;
  Comix_HuggedNotFound = false;
  Comix_AddOnEnabled = true;
  Comix_SoundEnabled = true;
  Comix_BS_Update = false;
  Comix_BSEnabled = true;
  Comix_DemoShoutEnabled = true;
  Comix_ZoneEnabled = false;
  Comix_FinishTarget = true;
  Comix_BamEnabled = false;
  Comix_ImagesEnabled = true;
  Comix_FinishhimEnabled = true;

  Comix_CritGapEnabled = false;
  Comix_OverkillEnabled = true;
  Comix_OneHit = false;

  Comix_PublicObjections = true;
  Comix_ObjectionSoundsEnabled = true;
  Comix_ObjectionImagesEnabled = true;

  -- reactions added for the UNIT_COMBAT fallback (无限)
  Comix_CritTakenEnabled = true;
  Comix_AvoidEnabled = true;

  Comix_BsShortDuration = true;
  Comix_HealorDmg = true;
  Comix_PlayerClass = UnitClass("player")

  Comix_CritFlashEnabled = true;
  Comix_HealFlashEnabled = true;
  Comix_BSSounds = true;
  Comix_DSSounds = true;
  Comix_BounceSoundEnabled = true;
  Comix_JumpCount = 0;
  Comix_ResSoundEnabled = true;
  Comix_ReadySoundEnabled = true;

  Comix_AbilitySoundsEnabled = true;

  -- These might be deprecated after the unit speed check change, don't remove util code is cleaned up more --
  forward = false;
  back = false;
  left = false;
  right = false;

  -- Hug Counter Variables --
  Comix_Hugs = {}
  Comix_Hugged = {}
  Comix_HugName = {}
  Comix_HugName[1] = UnitName("player")
  Comix_Hugs[1] = 0
  Comix_Hugged[1] = 0

  -- Calling functions to Create Frames and Load The Images/Sounds --
  Comix_CreateFrames();
  Comix_LoaddaShite();
  TimeSinceLastUpdate = 0;
  Comix_DongSound(ComixSpecialSounds, 6);

  DefaultWorldFramePoints = {}; -- for making sure the screen shakes are putting the world frame back in the right place

  -- Establish actual game version used for Classic / Retail API changes
  Comix_GameToc = select(4, GetBuildInfo());

  -- Slash Commands --
  SlashCmdList["Comix"] = Comix_Command;
  SLASH_Comix1 = "/Comix";
  SLASH_Comix2 = "/comix";
  SLASH_Comix3 = "/Comixreloaded";
  SLASH_Comix4 = "/comixreloaded";
  if Comix_GameToc < 16000 then
    SLASH_Comix5 = "/Comixclassic";
    SLASH_Comix6 = "/comixclassic";
  end
end

function startReadyCheck()
  if Comix_AddOnEnabled then
    if Comix_ReadySoundEnabled then
      Comix_DongSound(ComixReadySounds, fastrandom(1, ComixReadySoundsCt));
    end
  end
end

hooksecurefunc("DoReadyCheck", startReadyCheck)

function PlayBounceSound()
  if Comix_AddOnEnabled then
    local boing = false;

    if GetUnitSpeed("player") > 0 then
      boing = true;
    end

    if not UnitOnTaxi("player") then
      if IsMounted() then
        -- 无限 reports Interface 16001 but has flying, so test the API itself
        if IsFlying then
          -- DEFAULT_CHAT_FRAME:AddMessage("After TBC - Flying exists",1,0,0);
          -- DEFAULT_CHAT_FRAME:AddMessage(Comix_GameToc,1,0,0);
          if not IsFlying() then
            if boing then
              Comix_JumpCount = Comix_JumpCount + 1;
            end
            if Comix_BounceSoundEnabled and boing then
              Comix_DongSound(ComixSpecialSounds, 8);
            end
          end
        else
          -- DEFAULT_CHAT_FRAME:AddMessage("Classic - Flying API doesn't exist yet",1,0,0);
          -- DEFAULT_CHAT_FRAME:AddMessage(Comix_GameToc,1,0,0);
          if boing then
            Comix_JumpCount = Comix_JumpCount + 1;
          end
          if Comix_BounceSoundEnabled and boing then
            Comix_DongSound(ComixSpecialSounds, 8);
          end
        end
      else
        Comix_JumpCount = Comix_JumpCount + 1;
        if Comix_BounceSoundEnabled then
          Comix_DongSound(ComixSpecialSounds, 8);
        end
      end
    end
  end
end

hooksecurefunc("JumpOrAscendStart", PlayBounceSound)

-- These might be deprecated. Need to clean up more code to make sure --
function forwardstart()
  forward = true;
end

hooksecurefunc("MoveForwardStart", forwardstart)

function forwardstop()
  forward = false;
end

hooksecurefunc("MoveForwardStop", forwardstop)

function backstart()
  back = true;
end

hooksecurefunc("MoveBackwardStart", backstart)

function backstop()
  back = false;
end

hooksecurefunc("MoveBackwardStop", backstop)

function leftstart()
  left = true;
end

hooksecurefunc("StrafeLeftStart", leftstart)

function leftstop()
  left = false;
end

hooksecurefunc("StrafeLeftStop", leftstop)

function rightstart()
  right = true;
end

hooksecurefunc("StrafeRightStart", rightstart)

function rightstop()
  right = false;
end

hooksecurefunc("StrafeRightStop", rightstop)


function Comix_OnEvent(self, event, ...)
  --DEFAULT_CHAT_FRAME:AddMessage("ON EVENT LOLZ",0,0,1);
  -- The global arg1..argN variables no longer exist; take them from the event payload.
  local arg1, arg2, arg3, arg4 = ...

  local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, extraArg1, spellName, spellSchool, damageAmount, overkillAmount, extraArg6, critical, extraArg8, extraArg9, extraArg10
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, extraArg1, spellName, spellSchool, damageAmount, overkillAmount, extraArg6, critical, extraArg8, extraArg9, extraArg10 = CombatLogGetCurrentEventInfo()
    if sourceFlags == nil then
      return
    end
  elseif event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" or event == "CHAT_MSG_MONSTER_EMOTE" then
    -- chat text can be a protected "secret" value on newer clients
    if arg1 == nil or arg2 == nil or Comix_IsSecret(arg1) or Comix_IsSecret(arg2) then
      Comix_Dbg(event, "文字是保密值，跳过")
      return
    end
  end

  -- debug trace for everything except the high-frequency events
  if Comix_Debug and event ~= "UNIT_COMBAT" and event ~= "UNIT_HEALTH" and event ~= "COMBAT_LOG_EVENT_UNFILTERED" and event ~= "UNIT_SPELLCAST_SENT" then
    Comix_Dbg("事件", event, arg1, arg2)
  end

  if (Comix_AddOnEnabled) then

    if event == "UNIT_COMBAT" then
      Comix_OnUnitCombat(...)
      return
    end

    if event == "PLAYER_LOGIN" then
      --this gets the position of the world frame at player login or during an interface reload so that it knows where it should be
      for i = 1, WorldFrame:GetNumPoints() do
        local point, frame, relPoint, xOffset, yOffset = WorldFrame:GetPoint(i);
        --DEFAULT_CHAT_FRAME:AddMessage("p- "..point..",r- "..relPoint..",xO- "..xOffset..",yO- "..yOffset)
        DefaultWorldFramePoints[i] = {
          ["point"] = point,
          ["frame"] = frame,
          ["relPoint"] = relPoint,
          ["xOffset"] = xOffset,
          ["yOffset"] = yOffset,
        }
      end
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      --DEFAULT_CHAT_FRAME:AddMessage("COMBAT_LOG_EVENT_UNFILTERED fired "..select(2, ...));
      --DEFAULT_CHAT_FRAME:AddMessage("Should fire on self event "..select(2, ...));

      -- debug spells ;)
      --if sourceName == UnitName("player") then
      --  DEFAULT_CHAT_FRAME:AddMessage("tS:"..timestamp.." / subEvent: "..subEvent.." / eA1: "..tostring(extraArg1).." / spellName: "..tostring(spellName).." / spellSchool: "..tostring(spellSchool).." / damage: "..tostring(damageAmount).." / overkill: "..tostring(overkillAmount).." / eA6: "..tostring(extraArg6).." / critical: "..tostring(critical).." / eA8: "..tostring(extraArg8).." / eA9: "..tostring(extraArg9) .." / eA10: "..tostring(extraArg10));
      --end


      if subEvent == "SPELL_AURA_APPLIED" then
        if sourceName == UnitName("player") then
          --DEFAULT_CHAT_FRAME:AddMessage("Should fire on self event "..arg10);
          if spellName == COMIX_BS then
            if Comix_BSEnabled then
              Comix_Pic(0, 0,ComixSpecialImages[1])

              if Comix_BSSounds then
                Comix_DongSound(ComixSpecialSounds,1)
              end
            end
          elseif spellName == COMIX_DS or spellName == COMIX_DR then
            if Comix_DemoShoutEnabled then
              Comix_Pic(0, 0,ComixSpecialImages[2])

              if Comix_DSSounds then
                Comix_DongSound(ComixSpecialSounds,fastrandom(2,3))
              end
            end
          end
        end
      end


      if sourceFlags ~= nil then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
          if subEvent == "SPELL_HEAL" then
            if sourceName == UnitName("player") then
              --don't do anything for heals casted by player here
            else
              if destName == UnitName("player") then --someone cast a heal on the player we need to fire on a crit
                if critical == true then
                  if Comix_CritGapEnabled == true then
                    if damageAmount < Comix_CritGap then
                      return --nothin to see here
                    end
                  end
                  if fastrandom(1,100) <= Comix_CritPercent then
                    --heal cast on the player crit fire off stuff
                    --DEFAULT_CHAT_FRAME:AddMessage("heal crit fire friendly");
                    if Comix_HealFlashEnabled then
                      Comix_ScreenFlash(0, 1, 0, 1);
                      --UIFrameFlash( Comix_FrameFlash2, 0.5, 0.5, 2, false, 1, 0);
                    end
                    Comix_CallPic(ComixHolyHealImages[fastrandom(1, ComixHolyHealImagesCt)])
                    if Comix_CritHealsEnabled then
                      Comix_DongSound(ComixHealingSounds,fastrandom(1,ComixHealingSoundsCt))
                    end
                  end
                end
              end
            end
            --DEFAULT_CHAT_FRAME:AddMessage("Spell heal!! firing target = "..arg7);
          end
        end
      end

      if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
        if subEvent == "PARTY_KILL" then
          --DEFAULT_CHAT_FRAME:AddMessage("Should fire on self event "..arg2);
          KillCount()
        end
        --DEFAULT_CHAT_FRAME:AddMessage("Should fire on self event "..arg2);
        if subEvent == "SPELL_HEAL" then
          --DEFAULT_CHAT_FRAME:AddMessage("Spell heal firing arg11 = "..tostring(arg12).." "..arg13);
          if critical == true then
            if Comix_CritGapEnabled == true then
              if damageAmount < Comix_CritGap then
                return --nothin to see here
              end
            end

            if fastrandom(1,100) <= Comix_CritPercent then
              --DEFAULT_CHAT_FRAME:AddMessage("heal crit fire mine");
              if Comix_HealFlashEnabled then
                if destName == UnitName("player") then
                  --UIFrameFlash( Comix_FrameFlash2, 0.5, 0.5, 2, false, 1, 0); --self
                  Comix_ScreenFlash(0, 1, 0, 1);
                else
                  Comix_ScreenFlash(0, 1, 0, 2);
                  --	UIFrameFlash( Comix_FrameFlash4, 0.5, 0.5, 2, false, 1, 0);
                end
              end

              Comix_CallPic(ComixHolyHealImages[fastrandom(1, ComixHolyHealImagesCt)])
              if Comix_CritHealsEnabled then
                Comix_DongSound(ComixHealingSounds,fastrandom(1,ComixHealingSoundsCt))
              end
            end
          end
        end
        if subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" then
          --DEFAULT_CHAT_FRAME:AddMessage("spell/range_dmg fired "..arg10.." "..arg11.." "..arg15.." "..arg15.." "..tostring(critical));
          --DEFAULT_CHAT_FRAME:AddMessage("spell/range_dmg fired "..arg12 - arg13.." "..arg13 / (arg12 - arg13))

          --DEFAULT_CHAT_FRAME:AddMessage(damageAmount);
          --DEFAULT_CHAT_FRAME:AddMessage(overkillAmount);
          if Comix_OverkillEnabled == true and damageAmount ~= nil then

            if (damageAmount - overkillAmount) == 1 then
              --do nothing on training dummy
            else
              if overkillAmount / (damageAmount - overkillAmount) > Comix_Overkill / 100 then
                Comix_CallPic(ComixOverkillImages[fastrandom(1, ComixOverkillImagesCt)]);
                --DEFAULT_CHAT_FRAME:AddMessage("overkill")
              end
            end
          end

          --DEFAULT_CHAT_FRAME:AddMessage("crittest "..tostring(critical));
    			if extraArg10 == true then -- extraArg10 is critical with spelldamage
            if Comix_CritGapEnabled == true then

              if damageAmount < Comix_CritGap then
                return --nothin to see here
              end

            end


            if fastrandom(1,100) <= Comix_CritPercent then
              if Comix_ShakeEnabled then
                -- Disabled due to errors
                --Comix_ShakeScreen()
              end

              ComixCritCount = ComixCritCount + 1

              if ComixCritCount >= ComixMaxCrits then
                if Comix_SpecialsEnabled then
                  Comix_DongSound(ComixSpecialSounds,4)
                end
                Comix_Pic(Comix_x_coord+fastrandom(-15,15),Comix_y_coord+fastrandom(-20,20),ComixSpecialImages[3])
                ComixCritCount = 0
              end



              if Comix_CritSoundsEnabled then
                Comix_DongSound(ComixSounds)
              end
              if Comix_CritFlashEnabled then
                Comix_ScreenFlash(1, 0, 0, 2);
                --UIFrameFlash( Comix_FrameFlash3, 0.5, 0.5, 2, false, 1, 0);
              end

              if spellSchool == 16 then
                Comix_CallPic(ComixFrostImages[fastrandom(1,ComixFrostImagesCt)]);
              elseif spellSchool == 20 then
                Comix_CallPic(ComixFrostfireImages[fastrandom(1,ComixFrostfireImagesCt)]);
              elseif spellSchool == 4 then
                Comix_CallPic(ComixFireImages[fastrandom(1,ComixFireImagesCt)]);
              elseif spellSchool == 2 then
                Comix_CallPic(ComixHolyDmgImages[fastrandom(1,ComixHolyDmgImagesCt)]);
              elseif spellSchool == 8 then
                Comix_CallPic(ComixNatureImages[fastrandom(1,ComixNatureImagesCt)]);
              elseif spellSchool == 32 then
                Comix_CallPic(ComixShadowImages[fastrandom(1,ComixShadowImagesCt)]);
              elseif spellSchool == 36 then
                Comix_CallPic(ComixShadowflameImages[fastrandom(1,ComixShadowflameImagesCt)]);
              elseif spellSchool == 48 then
                Comix_CallPic(ComixShadowfrostImages[fastrandom(1,ComixShadowfrostImagesCt)]);
              elseif spellSchool == 64 then
                Comix_CallPic(ComixArcaneImages[fastrandom(1,ComixArcaneImagesCt)]);
              elseif spellSchool == 72 then
                Comix_CallPic(ComixSpellstormImages[fastrandom(1,ComixSpellstormImagesCt)]);
              elseif spellSchool == 1 then
                Comix_CallPic(ComixImages[fastrandom(1,ComixImagesCt)]);
              end

            end
          else
            ComixCritCount = 0
          end


        end

        if subEvent == "SWING_DAMAGE" then
          -- SWING_DAMAGE has no spell prefix: amount is field 12, overkill field 13
          damageAmount = extraArg1
          overkillAmount = spellName

          if Comix_OverkillEnabled == true and damageAmount ~= nil then
            if (damageAmount - overkillAmount) == 1 then
              --do nothing on training dummy
            else
              if overkillAmount / (damageAmount - overkillAmount) > Comix_Overkill / 100 then
                Comix_CallPic(ComixOverkillImages[fastrandom(1, ComixOverkillImagesCt)]);
                --DEFAULT_CHAT_FRAME:AddMessage("overkill")
              end
            end
          end

          if critical == true then

            if Comix_CritGapEnabled == true then

              if damageAmount < Comix_CritGap then
                return --nothin to see here
              end

            end


            if fastrandom(1,100) <= Comix_CritPercent then
              if Comix_ShakeEnabled then
                Comix_ShakeScreen()
              end
              ComixCritCount = ComixCritCount + 1

              if ComixCritCount >= ComixMaxCrits then
                if Comix_SpecialsEnabled then
                  Comix_DongSound(ComixSpecialSounds,4)
                end
                Comix_Pic(Comix_x_coord+fastrandom(-15,15),Comix_y_coord+fastrandom(-20,20),ComixSpecialImages[3])
                ComixCritCount = 0
              end

              if Comix_CritSoundsEnabled then
                Comix_DongSound(ComixSounds)
              end
              if Comix_CritFlashEnabled then
                Comix_ScreenFlash(1, 0, 0, 2);
                --UIFrameFlash( Comix_FrameFlash3, 0.5, 0.5, 2, false, 1, 0);
              end

              Comix_CallPic(ComixImages[fastrandom(1,ComixImagesCt)])
            end
          else
            ComixCritCount = 0
          end
        end
      end

    end




    if event == "READY_CHECK" then

      if Comix_ReadySoundEnabled then
        Comix_DongSound(ComixReadySounds, fastrandom(1, ComixReadySoundsCt));
      end
    end

    if event == "UNIT_HEALTH" then
      if arg1 == "target" then
        Comix_CheckTargetKill()
      end
      -- finish him --
      if Comix_FinishhimEnabled then
        if Comix_FinishTarget then
          if arg1 ~= "target" then
            return
          end
          local hp, hpMax = UnitHealth("target"), UnitHealthMax("target")
          if Comix_IsSecret(hp) or Comix_IsSecret(hpMax) then
            if not Comix_DbgHealthNoted then
              Comix_Dbg("目标血量是保密值，Finish Him 无法判断")
              Comix_DbgHealthNoted = true
            end
            return
          end
          if not hpMax or hpMax == 0 then
            return
          end
          if hp > 0 and not UnitIsFriend("player","target") then
            local TargetHealth = (hp / hpMax) * 100
            if TargetHealth < Comix_FinishHimGap then
              Comix_Dbg("Finish Him：目标血量", floor(TargetHealth), "%")
              Comix_DongSound(ComixSpecialSounds,12)
              Comix_FinishTarget = false
              Comix_OneHit = true;
            end
          end
        end
      end
    end


    -- Finish Him fallback: target health is secret on 无限, but fleeing mobs
    -- still announce "%s attempts to run away in fear!" at low health.
    if event == "CHAT_MSG_MONSTER_EMOTE" then
      if Comix_FinishhimEnabled and Comix_FinishTarget and COMIX_FLEE and strfind(arg1, COMIX_FLEE, 1, true) then
        Comix_Dbg("Finish Him：怪物逃跑", arg2)
        Comix_DongSound(ComixSpecialSounds,12)
        Comix_FinishTarget = false
        Comix_OneHit = true;
      end
    end

    if event == "PLAYER_DEAD" then
      --DEFAULT_CHAT_FRAME:AddMessage("dead",1,0,0)
      unghosted = false;
      dead = true
      ComixKillCount = 0; -- dying always ends the kill streak
      -- Oh poor guy ... you died ... noob :P --
      if Comix_DeathSoundEnabled then
        --if UnitIsDead("player") and strfind(arg1, getglobal("COMIX_YOUUP")) then
        Comix_CallPic(ComixDeathImages[fastrandom(1, ComixDeathImagesCt)]);
        Comix_DongSound(ComixDeathSounds,fastrandom(1,ComixDeathSoundsCt))
        ComixKillCount = 0;
        --end
      end

    end


    --res sound--
    if event == "RESURRECT_REQUEST" then
      --DEFAULT_CHAT_FRAME:AddMessage("res",1,0,0)
      unghosted = false;
      dontfireonalive = true;
      if Comix_ResSoundEnabled then
        Comix_DongSound(ComixResSounds, fastrandom(1, ComixResSoundsCt));
      end
    end

    -- zone change sounds --
    if event == "ZONE_CHANGED_NEW_AREA" then
      local ininstance, instancetype = IsInInstance();


      if ininstance then
        if instancetype == "party" or instancetype == "raid" then
          if Comix_SpecialsEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("[Dr. Evil] yells: Ladies and Gentlemen, Welcome to my Underground Lair!",1,0,0)
            Comix_DongSound(ComixSpecialSounds, 16); -- if specials are on we want a different sound when entering an instance, whether zone sounds are on or not --
          else
            if Comix_ZoneEnabled then
              Comix_DongSound(ComixZoneSounds,fastrandom(1,ComixZoneSoundsCt))
            end
          end
        else
          if Comix_ZoneEnabled then
            Comix_DongSound(ComixZoneSounds,fastrandom(1,ComixZoneSoundsCt))
          end
        end
      else
        if Comix_ZoneEnabled then
          Comix_DongSound(ComixZoneSounds,fastrandom(1,ComixZoneSoundsCt))
        end
      end


    end





    if event == "CHAT_MSG_EMOTE" then

      if Comix_SpecialsEnabled then
        if arg1 ~= nil then
          if strfind(arg1, COMIX_BADJOKE) then
            Comix_DongSound(ComixSpecialSounds, 17);
          end
          if strfind(arg1, COMIX_DRAMAEMOTE) then
            Comix_DongSound(ComixSpecialSounds, 19);
          end
        end
      end
    end

    -- These ability triggers seem bugged. Need more testing, but doesn't look like the event throws any arg at all
    -- Might be misunderstanding the trigger, but doesn't seem right at least
    -- Ability Sounds Checks - well besides cannibalize and sprint/dash --
    if event == "UNIT_SPELLCAST_SENT" then
      -- payload: unit, target, castGUID, spellID -> look up the localized spell name
      if arg1 ~= "player" then
        return
      end
      local arg2 = Comix_GetSpellName(arg4)
      if arg2 == nil or Comix_IsSecret(arg2) then
        return
      end
      Comix_Dbg("施法:", arg2)
      -- Battle Shout used to come from the combat log aura event; without the
      -- combat log, react to the cast instead.
      if not Comix_CombatLogAvailable and arg2 == COMIX_BS and Comix_BSEnabled then
        Comix_Pic(0, 0, ComixSpecialImages[1])
        if Comix_BSSounds then
          Comix_DongSound(ComixSpecialSounds,1)
        end
      end
      if Comix_DemoShoutEnabled then
        if arg2 == COMIX_DS or arg2 == COMIX_DR then
          Comix_Pic(0, 0,ComixSpecialImages[2])
        end
      end
      if Comix_AbilitySoundsEnabled then
        if arg2 == COMIX_ICEBLOCK then
          Comix_DongSound(ComixAbilitySounds, 2);
        elseif arg2 == COMIX_CANNIBALIZE then
          Comix_DongSound(ComixAbilitySounds, 1);
        elseif arg2 == COMIX_SPRINT or arg2 == COMIX_DASH or arg2 == COMIX_ASPECT then
          Comix_DongSound(ComixSpecialSounds,11)
        elseif arg2 == COMIX_DS or arg2 == COMIX_DR then
          if Comix_DemoShoutEnabled then
            if Comix_DSSounds then
              Comix_DongSound(ComixSpecialSounds,fastrandom(2,3))
            end
          end
        end
      end
    end



    -- Special Target Sounds --
    if event == "PLAYER_TARGET_CHANGED" then
      Comix_FinishTarget = true;
      Comix_DbgHealthNoted = false;

      if UnitName("target") == nil then
        return
      end

      if UnitName("target") == _G["COMIX_BIGGLESWORTH"] then
        Comix_DongSound(ComixSpecialSounds,5)
        DEFAULT_CHAT_FRAME:AddMessage("[Dr. Evil] yells: That makes me angry and when Dr. Evil gets angry Mr. Bigglesworth gets upset and when Mr. Bigglesworth gets upset...... PPL DIE!!!!!!!!11111oneoneoneoneeleveneleven",1,0,0)
        DEFAULT_CHAT_FRAME:AddMessage("[Venomia] yells: I COMMAND YOU!!! LEAVE THE CAT ALIVE OR YOU GET -50DKP!!!! (rly)",1,0,0)

      elseif UnitName("target") == _G["COMIX_REPAIRBOT"] or UnitName("target") == _G["COMIX_REPAIRBOT2"] then
        Comix_DongSound(ComixSpecialSounds,7)
        DEFAULT_CHAT_FRAME:AddMessage("["..UnitName("target").."]".." says: All your base, r belong to us")

      elseif UnitName("target") == _G["COMIX_MUFFIN"] then
        Comix_DongSound(ComixSpecialSounds, 10)
        DEFAULT_CHAT_FRAME:AddMessage("Do you know the Muffin Man???", 0,1,0)

      end

    end




    -- Hug Coounter .. FU String Manipulation!!! --
    if event == "CHAT_MSG_TEXT_EMOTE" then

      if arg1 ~= nil then

        if strfind(arg1, _G["COMIX_OBJECT"]) or strfind(arg1, _G["COMIX_OBJECTS"]) or strfind(arg1, _G["COMIX_OBJECTTO"]) or strfind(arg1, _G["COMIX_OBJECTSTO"]) then
          --			DEFAULT_CHAT_FRAME:AddMessage("OBJECTION from "..arg2.." "..UnitSex(arg2), 0,1,0)

          if UnitInParty(arg2) or UnitInRaid(arg2) then
            if Comix_ObjectionImagesEnabled then
              Comix_CallPic("portrait", arg2)
              Comix_CallPic(ComixSpecialImages[5])
            end

            if Comix_ObjectionSoundsEnabled then
              if UnitSex(arg2) == 3 then
                Comix_DongSound(ComixObjectionSounds, fastrandom(3, 4))
              else
                Comix_DongSound(ComixObjectionSounds, fastrandom(1, 2))
              end
            end

          else
            if Comix_PublicObjections then
              if Comix_ObjectionImagesEnabled then
                Comix_CallPic(ComixSpecialImages[5])
              end

              if Comix_ObjectionSoundsEnabled then
                Comix_DongSound(ComixObjectionSounds, fastrandom(1, 4))
              end

            end

          end
        end

        if strfind(arg1, _G["COMIX_HUG"]) or strfind(arg1,_G["COMIX_HUGS"]) then
          local HuggerNotFound = true
          local HuggedNotFound = true
          local comix_the_hugged_one = nil
          if strfind(arg1,_G["COMIX_HUGS"]) then
            if GetLocale() == "frFR" then
              comix_the_hugged_one = strsub(arg1,strfind(arg1,'%a+',13))
            else
              local gappie = tonumber(_G["COMIX_HUGGAP"])
              if arg2 == UnitName("player") then
                gappie = gappie + 3
              else
                gappie = gappie + strlen(arg2)
              end
              comix_the_hugged_one = strsub(arg1,strfind(arg1,'%a+',gappie))

            end
          elseif strfind(arg1,"vous serre ") then
            comix_the_hugged_one = UnitName("player")
          elseif strfind(arg1, _G["COMIX_HUG"]) then
            local gappie = tonumber(_G["COMIX_HUGGAP"])
            if arg2 == UnitName("player") then
              gappie = gappie + 3
            else
              gappie = gappie + strlen(arg2)
            end
            comix_the_hugged_one = strsub(arg1,strfind(arg1,'%a+',gappie))

          end

          if strfind(comix_the_hugged_one, _G["COMIX_YOULOW"]) then
            comix_the_hugged_one = UnitName("player")
          end

          for i, line in ipairs(Comix_HugName) do
            if comix_the_hugged_one == _G["COMIX_YOULOW"] then
              comix_the_hugged_one = UnitName("player")
            end

            if Comix_HugName[i] == arg2 then
              if not strfind(arg1, _G["COMIX_NEED"]) then
                Comix_Hugs[i] = Comix_Hugs[i]+1
                HuggerNotFound = false
              end
            end

            if Comix_HugName[i] == comix_the_hugged_one then
              Comix_Hugged[i] = Comix_Hugged[i]+1
              HuggedNotFound = false
            end

          end

          if HuggedNotFound then
            if not strfind(arg1, _G["COMIX_NEED"]) then
              Comix_HugName[#Comix_HugName+1] = comix_the_hugged_one
              Comix_Hugged[#Comix_HugName] = 1
              Comix_Hugs[#Comix_HugName] = 0
              Comix_HuggedNotFound = false;
            end
          end

          if HuggerNotFound then
            if not strfind(arg1, _G["COMIX_NEED"]) then
              Comix_HugName[#Comix_HugName+1] = arg2
              Comix_Hugs[#Comix_HugName] = 1
              Comix_Hugged[#Comix_HugName] = 0
              Comix_HuggedNotFound = false;
            end
          end

          for i,line in ipairs(Comix_HugName) do
            for j, line in ipairs(Comix_HugName) do
              if Comix_Hugged[i] > Comix_Hugged[j] then
                local Comix_TempHugged = Comix_Hugged[j]
                local Comix_TempHugs = Comix_Hugs[j]
                local Comix_TempHugName = Comix_HugName[j]
                Comix_Hugged[j] = Comix_Hugged[i]
                Comix_Hugs[j] = Comix_Hugs[i]
                Comix_HugName[j] = Comix_HugName[i]
                Comix_Hugged[i] = Comix_TempHugged
                Comix_Hugs[i] = Comix_TempHugs
                Comix_HugName[i] = Comix_TempHugName
              end
            end
          end
        end
      end
    end




  end
end

-- Picks the crit image set that matches a spell school bitmask.
function Comix_SchoolPic(school)
  if school == 16 then
    Comix_CallPic(ComixFrostImages[fastrandom(1,ComixFrostImagesCt)]);
  elseif school == 20 then
    Comix_CallPic(ComixFrostfireImages[fastrandom(1,ComixFrostfireImagesCt)]);
  elseif school == 4 then
    Comix_CallPic(ComixFireImages[fastrandom(1,ComixFireImagesCt)]);
  elseif school == 2 then
    Comix_CallPic(ComixHolyDmgImages[fastrandom(1,ComixHolyDmgImagesCt)]);
  elseif school == 8 then
    Comix_CallPic(ComixNatureImages[fastrandom(1,ComixNatureImagesCt)]);
  elseif school == 32 then
    Comix_CallPic(ComixShadowImages[fastrandom(1,ComixShadowImagesCt)]);
  elseif school == 36 then
    Comix_CallPic(ComixShadowflameImages[fastrandom(1,ComixShadowflameImagesCt)]);
  elseif school == 48 then
    Comix_CallPic(ComixShadowfrostImages[fastrandom(1,ComixShadowfrostImagesCt)]);
  elseif school == 64 then
    Comix_CallPic(ComixArcaneImages[fastrandom(1,ComixArcaneImagesCt)]);
  elseif school == 72 then
    Comix_CallPic(ComixSpellstormImages[fastrandom(1,ComixSpellstormImagesCt)]);
  else
    Comix_CallPic(ComixImages[fastrandom(1,ComixImagesCt)]);
  end
end

-- Kill detection without the combat log: the current target was hit while
-- targeted, is now dead, and was not tapped by someone else.
Comix_HitGUID = nil
Comix_CountedGUID = nil
function Comix_CheckTargetKill()
  if Comix_CombatLogAvailable then return end -- PARTY_KILL handles it there
  local guid = UnitGUID("target")
  if guid == nil or Comix_IsSecret(guid) or guid ~= Comix_HitGUID or guid == Comix_CountedGUID then
    return
  end
  local dead = UnitIsDead("target")
  if Comix_IsSecret(dead) or not dead then
    return
  end
  local denied = UnitIsTapDenied("target")
  if Comix_IsSecret(denied) or denied then
    Comix_Dbg("目标死亡，但不是你的怪（灰名），不计连杀")
    Comix_CountedGUID = guid
    return
  end
  Comix_CountedGUID = guid
  KillCount()
  Comix_Dbg("击杀！连杀数:", ComixKillCount)
end

-- throttle so heavy fights don't turn into a wall of noise
Comix_LastCritTaken = 0
Comix_LastAvoid = 0
local Comix_AvoidActions = { DODGE = true, PARRY = true, BLOCK = true, MISS = true, RESIST = true, IMMUNE = true, DEFLECT = true, EVADE = true, REFLECT = true }

-- UNIT_COMBAT fallback for clients without combat log access (无限).
-- payload: unit, action ("WOUND"/"HEAL"/...), descriptor ("CRITICAL"/""/...), amount (secret), school
function Comix_OnUnitCombat(unit, action, descriptor, amount, school)
  if Comix_IsSecret(unit) or Comix_IsSecret(action) or Comix_IsSecret(descriptor) then
    return
  end
  if Comix_IsSecret(school) then
    school = 1
  end
  -- the same hit is also reported for nameplateN / softenemy / pet; only use target and player
  if unit ~= "target" and unit ~= "player" then
    return
  end
  local isCrit = (descriptor == "CRITICAL")
  if isCrit then
    Comix_Dbg("UNIT_COMBAT 爆击:", unit, action, school)
  end

  if unit == "player" then
    -- you got crit by something
    if action == "WOUND" and isCrit and Comix_CritTakenEnabled and GetTime() - Comix_LastCritTaken > 3 then
      Comix_LastCritTaken = GetTime()
      Comix_Dbg("你被爆击了")
      if Comix_CritFlashEnabled then
        Comix_ScreenFlash(1, 0, 0, 1);
      end
      Comix_DongSound(ComixDeathSounds, fastrandom(4, 6)) -- whoa / whoops / oh no
      return
    end
    -- you dodged / parried / blocked / resisted ...
    if Comix_AvoidActions[action] and Comix_AvoidEnabled and GetTime() - Comix_LastAvoid > 2 then
      Comix_LastAvoid = GetTime()
      Comix_Dbg("你躲开了:", action)
      Comix_CallPic(ComixSpecialImages[4])
      Comix_DongSound(ComixSpecialSounds, 8) -- boing
      return
    end
  end

  if unit == "target" and action == "WOUND" then
    -- damage dealt to the current hostile target (the source is not known)
    if UnitIsFriend("player", "target") then
      return
    end
    -- remember we fought this target, then see whether that hit killed it
    local guid = UnitGUID("target")
    if guid and not Comix_IsSecret(guid) then
      Comix_HitGUID = guid
    end
    Comix_CheckTargetKill()
    if not isCrit then
      ComixCritCount = 0
      return
    end
    if fastrandom(1,100) > Comix_CritPercent then
      return
    end
    ComixCritCount = ComixCritCount + 1
    if ComixCritCount >= ComixMaxCrits then
      if Comix_SpecialsEnabled then
        Comix_DongSound(ComixSpecialSounds,4)
      end
      Comix_Pic(Comix_x_coord+fastrandom(-15,15),Comix_y_coord+fastrandom(-20,20),ComixSpecialImages[3])
      ComixCritCount = 0
    end
    if Comix_CritSoundsEnabled then
      Comix_DongSound(ComixSounds)
    end
    if Comix_CritFlashEnabled then
      Comix_ScreenFlash(1, 0, 0, 2);
    end
    Comix_SchoolPic(school)

  elseif action == "HEAL" and isCrit then
    -- heal crit on yourself (big flash) or on your friendly target (small flash)
    if unit == "target" and (UnitIsUnit("target", "player") or not UnitIsFriend("player", "target")) then
      return
    end
    if fastrandom(1,100) > Comix_CritPercent then
      return
    end
    if Comix_HealFlashEnabled then
      Comix_ScreenFlash(0, 1, 0, unit == "player" and 1 or 2);
    end
    Comix_CallPic(ComixHolyHealImages[fastrandom(1, ComixHolyHealImagesCt)])
    if Comix_CritHealsEnabled then
      Comix_DongSound(ComixHealingSounds,fastrandom(1,ComixHealingSoundsCt))
    end
  end
end

function KillCount()
  if Comix_KillCountEnabled then

    --if strfind(arg1,getglobal("COMIX_YOUUP")) then
    ComixKillCount = ComixKillCount +1;
    ComixKillCountSoundPlayed = false;
    --end

    if ComixKillCountSoundPlayed == false then
      if ComixKillCount == 2 then
        Comix_DongSound(ComixKillCountSounds,1)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 5 then
        Comix_DongSound(ComixKillCountSounds,2)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 8 then
        Comix_DongSound(ComixKillCountSounds,3)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 10 then
        Comix_DongSound(ComixKillCountSounds,4)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 15 then
        Comix_DongSound(ComixKillCountSounds,5)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 20 then
        Comix_DongSound(ComixKillCountSounds,6)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 30 then
        Comix_DongSound(ComixKillCountSounds,7)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 40 then
        Comix_DongSound(ComixKillCountSounds,8)
        ComixKillCountSoundPlayed = true
      elseif ComixKillCount == 50 then
        Comix_DongSound(ComixKillCountSounds,9)
        ComixKillCountSoundPlayed = true
      end
    end
  end
end

function Comix_ShakeScreen()
  if Comix_AddOnEnabled then
    if Comix_ShakeEnabled then
      if not IsShaking then
        OldWorldFramePoints = {};
        for i = 1, WorldFrame:GetNumPoints() do
          local point, frame, relPoint, xOffset, yOffset = WorldFrame:GetPoint(i);
          --DEFAULT_CHAT_FRAME:AddMessage("p- "..point..",r- "..relPoint..",xO- "..xOffset..",yO- "..yOffset)
          --need to make sure the offset is the same as the default one
          --DEFAULT_CHAT_FRAME:AddMessage(tostring(DefaultWorldFramePoints[i]["xOffset"]))
          if xOffset ~= DefaultWorldFramePoints[i]["xOffset"] then
            --DEFAULT_CHAT_FRAME:AddMessage("X OFFSET "..xOffset.." WRONG using default "..DefaultWorldFramePoints[i]["xOffset"])
            xOffset = DefaultWorldFramePoints[i]["xOffset"]

          end

          if yOffset ~= DefaultWorldFramePoints[i]["yOffset"] then
            --	DEFAULT_CHAT_FRAME:AddMessage("Y OFFSET "..yOffset.." WRONG using default "..DefaultWorldFramePoints[i]["yOffset"])
            yOffset = DefaultWorldFramePoints[i]["yOffset"]
          end


          OldWorldFramePoints[i] = {
            ["point"] = point,
            ["frame"] = frame,
            ["relPoint"] = relPoint,
            ["xOffset"] = xOffset,
            ["yOffset"] = yOffset,
          }
        end
        IsShaking = Comix_ShakeDuration;
      end
    end
  end
end

Comix_UpdateInterval = .008
function Comix_OnUpdate(self, elapsed)
  local TimeSinceLastUpdate = 0;
  if elapsed == nil then
    elapsed = 0
  end
  -- DEFAULT_CHAT_FRAME:AddMessage("ding "..elapsed);

  TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed;

  while (TimeSinceLastUpdate > Comix_UpdateInterval) do

    -- ScreenShake
    --			if type(IsShaking) == "number" then
    --			IsShaking = IsShaking - elapsed;
    --			if IsShaking <= 0 then
    --				WorldFrame:ClearAllPoints();
    --				for index, value in pairs(OldWorldFramePoints) do
    --					WorldFrame:SetPoint(value.point, value.xOffset, value.yOffset);
    --				end
    --				IsShaking = false;
    --			else
    --				WorldFrame:ClearAllPoints();
    --				local moveBy;
    --				moveBy = fastrandom(-100, 100)/(101 - Comix_ShakeIntensity - (Comix_ShakeOffset - 1));
    --				for index, value in pairs(OldWorldFramePoints) do
    --					WorldFrame:SetPoint(value.point, value.xOffset + moveBy, value.yOffset + moveBy);
    --				end
    --			end
    --		end

    --The Picture Animation
    for i = 1,5 do
      if Comix_Frames[i] ~= nil then
        if Comix_Frames[i]:IsVisible() then
          if Comix_FramesStatus[i] == 0 then
            Comix_FramesScale[i] = Comix_FramesScale[i]*1.1*ComixAniSpeed
            if Comix_FramesScale[i] >= Comix_Max_Scale then
              Comix_FramesScale[i] = Comix_Max_Scale
              Comix_FramesStatus[i] = 1
            end
            Comix_Frames[i]:SetScale(Comix_FramesScale[i])
          elseif Comix_FramesStatus[i] == 1 then
            Comix_FramesScale[i] = Comix_Max_Scale--Comix_FramesScale[i]*0.8
            Comix_Frames[i]:SetScale(Comix_FramesScale[i])
            if Comix_FramesScale[i] >= Comix_Max_Scale*0.4 then
              Comix_FramesStatus[i] = 2
            end
          elseif Comix_FramesStatus[i] == 2 then
            Comix_FramesVisibleTime[i] = Comix_FramesVisibleTime[i] + 0.01
            if Comix_FramesVisibleTime[i] >= 1.0 then
              Comix_FramesStatus[i] = 3
            end
          elseif Comix_FramesStatus[i] == 3 then
            Comix_FramesScale[i] = Comix_FramesScale[i]*0.5
            Comix_Frames[i]:SetScale(Comix_FramesScale[i])
            if Comix_FramesScale[i] <= 0.2 then
              Comix_Frames[i]:Hide()
              Comix_FramesStatus[i] = 0
              Comix_FramesScale[i] = 0.2
              Comix_FramesVisibleTime[i] = 0
            end
          end
        end
      end
    end



    TimeSinceLastUpdate = TimeSinceLastUpdate-Comix_UpdateInterval;
  end



end

function Comix_Command(Nerd)

  Nerd = strlower(Nerd)

  if (Nerd == "create") then
    DEFAULT_CHAT_FRAME:AddMessage("Me Creates: Hello World")
    Comix_DongSound(ComixSpecialSounds,15)


    --elseif(Nerd == "deathtest") then
    --Comix_CallPic(ComixDeathImages[fastrandom(1, ComixDeathImagesCt)]);

    -- elseif(Nerd == "test1") then
    -- Comix_ScreenFlash(1, 0, 0, 1);


    -- elseif(Nerd == "test2") then
    -- Comix_ScreenFlash(1, 0, 1, 1);


    -- elseif(Nerd == "test3") then
    -- Comix_ScreenFlash(1, 0, 0, 2);


    -- elseif(Nerd == "test4") then
    -- Comix_ScreenFlash(0, 1, 1, 2);
  elseif (Nerd == "help") then
    Comix_ShowHelp()

  elseif (Nerd == "debug") then
    Comix_Debug = not Comix_Debug
    print(Comix_Debug and "[Comix] 调试已开启（/comix debug 关闭）" or "[Comix] 调试已关闭")
    if Comix_Debug then
      local S = function(b) return b and "开" or "关" end
      print("[Comix] 战斗日志:", S(Comix_CombatLogAvailable), " 插件:", S(Comix_AddOnEnabled), " 声音:", S(Comix_SoundEnabled), " 图片:", S(Comix_ImagesEnabled))
      print("[Comix] 死亡:", S(Comix_DeathSoundEnabled), " 复活:", S(Comix_ResSoundEnabled), " 就位:", S(Comix_ReadySoundEnabled), " 区域:", S(Comix_ZoneEnabled), " 特殊:", S(Comix_SpecialsEnabled), " FinishHim:", S(Comix_FinishhimEnabled), " 技能:", S(Comix_AbilitySoundsEnabled), " 跳跃:", S(Comix_BounceSoundEnabled))
    end

  elseif (Nerd == "test") then
    -- play every effect once, 2 seconds apart, to check images/sounds work.
    -- Only one run at a time: asking again while it runs stops it.
    Comix_TestRunId = (Comix_TestRunId or 0) + 1
    if Comix_TestRunning then
      Comix_TestRunning = false
      print(Comix_OptionsText().testStopped)
      if Comix_RefreshOptionsText then Comix_RefreshOptionsText() end
      return
    end
    local runId = Comix_TestRunId
    Comix_TestRunning = true
    if Comix_RefreshOptionsText then Comix_RefreshOptionsText() end
    local steps = {
      { "死亡", function() Comix_CallPic(ComixDeathImages[fastrandom(1, ComixDeathImagesCt)]); Comix_DongSound(ComixDeathSounds, fastrandom(1, ComixDeathSoundsCt)) end },
      { "复活", function() Comix_DongSound(ComixResSounds, fastrandom(1, ComixResSoundsCt)) end },
      { "就位确认", function() Comix_DongSound(ComixReadySounds, fastrandom(1, ComixReadySoundsCt)) end },
      { "治疗爆击", function() Comix_ScreenFlash(0, 1, 0, 1); Comix_CallPic(ComixHolyHealImages[fastrandom(1, ComixHolyHealImagesCt)]); Comix_DongSound(ComixHealingSounds, fastrandom(1, ComixHealingSoundsCt)) end },
      { "战斗怒吼", function() Comix_Pic(0, 0, ComixSpecialImages[1]); Comix_DongSound(ComixSpecialSounds, 1) end },
      { "挫志怒吼", function() Comix_Pic(0, 0, ComixSpecialImages[2]); Comix_DongSound(ComixSpecialSounds, 2) end },
      { "Impressive", function() Comix_Pic(0, 0, ComixSpecialImages[3]); Comix_DongSound(ComixSpecialSounds, 4) end },
      { "Finish Him", function() Comix_DongSound(ComixSpecialSounds, 12) end },
      { "技能（疾跑）", function() Comix_DongSound(ComixSpecialSounds, 11) end },
      { "异议", function() Comix_CallPic(ComixSpecialImages[5]); Comix_DongSound(ComixObjectionSounds, fastrandom(1, 4)) end },
      { "切换区域", function() Comix_DongSound(ComixZoneSounds, fastrandom(1, ComixZoneSoundsCt)) end },
      { "进入副本", function() Comix_DongSound(ComixSpecialSounds, 16) end },
      { "超杀图片", function() Comix_CallPic(ComixOverkillImages[fastrandom(1, ComixOverkillImagesCt)]) end },
      { "被爆击", function() Comix_ScreenFlash(1, 0, 0, 1); Comix_DongSound(ComixDeathSounds, fastrandom(4, 6)) end },
      { "闪避/招架", function() Comix_CallPic(ComixSpecialImages[4]); Comix_DongSound(ComixSpecialSounds, 8) end },
      { "连杀（Killing Spree）", function() Comix_DongSound(ComixKillCountSounds, 1) end },
    }
    for i, step in ipairs(steps) do
      C_Timer.After((i - 1) * 2, function()
        if runId ~= Comix_TestRunId then return end -- stopped or restarted
        print("[Comix] 测试 "..i.."/"..#steps..": "..step[1])
        step[2]()
        if i == #steps then
          Comix_TestRunning = false
          if Comix_RefreshOptionsText then Comix_RefreshOptionsText() end
        end
      end)
    end

  elseif (Nerd == "lang" or strsub(Nerd, 1, 5) == "lang ") then
    -- /comix lang [zh|en|auto]
    Comix_SetOptionsLang(strtrim(strsub(Nerd, 6)))



    elseif (Nerd == "hide") then
      Comix_Framehide();

    elseif (Nerd == "pic") then
      Comix_CallPic(ComixImages[fastrandom(1,ComixImagesCt)]);

    elseif (Nerd == "specialpic") then
      Comix_CallPic(ComixSpecialImages[fastrandom(1,ComixSpecialCt)]);

    elseif (Nerd == "clearhug") then
      for i, line in ipairs(Comix_HugName) do
        Comix_HugName[i] = nil ;
        Comix_Hugged[i] = nil;
        Comix_Hugs[i] = nil;
      end
      Comix_HugName[1] = UnitName("player")
      Comix_Hugs[1] = 0
      Comix_Hugged[1] = 0

    elseif (Nerd == "showhug") then
      for i = 1,5 do
        if Comix_HugName[i] ~= nil then
          DEFAULT_CHAT_FRAME:AddMessage("[Hug Report]: "..Comix_HugName[i].." has been hugged " ..Comix_Hugged[i].." times and Hugged "..Comix_Hugs[i].." times",0,0,1)
        end
      end

    elseif (Nerd == "reporthug") then
      for i = 1,5 do
        if Comix_HugName[i] ~= nil then
          Comix_SendChat("[Hug Report]: "..Comix_HugName[i].." has been hugged " ..Comix_Hugged[i].." times and Hugged "..Comix_Hugs[i].." times", "SAY")
        end
      end


    elseif (Nerd == "clearjump") then
      Comix_JumpCount = 0;
      DEFAULT_CHAT_FRAME:AddMessage("Jump Counter Reset",0,0,1)

    elseif (Nerd == "showjump") then
      DEFAULT_CHAT_FRAME:AddMessage("[Jump Report]: "..UnitName("player").." has jumped " ..Comix_JumpCount.." times",0,0.5,1)


    elseif (Nerd == "reportjump") then
      Comix_SendChat("[Jump Report]: "..UnitName("player").." has jumped " ..Comix_JumpCount.." times", "SAY")

    elseif (Nerd == "probe") then
      -- Debug helper: print the first 15 UNIT_COMBAT payloads, showing
      -- "秘" for values the client keeps secret.
      local S = issecretvalue or function() return false end
      local function V(x) if S(x) then return "秘" end return tostring(x) end
      if not ComixProbeFrame then
        ComixProbeFrame = CreateFrame("Frame")
        ComixProbeFrame:SetScript("OnEvent", function(self, e, u, a, d, v, s)
          self.n = self.n + 1
          if self.n <= 15 then
            print("UC", self.n, V(u), V(a), V(d), V(v), V(s))
          else
            self:UnregisterAllEvents()
            print("[Comix] 探测结束")
          end
        end)
      end
      ComixProbeFrame.n = 0
      ComixProbeFrame:RegisterEvent("UNIT_COMBAT")
      print("[Comix] 探测已开启，去打怪吧")

    elseif (Nerd == "about") then
      DEFAULT_CHAT_FRAME:AddMessage("[Comix] "..Comix_OptionsText().author.." / "..Comix_OptionsText().original.." / Version: "..ComixVersion,0,0.5,1)


    elseif (Nerd == "minimap") then
      Comix_MinimapHidden = not Comix_MinimapHidden
      Comix_UpdateMinimapButton()

    else
      Comix_ToggleOptions()

    end

  end

  function Comix_BadJoke()

    if UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
      Comix_SendChat(COMIX_JOKEEMOTE2A..UnitName("target")..COMIX_JOKEEMOTE2B, "EMOTE");
    else
      Comix_SendChat(COMIX_JOKEEMOTE1, "EMOTE");
    end


  end

  function Comix_Drama()
    Comix_SendChat(COMIX_DRAMAEMOTE, "EMOTE");
  end

  function Comix_ReloadUI()
    ReloadUI()
  end

  function Comix_Fail(msg)
    local link = "\124cff71d5ff\124Hspell:65311\124h[Supermassive Fail]\124h\124r"
    msgSender(msg,link)
  end

  function Comix_Awesome(msg)
    local link = "\124cff71d5ff\124Hspell:58783\124h[Pure Awesome]\124h\124r"
    msgSender(msg, link)
  end

  function msgSender(message,link)
    local command, txt = message:match("^(%S*)%s*(.-)$")
    local fl = GetDefaultLanguage("PLAYER")
    txt = gsub(txt,"~~",link)
    if command == "say" or command == "emote" or command == "yell" or command == "party" or command == "guild" or command == "officer" or command == "raid" or command == "rw" or command == "bg" or command == "afk" or command == "dnd" then
      if command == "bg" then
        command = "INSTANCE_CHAT"
      end
      if command == "rw" then
        command = "raid_warning"
      end
      Comix_SendChat(txt,command)
    elseif tonumber(command) ~= nil and tonumber(command) > 0 and tonumber(command) < 100 then
      Comix_SendChat(txt,"channel",fl,command)
    else
      Comix_SendChat(txt,"whisper",fl,command)
    end
  end




  function Comix_DongSound(SoundTable,Sound)
    if not Comix_AddOnEnabled then
      return
    end
    if Comix_SoundEnabled then
      if SoundTable == ComixSounds then
        if Comix_BamEnabled then
          PlaySoundFile("Interface\\AddOns\\Comix\\Sounds\\"..ComixSpecialSounds[13])
        else
          local randsound = fastrandom(1,ComixSoundsCt)
          PlaySoundFile("Interface\\AddOns\\Comix\\Sounds\\"..SoundTable[randsound]);
        end
      else if SoundTable == "customcomixsound" then
        PlaySoundFile(Sound)

      else
        PlaySoundFile("Interface\\AddOns\\Comix\\Sounds\\"..SoundTable[Sound]);
      end
    end
  end

end



function Comix_Pic(x,y,Pic, name)

  if Comix_ImagesEnabled then
    -- Resetting Frames animation values --
    if Comix_Frames[ComixCurrentFrameCt]:IsVisible() then
      Comix_Frames[ComixCurrentFrameCt]:Hide()
    end
    Comix_FramesStatus[ComixCurrentFrameCt] = 0
    Comix_FramesScale[ComixCurrentFrameCt] = 0.2
    Comix_FramesVisibleTime[ComixCurrentFrameCt] = 0

    -- Setting Texture --
    if Pic == "portrait" then
      SetPortraitTexture(Comix_textures[ComixCurrentFrameCt], name);
    else if name == "customcomixpic" then
      Comix_textures[ComixCurrentFrameCt]:SetTexture(Pic);
    else
      Comix_textures[ComixCurrentFrameCt]:SetTexture("Interface\\Addons\\Comix\\"..Pic);
    end
  end
  Comix_textures[ComixCurrentFrameCt]:SetAllPoints(Comix_Frames[ComixCurrentFrameCt]);
  Comix_Frames[ComixCurrentFrameCt].texture = Comix_textures[ComixCurrentFrameCt];

  -- Positioning Frame --
  if Pic == "portrait" then
    Comix_Frames[ComixCurrentFrameCt]:SetPoint("Center",-150,-50);
  else
    Comix_Frames[ComixCurrentFrameCt]:SetPoint("Center",x,y);
  end
  Comix_Frames[ComixCurrentFrameCt]:Show();

  -- Increasing Current Frame or resetting it to 1 --
  if ComixCurrentFrameCt == 5 then
    ComixCurrentFrameCt = 1
  else
    ComixCurrentFrameCt = ComixCurrentFrameCt +1
  end
end
end

function Comix_LoaddaShite()

  -- Counting Normal Images --
  ComixImagesCt = #ComixImages

  -- Counting Images in Image-Sets --
  ComixFireImagesCt = #ComixFireImages

  ComixFrostImagesCt = #ComixFrostImages

  ComixFrostfireImagesCt = #ComixFrostfireImages

  ComixSpellstormImagesCt = #ComixSpellstormImages

  ComixShadowflameImagesCt = #ComixShadowflameImages

  ComixShadowfrostImagesCt = #ComixShadowfrostImages

  ComixShadowImagesCt = #ComixShadowImages

  ComixNatureImagesCt = #ComixNatureImages

  ComixArcaneImagesCt = #ComixArcaneImages

  ComixHolyHealImagesCt = #ComixHolyHealImages

  ComixHolyDmgImagesCt = #ComixHolyDmgImages

  ComixDeathImagesCt = #ComixDeathImages

  ComixOverkillImagesCt = #ComixOverkillImages

  -- Counting Normal Sounds --
  ComixSoundsCt = #ComixSounds

  -- Counting Zone Sounds --
  ComixZoneSoundsCt = #ComixZoneSounds

  -- Counting One hit Sounds --
  ComixOneHitSoundsCt = #ComixOneHitSounds

  -- Counting Healing Sounds --
  ComixHealingSoundsCt = #ComixHealingSounds


  -- Counting Specials --
  ComixSpecialCt = #ComixSpecialImages

  -- Counting Ability Sounds --
  ComixAbilitySoundsCt = #ComixAbilitySounds

  -- Counting Death Sounds --
  ComixDeathSoundsCt = #ComixDeathSounds

  -- Counting Ready check Sounds --
  ComixReadySoundsCt = #ComixReadySounds

  -- Counting Res Sounds --
  ComixResSoundsCt = #ComixResSounds



end

function Comix_Framehide()
  for i,line in ipairs(Comix_Frames) do
    Comix_Frames[i]:Hide();
    DEFAULT_CHAT_FRAME:AddMessage("Hiding Comix_Frames["..i.."]")
  end
end



function Comix_CallPic(Image, name)
  if not Comix_AddOnEnabled then
    return
  end

  if Comix_ImagesEnabled then
    -- Creating x,y Coordinates --
    Comix_x_coord = fastrandom(-120,120)
    if Comix_x_coord <= 0 then
      Comix_x_coord = Comix_x_coord -40
    else
      Comix_x_coord= Comix_x_coord +40
    end

    if (abs(Comix_x_coord)<75) then
      local y_buffer = 50
      Comix_y_coord = fastrandom(y_buffer,130)
    else
      Comix_y_coord = fastrandom(0,130)
    end

    -- Finally handing over x,y Coords and the image to show --
    Comix_CurrentImage = Image
    Comix_Pic(Comix_x_coord,Comix_y_coord,Image, name, gen)
  end

end



function Comix_CreateFrames()
  -- Creating 5 Frames, creating 5 Textures and setting FramesScale, FramesVisibleTime & FramesStatus--
  for i = 1,5 do
    -- Create Frame --
    Comix_Frames[i] = CreateFrame("Frame","ComixFrame"..i,UIParent)
    Comix_Frames[i]:SetWidth(128);
    Comix_Frames[i]:SetHeight(128);
    Comix_Frames[i]:Hide()
    -- Create texture for each frame --
    Comix_textures[i] = Comix_Frames[i]:CreateTexture(nil,"BACKGROUND")
    -- Setting FramesScale, FramesVisibleTime & FramesStatus  to 0 --
    Comix_FramesScale[i] = 0.2
    Comix_FramesVisibleTime[i] = 0
    Comix_FramesStatus[i] = 0
  end


  Comix_FrameFlashTexture:SetVertexColor(1,0,0);

end


--Functions for outside mods to access comix functions easier also for ComixPlus support
function Comix_CustomPic(path)
  Comix_CallPic(path, "customcomixpic");
end

function Comix_CustomSound(path)
  Comix_DongSound("customcomixsound", path);
end

function Comix_ScreenFlash(r, g, b, size)

  if size < 1 then
    size = 1
  end

  if size > 2 then
    size = 2
  end

  Comix_FrameFlashTexture:SetTexture("Interface\\Addons\\Comix\\Images\\flash"..size..".tga")

  Comix_FrameFlashTexture:SetVertexColor(r, g, b)

  -- Self-contained flash animation (UIFrameFlash is not guaranteed to exist
  -- on every client). Fade in 0.5s, hold 1s, fade out 0.5s, then hide.
  local f = Comix_FrameFlash
  if not f.ComixFlashAnim then
    local ag = f:CreateAnimationGroup()
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(1)
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetStartDelay(1)
    fadeOut:SetOrder(2)
    ag:SetScript("OnFinished", function()
      f:SetAlpha(0)
      f:Hide()
    end)
    f.ComixFlashAnim = ag
  end

  f.ComixFlashAnim:Stop()
  f:SetAlpha(0)
  f:Show()
  f.ComixFlashAnim:Play()

end

function Comix_ActivatePlus()
  if comixheader then
    comixheader:SetText("COMIX +")
  end
end
