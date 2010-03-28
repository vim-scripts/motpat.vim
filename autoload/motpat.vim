" Vim autoload script - create motion mappings defined by a pattern
" File:		motpat.vim   (motion pattern . vim)
" Created:	2009 Dec 02
" Last Change:	2010 Mar 28
" Rev Days:	5
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license
" Version:	0.1

" 2009 Dec 11	added g:motpat_silent
" 2010 Mar 28	gvmap#mode_no() dropped

let s:cpo_save = &cpo
set cpo&vim

if !exists("g:motpat_silent")
    let g:motpat_silent = 0
endif

" Map a forward and a backward motion (when both share the same pattern)
func! motpat#Map(bufmod, lhsforw, lhsback, rhspat, ...)
    " {bufmod}	if non-zero, create buffer-local mappings (else global)
    " {lhsforw}	key to be mapped for forward searching (not if empty)
    " {lhsback}	key to be mapped for backward searching (not if empty)
    " {rhspat}	pattern to define the motion, will be part of the {rhs}
    " a:1	type of motion, one of "e" (default), "i", "l"
    let bm = a:bufmod ? "<buffer>" : ""
    let excl = a:0>=1 ? a:1 : "e"
    let inq_rhs = s:InQuEsc(a:rhspat)
    call s:MapOne(bm, a:lhsforw, '/'.inq_rhs, excl)
    call s:MapOne(bm, a:lhsback, '?'.inq_rhs, excl)
endfunc

" map a forward motion key, similar to motpat#Map()
func! motpat#Fmap(bufmod, lhs, rhspat, ...)
    let excl = a:0>=1 ? a:1 : "e"
    call s:MapOne(a:bufmod ? "<buffer>" : "", a:lhs, '/'.s:InQuEsc(a:rhspat), excl)
endfunc

" map a backward motion key, similar to motpat#Map()
func! motpat#Bmap(bufmod, lhs, rhspat, ...)
    let excl = a:0>=1 ? a:1 : "e"
    call s:MapOne(a:bufmod ? "<buffer>" : "", a:lhs, '?'.s:InQuEsc(a:rhspat), excl)
endfunc

" exclusive, inclusive or linewise
let s:mov_eil = {"e": "<SID>Move", "i": "<SID>Movi", "l": "<SID>Movl"}

func! s:MapOne(bm, lhs, cinqpat, excl)
    if a:lhs != ""
	let mov = get(s:mov_eil, a:excl, "<SID>Move")
	exec "no <script><silent>".a:bm a:lhs mov.a:cinqpat."<SID><CR>"
	exec "sunmap" a:bm a:lhs
    endif
endfunc
" cinqpat - command plus inner quote pattern

func! s:InQuEsc(str)
    return string(s:MapEscape(a:str))[1:-2]
endfunc
" InQu = withIn Quotes = prepare for use in quotes = double the quotes
" InQuEsc = InQu . s:MapEscape

" Escaping: escaped string will occur first in a mapping, then after a
" search command "/" or "?" (or in a search() argument)
" - mapping: turn chars into key codes: "|" and "<"
" - mapping & search cmd: turn some control chars into a pattern: \r \n \e
" - other control chars: not allowed, replaced with "."
" escape table:
let s:esctbl = {"|": "<Bar>", "<": "<lt>", "\r": '\r', "\n": '\n', "\e": '\e', "\t": '\t'}
let s:escpat = '[|<[:cntrl:]]'

func! s:MapEscape(str)
    if a:str =~ s:escpat
	let str = substitute(a:str, s:escpat, '\=get(s:esctbl, submatch(0), ".")', 'g')
	return str
    else
	return a:str
    endif
endfunc

" wrapper function for a search command
func! <sid>InFunc(normarg, post)
    " {normarg}	    command char ('/' or '?') + motion pattern
    " {post}	    extra chars (^M) to finish a :normal command
    let oldlnum = line(".")
    call gvmap#vrestore()
    let cnt = v:count >= 1 ? v:count : ""
    try
	if cnt == ""
	    " can use search(), which is much faster
	    let pat = strpart(a:normarg, 1)
	    let backw = a:normarg[0] == "?"
	    let flags = backw ? "bWn" : "Wn"
	    let [lnum, column] = searchpos(pat, flags)
	    if lnum == 0
		call s:SearchWarn(backw, pat)
	    else
		if lnum+1 < oldlnum || lnum-1 > oldlnum
		    normal! m'
		endif
		call cursor(lnum, column)
		normal! zv
	    endif
	else
	    " with count
	    try
		let sav_ws = &wrapscan
		set nowrapscan
		exec 'silent normal!' cnt. a:normarg. a:post
		normal! zv
	    catch /:E38[45]:/
		" search hit [TOP|BOTTOM] without match for
		call s:SearchWarn(v:exception)
	    finally
		call histdel("search", -1)
		let &wrapscan = sav_ws
	    endtry
	endif
    endtry
endfunc

func! s:SearchWarn(eob, ...)
    " {eob}	exception message or (boolean)
    if g:motpat_silent
	return
    endif
    echohl WarningMsg
    if a:0 >= 1
	echomsg 'motpat: search hit' (a:eob ? "TOP" : "BOTTOM") 'without match for:' a:1
    else
	normal! :
	echomsg matchstr(a:eob, ':\zs.*')
    endif
    echohl None
endfunc

noremap <script>   <SID>Move	<SID>:<C-U>call <sid>InFunc('
noremap <script>   <SID>Movi	<SID>o:<C-U>call <sid>InFunc('
noremap <script>   <SID>Movl	<SID>l:<C-U>call <sid>InFunc('
cnoremap           <SID><CR>	','<C-V><CR>')<CR>
noremap <expr>     <SID>:	gvmap#mode()
noremap <expr>     <SID>o:	gvmap#mode("i")
noremap <expr>     <SID>l:	gvmap#mode("l")

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:ts=8 noet sts=4 sw=4:
