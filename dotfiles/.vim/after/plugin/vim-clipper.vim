if !exists('g:ClipperLoaded')
  finish
endif

call clipper#set_invocation('')

let g:ClipperAddress='~/.clipper.sock'
let g:ClipperPort=0
