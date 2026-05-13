local utils = require("colorful-menu.utils")
local Kind = require("colorful-menu").Kind
local config = require("colorful-menu").config

local M = {}

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.jdtls(completion_item, ls)
    local label = completion_item.label
    local kind = completion_item.kind
    -- jdtls: labelDetails.detail = " : ReturnType" for methods/fields
    -- jdtls: labelDetails.description = " - ClassName" or package path for classes
    local detail = completion_item.labelDetails and completion_item.labelDetails.detail
    local description = completion_item.labelDetails and completion_item.labelDetails.description

    if not kind then
        return utils.highlight_range(label, ls, 0, #label)
    end

    if kind == Kind.Method or kind == Kind.Function then
        -- label: "methodName(Type param, ...)"
        -- detail: " : ReturnType"
        local return_type = "void"
        if detail then
            return_type = detail:match("^%s*:%s*(.-)%s*$") or "void"
        end
        -- Construct synthetic Java: "class C { ReturnType label {} }"
        local prefix = string.format("class C { %s ", return_type)
        local source = prefix .. label .. " {} }"
        local item = utils.highlight_range(source, ls, #prefix, #prefix + #label)
        -- Add class description as dimmed extra info
        if description and config.ls.jdtls.extra_info_hl ~= false then
            local extra = description:match("^%s*%-%s*(.-)%s*$") or vim.trim(description)
            if #extra > 0 then
                item.text = item.text .. " " .. extra
                table.insert(item.highlights, {
                    config.ls.jdtls.extra_info_hl,
                    range = { #label + 1, #item.text },
                })
            end
        end
        return item
        --
    elseif kind == Kind.Constructor then
        -- label: "ClassName(Type param, ...)"
        -- Constructor name must match the class name for valid Java
        local class_name = label:match("^(.-)%(") or label
        local prefix = string.format("class %s { ", class_name)
        local source = prefix .. label .. " {} }"
        return utils.highlight_range(source, ls, #prefix, #prefix + #label)
        --
    elseif kind == Kind.Field or kind == Kind.Property then
        -- label: "fieldName"
        -- detail: " : Type"
        local field_type = detail and detail:match("^%s*:%s*(.-)%s*$")
        if field_type and #field_type > 0 then
            -- Construct synthetic Java: "class C { FieldType fieldName; }"
            local prefix = string.format("class C { %s ", field_type)
            local source = prefix .. label .. "; }"
            return utils.highlight_range(source, ls, #prefix, #prefix + #label)
        else
            local highlight_name = utils.hl_exist_or("@lsp.type.property", "@variable.member", "java")
            return {
                text = label,
                highlights = { { highlight_name, range = { 0, #label } } },
            }
        end
        --
    elseif kind == Kind.Class or kind == Kind.Interface or kind == Kind.Enum then
        local highlight_name
        if kind == Kind.Interface then
            highlight_name = utils.hl_exist_or("@lsp.type.interface", "@type", "java")
        elseif kind == Kind.Enum then
            highlight_name = utils.hl_exist_or("@lsp.type.enum", "@type", "java")
        else
            highlight_name = utils.hl_exist_or("@lsp.type.class", "@type", "java")
        end
        local text = label
        local highlights = { { highlight_name, range = { 0, #label } } }
        if description and config.ls.jdtls.extra_info_hl ~= false then
            local pkg = vim.trim(description)
            if #pkg > 0 then
                text = label .. " " .. pkg
                table.insert(highlights, {
                    config.ls.jdtls.extra_info_hl,
                    range = { #label + 1, #text },
                })
            end
        end
        return { text = text, highlights = highlights }
        --
    elseif kind == Kind.EnumMember then
        local highlight_name = utils.hl_exist_or("@lsp.type.enumMember", "@constant", "java")
        return {
            text = label,
            highlights = { { highlight_name, range = { 0, #label } } },
        }
        --
    elseif kind == Kind.Constant then
        local text = label
        local highlights = { { "@constant", range = { 0, #label } } }
        if detail and config.ls.jdtls.extra_info_hl ~= false then
            local type_info = detail:match("^%s*:%s*(.-)%s*$") or vim.trim(detail)
            if #type_info > 0 then
                text = label .. " " .. type_info
                table.insert(highlights, {
                    config.ls.jdtls.extra_info_hl,
                    range = { #label + 1, #text },
                })
            end
        end
        return { text = text, highlights = highlights }
        --
    elseif kind == Kind.Variable then
        local highlight_name = utils.hl_exist_or("@lsp.type.variable", "@variable", "java")
        local text = label
        local highlights = { { highlight_name, range = { 0, #label } } }
        if detail and config.ls.jdtls.extra_info_hl ~= false then
            local type_info = detail:match("^%s*:%s*(.-)%s*$") or vim.trim(detail)
            if #type_info > 0 then
                text = label .. " " .. type_info
                table.insert(highlights, {
                    config.ls.jdtls.extra_info_hl,
                    range = { #label + 1, #text },
                })
            end
        end
        return { text = text, highlights = highlights }
        --
    elseif kind == Kind.Module then
        local highlight_name = utils.hl_exist_or("@lsp.type.namespace", "@namespace", "java")
        return {
            text = label,
            highlights = { { highlight_name, range = { 0, #label } } },
        }
        --
    elseif kind == Kind.Keyword then
        return {
            text = label,
            highlights = { { "@keyword", range = { 0, #label } } },
        }
        --
    else
        return require("colorful-menu.languages.default").default_highlight(
            completion_item,
            detail,
            "java",
            config.ls.jdtls.extra_info_hl
        )
    end
end

return M
