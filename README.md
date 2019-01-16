# personal-npp-luascript

This file contains my personal startup.lua used with the extension
LuaScript for Notepad++.

It's chaotic, never finished and continuously evolving, and of course
there are bugs, but you may find it useful for your own needs, as a
starting point.

Most of tools are for LaTeX. The main ones are the following.

### Hard wrap

EOLs are inserted as you type, if you are at column >72. Comments are
taken into account, and with things like * or - spaces at the start of
the line are inserted.

### Environments - CtrSh-E

Surround the selected text with a LaTeX environment, with a popup
list. If <> is selected, a multiselection allows to enter a name.

### Align by char - CtrSh-G

Select some lines and type CtrSh-G. Then select a char for the
alignment from the popup list.

### Auto bookmark

Add booksmarks as you type, if there is none nearby. Useful to navigate
the latest changes (I also use LocationNavigate).

### Fill paragraph - CtrSh-Y

The behavior of the function may seem odd, but it does what *I*
want. If no text is selected, CtrSh-Y selects the current paragraph,
*without* wrapping it. A second CtrSh-Y does the fill. With a
selection, does the fill. A useful combination: CtrSh-Y Ctr-J is
"paragraph to line". It takes into account \begin and \end.

### Comment out

With comment characters at the beginning of the lines

### Find with popup - CtrSh-A

Type CtrSh-A after selecting a text, and a popup list shows all
occurrences.

### LaTeX TOC - CtrSh-O

Shows a TOC based on \section, \subsection, etc.
