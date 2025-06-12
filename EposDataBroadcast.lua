local _, Epos = ...

local AceComm = LibStub("AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local LS = LibStub("LibSerialize", true)

-- Function to send the message using AceComm
function Epos:Broadcast(event, payload, distribution, channel, sender)
    -- Serialize the payload
    local serialized = LS:Serialize(payload)
    -- Compress the serialized data
    local compressed = LibDeflate:CompressDeflate(serialized)
    -- Encode the compressed data for the WoW addon channel
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

    -- Send the message via AceComm
    AceComm:SendCommMessage(
            event, -- The event name to send, e.g., "EPOS_DATA_REQ"
            encoded, -- The serialized, compressed payload
            channel, -- The channel to use (e.g., "WHISPER", "GUILD", etc.)
            sender, -- The specific sender if using "WHISPER", nil for general channels
            distribution    -- The message priority (e.g., "ALERT", "BULK", etc.)
    )
end

AceComm:RegisterComm("EPOS_MSG", function(prefix, encoded, distribution, sender)

    if not (LibDeflate and LibSerialize) then
        return
    end

    local decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
    if not decoded then
        return
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return
    end

    local success, payload = LibSerialize:Deserialize(decompressed)
    if not success then
        return
    end

    -- route the payload into your existing handler
    Epos:HandleEvent("EPOS_MSG", false, true, payload, sender)
end)


--
--AceComm:RegisterComm("EPOS_MSG", function(_, text, chan, sender) ReceiveComm(text, chan, sender, false, true) end)
--AceComm:RegisterComm("EPOS_WHISPER", function(_, text, chan, sender) ReceiveComm(text, chan, sender, true, true) end)