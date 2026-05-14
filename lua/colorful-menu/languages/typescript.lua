local utils = require("colorful-menu.utils")
local config = require("colorful-menu").config

local M = {}

local function one_line(s)
    s = s:gsub("    ", "")
    s = s:gsub("\n", " ")
    return s
end

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.ts_server(completion_item, ls)
    local label = completion_item.label
    local detail = completion_item.detail
    local detail_text = detail and one_line(detail) or nil
    local kind = completion_item.kind
    -- Combine label + detail for final display
    local text = (detail_text and config.ls.ts_ls.extra_info_hl ~= false) and (label .. " " .. detail_text) or label

    if not kind then
        return utils.highlight_range(text, ls, 0, #text)
    end

    local highlights = {
        {
            utils.hl_by_kind(kind, "typescript"),
            range = { 0, #label },
        },
    }

    if detail_text and config.ls.ts_ls.extra_info_hl ~= false then
        local extra_info_hl = config.ls.ts_ls.extra_info_hl
        table.insert(highlights, {
            extra_info_hl,
            range = { #label + 1, #label + 1 + #detail_text },
        })
    end

    return {
        text = text,
        highlights = highlights,
    }
end

-- see https://github.com/zed-industries/zed/pull/13043
-- Untested.
---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.vtsls(completion_item, ls)
    local label = completion_item.label

    local kind = completion_item.kind
    if not kind then
        return utils.highlight_range(label, ls, 0, #label)
    end

    local description = completion_item.labelDetails and completion_item.labelDetails.description
    local description_text = description and one_line(description) or nil
    local detail = completion_item.detail
    local detail_text = detail and one_line(detail) or nil

    local highlights = {
        {
            utils.hl_by_kind(kind, "typescript"),
            range = { 0, #label },
        },
    }
    local text = label
    if config.ls.vtsls.extra_info_hl ~= false then
        if description_text then
            text = label .. " " .. description_text
            table.insert(highlights, {
                config.ls.vtsls.extra_info_hl,
                range = { #label + 1, #text },
            })
        elseif detail_text then
            text = label .. " " .. detail_text
            table.insert(highlights, {
                config.ls.vtsls.extra_info_hl,
                range = { #label + 1, #text },
            })
        end
    end

    return {
        text = text,
        highlights = highlights,
    }
end

return M
