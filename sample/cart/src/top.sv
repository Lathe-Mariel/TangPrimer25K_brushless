`default_nettype none

module top (
  input  wire       clk,

  input wire[1:0] tacSW,  // tac SW1-2
  input wire[2:0] toggleSW,  //toggle SW 1-3
  input wire direction,
  input  wire[2:0] HS,  //HallSensor
  output wire AD_CLK,  // for MCP3008(ADC)
  output logic CS,  // for MCP3008
  output logic DIN,  //for MCP3008
  input reg DOUT,  //for MCP3008
  output logic HIN_R,  // Upper arm
  output logic HIN_S,
  output logic HIN_T,
  output logic _LIN_R,  //Lower arm
  output logic _LIN_S,
  output logic _LIN_T,
  output logic CAN_LED0,
  output logic CAN_LED1,
  output logic CAN_S,
  output logic CAN_TX,
  input wire CAN_RX,
  output logic CAN_WS
);

  logic  controlCLK;
  logic rotateCLK;
  logic[10:0] forcedRotationCounter;  //強制転流用インターバルカウンタ
  logic[2:0]  rotateState;  // 120°矩形波のmode
  logic duty;  // current duty state
  logic[5:0] dutyCounter;  // for duty control(relate to accel)
  logic _LR;  // tmp value for lower arm value
  logic _LS;
  logic _LT;
  logic[15:0] processCounter;  // general counter 
  logic[9:0] HSCounter;  // measurement hall sensor pulse
  logic isRotate;  // for control forcedRotation
  logic[2:0] oldHS;  // old Hall Sensor value

  logic[1:0] tacSWpushed; // flag for tac_SW1-4

  logic[9:0] recieveADC;  // adc data from MCP3008
  logic[9:0] accel;  // accel value, that is transformed from recieveADC

  logic[11:0] dutyList[8]={'d1400, 'd1000, 'd800, 'd700, 'd620, 'd560, 'd520, 'd500};
  logic[2:0] dutyPara;

  always @(posedge controlCLK)begin

// forced rotation
    if(isRotate == 0)begin
      if(forcedRotationCounter == 0)begin
        rotateState <= (rotateState + 1) % 6;
      end
        forcedRotationCounter <= forcedRotationCounter + 1;
    end else begin

// rotation by hall sensor
      if(direction)begin   //CW
        case(HS)
          3'd1: rotateState = 3'd4;
          3'd2: rotateState = 3'd0;
          3'd3: rotateState = 3'd5;
          3'd4: rotateState = 3'd2;
          3'd5: rotateState = 3'd3;
          3'd6: rotateState = 3'd1;
        endcase
      end else begin         //CCW
        case(HS)
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
    if(processCounter % 2048 == 0)begin
      if(tacSW[1] != tacSWpushed[1] && tacSWpushed[1] == 1)begin
        dutyPara <= dutyPara + 'd1;
      end else begin
        if(HSCounter > 42)begin
          dutyPara <= 'd7;
        end else if(HSCounter > 34)begin
          dutyPara <= 'd6;
        end else if(HSCounter > 27)begin
          dutyPara <= 'd5;
        end else if(HSCounter > 20)begin
          dutyPara <= 'd4;
        end else if(HSCounter > 14)begin
          dutyPara <= 'd3;
        end else if(HSCounter > 9)begin
          dutyPara <= 'd2;
        end else if(HSCounter > 5)begin
          dutyPara <= 'd1;
        end else begin
          dutyPara <= 'd0;
        end

      end
      tacSWpushed[1] <= tacSW[1];

// measure speed

      if(HSCounter > 0)begin
        isRotate <= 'b1;
      end else begin
        isRotate <= 'b0;
      end
      HSCounter <= 0;
    end else begin
      if(oldHS != HS)begin
        HSCounter <= HSCounter + 1;
        oldHS <= HS;
      end
    end

//ADC
    if(processCounter[4:0] == 5'd0)begin
      CS <= 0;
      DIN <= 0;
    end else if(processCounter[4:0] < 5'd8)begin
      CS <=0;
    end else if(processCounter[4:0] == 5'd8)begin  // START(always: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd9)begin  //SINGLE or DIFFERENTIAL(SGL: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd10)begin  // D2
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd11)begin  // D1
      DIN <= 0;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd12)begin  // D0
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] < 5'd15)begin  // 0
      CS <= 0;
    end else if(processCounter[4:0] > 5'd14 && processCounter[4:0] < 25)begin  // recieve data
      recieveADC[24 - processCounter[4:0]] <= DOUT;
      DIN <= 0;
      CS <= 0;
    end else begin
      if(recieveADC < 'd280)begin
        accel <= 'd0;
      end else if(recieveADC > 'd780) begin
        accel <= 'd1000;
      end else begin
        accel <= (recieveADC - 'd280) * 2;  // for Mini Cart Accel     //origin 270 - 780  to 0 - 16
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

  assign CAN_LED0 = processCounter[11];
  assign CAN_LED1 = ~processCounter[12];

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
