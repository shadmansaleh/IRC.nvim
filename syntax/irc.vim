" Adapted from ircnvim 
" [https://github.com/marchelzo/ircnvim/blob/master/after/syntax/irc.vim]
if exists("b:current_syntax")
  finish
endif

syn clear
syn match IRCTime    '\[ \d\d:\d\d \]\s*$'
syn match IRCNick    '^.\{-\}\ze>'       nextgroup=IRCMessage
syn match IRCMessage '>\zs.*$'             contains=IRCMention
syn match IRCMention '\s@\S\+'            contained

hi! def link IRCMessage         Normal
hi! def link IRCMention         Special
hi! def link IRCTime            Comment
hi! def link IRCNick            String

let b:current_syntax = "irc"
