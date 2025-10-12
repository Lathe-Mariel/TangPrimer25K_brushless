module gw_gao(
    \rotateState[2] ,
    \rotateState[1] ,
    \rotateState[0] ,
    HIN_R,
    HIN_S,
    HIN_T,
    \ele120_time[15] ,
    \ele120_time[14] ,
    \ele120_time[13] ,
    \ele120_time[12] ,
    \ele120_time[11] ,
    \ele120_time[10] ,
    \ele120_time[9] ,
    \ele120_time[8] ,
    \ele120_time[7] ,
    \ele120_time[6] ,
    \ele120_time[5] ,
    \ele120_time[4] ,
    \ele120_time[3] ,
    \ele120_time[2] ,
    \ele120_time[1] ,
    \ele120_time[0] ,
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
    controlCLK,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \rotateState[2] ;
input \rotateState[1] ;
input \rotateState[0] ;
input HIN_R;
input HIN_S;
input HIN_T;
input \ele120_time[15] ;
input \ele120_time[14] ;
input \ele120_time[13] ;
input \ele120_time[12] ;
input \ele120_time[11] ;
input \ele120_time[10] ;
input \ele120_time[9] ;
input \ele120_time[8] ;
input \ele120_time[7] ;
input \ele120_time[6] ;
input \ele120_time[5] ;
input \ele120_time[4] ;
input \ele120_time[3] ;
input \ele120_time[2] ;
input \ele120_time[1] ;
input \ele120_time[0] ;
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
input controlCLK;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \rotateState[2] ;
wire \rotateState[1] ;
wire \rotateState[0] ;
wire HIN_R;
wire HIN_S;
wire HIN_T;
wire \ele120_time[15] ;
wire \ele120_time[14] ;
wire \ele120_time[13] ;
wire \ele120_time[12] ;
wire \ele120_time[11] ;
wire \ele120_time[10] ;
wire \ele120_time[9] ;
wire \ele120_time[8] ;
wire \ele120_time[7] ;
wire \ele120_time[6] ;
wire \ele120_time[5] ;
wire \ele120_time[4] ;
wire \ele120_time[3] ;
wire \ele120_time[2] ;
wire \ele120_time[1] ;
wire \ele120_time[0] ;
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
    .data_i({\rotateState[2] ,\rotateState[1] ,\rotateState[0] ,HIN_R,HIN_S,HIN_T,\ele120_time[15] ,\ele120_time[14] ,\ele120_time[13] ,\ele120_time[12] ,\ele120_time[11] ,\ele120_time[10] ,\ele120_time[9] ,\ele120_time[8] ,\ele120_time[7] ,\ele120_time[6] ,\ele120_time[5] ,\ele120_time[4] ,\ele120_time[3] ,\ele120_time[2] ,\ele120_time[1] ,\ele120_time[0] ,\HSCounter[9] ,\HSCounter[8] ,\HSCounter[7] ,\HSCounter[6] ,\HSCounter[5] ,\HSCounter[4] ,\HSCounter[3] ,\HSCounter[2] ,\HSCounter[1] ,\HSCounter[0] ,\HS[2] ,\HS[1] ,\HS[0] ,\drive_mode[2] ,\drive_mode[1] ,\drive_mode[0] }),
    .clk_i(controlCLK)
);

endmodule
