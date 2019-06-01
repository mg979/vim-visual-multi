
fun! vm#variables#init() abort
  let F = b:VM_Selection.Funcs
  let v = b:VM_Selection.Vars

  "init search
  let v.def_reg          = F.default_reg()
  let v.oldreg           = F.get_reg()
  let v.oldregs_1_9      = F.get_regs_1_9()
  let v.oldsearch        = [getreg("/"), getregtype("/")]

  "store old vars
  let v.oldvirtual       = &virtualedit
  let v.oldwhichwrap     = &whichwrap
  let v.oldlz            = &lz
  let v.oldch            = &ch
  let v.oldcase          = [&smartcase, &ignorecase]
  let v.indentkeys       = &indentkeys
  let v.cinkeys          = &cinkeys
  let v.synmaxcol        = &synmaxcol
  let v.oldmatches       = getmatches()
  let v.clipboard        = &clipboard

  "init new vars

  "block: [ left edge, right edge,
  "         minimum edge for all regions,
  "         flag for autocommand ]

  let v.block            = [0,0,0,0]
  let v.search           = []
  let v.IDs_list         = []
  let v.ID               = 0
  let v.active_group     = 0
  let v.index            = -1
  let v.direction        = 1
  let v.nav_direction    = 1
  let v.auto             = 0
  let v.silence          = 0
  let v.eco              = 0
  let v.only_this        = 0
  let v.only_this_always = 0
  let v.using_regex      = 0
  let v.multiline        = 0
  let v.block_mode       = 0
  let v.yanked           = 0
  let v.merge            = 0
  let v.insert           = 0
  let v.whole_word       = 0
  let v.winline          = 0
  let v.restore_scroll   = 0
  let v.find_all_overlap = 0
  let v.dot              = ''
  let v.no_search        = 0
  let v.no_msg           = g:VM_manual_infoline
  let v.visual_regex     = 0
endfun

" vim: et ts=2 sw=2 sts=2 :
