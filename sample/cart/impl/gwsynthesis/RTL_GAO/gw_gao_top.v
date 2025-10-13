module gw_gao(
    \rotateState[2] ,
    \rotateState[1] ,
    \rotateState[0] ,
    \HSCounter[9] ,
    \HSCounter[8] ,
    \HSCounter[7] ,
    \HSCounter[6] ,
    \HSCounter[5] ,
    \HSCounter[4] ,
    \HSCounter[3] ,
    \HSCounter[2] ,
    \HSCounter[1] ,
    \HSCounter[0] ,
    \HS[2] ,
    \HS[1] ,
    \HS[0] ,
    \drive_mode[2] ,
    \drive_mode[1] ,
    \drive_mode[0] ,
    \oldCounter_per_cycle[15] ,
    \oldCounter_per_cycle[14] ,
    \oldCounter_per_cycle[13] ,
    \oldCounter_per_cycle[12] ,
    \oldCounter_per_cycle[11] ,
    \oldCounter_per_cycle[10] ,
    \oldCounter_per_cycle[9] ,
    \oldCounter_per_cycle[8] ,
    \oldCounter_per_cycle[7] ,
    \oldCounter_per_cycle[6] ,
    \oldCounter_per_cycle[5] ,
    \oldCounter_per_cycle[4] ,
    \oldCounter_per_cycle[3] ,
    \oldCounter_per_cycle[2] ,
    \oldCounter_per_cycle[1] ,
    \oldCounter_per_cycle[0] ,
    \counter_per_cycle[15] ,
    \counter_per_cycle[14] ,
    \counter_per_cycle[13] ,
    \counter_per_cycle[12] ,
    \counter_per_cycle[11] ,
    \counter_per_cycle[10] ,
    \counter_per_cycle[9] ,
    \counter_per_cycle[8] ,
    \counter_per_cycle[7] ,
    \counter_per_cycle[6] ,
    \counter_per_cycle[5] ,
    \counter_per_cycle[4] ,
    \counter_per_cycle[3] ,
    \counter_per_cycle[2] ,
    \counter_per_cycle[1] ,
    \counter_per_cycle[0] ,
    \delayAngleCounter[15] ,
    \delayAngleCounter[14] ,
    \delayAngleCounter[13] ,
    \delayAngleCounter[12] ,
    \delayAngleCounter[11] ,
    \delayAngleCounter[10] ,
    \delayAngleCounter[9] ,
    \delayAngleCounter[8] ,
    \delayAngleCounter[7] ,
    \delayAngleCounter[6] ,
    \delayAngleCounter[5] ,
    \delayAngleCounter[4] ,
    \delayAngleCounter[3] ,
    \delayAngleCounter[2] ,
    \delayAngleCounter[1] ,
    \delayAngleCounter[0] ,
    controlCLK,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \rotateState[2] ;
input \rotateState[1] ;
input \rotateState[0] ;
input \HSCounter[9] ;
input \HSCounter[8] ;
input \HSCounter[7] ;
input \HSCounter[6] ;
input \HSCounter[5] ;
input \HSCounter[4] ;
input \HSCounter[3] ;
input \HSCounter[2] ;
input \HSCounter[1] ;
input \HSCounter[0] ;
input \HS[2] ;
input \HS[1] ;
input \HS[0] ;
input \drive_mode[2] ;
input \drive_mode[1] ;
input \drive_mode[0] ;
input \oldCounter_per_cycle[15] ;
input \oldCounter_per_cycle[14] ;
input \oldCounter_per_cycle[13] ;
input \oldCounter_per_cycle[12] ;
input \oldCounter_per_cycle[11] ;
input \oldCounter_per_cycle[10] ;
input \oldCounter_per_cycle[9] ;
input \oldCounter_per_cycle[8] ;
input \oldCounter_per_cycle[7] ;
input \oldCounter_per_cycle[6] ;
input \oldCounter_per_cycle[5] ;
input \oldCounter_per_cycle[4] ;
input \oldCounter_per_cycle[3] ;
input \oldCounter_per_cycle[2] ;
input \oldCounter_per_cycle[1] ;
input \oldCounter_per_cycle[0] ;
input \counter_per_cycle[15] ;
input \counter_per_cycle[14] ;
input \counter_per_cycle[13] ;
input \counter_per_cycle[12] ;
input \counter_per_cycle[11] ;
input \counter_per_cycle[10] ;
input \counter_per_cycle[9] ;
input \counter_per_cycle[8] ;
input \counter_per_cycle[7] ;
input \counter_per_cycle[6] ;
input \counter_per_cycle[5] ;
input \counter_per_cycle[4] ;
input \counter_per_cycle[3] ;
input \counter_per_cycle[2] ;
input \counter_per_cycle[1] ;
input \counter_per_cycle[0] ;
input \delayAngleCounter[15] ;
input \delayAngleCounter[14] ;
input \delayAngleCounter[13] ;
input \delayAngleCounter[12] ;
input \delayAngleCounter[11] ;
input \delayAngleCounter[10] ;
input \delayAngleCounter[9] ;
input \delayAngleCounter[8] ;
input \delayAngleCounter[7] ;
input \delayAngleCounter[6] ;
input \delayAngleCounter[5] ;
input \delayAngleCounter[4] ;
input \delayAngleCounter[3] ;
input \delayAngleCounter[2] ;
input \delayAngleCounter[1] ;
input \delayAngleCounter[0] ;
input controlCLK;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \rotateState[2] ;
wire \rotateState[1] ;
wire \rotateState[0] ;
wire \HSCounter[9] ;
wire \HSCounter[8] ;
wire \HSCounter[7] ;
wire \HSCounter[6] ;
wire \HSCounter[5] ;
wire \HSCounter[4] ;
wire \HSCounter[3] ;
wire \HSCounter[2] ;
wire \HSCounter[1] ;
wire \HSCounter[0] ;
wire \HS[2] ;
wire \HS[1] ;
wire \HS[0] ;
wire \drive_mode[2] ;
wire \drive_mode[1] ;
wire \drive_mode[0] ;
wire \oldCounter_per_cycle[15] ;
wire \oldCounter_per_cycle[14] ;
wire \oldCounter_per_cycle[13] ;
wire \oldCounter_per_cycle[12] ;
wire \oldCounter_per_cycle[11] ;
wire \oldCounter_per_cycle[10] ;
wire \oldCounter_per_cycle[9] ;
wire \oldCounter_per_cycle[8] ;
wire \oldCounter_per_cycle[7] ;
wire \oldCounter_per_cycle[6] ;
wire \oldCounter_per_cycle[5] ;
wire \oldCounter_per_cycle[4] ;
wire \oldCounter_per_cycle[3] ;
wire \oldCounter_per_cycle[2] ;
wire \oldCounter_per_cycle[1] ;
wire \oldCounter_per_cycle[0] ;
wire \counter_per_cycle[15] ;
wire \counter_per_cycle[14] ;
wire \counter_per_cycle[13] ;
wire \counter_per_cycle[12] ;
wire \counter_per_cycle[11] ;
wire \counter_per_cycle[10] ;
wire \counter_per_cycle[9] ;
wire \counter_per_cycle[8] ;
wire \counter_per_cycle[7] ;
wire \counter_per_cycle[6] ;
wire \counter_per_cycle[5] ;
wire \counter_per_cycle[4] ;
wire \counter_per_cycle[3] ;
wire \counter_per_cycle[2] ;
wire \counter_per_cycle[1] ;
wire \counter_per_cycle[0] ;
wire \delayAngleCounter[15] ;
wire \delayAngleCounter[14] ;
wire \delayAngleCounter[13] ;
wire \delayAngleCounter[12] ;
wire \delayAngleCounter[11] ;
wire \delayAngleCounter[10] ;
wire \delayAngleCounter[9] ;
wire \delayAngleCounter[8] ;
wire \delayAngleCounter[7] ;
wire \delayAngleCounter[6] ;
wire \delayAngleCounter[5] ;
wire \delayAngleCounter[4] ;
wire \delayAngleCounter[3] ;
wire \delayAngleCounter[2] ;
wire \delayAngleCounter[1] ;
wire \delayAngleCounter[0] ;
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
    .data_i({\rotateState[2] ,\rotateState[1] ,\rotateState[0] ,\HSCounter[9] ,\HSCounter[8] ,\HSCounter[7] ,\HSCounter[6] ,\HSCounter[5] ,\HSCounter[4] ,\HSCounter[3] ,\HSCounter[2] ,\HSCounter[1] ,\HSCounter[0] ,\HS[2] ,\HS[1] ,\HS[0] ,\drive_mode[2] ,\drive_mode[1] ,\drive_mode[0] ,\oldCounter_per_cycle[15] ,\oldCounter_per_cycle[14] ,\oldCounter_per_cycle[13] ,\oldCounter_per_cycle[12] ,\oldCounter_per_cycle[11] ,\oldCounter_per_cycle[10] ,\oldCounter_per_cycle[9] ,\oldCounter_per_cycle[8] ,\oldCounter_per_cycle[7] ,\oldCounter_per_cycle[6] ,\oldCounter_per_cycle[5] ,\oldCounter_per_cycle[4] ,\oldCounter_per_cycle[3] ,\oldCounter_per_cycle[2] ,\oldCounter_per_cycle[1] ,\oldCounter_per_cycle[0] ,\counter_per_cycle[15] ,\counter_per_cycle[14] ,\counter_per_cycle[13] ,\counter_per_cycle[12] ,\counter_per_cycle[11] ,\counter_per_cycle[10] ,\counter_per_cycle[9] ,\counter_per_cycle[8] ,\counter_per_cycle[7] ,\counter_per_cycle[6] ,\counter_per_cycle[5] ,\counter_per_cycle[4] ,\counter_per_cycle[3] ,\counter_per_cycle[2] ,\counter_per_cycle[1] ,\counter_per_cycle[0] ,\delayAngleCounter[15] ,\delayAngleCounter[14] ,\delayAngleCounter[13] ,\delayAngleCounter[12] ,\delayAngleCounter[11] ,\delayAngleCounter[10] ,\delayAngleCounter[9] ,\delayAngleCounter[8] ,\delayAngleCounter[7] ,\delayAngleCounter[6] ,\delayAngleCounter[5] ,\delayAngleCounter[4] ,\delayAngleCounter[3] ,\delayAngleCounter[2] ,\delayAngleCounter[1] ,\delayAngleCounter[0] }),
    .clk_i(controlCLK)
);

endmodule
