local SR_REP_MSG = "%s(%d/%d)：%+d声望";
local rep = {};
--额外声望
local extraRep = {};
local C_Reputation_IsFactionParagon = C_Reputation.IsFactionParagon
local function SR_Update()
	local numFactions = C_Reputation.GetNumFactions();
	for i = 1, numFactions, 1 do
        local factionData = C_Reputation.GetFactionDataByIndex(i);
        local name = factionData.name;
        local barValue = factionData.currentStanding or 0;
        local factionID = factionData.factionID;
        local barMin = factionData.currentReactionThreshold or 0;
        local barMax = factionData.nextReactionThreshold;
        if C_Reputation.IsMajorFaction(factionID) then
            local majorFactionData = C_MajorFactions.GetMajorFactionData(factionData.factionID);
            barMin, barMax, barValue = 0, majorFactionData.renownLevelThreshold, majorFactionData.renownReputationEarned;
        end
		local value = 0;
		if barValue == nil then
		--7.2额外声望
		elseif barValue >= 42000 then
            local hasParagon = C_Reputation_IsFactionParagon(factionID)
            if hasParagon then
              initExtraRep(factionID,name)
              local currentValue, threshold, _, hasRewardPending, _ = C_Reputation.GetFactionParagonInfo(factionID)
              value = currentValue % threshold
              if hasRewardPending then 
                value = value + threshold
              end
              local extraChange = value - extraRep[name];
              if(extraChange > 0) then 
                extraRep[name] = value
                local extra_msg = string.format(SR_REP_MSG, name, value, threshold, extraChange)
                createMessage(extra_msg);
              end
            end
        elseif name and barMax then
          if not rep[name] then
              rep[name] = {barValue = barValue, lastBarMax = barMax};
          end
          local change = barValue - rep[name].barValue;
          if change < 0 then
              change = rep[name].lastBarMax - rep[name].barValue + barValue;
          end
          if (change > 0) then
            rep[name] = {barValue = barValue, lastBarMax = barMax}
            local msg = string.format(SR_REP_MSG, name, barValue - barMin, barMax - barMin, change)
            createMessage(msg)
          end
        end
	end
end
function createMessage(msg)
  local info = ChatTypeInfo["COMBAT_FACTION_CHANGE"];
	for j = 1, 4, 1 do
    local chatfrm = getglobal("ChatFrame"..j);
    for k,v in pairs(chatfrm.messageTypeList) do
      if v == "COMBAT_FACTION_CHANGE" then
        chatfrm:AddMessage(msg, info.r, info.g, info.b, info.id);
        break;
      end
    end
  end
end

function initExtraRep(factionID, name)
  local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
  if not extraRep[name] then
		extraRep[name] = currentValue % threshold
		if hasRewardPending then
      extraRep[name] = extraRep[name] + threshold
    end
	end
	if extraRep[name] > threshold and (not hasRewardPending) then
    extraRep[name] = extraRep[name] - threshold
  end
end

local ReputationFrameEvents = {
	"MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
	"MAJOR_FACTION_UNLOCKED",
	"QUEST_LOG_UPDATE",
	"UPDATE_FACTION",
}

function RegisterFrameForEvents(frame, events)
   for i, event in ipairs(events) do
	  frame:RegisterEvent(event);
   end
end

local frame = CreateFrame("Frame");
RegisterFrameForEvents(frame, ReputationFrameEvents)
frame:SetScript("OnEvent", SR_Update);
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", function() return true; end);