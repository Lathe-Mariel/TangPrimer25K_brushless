`default_nettype none

// エンジン回転数と車速をシミュレーションするモジュール
module vehicle_simulator #(
  parameter CLK_FREQ_HZ = 50_000_000  // 入力クロック周波数
) (
  input  wire         clk,          // クロック入力
  output logic [13:0] engine_rev,   // エンジン回転数出力
  output logic [8:0]  vehicle_speed // 車速出力
);

  ///////// 1 ms タイマー /////////
  logic [31:0] timer = 'd0;
  wire signal_ms = (timer == CLK_FREQ_HZ / 1_000 - 1);
  always_ff @ (posedge clk) begin
    if (signal_ms) begin
      timer <= 'd0;
    end else begin
      timer <= timer + 'd1;
    end
  end

  ///////// ステートマシン /////////
  localparam STATE_IDLE = 0;
  localparam STATE_LAUNCH_CONTROL = 1;
  localparam STATE_CLUTCH_CONTROL = 2;
  localparam STATE_GEAR_1ST = 3;
  localparam STATE_GEAR_2ND = 4;
  localparam STATE_GEAR_3RD = 5;
  localparam STATE_GEAR_4TH = 6;
  localparam STATE_BRAKE = 7;
  localparam STATE_NUM = 8;
  logic [$clog2(STATE_NUM)-1:0] state = STATE_IDLE;
  logic [15:0] wait_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (signal_ms) begin
      case(state)
        STATE_IDLE: begin
          engine_rev <= 'd2000;
          vehicle_speed <= 'd0;
          if (wait_counter == 'd999) begin
            wait_counter <= 'd0;
            state <= STATE_LAUNCH_CONTROL;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_LAUNCH_CONTROL: begin
          engine_rev <= 'd6000;
          vehicle_speed <= 'd0;
          if (wait_counter == 'd999) begin
            wait_counter <= 'd0;
            state <= STATE_CLUTCH_CONTROL;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_CLUTCH_CONTROL: begin
          engine_rev <= 'd5000;
          if (vehicle_speed >= 'd50) begin
            wait_counter <= 'd0;
            state <= STATE_GEAR_1ST;
          end else if (wait_counter == 'd30) begin
            wait_counter <= 'd0;
            vehicle_speed <= vehicle_speed + 'd1;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_GEAR_1ST: begin
          if (engine_rev >= 'd7000) begin
            engine_rev <= 'd5000;
            wait_counter <= 'd0;
            state <= STATE_GEAR_2ND;
          end else if (wait_counter == 'd30) begin
            wait_counter <= 'd0;
            engine_rev <= engine_rev + 'd100;
            vehicle_speed <= vehicle_speed + 'd1;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_GEAR_2ND: begin
          if (engine_rev >= 'd7000) begin
            engine_rev <= 'd5000;
            wait_counter <= 'd0;
            state <= STATE_GEAR_3RD;
          end else if (wait_counter == 'd40) begin
            wait_counter <= 'd0;
            engine_rev <= engine_rev + 'd75;
            vehicle_speed <= vehicle_speed + 'd1;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_GEAR_3RD: begin
          if (engine_rev >= 'd7000) begin
            engine_rev <= 'd5000;
            wait_counter <= 'd0;
            state <= STATE_GEAR_4TH;
          end else if (wait_counter == 'd50) begin
            wait_counter <= 'd0;
            engine_rev <= engine_rev + 'd45;
            vehicle_speed <= vehicle_speed + 'd1;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_GEAR_4TH: begin
          if (engine_rev >= 'd7000) begin
            // engine_rev <= 'd5000;
            wait_counter <= 'd0;
            state <= STATE_BRAKE;
          end else if (wait_counter == 'd60) begin
            wait_counter <= 'd0;
            engine_rev <= engine_rev + 'd30;
            vehicle_speed <= vehicle_speed + 'd1;
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        STATE_BRAKE: begin
          if (vehicle_speed <= 'd0) begin
            wait_counter <= 'd0;
            state <= STATE_IDLE;
          end else if (wait_counter == 'd30) begin
            wait_counter <= 'd0;
            vehicle_speed <= vehicle_speed - 'd1;
            if (engine_rev > 'd2020) begin
              // engine_rev <= engine_rev - 'd20;
              engine_rev <= engine_rev - 'd30;
            end else begin
              engine_rev <= 'd2000;
            end
          end else begin
            wait_counter <= wait_counter + 'd1;
          end
        end
        default:
          state <= STATE_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
