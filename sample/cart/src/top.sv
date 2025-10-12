`default_nettype none

module top (
  input  wire       clk,

  input wire[1:0] tacSW,     // tac SW1-2
  input wire[2:0] toggleSW,  //toggle SW 1-3
  input wire direction,
  input  wire[2:0] HS,       //HallSensor
  output wire AD_CLK,        // for MCP3008(ADC)
  output logic CS,           // for MCP3008
  output logic DIN,          //for MCP3008
  input reg DOUT,            //for MCP3008
  output logic HIN_R,        // Upper arm
  output logic HIN_S,
  output logic HIN_T,
  output logic _LIN_R,       //Lower arm
  output logic _LIN_S,
  output logic _LIN_T,
  output logic CAN_LED0,
  output logic CAN_LED1,
  output logic s,            //CAN Mode Select
  output logic txd,          //CAN データ送信線
  input wire rxd,            //CAN データ受信線
  output logic led_g,
  output logic led_y,
  output logic CAN_WS
);

  localparam CLK_FREQ_HZ    = 50_000_000;         // 入力クロック周波数
  localparam CAN_BITRATE_HZ = 500_000;            // CAN のビットレート
  localparam SLEEP_CYCLE    = CLK_FREQ_HZ / 100;  // データ送信後、スリープするcycle 数
  localparam ID_ENGINE_REV  = 11'h3D9;            // の送信ID
  localparam ID_CAR_SPEED   = 11'h3E9;            // モータ回転数の送信ID

  // Pmod CAN制御用，Normal mode に固定
  assign s = 1'b0;

  assign led_g = HS[0];
  assign led_y = ele120_time[7];

  // モジュール間の接続に使用する変数
  wire status_warning;
  wire status_bus_off;
  logic [13:0] engine_rev;           // Motor revolution
  logic [8:0]  vehicle_speed;        // Motor current
  logic [7:0]  battery_value;        // Battery
  wire [63:0] stm_send_data_tdata;
  wire [10:0] stm_send_data_tid;
  wire [7:0]  stm_send_data_tkeep;
  wire        stm_send_data_tvalid;
  wire        stm_send_data_tready;
  wire [2:0]  stm_result_tdata;
  wire        stm_result_tvalid;
  wire        stm_result_tready;

  logic       controlCLK;
  logic       rotateCLK;
  logic[10:0] forcedRotationCounter;  //強制転流用インターバルカウンタ
  logic[2:0]  rotateState;            // 120°矩形波のmode
  logic duty;                         // current duty state
  logic[5:0]  dutyCounter;            // for duty control(relate to accel)
  logic _LR;                          // tmp value for lower arm value
  logic _LS;
  logic _LT;
  logic[15:0] processCounter;         // general counter 
  logic[9:0]  HSCounter;              // measurement hall sensor pulse
  logic[15:0]  OldprocessCounter;
  logic[15:0]  ele120_time;
  logic       isRotate;               // for control forcedRotation
  logic[2:0]  oldHS;                  // old Hall Sensor value

  logic[2:0]  drive_mode;                   // BLDC drive mode

  logic[1:0]  tacSWpushed;            // flag for tac_SW1-4

  logic[9:0]  recieveADC;             // adc data from MCP3008
  logic[9:0]  accel;                  // accel value, that is transformed from recieveADC

  logic[9:0]  analog_scan[8];         // storing adc(MCP3008, 10bits) values

  logic[11:0] dutyList[8]={'d1400, 'd1000, 'd800, 'd700, 'd620, 'd560, 'd520, 'd500};  //ドレミファインバータ風
  logic[2:0]  dutyPara;  //ドレミファインバータ制御用インデックス


///////// エンジン回転数と車速を送信するモジュール /////////
  vehicle_data_generator #(
    .SLEEP_CYCLE(SLEEP_CYCLE),
    .ID_ENGINE_REV(ID_ENGINE_REV),
    .ID_CAR_SPEED(ID_CAR_SPEED)
  ) vehicle_data_generator_i (
    .stm_send_data_out_tdata (stm_send_data_tdata),
    .stm_send_data_out_tid   (stm_send_data_tid),
    .stm_send_data_out_tkeep (stm_send_data_tkeep),
    .stm_send_data_out_tvalid(stm_send_data_tvalid),
    .stm_send_data_out_tready(stm_send_data_tready),
    .stm_result_in_tdata     (stm_result_tdata),
    .stm_result_in_tvalid    (stm_result_tvalid),
    .stm_result_in_tready    (stm_result_tready),
    .*
  );

  ///////// CAN コントローラ /////////
  can_controller #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .CAN_BITRATE_HZ(CAN_BITRATE_HZ)
  ) can_controller_i (
    .stm_send_data_in_tdata (stm_send_data_tdata),
    .stm_send_data_in_tid   (stm_send_data_tid),
    .stm_send_data_in_tkeep (stm_send_data_tkeep),
    .stm_send_data_in_tvalid(stm_send_data_tvalid),
    .stm_send_data_in_tready(stm_send_data_tready),
    .stm_result_out_tdata   (stm_result_tdata),
    .stm_result_out_tvalid  (stm_result_tvalid),
    .stm_result_out_tready  (stm_result_tready),
    .*
  );


  always @(posedge controlCLK)begin

// forced rotation
    if(isRotate == 0)begin
      if(forcedRotationCounter == 0)begin
        rotateState <= (rotateState + 1) % 6;
      end
      forcedRotationCounter <= forcedRotationCounter + 1;
    end else begin

// rotation by hall sensor
      if(toggleSW[0])begin     //CW  //direction
        case(drive_mode)
          3'd1: rotateState = 3'd4;
          3'd2: rotateState = 3'd0;
          3'd3: rotateState = 3'd5;
          3'd4: rotateState = 3'd2;
          3'd5: rotateState = 3'd3;
          3'd6: rotateState = 3'd1;
        endcase
      end else begin         //CCW
        case(drive_mode)
          3'd1: rotateState = 3'd1;
          3'd2: rotateState = 3'd3;
          3'd3: rotateState = 3'd2;
          3'd4: rotateState = 3'd5;
          3'd5: rotateState = 3'd0;
          3'd6: rotateState = 3'd4;
        endcase
      end
    end

    processCounter <= processCounter + 1;

// check sw //change something to display
    if(processCounter % 4096 == 0)begin
      if(HSCounter > 84)begin
        dutyPara <= 'd7;
      end else if(HSCounter > 68)begin
        dutyPara <= 'd6;
      end else if(HSCounter > 54)begin
        dutyPara <= 'd5;
      end else if(HSCounter > 40)begin
        dutyPara <= 'd4;
      end else if(HSCounter > 28)begin
        dutyPara <= 'd3;
      end else if(HSCounter > 18)begin
        dutyPara <= 'd2;
      end else if(HSCounter > 10)begin
        dutyPara <= 'd1;
      end else begin
        dutyPara <= 'd0;
      end

      engine_rev <= HSCounter * 10'd3;
      HSCounter <= 0;

// measure speed
      if(HSCounter > 0)begin
        isRotate <= 'b1;
      end else begin
        isRotate <= 'b0;
        forcedRotationCounter <= 0;
      end

// counter changing HS value
// advancing electric angle 
    end else begin  // when(processCounter % 2048 != 0)
      if(oldHS != HS)begin
        HSCounter <= HSCounter + 1;
        oldHS <= HS;
//        drive_mode <= HS;
        ele120_time <= (processCounter > OldprocessCounter)? (processCounter - OldprocessCounter): 16'hffff - OldprocessCounter + processCounter;
//        ele120_time <= (processCounter - OldprocessCounter);
        OldprocessCounter <= processCounter;
      end else begin
        HSCounter <= HSCounter;
        oldHS <= HS;
        ele120_time <= ele120_time - 16'd1;
        if(ele120_time < 16'd250)begin
          drive_mode <= HS; //change motor drive mode
        end
      end
    end

//ADC
    if(processCounter[4:0] == 5'd0)begin
      CS <= 0;
      DIN <= 0;
    end else if(processCounter[4:0] < 5'd8)begin
      CS <=0;
    end else if(processCounter[4:0] == 5'd8)begin   // START(always: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd9)begin   //SINGLE or DIFFERENTIAL(SGL: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd10)begin  // D2
//    DIN <= 1;
      DIN <= processCounter[5];
      CS <= 0;
    end else if(processCounter[4:0] == 5'd11)begin  // D1
//    DIN <= 0;
      DIN <= processCounter[6];
      CS <= 0;
    end else if(processCounter[4:0] == 5'd12)begin  // D0
//      DIN <= 1;
      DIN <= processCounter[7];
      CS <= 0;
    end else if(processCounter[4:0] < 5'd15)begin   // 0
      CS <= 0;
    end else if(processCounter[4:0] > 5'd14 && processCounter[4:0] < 25)begin  // recieve data
      recieveADC[24 - processCounter[4:0]] <= DOUT;
      DIN <= 0;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd25)begin
      analog_scan[processCounter[7:5]] <= recieveADC;
      DIN <= 0;
      CS <= 1;
    end else begin

//      vehicle_speed <= analog_scan[0] >> 2;            // for MCP3008 0ch(C7-28) 7ch(C10-28)
/*      if(analog_scan[7] < 'd750)begin
        vehicle_speed <= 'd0;
      end else begin
        vehicle_speed <= 'd0;
        //vehicle_speed <= (analog_scan[7] - 'd750) >> tacSW  ;  // for 
      end
*/
      if(analog_scan[5] < 'd280)begin
        vehicle_speed <= 0;
      end else begin
        vehicle_speed <= (analog_scan[5] - 'd280)  >> 1;  //Throttle power        
      end

      battery_value <= analog_scan[1] >> 3 ;         // for MCP3008 2ch(analog input)

      if(analog_scan[5] < 'd280)begin
        accel <= 'd0;
      end else if(analog_scan[5] > 'd780) begin
        accel <= 'd1000;
      end else begin
//        if(HSCounter < 5)begin  //soft start
//          accel <= (((analog_scan[5] - 'd280) * 2) < 100) ?(analog_scan[5] - 'd280) * 2 : 'd400;
//        end else if(HSCounter < 10)begin //soft start2
//          accel <= (((analog_scan[5] - 'd280) * 2) < 300) ?(analog_scan[5] - 'd280) * 2 : 'd500;
//        end else begin
          accel <= (analog_scan[5] - 'd280) * 2;  // for Mini Cart Accel     //origin 270 - 780
//        end
      end

      DIN <= 0;
      CS <= 1;
    end

  end

//120 square pulse drive
  always @(rotateState)begin
    if(toggleSW[2])begin
      case(rotateState)
        3'd0: begin HIN_R <= 1; _LR <= 1; HIN_S <= 0; _LS <= 0; HIN_T <= 0; _LT <= 1; end
        3'd1: begin HIN_R <= 1; _LR <= 1; HIN_S <= 0; _LS <= 1; HIN_T <= 0; _LT <= 0; end
        3'd2: begin HIN_R <= 0; _LR <= 1; HIN_S <= 1; _LS <= 1; HIN_T <= 0; _LT <= 0; end
        3'd3: begin HIN_R <= 0; _LR <= 0; HIN_S <= 1; _LS <= 1; HIN_T <= 0; _LT <= 1; end
        3'd4: begin HIN_R <= 0; _LR <= 0; HIN_S <= 0; _LS <= 1; HIN_T <= 1; _LT <= 1; end
        3'd5: begin HIN_R <= 0; _LR <= 1; HIN_S <= 0; _LS <= 0; HIN_T <= 1; _LT <= 1; end
      endcase
    end else begin
      HIN_R <= 0; _LR <= 1; HIN_S <= 0; _LS <= 1; HIN_T <= 0; _LT <= 1;
    end
  end

  assign AD_CLK = controlCLK;

//  assign CAN_LED0 = processCounter[11];
//  assign CAN_LED1 = ~processCounter[12];

  assign _LIN_R = ~(~_LR * duty);
  assign _LIN_S = ~(~_LS * duty);
  assign _LIN_T = ~(~_LT * duty);


// generate pulse
  parameter COUNT_MAX = 1350;  //100us for controllCLK

  logic [11:0] counter = 'd0;
  logic [11:0] counterB = 'd0;

  always_ff @(posedge clk) begin
    if(counter == COUNT_MAX)begin
      counter  <= 'd0;
    end else if (counter < COUNT_MAX/2) begin
      controlCLK <= 'd1;
      counter  <= counter + 'd1;
    end else begin
      counter  <= counter + 'd1;
      controlCLK <= 'd0;
    end

// duty control
    if(counterB == dutyList[dutyPara])begin
      if(dutyCounter < (accel/'d16))begin
        duty <= 'b1;
      end else begin
        duty <= 'b0;
      end
      dutyCounter <= dutyCounter + 'd1;
      counterB <= 'd0;
    end else begin
      counterB <= counterB + 'd1;
    end
  end

endmodule

`default_nettype wire
