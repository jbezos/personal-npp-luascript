
-- Changes will take effect once Notepad++ is restarted

-- WARNING. Some functions (like fillText) assume utf8. It doesn't work
-- with ANSI.

------------
--- Init ---
------------

-- Globals:

envirList = ''

langMap = {}

doUserlist = {}

RE = SCFIND_REGEXP

UL_ENVIR = 1
UL_FIND  = 2
UL_ALIGN = 3

edgeCol = 72

editor.CallTipFore = 0

-- File types:

langMap['dtx'] = 'tex'
langMap['sty'] = 'tex'
langMap['lvt'] = 'tex'
langMap['htm'] = 'html'

docLang = 'tex'

langDesc = {}

langDesc.tex = {
  comment = '%%',
  commentString = '%% ',
  item = '%-%*',
  it = {'\\textit{', '}'},
  bf = {'\\textbf{', '}'}
}

langDesc.lua = {
  comment = '%-',
  commentString = '-- ',
  item = '%-%*',
  it = {'\\textit{', '}'},
  bf = {'\\textbf{', '}'},
  exe = 'texlua "%s"'
}

langDesc.py = {
  comment = '# ',
  commentString = '# ',
  item = '%-%*',
  it = {'\\textit{', '}'},
  bf = {'\\textbf{', '}'},
  exe = 'py "%s"'
}

langDesc.wiki = {
  comment = '%%',
  item = ':;#%*',
  it = {"''", "''"},
  bf = {"'''", "'''"}
}

langDesc.html = {
  comment = '',
  item = '',
  it = {"<i>", "</i>"},
  bf = {"<b>", "</b>"}
} 

-- Events:

npp.RemoveAllEventHandlers("OnSwitchFile")
npp.AddEventHandler("OnSwitchFile",
  function(filename, bufferid)
      -- Global declarations
    docLang = string.sub(npp:GetExtPart(), 2)
    if not langDesc[docLang] then
      docLang = langMap[docLang] or 'tex'
    end
    docLangDesc = langDesc[docLang]
    itemStart = docLangDesc.item
    commentStart = docLangDesc.commentString or '>'
    --or do 'Toggle Single Line Comment' ??
    --?? ul_envir() ?? 
  end)

npp.RemoveAllEventHandlers("OnUserListSelection")
npp.AddEventHandler("OnUserListSelection",
  function(type, pos, txt)
    doUserlist[type](pos, txt)
    return false
  end)

npp.RemoveAllEventHandlers("OnChar")
npp.AddEventHandler("OnChar",
  function(c) hardBreak(c) end)

npp.RemoveAllEventHandlers("OnModification")
npp.AddEventHandler("OnModification",
  function(c, d, e, f, g, h)
    autoBookmark()
  end)

npp.RemoveAllEventHandlers("OnDoubleClick")
npp.AddEventHandler("OnDoubleClick",
  function(pos, lin, mod)
    if mod == 2 then     -- 2 = ctrl
      goToFromText()
      editor:SetEmptySelection(editor.SelectionStart)
    else
      backslash()
    end
  end)

-------------
--- Tools ---
-------------

function GetEOL()
  return (editor.EOLMode == 0 and '\r\n') or
         (editor.EOLMode == 1 and '\r') or
         (editor.EOLMode == 2 and '\n')
end

function currentLine()
  return editor:LineFromPosition(editor.CurrentPos)
end

-- Get the start and end position of a specific line number (excludes
-- eol). Unused!

function getLinePositions(line)
    local spos = editor:PositionFromLine(line)
    local epos = editor.LineEndPosition[line]
    -- local epos = spos + editor:LineLength(line)
    return spos, epos
end

npp.AddShortcut("Copy Allow Line", "Ctrl+C",
  function() editor:CopyAllowLine() end)

-----------------
--- Selection ---
-----------------

function extendSelectedLines()   -- Does _not_ include the last eol
   local spos = editor:PositionFromLine(
     editor:LineFromPosition(editor.SelectionStart))
   local epos = editor.LineEndPosition[
     editor:LineFromPosition(editor.SelectionEnd)]
   editor:SetSel(spos, epos)
   return spos, epos
end

-- eol's must be given explicitly in the regexps where
-- relevant, to get the correct position.

function parStart()
  local cPos = editor.CurrentPos
  local _, sposa = editor:findtext('^[ \\t%\\-]*?\\r?\\n', RE, cPos, 0)
  sposa = sposa or 0
  local _, sposb = editor:findtext('^%?\\s*\\\\begin{.*?\\r?\\n', RE, cPos, 0)
  sposb = sposb or 0
  local _, spose = editor:findtext('^%?\\s*\\\\end{.*?\\r?\\n', RE, cPos, 0) 
  spose = spose or 0
  local sposi, _ = editor:findtext('^%?\\s*\\\\item', RE, cPos, 0)
  sposi = sposi or 0
  return math.max(sposa, sposb, spose, sposi)
end

function parEnd()          -- Does _not_ include the last eol
  local cPos = editor.CurrentPos
  local eposa = editor:findtext('\\r?\\n[ \\t%\\-]*?$', RE, cPos)
  eposa = eposa or editor.TextLength
  local eposb = editor:findtext('\\r?\\n%?\\s*\\\\begin{.*?$', RE, cPos)
  eposb = eposb or editor.TextLength
  local epose = editor:findtext('\\r?\\n%?\\s*\\\\end{.*?$', RE, cPos)
  epose = epose or editor.TextLength
  local eposi = editor:findtext('\\r?\\n%?\\s*\\\\item', RE, cPos)
  eposi = eposi or editor.TextLength
  return math.min(eposa, epose, eposb, eposi)
end

---------------------------
---  Auto environments  ---
---------------------------

-- Highlight somehow the last used??

npp.AddShortcut("Add Environment", "Ctrl+Shift+E",
  function() ul_envir_show() end)

function ul_envir()
  local envs = { 'itemize', 'enumerate', 'verbatim' }
  local envsf = { ['itemize']   = '',
                  ['enumerate'] = '' ,
                  ['verbatim']  = '',
                  ['document']  = '' } -- ignore this, too (or not?)
  for env in string.gmatch(editor:GetText(),'\\begin%{([^%}]+)%}') do
    if not envsf[env] then 
      envs[#envs+1] = env
      envsf[env] = ''
    end
  end
  table.sort(envs)
  envirList = '<> ' .. table.concat(envs, ' ')
end

function ul_envir_show()  --- en 
  ul_envir()   --- mientras pruebo
  local ch = editor.AutoCMaxHeight
  editor.AutoCMaxHeight = 15
  editor:UserListShow(UL_ENVIR, envirList)
  editor.AutoCMaxHeight = ch
end

doUserlist[UL_ENVIR] = function(pos, txt)
  local spos, epos = extendSelectedLines()
  editor:InsertText(epos, '\r\n\\end{' .. txt .. '}')
  editor:SetSel(spos, epos)
  editor:ReplaceSel('  ' .. string.gsub(editor:GetSelText(), '\n', '\n  '))
  editor:InsertText(spos, '\\begin{' .. txt .. '}\r\n')
  if txt == '<>' then
    editor:SetSelection(editor.CurrentPos+7, editor.CurrentPos+9) --\end
    editor:AddSelection(spos+7, spos+9)  --\begin
  end
end

---------------------
--- Align by char ---
---------------------

npp.AddShortcut("Align by char", "Ctrl+Shift+G",
  function() alignByChar() end)

function findAlignChar(s)
  local al = {}
  local result = ''
  for c in s:gmatch('[^%a%d\n%s]') do
    if c:byte() > 32 and c:byte() < 127 and al[c] == nil then
      al[c] = ''
      result = result .. ' ' .. c
    end
  end
  return result:sub(2)
end

function alignByChar()
   if editor.SelectionEmpty then return end
   local spos, epos = extendSelectedLines()

   local sel = editor:GetSelText()
   if #sel == 0 then return end

   local ch = editor.AutoCMaxHeight
   editor.AutoCMaxHeight = 15
   editor:UserListShow(UL_ALIGN, findAlignChar(sel))
   editor.AutoCMaxHeight = ch
   return false
end

doUserlist[UL_ALIGN] = function(pos, txt)
  local sel = editor:GetSelText()
    local mpos = 0
  sel = '\n' .. sel
  for n in sel:gmatch('\n([^\n%' .. txt .. ']-) *%' .. txt) do
    mpos = math.max(mpos, utf8.len(n))
  end
  sel = sel:gsub('\n([^\n%' .. txt .. ']-) *%' .. txt .. ' *', function (t)
      return '\n' .. t .. string.rep(' ', mpos - utf8.len(t)) .. ' ' .. txt .. ' '
    end)
  sel = sel:sub(2)
  editor:ReplaceSel(sel)
end

-- I don't need it (I prefer Elastic Tabstops), but who knows:
-- https://www.rosettacode.org/wiki/Align_columns#Lua

---------------------------
--- Font markup styling ---
---------------------------

--- TODO. Corregir porque ahora solo funciona con tex

function text_wrap(before, after)
  editor:ReplaceSel(before .. editor:GetSelText() .. after)
  editor:GotoPos(editor.CurrentPos - #after)
  return false
end

function text_wrap_lang(e)
  local ld = langDesc[docLang][e] or langDesc.tex[e]
  text_wrap(ld[1], ld[2])
end

npp.AddShortcut("Add Italics", "Ctrl+Shift+I",
  function() text_wrap_lang('it') end)

npp.AddShortcut("Add Bold", "Ctrl+Shift+B",
  function() text_wrap_lang('bf') end )

npp.AddShortcut("Add Sans", "Ctrl+Shift+F",
  function() text_wrap('\\textsf{', '}') end)

npp.AddShortcut("Add Small Caps", "Ctrl+Shift+S",
  function() text_wrap('\\textsc{', '}') end)

npp.AddShortcut("Add Typewriter", "Ctrl+Shift+T",
  function() text_wrap('\\texttt{', '}') end)

npp.AddShortcut("Add Quotes", "Ctrl+Shift+Q",
  function() text_wrap('«', '»') end)

npp.AddShortcut("Add Parentesis", "Ctrl+Shift+P",
  function() text_wrap('{', '}') end)

npp.AddShortcut("Add Verbatim", "Ctrl+Shift+V",
  function() text_wrap('\\verb|', '|') end)

npp.AddShortcut("Add Math", "Ctrl+Shift+M",
  function() text_wrap('$', '$') end)

---------------------------------
-- Extend selection to prev \ ---
---------------------------------

function backslash(ch, x, y)
    --print("You typed " .. ch .. editor.CharAt[editor.SelectionStart - 1])
    if editor.SelectionStart > 0 and
        editor.CharAt[editor.SelectionStart - 1] == 92 then
        editor.SelectionStart = editor.SelectionStart - 1
    end
    return false
end

----------------------
--- Auto bookmark  ---
----------------------

-- 24 is the internal type for marks in npp. 
-- Problem: it's global! There must be a way to remember it by
-- document.

last_line = -11

function autoBookmark()
  local cline = currentLine()
  if math.abs(last_line - cline) > 5 then
    for i = cline-5, cline+5 do
      editor:MarkerDelete(i,24)
    end
    editor:MarkerAdd(cline,24)
    last_line = cline  -- global
  end
  return false -- pass event
end

----------------------
--- Fill paragraph ---
----------------------

-- The behavior of the function may seem odd, but it does what *I*
-- want. If no text is selected, CtrSh-Y selects the current paragraph,
-- *without* wrapping it. A second CtrSh-Y does the fill. With a
-- selection, does the fill. A useful combination: CtrSh-Y Ctr-J is
-- "paragraph to line".

function fillText()

   local savePos = editor.CurrentPos

   if editor.SelectionEmpty then
     local spos = parStart()
     local epos = parEnd()
     editor:SetSel(spos, epos)
     return false
   else
     local spos, epos = extendSelectedLines()
   end

   local sel = editor:GetSelText()
   if #sel == 0 then return end

      -- Memoriza los prefijos y los quita. Note it can match none, and
      -- we are at the very beginning of a line.
   local prefix, type = string.match(sel, '( *([%%%-%*]*) *)')
--    if prefix == '' then
--      prefix = string.match(sel, '^--s*\\item')
--      if prefix == '\item' then prefix = '  ' end
--    end
   local eol = GetEOL()
   local limit = edgeCol - #prefix
   sel = string.gsub('\n' .. sel, '\n[%%%s%-%*]*', '\n')

     -- Recrea el párrafo palabra por palabra (bloques entre espacios)
   local result = ''
   local line = ''
   for token in string.gmatch(sel, "[^%s]+") do
     if utf8.len(line .. token) >= limit then
       if result == '' then
         result = line:gsub('%s+$', '')
       else
         result = result .. eol .. line:gsub('%s+$', '')
       end
       line = token .. " "
     else
       line = line .. token .. " "
     end
   end

     -- Repone los prefijos
   if result ~= '' then
     result = prefix .. result:gsub('\n', '\n' .. prefix:gsub('%%', '%%%%')) .. eol
   end
   editor:ReplaceSel(result .. prefix .. line:gsub('%s+$', ''))
   editor:GotoPos(savePos)  --- ¿no es mejor mantener la selección? (¿Alpha?)
   return false
end

npp.AddShortcut("Fill Text", "Ctrl+Shift+Y",
  function() fillText() end)

-----------------
--- Hard wrap ---
-----------------

-- With event OnChar

function hardBreak(c)
  local curr = editor.CurrentPos
  local next = editor.Column[curr] + 1

    -- Trigger only beyond edgeCol:
  if next <= edgeCol then return true end

  local lin = editor:GetLine(editor:LineFromPosition(curr))
  local bpos = editor:PositionFromLine(editor:LineFromPosition(curr))

    -- We compute the length in bytes, taking utf8 into account:
  local uoffset = utf8.offset(lin, edgeCol + 1)
  begsp, endsp = string.match(lin:sub(1, uoffset), '^ *().*() ')

    -- Try to avoid 'down-lines' when there are no spaces, or they
    -- are only at the beginning. If there is no space, do nothing:
  if begsp == endsp then return true end  -- includes nil

    -- Break _before_ space:
  bkpos =  bpos + endsp - 1
  local pfx, type = string.match(lin, '( *([%%%-%*]*) *)')
  if type:match('%-%-+') or type:match('%%+') then
    -- do nothing
  else    -- eg, ' ', '-', '*', '**', but not '--', '---'
    pfx = string.rep(' ', #pfx)
  end
  local eol = GetEOL() 
  editor:InsertText(bkpos, eol .. pfx)

    -- Now, delete the space the line was broken at
  editor:DeleteRange(bkpos + #eol + #pfx, 1)
  return true -- don't pass event
end

-----------------------------------------
--- Comment out at the start of lines ---
-----------------------------------------

npp.AddShortcut("Comment out", "Ctrl+Shift+C",
  function() commentOut() end)

function commentOut()
  extendSelectedLines()
  local sel = editor:GetSelText()
  local comment = commentStart
  sel = sel:gsub('^', comment)  -- start of text, not of line (this is lua)
  sel = sel:gsub('\n', '\n' .. comment)
  editor:ReplaceSel(sel)
   -- editor:GotoPos(savePos)  -- ¿mantener la selección? (Alpha)
  return false
end

-------------------------------------
--- Select next current selection ---
-------------------------------------

npp.AddShortcut("Add to multiselection", "Ctrl+Shift+R",
  function() addSelection() end)

function addSelection()
  local mainSel = editor.MainSelection
  local sPos = editor.SelectionNStart[mainSel]
  local ePos = editor.SelectionNEnd[mainSel]
  local s = editor:textrange(sPos, ePos)
  local b, e = editor:findtext(s, 0, editor.SelectionEnd)
  if b then
    editor:AddSelection(b, e)
    editor.FirstVisibleLine = editor:LineFromPosition(b) - 18
  end
end

-- See also:
-- https://dail8859.github.io/LuaScript/examples/selectionaddnext.lua.html
-- My simpler version works for me.

------------------
--- Popup find ---
------------------

--- Common:

function buildSearch(toSearch, plain)
  -- Build Index
  local result = ''
  for lin in editor:match('^(.*)$', RE) do
    local ln = editor:LineFromPosition(lin.pos)
    local st = editor:GetLine(ln)
    for _, ss in ipairs(toSearch) do
      if st:find(ss, 1, plain) then
        if not plain then st = st:gsub(ss, sectioningReps[ss]) end
        result = result .. string.format('%5d  %s', ln+1, st)
      end
    end
  end
  --- Show UserList
  local sep = '\n'
  local ch = editor.AutoCMaxHeight
  editor.AutoCMaxHeight = 18
  editor.AutoCSeparator = string.byte(sep)
  editor:UserListShow(UL_FIND,result)
  editor.AutoCMaxHeight = ch
  editor.AutoCSeparator = string.byte(' ')
end

doUserlist[UL_FIND] = function(pos, txt)
  editor:GotoLine(tonumber(txt:sub(1,5))-1)
  editor.FirstVisibleLine = currentLine()-12
end

--- TOC
--- How to extend it to multi-file projects?

npp.AddShortcut("TOC", "Ctrl+Shift+O",
  function() buildSearch(sectioningList, false) end)

sectioningList = { '\\section{', '\\subsection{',
                   '\\subsubsection{', '%%%<%*' }

sectioningReps = { ['\\section{'] = ': {', ['\\subsection{'] = ': : {',
                   ['\\subsubsection{'] = ': : : {', ['%%%<%*'] = '<*'}

--- Find all like selection:

npp.AddShortcut("Find all selected", "Ctrl+Shift+A",
  function()
    local txt = editor:GetSelText()
    buildSearch( { txt }, true )
  end)

------------------------------------------
--- Show code + chars of selected text ---
------------------------------------------

npp.AddShortcut("Show hex chars", "Ctrl+Shift+X",
  function() showChars() end)

function showChars()
  local txt = editor:GetSelText()
  local cods = ''
  local chrs = '  '
  local n = 0
  for _, c in utf8.codes(txt) do
    n = n + 1
    cods = cods .. ' ' .. string.format('%04x', c) 
    if c < 32 then c = 32 end -- tiene que ir despues de cods =
    chrs = chrs .. utf8.char(0x200e) .. ' ' .. utf8.char(c)
    if n == 8 then
      cods = cods .. chrs .. '\n'
      chrs = '  '
      n = 0
    end
  end
  cods = cods .. string.rep(' ', (8-n) * 5)
  editor:CallTipShow(editor.SelectionEnd, cods .. chrs)
end

-----------------------
--- LaTeX \index'es ---
-----------------------

-- Under development. Tool to extract and revise index entries. Only
-- for quick revisions. A better option is reading the idx file(s).

function buildIndex()
  local idxs = {}
  local idxsf = {}
  for pos, idx in string.gmatch(editor:GetText(),'()\\x?index%*?(%b{})') do
  -- for pos, idx in string.gmatch(editor:GetText(),'()\\ee?(%b{})') do
    idx = idx:sub(2,-2)
    idx = idx:gsub('%s+', ' ')
    if not idxsf[idx] then 
      idx = idx .. string.rep(' ', 60)         -- proper align with
      idx = idx:sub(1, utf8.offset(idx, 60))   -- utf8 text
      idxs[#idxs+1] = string.format(
         '%s ... %5d ', idx, editor:LineFromPosition(pos)+1)
      idxsf[idx] = ''
    end
  end
  npp:MenuCommand(41001) -- New
  npp:MenuCommand(10001) -- Goto another view
  editor:InsertText(0, table.concat(idxs, '\r\n'))
end

npp.AddShortcut("Build and Show Index Entries", "Ctrl+Alt+X",
  function() buildIndex() end)
  
-- See also OnDoubleClick:

npp.AddShortcut("Goto Line from text", "Ctrl+Shift+D",
  function() goToFromText() end)

function goToFromText()
  local lin = editor:GetLine(currentLine())
  local linMain = lin:match('%.%.%.%s+(%d+)%s*$')
  local tgt = linMain-1
  editor1:GotoLine(tgt)
  editor1.FirstVisibleLine = tgt-12
end
