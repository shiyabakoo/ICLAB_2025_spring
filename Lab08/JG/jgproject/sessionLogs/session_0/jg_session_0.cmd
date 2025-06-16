# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.09
# platform  : Linux 3.10.0-1160.88.1.el7.x86_64
# version   : 2023.09p001 64 bits
# build date: 2023.10.25 14:35:20 UTC
# ----------------------------------------
# started   : 2025-04-27 12:14:03 CST
# hostname  : ee21.EEHPC
# pid       : 42609
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:43511' '-style' 'windows' '-data' 'AAAAnnicVYq9CkBgGEbPR0omV+AOGMxWG4nBapCUZPCzWLhUd/J5E+LU81ePAqJNa82FuYq5JKQUxOIZpeSLOu4SKb6ofP8lWM/xuRgiG5+Jhlq6R0dLde+KkYWBkIBZdi8PhxN+VREN' '-proj' '/RAID2/COURSE/2025_Spring/iclab/iclab023/Lab08/JG/jgproject/sessionLogs/session_0' '-init' '-hidden' '/RAID2/COURSE/2025_Spring/iclab/iclab023/Lab08/JG/jgproject/.tmp/.initCmds.tcl' 'jg_sec_run2.tcl'
clear -all 

set_proofgrid_max_local_jobs 10
check_sec -analyze -sv -both ../EXERCISE/01_RTL/GATED_OR.v
check_sec -analyze -sv -both ../EXERCISE/01_RTL/SNN.v 
check_sec -elaborate -both  -top SNN
check_sec -setup

#clock clk -both_edge
clock clk -both_edge 
reset ~rst_n

check_sec -gen
check_sec -interface

assume cg_en==0
assume SNN_imp.cg_en==1
check_sec -waive -waive_signals cg_en
check_sec -waive -waive_signals SNN_imp.cg_en


check_sec -interface


set_sec_autoprove_strategy design_style
set_sec_autoprove_design_style_type clock_gating


check_sec -prove -bg
