function! venu#util#sortByValues(key1, key2) dict
    let l:val1 = string(self[a:key1])
    let l:val2 = string(self[a:key2])
    return l:val1 == l:val2 ? 0 : l:val1 > l:val2 ? 1 : -1
endfunction
