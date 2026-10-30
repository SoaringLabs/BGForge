--[[
    Core/Protocol/SendGateway.lua — 统一发送入口

    本文件只做转发：参数字序、分发类型、返回值全部原样透传，不加限流、
    不改分发类型、不吞错误。所有对外通信都必须经过这里的四个函数，
    便于审计「插件到底发了什么」。
--]]
local AddonName, ns = ...

local C = ns.Protocol

local G = {}
ns.SendGateway = G

-- 普通 addon 通道消息
function G.Addon(prefix, msg, dist, target)
    if target ~= nil then
        return C_ChatInfo.SendAddonMessage(prefix, msg, dist, target)
    end
    return C_ChatInfo.SendAddonMessage(prefix, msg, dist)
end

-- addon 通道密语
function G.WhisperAddon(prefix, msg, target)
    return C_ChatInfo.SendAddonMessage(prefix, msg, "WHISPER", target)
end

-- 聊天框消息
function G.Chat(msg, chatType, lang, target)
    if target ~= nil then
        return SendChatMessage(msg, chatType, lang, target)
    end
    if lang ~= nil then
        return SendChatMessage(msg, chatType, lang)
    end
    return SendChatMessage(msg, chatType)
end

-- 经 ChatThrottleLib 限流的 addon 通道消息
function G.Throttled(prefix, msg, dist, target)
    return ChatThrottleLib:SendAddonMessage("NORMAL", prefix, msg, dist, target)
end
