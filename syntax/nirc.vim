" Adapted from ircnvim 
" [https://github.com/marchelzo/ircnvim/blob/master/after/syntax/irc.vim]
if exists("b:current_syntax")
  finish
endif

syn clear
syn match NIRCTime    '\[ \d\d:\d\d \]\s*$'
syn match NIRCNick    '^.\{-\}\ze>'       nextgroup=NIRCMessage
syn match NIRCMessage '>\zs.*$'             contains=NIRCMention
syn match NIRCMention '\s@\S\+'            contained

hi! def link NIRCMessage         Normal
hi! def link NIRCMention         Special
hi! def link NIRCTime            Comment
hi! def link NIRCNick            String

let b:current_syntax = "nirc"
