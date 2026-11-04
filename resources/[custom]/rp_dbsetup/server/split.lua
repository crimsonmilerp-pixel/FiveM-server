-- ============================================================
--  rp_dbsetup - splits a .sql file into single statements
--  Handles quotes ('...', "...", `...`), comments (-- , #, /* */)
--  and DELIMITER blocks (used for triggers).
-- ============================================================
local function trim(text)
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

function SplitSql(text)
    text = text:gsub('\r\n', '\n')
    local statements = {}
    local current = {}
    local delimiter = ';'
    local i, n = 1, #text
    local atLineStart = true

    local function finish()
        local statement = trim(table.concat(current))
        if statement ~= '' then statements[#statements + 1] = statement end
        current = {}
    end

    while i <= n do
        local c = text:sub(i, i)

        -- A DELIMITER line changes what ends a statement (only at the start of a line).
        if atLineStart then
            local spaces, word, value = text:match('^([ \t]*)([Dd][Ee][Ll][Ii][Mm][Ii][Tt][Ee][Rr])[ \t]+(%S+)', i)
            if word then
                finish()
                delimiter = value
                local lineEnd = text:find('\n', i, true) or n
                i = lineEnd + 1
                goto continue
            end
        end
        atLineStart = false

        if c == "'" or c == '"' or c == '`' then
            -- Copy the whole quoted text as-is.
            local quote = c
            local j = i + 1
            while j <= n do
                local d = text:sub(j, j)
                if d == '\\' and quote ~= '`' then
                    j = j + 2
                elseif d == quote then
                    if text:sub(j + 1, j + 1) == quote then
                        j = j + 2 -- doubled quote inside the text
                    else
                        break
                    end
                else
                    j = j + 1
                end
            end
            current[#current + 1] = text:sub(i, j)
            i = j + 1
        elseif text:sub(i, i + 2):match('^%-%-[ \t\n]') or (text:sub(i, i + 1) == '--' and i + 1 == n) or c == '#' then
            -- Line comment: skip to the end of the line.
            local lineEnd = text:find('\n', i, true) or n
            i = lineEnd + 1
            current[#current + 1] = '\n'
            atLineStart = true
        elseif text:sub(i, i + 1) == '/*' then
            local close = text:find('*/', i + 2, true) or (n - 1)
            i = close + 2
            current[#current + 1] = ' '
        elseif text:sub(i, i + #delimiter - 1) == delimiter then
            finish()
            i = i + #delimiter
        else
            current[#current + 1] = c
            if c == '\n' then atLineStart = true end
            i = i + 1
        end

        ::continue::
    end
    finish()
    return statements
end
