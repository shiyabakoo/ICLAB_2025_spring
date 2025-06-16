# please modify by yourself
floorPlan -site core_5040 -r 0.996012385063 0.7 100 100 100 100
uiSetTool move
selectInst CORE/L1
setObjFPlanBox Instance CORE/L1 592.225 1118.775 1607.785 1883.175
deselectAll
selectInst CORE/L0
setObjFPlanBox Instance CORE/L0 597.74 288.993 1613.3 1053.393
addHaloToBlock {15 15 15 15} -allMacro
saveDesign ./DBS/CHIP_floorplan.inn