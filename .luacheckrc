std = "lua51"
max_line_length = 120
self = false
globals = {
    "GoblinThingsDB", "SLASH_GOBLINTHINGS1", "SLASH_GOBLINTHINGS2", "SlashCmdList",
    "QuestObjectiveTracker",  -- API.SetTrackerSort sets its BuildQuestWatchInfos
}
read_globals = {
    "print", "CreateFrame", "UIParent", "UISpecialFrames", "GameTooltip",
    "Settings", "SettingsPanel", "HideUIPanel",
    "Minimap", "GetCursorPosition", "GetPhysicalScreenSize", "C_Timer",
    "IsShiftKeyDown", "C_GossipInfo", "C_QuestLog",
    "GetNumActiveQuests", "GetActiveTitle", "GetActiveQuestID",
    "GetNumAvailableQuests", "GetAvailableQuestInfo", "GetAvailableTitle",
    "GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "GetSuggestedGroupSize", "GetTitleText",
    "IsQuestCompletable", "GetQuestMoneyToGet", "GetNumQuestChoices",
    "SelectActiveQuest", "SelectAvailableQuest", "AcceptQuest", "AcknowledgeAutoAcceptQuest",
    "CompleteQuest", "GetQuestReward",
    "C_Container", "C_Item", "CanMerchantRepair", "GetRepairAllCost", "GetMoney", "RepairAllItems",
    "C_CVar", "CancelDuel", "DeclineGuild",
    "StopCinematic", "MovieFrame", "GetCurrentCinematicSummary", "UnitRace", "C_Map",
    "QuestObjectiveTrackerMixin",
    "AcceptGroup", "IsGuildMember", "C_FriendList", "C_BattleNet", "WillAcceptInviteRemoveQueues", "StaticPopup_FindVisible",
    "StaticPopup_Hide", "C_SummonInfo", "Enum", "UnitAffectingCombat", "PlayerCanTeleport",
    "GetNumLootItems", "GetLootSlotInfo", "LootSlot",
}
