import vim

def merge_regions():
    """Merge regions."""
    bmap = vim.eval('b:VM_Selection.Bytes')
    bys = sorted([int(b) for b in bmap.keys()])
    start, end = bys[0], bys[0]

    vim.command('call vm#commands#erase_regions()')

    for i in bys[1:]:
        if i == end+1:
            end = i
        else:
            vim.command('call vm#region#new(0, %d, %d)' % (start, end))
            start, end = i, i

    vim.command('call vm#region#new(0, %d, %d)' % (start, end))
