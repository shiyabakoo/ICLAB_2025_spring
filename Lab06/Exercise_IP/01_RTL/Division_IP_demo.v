//###############################################################################################
//***********************************************************************************************
//    File Name   : Division_IP_demo.v
//    Module Name : Division_IP_demo
//***********************************************************************************************
//###############################################################################################


//synopsys translate_off   
`include "Division_IP.v"
//synopsys translate_on

module Division_IP_demo #(parameter IP_WIDTH = 7)(
	//Input signals
	IN_Dividend, IN_Divisor,
	//Output signals
	OUT_Quotient 
);

// ======================================================
// Input & Output Declaration
// ======================================================
input [IP_WIDTH*4-1:0]  IN_Dividend;
input [IP_WIDTH*4-1:0]  IN_Divisor;

output logic [IP_WIDTH*4-1:0] OUT_Quotient;

// ======================================================
// Soft IP
// ======================================================
Division_IP #(.IP_WIDTH(IP_WIDTH)) I_Division_IP(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient)); 

endmodule