function! metarw#webdav#cred()
  let user = inputdialog('User: ')
  if user == '' | return | endif
  let secret = inputsecret('Password: ')
  if secret == '' | return | endif
  let $DAVC_CRED = user . ':' . secret
endfunction

function! s:iferr(r)
  if v:shell_error == 2
    return ["authenticate faild: do :SetupWebDAV"]
  endif
  return a:r
endfunction

function! s:webdav_list(_)
  return s:iferr(split(system(printf("davc %s://%s ls %s", a:_.scheme, a:_.host, a:_.path)), "\n"))
endfunction

function! s:webdav_get(_)
  return s:iferr(split(system(printf("davc %s://%s cat %s", a:_.scheme, a:_.host, a:_.path)), "\n"))
endfunction

function! s:webdav_put(_, content)
  return s:iferr(split(system(printf('davc %s://%s write %s', a:_.scheme, a:_.host, a:_.path), a:content), "\n"))
endfunction

function! metarw#webdav#complete(arglead, cmdline, cursorpos)
  if a:arglead !~ '[\/]$'
    let path = substitute(a:arglead, '/\zs[^/]\+$', '', '')
  else
    let path = a:arglead
  endif
  let _ = s:parse_incomplete_fakepath(path)
  try
    let result = s:read_list(_)
    let head_part = printf('%s://%s/%s',
    \                      _.scheme,
    \                      _.host,
    \                      _.path)
    return [filter(map(copy(result[1]), 'v:val["fakepath"]'), 'stridx(v:val, a:arglead)==0'), head_part, '']
  catch
    return [[], '', '']
  endtry
endfunction

function! metarw#webdav#read(fakepath)
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  try
    if _.path == '' || _.path =~ '[\/]$'
      let result = s:read_list(_)
    else
      let result = s:read_content(_)
    endif
    return result
  catch
    return ['error', v:exception]
  endtry
endfunction

function! metarw#webdav#write(fakepath, line1, line2, append_p)
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  if _.path == '' || _.path =~ '[\/]$'
    echoerr 'Unexpected a:incomplete_fakepath:' string(a:incomplete_fakepath)
    throw 'metarw:webdav#e1'
  endif
  try
    return s:write_content(_, join(getline(a:line1, a:line2), "\n"))
  catch
    return ['error', v:exception]
  endtry
endfunction

function! s:parse_incomplete_fakepath(incomplete_fakepath)
  let _ = {}
  let incomplete_fakepath = substitute(a:incomplete_fakepath, '\\', '/', 'g')
  let fragments = matchlist(incomplete_fakepath, '^\(webdav\|webdavs\)://\([^/]\+\)\(/.*\)$')
  if len(fragments) <= 1
    echoerr 'Unexpected a:incomplete_fakepath:' string(incomplete_fakepath)
    throw 'metarw:webdav#e1'
  endif
  let _.given_fakepath = incomplete_fakepath
  let _.scheme = fragments[1]
  let _.host = fragments[2]
  let _.path = fragments[3]
  let _.cred = ''
  let _.file = split(fragments[3], '[\/]', 1)[-1]
  return _
endfunction

function! s:response_to_result(_, response)
  let result = []
  for item in a:response
    call add(result, {
    \    'label': item,
    \    'fakepath': printf('%s://%s%s',
    \                       a:_.scheme,
    \                       a:_.host,
    \                       a:_.path . item)
    \ })
  endfor
  return result
endfunction

function! s:read_content(_)
  let response = s:webdav_get(a:_)
  let g:hoge = a:_
  if a:_.path =~# '/$'
    return ['browse', s:response_to_result(a:_, response)]
  endif
  call setline(2, response)
  return ['done', '']
endfunction

function! s:write_content(_, content)
  call s:webdav_put(a:_, a:content)
  return ['done', '']
endfunction

function! s:read_list(_)
  let response = s:webdav_list(a:_)
  return ['browse', s:response_to_result(a:_, response)]
endfunction
