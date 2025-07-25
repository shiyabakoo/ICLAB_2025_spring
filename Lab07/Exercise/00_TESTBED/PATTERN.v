// `ifdef RTL
// 	`define CYCLE_TIME_clk1 14.1
// 	`define CYCLE_TIME_clk2 3.9
// 	// `define CYCLE_TIME_clk3 4.1
//     // `define CYCLE_TIME_clk3 20.7
//     // `define CYCLE_TIME_clk3 67.3
//     // `define CYCLE_TIME_clk3 99.9
// `endif
// `ifdef GATE
// 	`define CYCLE_TIME_clk1 14.1
// 	`define CYCLE_TIME_clk2 3.9
// 	`define CYCLE_TIME_clk3 20.7
// `endif

// module PATTERN(
// 	clk1,
// 	clk2,
// 	clk3,
// 	rst_n,
// 	in_valid,
// 	seed,
// 	out_valid,
// 	rand_num
// );

// output reg clk1, clk2, clk3;
// output reg rst_n;
// output reg in_valid;
// output reg [31:0] seed;

// input out_valid;
// input [31:0] rand_num;
// reg [31:0] golden_ans [0:255];

// //================================================================
// // parameters & integer
// //================================================================
// real	CYCLE_clk1 = `CYCLE_TIME_clk1;
// real	CYCLE_clk2 = `CYCLE_TIME_clk2;
// // real	CYCLE_clk3 = `CYCLE_TIME_clk3;
// real	CYCLE_clk3 = 99.9;
// integer total_latency, t, latency, patcount, out_count;

// reg [31:0] seed_dff;
// //================================================================
// // wire & registers 
// //================================================================


// //================================================================
// // clock
// //================================================================
// always #(CYCLE_clk1 / 2.0) clk1 = ~clk1;
// always #(CYCLE_clk2 / 2.0) clk2 = ~clk2;
// always #(CYCLE_clk3 / 2.0) clk3 = ~clk3;
// initial clk1 = 0;
// initial clk2 = 0;
// initial clk3 = 0;
// integer a;
// //================================================================
// // initial
// //================================================================
// initial begin
// 	reset_task;
// 	total_latency = 0;
// 	a = $fopen("debug.txt", "w");
// 	for(patcount = 1; patcount <= 1000; patcount = patcount + 1)begin
// 		input_task;
// 		out_count = 1;
// 		while(out_count <= 256)begin
// 			wait_out_valid_task;
// 			check_ans;
// 		end
// 		$display(" You pass %d pattern", patcount);
// 	end
// 	YOU_PASS_task;
// end

// //================================================================
// // task
// //================================================================
// task reset_task;
// 	rst_n = 1'b1;
// 	in_valid = 1'b0;
// 	seed = 'bX;
// 	latency = 0;
// 	force clk1 = 0;
// 	force clk2 = 0;
// 	force clk3 = 0;
// 	#(CYCLE_clk3); rst_n = 1'b0;
// 	#(CYCLE_clk3); rst_n = 1'b1;
// 	if(out_valid !== 0 || rand_num !== 0)begin
// 		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 		$display ("                                                                        FAIL!                                                               ");
// 		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
// 		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		
// 		#(100);
// 	    $finish ;
// 	end
// 	#(CYCLE_clk3); release clk1;
// 	release clk2;
// 	release clk3;
// endtask
// integer i;
// task input_task;
// 	latency = 0;
// 	t = $urandom_range(1,3);
// 	repeat (t)@(negedge clk1);
// 	in_valid = 1'b1;
// 	seed = $urandom();
// 	seed_dff = seed;
// 	@(negedge clk1);
// 	in_valid = 1'b0;
// 	seed = 'bX;
// 	golden_ans[0] = seed_dff ^ (seed_dff << 13);
// 	golden_ans[0] = golden_ans[0] ^ (golden_ans[0] >> 17);
// 	golden_ans[0] = golden_ans[0] ^ (golden_ans[0] << 5);
// 	for(i = 1; i < 256; i = i + 1)begin
// 		golden_ans[i] = golden_ans[i - 1] ^ (golden_ans[i - 1] << 13);
// 		golden_ans[i] = golden_ans[i] ^ (golden_ans[i] >> 17);
// 		golden_ans[i] = golden_ans[i] ^ (golden_ans[i] << 5);
// 	end
// 	for(i = 0; i < 256; i = i + 1)begin
// 		$fwrite(a,"num %d = %h\n", i + 1, golden_ans[i]);
// 	end
// endtask

// task wait_out_valid_task;
// 	while(out_valid !== 1)begin
// 		latency = latency + 1;
// 		if(latency === 2000) begin
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			$display ("                                                                        FAIL!                                                               ");
// 			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
// 			$display ("                                                     The execution latency are over  2000 cycles                                          ");
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			repeat(2)@(negedge clk3);
// 			$finish;
// 		end
// 		@(negedge clk3);
// 	end
// 	total_latency = total_latency + latency;
// endtask
// reg [31:0] num, num1, num2, golden_num;
// task check_ans;
// 	num = seed_dff;
// 	while(out_valid === 1)begin
// 		num1 = num ^ (num << 13);
// 		num2 = num1 ^ (num1 >> 17);
// 		golden_num = num2 ^ (num2 << 5);
// 		total_latency = total_latency + 1;
// 		if(rand_num !== golden_num)begin
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			$display ("                                                                        FAIL!                                                               ");
// 			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
// 			$display ("                                                    			golden = %h      your num = %h                                                 ", golden_num, rand_num);
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			repeat(2) @(negedge clk3);
// 			$finish;
// 		end 
// 		if(out_count > 256)begin
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			$display ("                                                                        FAIL!                                                               ");
// 			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
// 			$display ("                                                    			     output never stop                                                         ");
// 			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
// 			repeat(2) @(negedge clk3);
// 			$finish;
// 		end
// 		out_count = out_count + 1;
// 		@(negedge clk3);
		
// 		num = golden_num;
// 	end

// endtask

// task YOU_PASS_task; begin
//     $display("*************************************************************************");
//     $display("*                         Congratulations!                              *");
//     $display("*                Your execution cycles = %5d cycles          *", total_latency);
//     $display("*                Your clock period = %.1f ns          *", CYCLE_clk3);
//     $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE_clk3);
//     $display("*************************************************************************");
//     $finish;
// end endtask


// endmodule

`ifdef RTL
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 4.1
    // `define CYCLE_TIME_clk3 20.7
    // `define CYCLE_TIME_clk3 67.3
    // `define CYCLE_TIME_clk3 99.9
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 20.7
`endif

module PATTERN(
	clk1,
	clk2,
	clk3,
	rst_n,
	in_valid,
	seed,
	out_valid,
	rand_num
);

output reg clk1, clk2, clk3;
output reg rst_n;
output reg in_valid;
output reg [31:0] seed;

input out_valid;
input [31:0] rand_num;



`protected
aH-<<(3L(YY.+NITLM&bQB[)+KKC/_BcB,6/HJ31IEBJ<A0J&+AP7)?AD8dCQ1>5
>V#MQf]adS?(?>fK0S8I8@,X3PB>MX8FL6+=]e\C:X?X:K&Q896[UEWW7PWGTccN
^R6)K8>gF=GVS,U@9bA238f1#_dU1cNe(^HU]HXUG>VEC^;^c0dI==A8YcZ9=>Lf
)C1DFF88D[c?&?fgBbVK.CIV.T77.G[]+#OBAUQaH;SBd0E2[SU=GL>XHXeL[b-6
R=AY<+3KbM&-YSCYY_O-IcTLW(,+VPL_9YFdA/)O-V[+AD<^0)DVS-/B8E&EE\8?
0c1D<W)da459Xa<1@@fMa#G1-[31&3.ObXKCFA&=WOF(4C&[P-O7.IXN8#5BN4&4
T07ON)MG43Zd@)49X)=\&>?fe1,@3\ILP<U5JG+T436GX=Q@1[-<?33c#H[L-79C
#38UW&adQ;aM<8R_Z+[F3J27UB?HbEDgD[+0EGIc^;^\-41+UV;W_4RZ1)Q^bRX#
_Vd6M58Y:=T0)0A>^\4)?ZAJ)I-[(2P0a,55<KIB1J\21B8]]K5MJU>?Q2E&FZd2
8Z3\cdN=ecAQ\C#c99?E:H.<XU[3)[M(4F[66\@a],E[?>GD&=Bg_8/Y?,WB09aK
3E;Z[(([167>/Ba[aH5+V9^#H3?-=c[G0ZRMGI;R\RG5d;KZ7F]f,E>1SGQQ80?2
<PMdM94J_#F\M9,,I#bMDL\E>#+5,2R:<aWg9;R/N>QWB[FXW_B]X/dT:UgIeD07
Y3?(;W=VG3S26P:KYZ/[4FS&dG?HJOZM]Q3R)RO,:O)#5\W?gb1TYa1)bN0VM[83
(CRRTZWMG@VA4FC\1;QW->PBUe;/SL6\.&C+6W666B4J.C#JP0NYe4YE:=^#:#BM
-XY(=>I\.,13(_SZ\)dMD>+D3M/cdcG&?aTH)GUc.I^fbba9V>M2PXC6.\9aX@,=
fb2RQN)gMN@RYeL@L(^_&00+;c\6#2-NR?1YV/>,g\9/5FF+bR,5Q3C^/=e&dBU-
NK<GfQd6ED?5fE+L4^9WCc4-(A6-e0Ob-2WWb.7LV7TINOe+9&2G.TRMPd6/EX=V
4[G?R,,@:-IE[1g\WXTK][a6E]]3OG?&d.P8@cU[:&.DV/5<g0<5AO8GUE0.NW-3
e-T)DK(cbGQdQ3abQ0-.8d\C_]:[7EU]=(3DN5],SKR;Z&86a95?\S<f^ZSbe#Q)
MZ<gPXK#YMY4+N0f@WJ)XT[XI)/1N39OSVO>^LC@,Sa.SG#LSeQC28\e3WbSg)42
+V.YabJEBGQ,KVN/^+_S4\aS8,6T/\1\M&6-XS.f5BRgV[LgB&ZR,>I,_G./-O&Z
FLa.YP?AA1.X]UKbb/=K&M0,,[7FWZ89Y.\OJX9[?2QT\MQ)6L=700&fEYYeB-E0
/#MVS.L:(;J:f=6ZI/&I+DX,,?4L)@G+JaZcaK.^#Z?:Ad>GC#Q8Q^KMMPBM&#-<
;(^<e>:5fT4N74W2I^F)Z4AF7Y-O@7TB.L:BR?R/7A9>8D#:,X_M?2FL,@KAJC.>
Y)/L@->7\FMUI.g&[6(?QfMN?fK=03Z..aOUM,O>@0Y_Q=YQL0_I4,<cQDgR^.[K
<Zc1ea6E4J[)F@.ZH[7918N&67RHf5Lg3\Mgb_YQSN1@HQI0UE04+9AcR4UM:bC7
aK<-SK<QH5\I7):D+1K[G]#>Q1+_INEV&HM4[PO(9Lda#WCWUR:-=F5([_SdL789
)6W/J<EdL0]f?S_1Z8Aa(bD\&KbZ)PCN@A,6:aU3E&MU@K@>Q\eYD>[/Q/8CbRG5
7B8]SM,VN<X:U;eg^=B^Z[/-M<#9,eUS]=<PG6L_VXGAR;VO4=)Q,E/=d#<,X1.D
NVVfbC^NH_e1_K8ZA4&,X67a5fD8E8^S>eGD96[8J\aXJK_ZFCR2AYG8/YdM&ASZ
.Bg]TQ.\C&42RPbF\->9,Y_&T)^B:,F,.8#d]4+46JCc=>044I>YfP;61fDb.RP)
OKfTNLCNCH/#-f\93c&UfgYW#\?KD/D41:e-JG#g,gG<DdD>A0ZJ3_DERc5>@HG1
f?c5/Y&U,;Q11D8?RYD+YZ)<&(=L\e<V,)f+A6T:VcQ0HM6J.JAOI.^T5+VW</+&
SU(TQ&=?6#,QKG<&4d&6+d+97.1D=64Je1QgQAbB32H3&@/F:5c=ecPTb,0a-0L-
JC?3S)^deLcC/;03b@/HH#N2DcCQbK1]+BIN?62).e0>f9HW]O?FcJ\#:T/EG3X^
BD_6#M:3\<L==0>_\,7W4edIUAG?I9eIR0=>BaK(I[fH3T#bG_F_^EFBTcYGP,NM
O3\]aQf/D<>[L4:V=AfJAKbIVfBZdYIfc9&E:,3G)GCS1R#&Sf?ZJIF@:c?.8d&O
\AR,2&32Q^6MU15R/4X=2\YV@a-O9.XVD(W:S8EHg[8c1_=/=>dPUCdIL4N&3P#H
(>6V:5(R)_G0^G:e6])H5[DG=O]0ESR;?S;BWfGR)<@XUA1_35V(Q(A+H,eeO0IX
?QQB^7]Sf?XAgJ:E8a(H)\SD@8DPe/S]91;cN&+OUd:D-5^5A]F\CXPWW)g1bI4[
g05;RG>>[ZDY_G9I[JB4T+d]X9R+K^XR&gVPQG^9Qb+DI66@#-D)2Y8+&3O0HC&:
DA_R]O_e&A@?I^3c;cN;b?cPdN_X3a#WGNPW).>fY,/[57,RF0dM4XX3;5-\.=R7
4[?e>ED:NMF#4Re]S+W.?bYXX#S@O2JLfHJNAM+gI:3_M=gJVW)116/@P>Cc(PP?
_<S2<J:1FegMb;\BPUX9Ta>84SPF?gT_g3,VM[g++0:NYE-NI9U:(/.XNKcb58g[
@#YKTgeYK#O?4b]]DHGe,VOZK3>?E[@48D&&T)B:C4d(<H7L\HKM5[+/.W?EB]CF
\5HUTEDE]X.JF4:]cURMNZJ4A,)>LCL4dH;(OV>@6^+OQDUY@QNIW/+]7,EM^.0:
c1T6@g_,CQA?QD,QL6QGA;L:4Pc?HKN:AV?d^H\^3,7fKJOMI/H7V#GE5)5WW1.#
C)4MbJX&YOXe1+VSJ7,X0CRTJ9-IOgPJG/?3-\@F35Ib^^O.d[HL(7+L=P?Q=Q;Y
YaGXGda=2/RP@05I4^\aQ08N?_O6^0cf=.QQMP,?+T#EN2WFDa&(F[,97CZ&K2OK
P51.e(ZIJXV1FRJbGE7O(L51c+)/_SaB^f,C5P-Y.85?3aDSb]URVR4S6RTgD9aV
II:XLTIB356.5>CFD95\[9)Na_T]_2C?YeH)R2[dK:=Z9C:adIJTY,_Y=F/]\Q[@
@,.)9AbR(/??NI,6=32EbL99gF8;OX3OSNU/,BSD#U6N?4KbA]daW]RE;B&0:E13
<)J#->fH-@@DQ)..QZ6N_Qa0@0>HDTb-J/]c10.#NaY:<(F4[4Q^=W]d-c/,W_WN
ReU@Z0CKSX;=?c4/Ed-G94LNM9_C?>TONKbSd^AU9G(L7,M\@B\aMg/[@g\VL)cP
?f/.D#K6VZB(O,6;g0O1:_43[dY5L135^?H?HN[7\\ddQR>f=+1SW+&Y)?AEc/^Q
bHJ(YMW^^2;V_=@IT@GPeK.#\e5EfdF:>1,0af<:.OM@URWBTVBIZd>?g.-RL);C
e^J84N;Z8<#;).fDU^@2I@Kf=I39//a6#AD9&d6=[Q=FZ,c8#SCg]1YYeKKI_c>P
I5Y/VZKQabD?6R=@SIAaMS#b>J/W6Sf\GB)-&2A)K)K6?-0=K9.QIMPQNGX:BWW0
7R.6CR.D53:+b_M:C\S:,&814.V4P3#SD_>FbF]ZDN\8F^a&8FAU;J7)2e5\JR>G
J-T)3;MRYK_KU=.3CJeF0Egb1-.Q,L@,=C.TZ<\@<0;WBNaT]dX0W2c&6[_WGIL4
_-4f(+-QRZ21FS=Bd4T,Y1LIcddA4Kc_PU3AB+)2?Ma4_[baMA()20@)GcPfYS9&
(_1+\,0V=<EZ=>g[^?R)5bT_eO=A9BJHVM_&@V2L>@_046;-P[C?R))LJ&H]+bH<
8bEea2Rc,Gd@DSOg./M;8WNAN+2J8?3QRb.QW_0WD8T2[gEd15JR0e^I+&LgPH\E
0QE5Y(ZXJXc+\G^B0dJVK:KP4f4_cVM64Ef3I4>49?H/0AP3227g_(\A]HbcU@Q(
(>C,=ARcF#_[J8[?;BMRH-APGI,g^7HX\B[+7?AH2CGL6UWM.DAQ?BRH@IH[@DeT
aMFg_bU:&7S9V-_9f&F_NfOM91a9(K80#=4LW21<9/6_;aBYV,M:&8&K=Yd3+a,2
1S&&d6;-M8<X5(Ob@+2F?Z-fDaMaUIR-dEYN.\[4.HXgc=T&JL[0(ZB/(U\<1Z;F
1e@WY3fX#8YIJbO;9UPe@;f\<+_Kg4R[KTZd>TQ25ZB3:eCZ;MT:7ScNIe9_OK<T
K#,Y-PPPN6a_P7#)[LTA,P+Me=O(>Adc._6a)?b)&,R8:58.KD@F5E@:/b\g<,-e
+]_OZ[DZ^f\;A+0SR-OZb]gI&VdBK.?Y4[](<UF#?Z=b7>#K:/7)Da;#GJRIN<B5
4+KG([6f-SW/bfGX.,85?)Vg,6)ZfS7,XJJ]#79B2/8Udf]4G]LaR?&4MO^+&;?;
RXP#La?10a-g>RdB4Df7DA90/@GB0ZJ[RG.N9f<2(Z.+:-I3+R);WXW)eQbI?RZZ
,K9#1IfCS@E1W(TH/XcT;D3K8FJ28>A(?6OJ/NVIfg1]aNK<U_a]7X[cXc#_NfbB
YI-+B/&NP]]c(KG^HT/ZLZ^T\36+Hf,&YU&/<1G4)c.U1VRF><M3<C.T?H01#@07
HCDQTAJ[@2.#2#(;AeB:d+B.4.LSUaf.UMT3#/a6+Ngb8Wde>df&#;O6):Q1T=WW
-/#fA+;UL/cS5dEa51Bg>e/C-P73DKXQDV.\KWIS^\bP10O+^X&5-a02^eSS]RV<
+KOP1WR,bC5V(R8I^VAN3]dC5D49:DLF5KTg&@>46.OC,,@\?YDeSC4d,>R3J&&G
KVRDIK?bb424d&:Za=_V?B:RZPe1;;27A&b?1>,eF5?.&ANK0Y[1#_@?_a3+?LMX
D\5ER9&#I1;E_HKL9D0A6&3_9>,#Nf+T[/Y^U?:P54(AOeQ=gCAaV:,+)8Ec,JeV
:Af\\=8XU<B@f68O>+ag_58M@(c<7Z\N;(_.?YA&+U-/gDD4+G&eL[^J2;A6O8[P
\;12Z,(CYM0(]0b.=:/TX9>__@fAT60H<W[Dd@/223Y7.OD(P-_X_A@aR&3c:7DF
^5&AfC3/D+<NI-45B)b3cd)E<L;G4/S[Z4XIaHKF97DR/9FfA9YfVJ9O6NZb(X[Y
^@9QLRC=e>gKN:.?(:J.,<IX;CZ9)=4>6+-_:T\<[6aFgWWd7/XgGb3XK&F7c:6V
.G_]/K&^@76NV-.(W]?#[09(6>XE7g.O?[TP1O7QY))PQ7XZ+8KA734&<H=CF;&I
VS6&7fee?;.fbb-6AA+@\gdK3CHE70==0_=<E#eVY&^M9H]1AcV:X8\R[efPe3#K
7Y(?DSRSaWX&CRKQaZOCDMCPJ0&e\c->NOY<V^fLZgSe?F#>CN?>-c5eVO,3;83D
QeK;g+RV+YZ8\-BZ@S_71\-5I,5GbBCY2YX>-=Z]GR&Z_.6A?cdD[Pb=_Y8Pf1@9
X:8T[26VKX5JW+UfC^(P+D?>/M44b_.V9P&(SFcc8ZZJ?=&=d/RD8a773KGddNLL
#-QHVKYETODIC&E)F9e:[TA9PDD-UQW,G/+QZR)Vb<G,<.=UV#EWeRJ@5S[/]+_f
f(UU#\Ec+88>-3B_cS2KD0](I]9&D#N;(+TY:YbG:NW6&O-WgRCC969T69Y(^8+H
e#\0(-K1PEb5d:(cBaNSc:7b?SG.&:2V>U<cKU(S?W&;3O?f[5ZH:HQP24JIEV_[
V]/C@UPWH;O?OfUgHHf.(@2_,\;6=43Ld>(2M:L(G6R9ga@7b>A^W_NeVcA#9VK-
Z(L;D@3RL>dE[?]@94GFg9?H/H,fWIVZa76[;5Y@GB5cY4I;EEIc))+d:^HJdO:L
aFE-,_W^=VF&O+:+W8,f+XcTE#d7>fL;<a9<gN_EAT>Qe5GG5/PZ<L@DI:aE)BH3
X>=;#.+=b>1HGHN;B0OCNQH8#J8J:+E?^)P5]CV;:OQBKc_Ba4AW6,HQdU:@C:f6
#-@-^?780,aQ>1Yf\3b&5:@<C9KO<W@gTW+ca5bPZF#^I=BBX0T@,?\SKU0=@]V<
-(cL(-f)+D^_^_#(3=C8fUT#;#.(Y6eWg>A9L=bRRG4UK57\#CV,TadVY=D1BU5,
2f3aXcTSUSB,973cVC8<aFf75ME5aQE:UZdM.3YeT<#L4R9XF:Pb?1fg(,2D\@D.
5aAVeTLDBZ\WeZ[Y^K2(;,FWVP^CeY(=A9>HWQ,0@EV>8GIG0WYKC7,R6c-FPTd^
&6RE]B:HQ6][g/7_7X<\8aG##Y.5e+4?6Ga+&-gKZ6YJ(SPbO?L6Y41^=GO7V7PN
^Q)N6=TW=5B=:G+IfJb2N1:&&f35Q8\PHS/^-E9bbE:3:+3c.@QG7#-cE0@-(9NZ
#A]9Jfeg0FU[Z<@->Q<6f1\AR1C37YR]P(fDZa4L\BR.cg8U1bVB8\O];A6D=-6#
60(#TGc5B07H1NDTI@I?JaC6ef:SVgE>V^M.XN7&,OI4.DbKTN#K6:/0_&6dQPP;
?G.;Df&R7g5/aHFE0]Uc,43,HZMf:Ie8&&2fXJf,,S(\3&QPATG4Q]eP7[_A\](a
c4c)C\.FWaRMJHGdZP\bY038MHgMU97R2VW4YEV#PD3DN-TR,<Q,=A@:O3Wb(Z#f
a6<&OD(S08WUQbc<Y?X&\[TJ<R9a.UeUL=dX](HMGcf[(-RG-:g@IPYZC<SS50CS
G[A<g+]X7\W6/QQ--Z6F:G6RR=5EG&M>[0.@3D@HWO<T.<fc=a9.0+HEALR>E60/
WTP0A1;FC)\F<Yf\0+9@a6A=OKRb)PN:9<[_4SYQ?PLE:g0QQ];b0))gI,OXW)O_
OMQ,Z471\?O\U>Vd:(=;KfA&/I:,MHfM)=PP5:fbFW8A>YGY=BQOX@e])D&>MXR0
]/E/Pb/Z>;TKbQ?IN?#f(Zf<S@RBIcRK_OaH1NJ8fBX0#/_7c60M.=6)8^c2:VB/
@NOGBC@5,GNMQYc&7D&1H>S+)(:1dC6IBPYBZX>B3-LF[AN;a9+2UE<ebF,\Ia&B
&)fTMM>L4OJ^A7R.1F(.P[e+4W0BZI(]Pa)cL/1gW\2]Y:&ZL?0CFgZK?Z8+BUBF
Y>?/7Z(>>R?Laa4(@/SC2HCc_;7c=>8MN9QDH##DH92G1ZF2If[B-WH47aUa\D)9
:/D#VO6[I:(5^F^IK/_U/._C&2a6=.NUG;I>&5b6;(55cBgGJ]@)\H22+]EM8XM<
W-[47H/cA__YHIDTG),X>[QQMJFY92Z3Z/e@FcKY@cYQ9,ZE^J6G-eVJSdUc9dg&
M)L#f/43d:#LgD6V.MP&UHa>KCd<.0C&cW.SB=JY+1#\f;,X-+4eM+ZJC>cJacSe
b5QKZMFYAc>A9XL&c;L+VcS+&CT4:/LdYO?#eSe_.AC->KKPPZ4NOcB;Te@S6Z0\
8]9FI:>EcXZL@4?SY@@X8DAZEf;7O;g@e^-6g:_A4(&[I:]?ffV\a&IE_SY<4+W2
GTI6dZKaAV0VZPQNLXY-LAYVcA4a7LKXJfZWd)I9e.9CgS[QO++&7,7+VME@^?FX
WJC\.#-7::LTFLbZa<?/N:;9P:&O2JVdFMdaFXM50?;7];REc@/FC?&QU]GgdHM>
b[/-:9b[((1CIX/c-8(Y<:]WS51#E,T[EV??Y\C(4P<7\^ac<EJI\I48K6_c_5[,
eg48KX/Q<@BVdS>IFL<TB9c;[8USIBT(0BNRPC:]A_4J])W=#:=I8K>D6,(?H),c
ZTA6ba;eF)O(O/.LM,IL9cY7YO^U(3?W2Y,0Y^e>.MJBTeNf\+b@)e9+_><4Y0+/
=:&WKG41?d?>5:;>Y[JeD#YE3#D:7;][e^HROFDD0b[SI<@8J;eJW\W<A<8a,f??
)&9LHQ^,&)H:[?FSW@2+gSd+-He)M\:MSI418)/dcEEXLOEV(P]D[25F-HMQ=egV
1AZ^&8^M9ID6[I#+AC1cO^:5[6edHb1]PRS,);=U1Ef;>g;Kfb<])b0I;LCWW+>)
?U#Gf[=<6Sd5L.g=(M(7;-QB3F(OW;IHeVH7#Na?VUB.d9&/&U>W&Y0UaN1YGJJ_
U7_7CC@XFQSZE8SM)JBL\Q5MPH<TgM:d6BRab4&?.,OAa]5O[3bceGF(4&-//32e
<V-4P&F<TQ2XQ9=5=^a2J(EH>MAIYM\J)1dTL:H8ADg9WAK(#WI[J?EWK=U(5cdB
MJV14RK@246_gfTCBR5SU;]EOg/18]7HN4Ge<1_:+&c&U]XF,),9SBKI<T0d,K\:
GbW1D\2WC@I_NTI)Kbd)73)9Ka\.gFf0VBW-0Q=d^g((V#))VGKG\6XYZ--)=P+2
,gY;d5_#\J;cQcV3D><M91D?V^d7;.&V+)TdXZdFL^JS&YgX;GU:2_7&?eQYcMdc
P00^H+7;D2(Q<G3N@UaSCKIP9\^IX-^2Y#f[cDVTNe\&+0e9Z&SAWg7g?bGW-V:c
_[5]I9D[/\^\Nd2Z,.>=_b?dY@COM/\LE]1^Ue)aM:G=AB[M,)]4@?0>P\]#V9I6
0cf),,;U\6OXUTCYF4<[+?X#H3UeN=?EF1#X]_R4bgI&UO.7&dae<T=U6L#CQ-[.
[ENW+R#2gNE5aIIGS>?V;fF8RgC=6H].5C\KYd\addOfbf24=;b&UK>O1N7c0CXE
(=D>63ca228BC5TA7O0EfX3,?.;d5aWOU05[;,#0:GE<-DG-cQT&Gf&R8=P8af:#
3(H@_.^G:NKQ,^MA2Je:)HY8#6D]e.eQ\.._Vc8b#NM35/#FVK?_=0/CeUfA_e)T
_?(ZYL)CN+<GAX+<:_,+K757f/4D@1a,Sa0\f3?UMG90OKT6Q.R=?TWIEe^,A70Q
TGWcaG0e7U[X:8&ea\<2;d4]L3HO>Z,&>2@Ydfg4[A[XHK0+JUfc-6A)O+#)U:dJ
?.[I3IMd@ccA2AAbGJLJ^Me8G8f#^K(Y8^W1-S4G?E7@gYI#c3F-e<0fP4ME#IKO
NH>e.[J[C3+U,-=ONA7B;;J6<bT:UG?N,d_2fO2-8VL/IMGPd?:Ng]+cU+D4XZ[>
4^,?\a9\RfPHb(1V[9d=Ta?2URK_5F>O912Z3?&LDC]c5YG-Ye7Q@>4\@HFFZ5c1
SCGMc\]PcYLBcZ7fU1S5TQIZOA<Sec6)Q9P4M0>Fa@Y1>Ae(::]UHAQ+7dgZ;SM,
F9DY/<cUd3ge?771A0P?3GUMAdaNMCgNE)R^8_T1Y>^=MRHBRLWg0QNd2eL<FZgJ
&YAMc_5WebdT&1bL)1JYgC\>aL8UARO3Sc6MF2+\MM\_a\RQC>G4RfEU+URBOa/c
YK9;bR#/;R#9#4LR#:g0?Lc?RIG;,;D#6NF?8abC5#J,#+fAfNPV(NUA\BaLIFHO
]0RE-Ode?VT0RMMM[&DHS^Fd)8c^12c(+M[f,fI1R[&IZ[A5GgJ79F^b^_8H++?A
5g7;ME>PUU<9f+).YW(?-9;++c@[;_gF+70D3)Wc5J8SfNB:E)MS\NU&-<M)1I=W
Z:C,FP.1VAV6S3IO/E<IS9:R)/a\Z_B^WI9Y3DbLN?f^6:IL;SO:E&MPA_VfJ@RZ
Q=>@0642^N1\<IR-3P_VBLNN1\0T1QELc.DDI9d3BNY&6O37M_K<1I_TL1=)?]a)
8BXLU,,O[Z1CM?I9X^R8#^PP1]X32N3[,6P6=e.5@4MHXMSe+X9D_OJ&9[9d14PI
[KdN&<[;Wa_<S(QH=G)Y\MPZNR(_KZ]^2C7gW28MgUU+]P-PDVEW\+ZM[IB@2A)]
\[7+J^6R3J@fWd1DgCH@#=U4SS>PBYF?AdP1[7SS_HPa27C#<RBJGIaBXC5L(:OH
;ZdJ_;G[<OfUeP17HOgI0+X^J):)2P-]Z7#PWeZ032WGdJRc>L]P6bO_Dd#A16O1
9Y-UF<62bJc1^C7M1VE8c/.?TGgHAU4:0M0WREOf\W1WaB/+=I02-82SLQ#G=f_M
39F]f=e#):+?H,ZO]N<T),U_@baRH-.._(6M4T<3M874,dX4RS1ZJM#;TbVTSID+
e4[+;YR(\JL(Id@LI@Jb[9+5+G./E6AG>>KV_SHUX,dGTSIJ:eZ;)d\D&5-8.A\B
?Z.0f;K>ZA.N/9)=KVQ.Ac201A=Ce#D8E65NIUWXS=4@>0<aTT5WEfW?e[&CK_+H
2MA30W:eg8>KULg\.0P;RYGfJ_A2dU-2WIdg@?=dKG>8d4RcS98^g41E,&^3Ha0#
OI?2+<G0-Sa-EWcd^g55\B.[CB9-H@KD/&J/C5=Q&3H5TT5=SUQ#5_B-gg)4BLP8
0GIO8VF)8@HB+?[e.gUVZH[E]7/6CAEV]bF_#IQT]+??ZcACa@bBBHBNdN,6:X;/
U-E;[1<d/_]1.3F)8))U/R3bK&Q[/beZCS/^4ab(R=241=-O_@\&/M2T8N6Lc?=G
RM<#=S?<C,.6Qa>F;e-)\aXX:CB:KfaQBdePGA5g1Cf.a=[R/3&?W>I:3C2_8d/T
O1.I,=C9@+A5S&5QG9;^;E0+F^B[fJEOK9_JPc_4LBMIQ+1bbg],Z(M4)LE<cE37
J^K77d9=^H+N#NF?0P<FfJ=J]+P8T?07O]R&>FM5Y5E8ObYF5AG(GRQF0#\(3/+R
b<d[Q.:I-7_BEb]\S<#WH^QX+-<b&#YTJ5NYcK>J?ADQG>#We/a-^A99]DeSFO<M
g:5ZE\g_4BN877gX@@K4,G?5QC8U3f>-Xb_;5ENPTea<MWT2J@C=50@OO/T)-6F\
^5Zbd3N@+HE>-NTd5BNe)?Y/+F=U3:_C&^HSaF;VL_7=X3O(38?IYeG?H/^GWY_&
aVD:33R4Lcd\+cSXbFP]&d-L<M+aK\E1<=6^[R.(V[1+)0O_,=#c_S&EBESL>Z9e
H1TH10H;cN9K)C5>6WIV2AO=dO81J2J1(da9DFXWg1XgXcUeK6IIN<4<>]ITI@-X
U.])J,JY,>3H1875N9(;T:g5?1H)QWXCPReII&Qa=6Cf/#4c.,Z6G?[JRM?a46EW
g@#f<#3O@\4^5N5^\J2BJb3&2?QC;/DGbaL\#_+9&GNSOS^WLW&1Qe#C;g^U1f,:
F:a@HE:KZ8I<[E75c)Y_<eV2;/QNY_bEE6:eW<CL=/;WAC5;S)3=<NVbOD4A3b9;
A/KQ-C\.)NP1U;-S6NB8Ia&-H-bRJdKWFA-H4+;#E70\:U,JG:1R[8(M>V6Ua+M7
3dS/OS3NV\TYeZR[Hf=0\PASe:LQYgP+_EH3c,EWf9<]/6X=@D/WNFKNHN8GA7V>
Ve_X)KB=<HBgBY1CR.\UUdGQ@DV#f6/[WYQR<(-]<8[:g,6\CEe5DN.b/1NYg<&M
-.K#7D1GH0)aN,AOY6C80LcR3-_NJC(M_54PdTMI#Pe]g20<?bQF+D#&3RYC492=
V=^O/<QL3[HbB##-R&B([]g[&1fMb=K5cND6Qd(1JZ5Ia)-:Bb1C#5E@.A\[ZS3M
)7QE.E-UWK5N1;H#D(61G-77c#fg&La3?FZ579X(E@66;W\f4I2<<7JT/1eG<#CW
=I]<DOKI3]/#a+F09MWB2:8=2#XR13,5^B^TEJMGSMd+KaFY_HQP<R@c#-?1S:YW
?(4C05ZF(BF5=?Z;V@ME1X_]JSMd8a^XgK)+L)7YU:fb]-OV_-bbPNM>a]NB08KY
LH?NB_7cIHPc1ASK-]R4?XG:Y5BI_2X\Qa?VF^BLcYP.ddUa8BVZYCaa<[G/J2;3
_1b??Ff-RSCX8\\EIDb=IX^&=?,e-d,,BZIPB89UZJP237P-</f]G)^2cAC&,PN9
M&YG->R1<TBWE1XPD9S#2Q?JEGGL7WS5UC[US]Yb_T_e8;),#d#^5.\[&02JA?TL
+-1SMAIY3I[b=OQ5+:)1P>8E.M>a4S-7NbR98K1?/89/)J6DJB<L&P1>,5LI37O[
-J)PM/TD;fT1DG<JEbRcdRJ1c+((KH8cTd4U^Sbd:)VLBd>DQA0<5,VbK5Sg8,6@
9-I/Y(4,bRaH<YF,4Jg:gg?V6#.A-5&V5APHT>,OPWDQ;\//I.0LUM@A5VY\)d@g
;(ga>_+QgeL&1\a?.EPLb<TW3<RLXXNJ1IK@7.@^D@[9/.MCfF&3]ee0,b1c5O^C
KLW8YXLX52NT,>R,;OD9[RI9X#CMBSSX]V[HCS1E.cgY24RW7=IeOWBM<_Yg1e@e
=2R0TF<eAY^WC;QGYQAW?D[ZP,/fJ1,\-1:d_=6@Y3RB;TC@[eRUCG(O#JYXeZXL
>IFSf#^8@H@/7<(UCdLFI4]N9>3N&B@AB(ec\,23d8^SZVX8GA?Y=7,dIVe)3-@Q
B?T9a&E[;#E,^]UaTS7P@4dUb]a&4B1E,<E^_,#-_PKe1W2NG_2VNROCI5?BJF2Y
V,D&>>)K@aF->/,V<ER04)H/a04KfP5F=cYF#Mg>NCUJP3YD;U3:9^XI29Nf]>Q7
b7GC;f&JVP2(WV3@F8XJ9e6b62YN:6I24(4J<=NCWJGPWgV_;Q+(U]2G:7H24]\E
X,;TGP5_FUV97[B3,Fe49GGGE7Q39<-.INJOL<PDf2V6g9^d,]2d4K>^e)Cd)X^Q
4+DME;:XRT8BWg<V-gKX0cM]Y7[d))VS_;F@cDc=C<1b(BZaN8L2C4AWETNNAA[R
;?/Q:@a-BZ)#e.@>-M,QICU)Ha=SH\MYWH=-(WX,=gN;c8Wg].GS\<6BM_72L\&G
-aU\8:,\UN-)I&^73C:M,WX@Y2UN>cd.Bf/Za4Agc5YgZ,C[E0K(5ZPQa+S#7T8Z
.@H7?J2URY+=K2.#A+0W],KUA.WBf0L/B.KT@IZS?98VO8b7+^Oe/.765GIG3Ua0
-D=74UDAgL,Teg1L9aZF[J?&)MJ.XFW^#<(=Wg/(J4Q]MH9UA+N_45Ab1Y>2Df:8
&-1)3b8\]>J,,aF.GL#a&2f^VW3&[&2[gXa2SW.@EbVV^R[<d,V71N]eIY9<=&aH
DH&gY4/f8[Qa>X8L@LCI2DEa8BGFE[R_=_G?G]geeTAKG(6)MTb+VJURF2Q857Re
cRZ7H=(G5B+QNL0T^4?+6XLG4#I[):cNQWH5@e/?>FO2@e/0J/J=@NVP(dOEM/.-
E/#[P(d+CEbC@<dSYaA4]gbNaXX<B(TSde345><5:g6W=d.P#2B0U0Jgg5_(&),E
&UWgMYKRM9W=VEQ2+112WeFRXM@#/COBCAdbR_,Ze:Td0;W;--6FI/#=9;BW8#^U
TV))\?B@25,G)BM_dfC>?J+(bS.(:>T/62T5?N&[;_CO)Cb\KO3J4^&gYCT(48U]
fN-8?A9S4O;?SU3Y]BbTMI42GBZD1B.0Rgd5#X4#4DH-:HJ)ZQ0ScI<+.>A9BKG^
KU(J6:8K<U.&fMGI^MKKJ)MOc@aUg/ZVG-45;E)1-XL^-4?>8))G7b8)W:IfWN+f
][JZ1_YJLOU,V@&GPNc5R=/-aLFXgR2-(^Fd5>FM9;GHN;caE6a(_]<g7@MeL#?Y
I#]KB9aMK:V6b_GR@?^HHK4&VK55J>Y?c\>cFQ32A4+P39HAZc5T>RI2-&[]+]]D
_55/?Xg^PM5_3:\Ma^-?fgH+^&#GFLZ+=$
`endprotected
endmodule