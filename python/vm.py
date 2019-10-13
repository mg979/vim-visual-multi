import vim

#------------------------------------------------------------------------------

def py_rebuild_from_map():
    """Rebuild regions from bytes map."""

    bmap = ev('l:dict')
    Range = ev('l:range')
    bys = sorted([int(b) for b in bmap.keys()])
    if Range:
        A, B = int(Range[0]), int(Range[1])
        bys = [b for b in bys if b >= A and b <= B]

    start, end = bys[0], bys[0]
    vim.command('call b:VM_Selection.Global.erase_regions()')

    for i in bys[1:]:
        if i == end + 1:
            end = i
        else:
            vim.command('call vm#region#new(0, %d, %d)' % (start, end))
            start, end = i, i

    vim.command('call vm#region#new(0, %d, %d)' % (start, end))

#------------------------------------------------------------------------------

def py_lines_with_regions():
    """Find lines with regions."""

    lines, regions = {}, ev('s:R()')
    specific_line, rev = evint('l:specific_line'), evint('a:reverse')

    for r in regions:
        line = int(r['l'])
        #called for a specific line
        if specific_line and line != specific_line:
            continue
        #add region index to indices for that line
        lines.setdefault(line, [])
        lines[line].append(int(r['index']))

    for line in lines:
      #sort list so that lower indices are put farther in the list
      if len(lines[line]) > 1:
          lines[line].sort(reverse=rev)

    let('lines', lines)



#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------

def evint(exp):
    """Eval a vim expression as integer."""
    return int(vim.eval(exp))


def ev(exp):
    """Eval a vim expression."""
    return vim.eval(exp)

def let(name, value):
    """Let variable through vim command."""
    vim.command('let %s = %s' % (name, str(value)))

