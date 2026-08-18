local judhead_exists_both = {}

function judhead_startup()
    local suggestions = {};
    local i = 1;

    for k, v in pairs(judhead_emotes) do
        if TwitchEmotes_defaultpack[k] ~= nil then
            judhead_exists_both[k] = true
        end

        TwitchEmotes:AddEmote(k, k, v);

        suggestions[i] = k;
        i = i + 1;
    end

    judhead_initsuggestions(suggestions);
end

-- Merges table entries from t2 into t1 if they don't exist in t1
function judhead_concat(t1, t2)
    local set = {}
    for i=1,#t1 do
        set[t1[i]] = true
    end

    for i=1,#t2 do
        if set[t2[i]] == nil then
            t1[#t1+1] = t2[i]
        end
    end

    return result
end


function judhead_get_id(text)
    return string.match("Interface\\AddOns\\TwitchEmotes_glorp\\emotes\\Corpa.tga:28:28", "([^\\\\]+).tga:")
end

function judhead_initsuggestions(suggestions)
    if AllTwitchEmoteNames ~= nil and Emoticons_Settings ~= nil and Emoticons_RenderSuggestionFN ~= nil and Emoticons_Settings["ENABLE_AUTOCOMPLETE"] then

        judhead_concat(suggestions, AllTwitchEmoteNames);
        table.sort(suggestions);

        for i=1, NUM_CHAT_WINDOWS do
            local frame = _G["ChatFrame"..i]

            local maxButtonCount = 20;

            SetupAutoComplete(frame.editBox, suggestions, maxButtonCount, {
                perWord = true,
                activationChar = ':',
                closingChar = ':',
                minChars = 2,
                fuzzyMatch = true,
                onSuggestionApplied = function(suggestion)
                    if UpdateEmoteStats ~= nil then
                        UpdateEmoteStats(suggestion, true, false, false);
                    end
                end,
                renderSuggestionFN = function(text)
                    if judhead_emotes[text] ~= nil then
                        if judhead_exists_both[text] ~= nil then
                            return Emoticons_RenderSuggestionFN(text) .. "    |cffffff00<glorp and default pack>|r"
                        end
                        return Emoticons_RenderSuggestionFN(text) .. "    |cffffff00<glorp>|r"
                    end
                    return Emoticons_RenderSuggestionFN(text)
                end,
                suggestionBiasFN = function(suggestion, text)
                    --Bias the sorting function towards the most autocompleted emotes
                    if TwitchEmoteStatistics ~= nil and TwitchEmoteStatistics[suggestion] ~= nil then
                        return TwitchEmoteStatistics[suggestion][1] * 5
                    end
                    return 0;
                end,
                interceptOnEnterPressed = true,
                addSpace = true,
                useTabToConfirm = Emoticons_Settings["AUTOCOMPLETE_CONFIRM_WITH_TAB"],
                useArrowButtons = true,
            });
        end
    end
end

function judhead_dump()
    local str = ""
    local i = 0

    for k, v in pairs(judhead_emotes) do
        str = str .. "|Htel:name = " .. k .. "\npath = " .. v .. "|h|T" .. v .. "|t|h "

        i = i + 1
        if i == 8 then
            print(str)
            str = ""
            i = 0
        end
    end

    if i > 0 then
        print(str)
    end
end

local function escpattern(x)
    return (x:gsub('%%', '%%%%')
             :gsub('^%^', '%%^')
             :gsub('%$$', '%%$')
             :gsub('%(', '%%(')
             :gsub('%)', '%%)')
             :gsub('%.', '%%.')
             :gsub('%[', '%%[')
             :gsub('%]', '%%]')
             :gsub('%*', '%%*')
             :gsub('%+', '%%+')
             :gsub('%-', '%%-')
             :gsub('%?', '%%?'))
end

function TwitchEmotes_BuildEmoteFrameStringWithDimensions(imagepath, animdata,
														framenum, framewidth,
														frameheight)
    local imageFrameHeight = animdata.imageFrameHeight
    if imageFrameHeight == nil then
        imageFrameHeight = animdata.imageWidth
    end

	local top = framenum * imageFrameHeight;
	local bottom = top + imageFrameHeight;

	local emoteStr = "|T" .. imagepath .. ":" .. frameheight .. ":" ..
						framewidth .. ":0:0:" .. animdata.imageWidth .. ":" ..
						animdata.imageHeight .. ":0:" .. animdata.imageWidth ..
						":" .. top .. ":" .. bottom .. "|t";
	return emoteStr
end

function TwitchEmotesAnimator_UpdateEmoteInFontString(fontstring, widthOverride, heightOverride)
    local txt = fontstring:GetText();
    if (txt ~= nil and not issecretvalue(txt)) then
        for emoteTextureString in txt:gmatch("(|TInterface\\AddOns\\TwitchEmotes.-|t)") do
            local imagepath = emoteTextureString:match("|T(Interface\\AddOns\\TwitchEmotes.-tga).-|t")

            local animdata = TwitchEmotes_animation_metadata[imagepath];
            -- print(animdata)
            if (animdata ~= nil) then
                local framenum = TwitchEmotes_GetCurrentFrameNum(animdata);
                local nTxt;
                if(widthOverride ~= nil or heightOverride ~= nil) then
                    local correctedWidthOverride = (widthOverride * animdata.frameWidth) / animdata.frameHeight
                    local str = TwitchEmotes_BuildEmoteFrameStringWithDimensions(imagepath, animdata, framenum, correctedWidthOverride, heightOverride)
                    -- print(str)
                    nTxt = txt:gsub(escpattern(emoteTextureString), str)
                else
                    local str = TwitchEmotes_BuildEmoteFrameString(imagepath, animdata, framenum)
                    -- print(str)
                    nTxt = txt:gsub(escpattern(emoteTextureString), str)
                end

                -- If we're updating a chat message we need to alter the messageInfo as wel
                if (fontstring.messageInfo ~= nil) then
                    fontstring.messageInfo.message = nTxt
                end
                fontstring:SetText(nTxt);
                txt = nTxt;
            end
        end
    end
end

judhead_startup();
