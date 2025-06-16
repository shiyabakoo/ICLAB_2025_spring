set marker [dbGet top.markers.subType "Metal Short" -p]
echo $marker
foreach m $marker {
    set area  [dbGet $m.box]
    echo $area
    set inst  [dbGet [dbQuery -area $area -objType inst].cell.name AOI -p2]
    set insts [add_to_collection $insts $inst]
}
foreach cell insts {
    specifyInstPad $cell -left 2 -right 2
}
refinePlace -preserveRouting true
setNanoRouteMode -drouteEndIteration 40
ecoRoute -fix_drc