module gw_gao(
    duty,
    \rotateState[2] ,
    \rotateState[1] ,
    \rotateState[0] ,
    HIN_R,
    HIN_S,
    HIN_T,
    CS,
    DIN,
    DOUT,
    \processCounter[5] ,
    \processCounter[4] ,
    \processCounter[3] ,
    \processCounter[2] ,
    \processCounter[1] ,
    \processCounter[0] ,
    isRotate,
    controlCLK,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input duty;
input \rotateState[2] ;
input \rotateState[1] ;
input \rotateState[0] ;
input HIN_R;
input HIN_S;
input HIN_T;
input CS;
input DIN;
input DOUT;
input \processCounter[5] ;
input \processCounter[4] ;
input \processCounter[3] ;
input \processCounter[2] ;
input \processCounter[1] ;
input \processCounter[0] ;
input isRotate;
input controlCLK;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire duty;
wire \rotateState[2] ;
wire \rotateState[1] ;
wire \rotateState[0] ;
wire HIN_R;
wire HIN_S;
wire HIN_T;
wire CS;
wire DIN;
wire DOUT;
wire \processCounter[5] ;
wire \processCounter[4] ;
wire \processCounter[3] ;
wire \processCounter[2] ;
wire \processCounter[1] ;
wire \processCounter[0] ;
wire isRotate;
wire controlCLK;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({duty,\rotateState[2] ,\rotateState[1] ,\rotateState[0] ,HIN_R,HIN_S,HIN_T,CS,DIN,DOUT,\processCounter[5] ,\processCounter[4] ,\processCounter[3] ,\processCounter[2] ,\processCounter[1] ,\processCounter[0] ,isRotate}),
    .clk_i(controlCLK)
);

endmodule
