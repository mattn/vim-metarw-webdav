function! metarw#webdavs#complete(arglead, cmdline, cursorpos)
  return metarw#webdav#complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! metarw#webdavs#read(fakepath)
  return metarw#webdav#read(a:fakepath)
endfunction

function! metarw#webdavs#write(fakepath, line1, line2, append_p)
  return metarw#webdav#write(a:fakepath, a:line1, a:line2, a:append_p)
endfunction
