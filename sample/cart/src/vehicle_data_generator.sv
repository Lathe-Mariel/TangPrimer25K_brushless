`default_nettype none

// エンジン回転数と車速を送信するモジュール
module vehicle_data_generator #(
  parameter SLEEP_CYCLE   = 50_000_000,       // データ送信後、スリープするcycle 数
  parameter ID_ENGINE_REV = 11'h3D9,          // エンジン回転数送信時のID
  parameter ID_CAR_SPEED  = 11'h3E9           // 車速送信時のID
) (
  input  wire clk,                            // クロック入力
  input  wire [13:0] engine_rev,              // エンジン回転数入力
  input  wire [8:0]  vehicle_speed,           // 車速入力
  input  wire [7:0]  battery_value,           // バッテリ残量
  // AXI4-Stream 出力
  output wire [63:0] stm_send_data_out_tdata, // 送信データ
  output wire [10:0] stm_send_data_out_tid,   // 送信ID
  output wire [7:0]  stm_send_data_out_tkeep, // 送信データのサイズを指定
  output wire        stm_send_data_out_tvalid,
  input  wire        stm_send_data_out_tready,
  // AXI4-Stream 入力
  input  wire [2:0]  stm_result_in_tdata,     // 送信結果:
                                              // {アービトレーション負けの有無,
                                              //  ACK チェックエラーの有無,
                                              //  ビットモニタリングエラーの有無}
  input  wire        stm_result_in_tvalid,
  output wire        stm_result_in_tready
);

  // 入出力との接続
  assign stm_send_data_out_tdata = (state == STATE_SEND_ENGINE_REV)? {8'd0, 8'd0, engine_rev, 2'd0, 32'd0}:
                                   (state == STATE_SEND_CAR_SPEED)?  {vehicle_speed, 7'd0, 48'd0}:
                                                                     'd0;
  assign stm_send_data_out_tid = (state == STATE_SEND_ENGINE_REV)? ID_ENGINE_REV:
                                 (state == STATE_SEND_CAR_SPEED)?  ID_CAR_SPEED:
                                                                   'd0;
  assign stm_send_data_out_tkeep = 8'b11111111;
  assign stm_send_data_out_tvalid = ((state == STATE_SEND_ENGINE_REV) | (state == STATE_SEND_CAR_SPEED));
  assign stm_result_in_tready = ((state == STATE_RESULT_ENGINE_REV) | (state == STATE_RESULT_CAR_SPEED));

  ///////// ステートマシン /////////
  localparam STATE_SEND_ENGINE_REV = 0;
  localparam STATE_RESULT_ENGINE_REV = 1;
  localparam STATE_SEND_CAR_SPEED = 2;
  localparam STATE_RESULT_CAR_SPEED = 3;
  localparam STATE_SLEEP = 4;
  localparam STATE_NUM = 5;
  logic [$clog2(STATE_NUM)-1:0] state = STATE_SEND_ENGINE_REV;
  logic [$clog2(SLEEP_CYCLE)-1:0] sleep_counter = 'd0;
  always_ff @ (posedge clk) begin
    case(state)
      STATE_SEND_ENGINE_REV: begin    // エンジン回転数をAXI4-Stream に出力するステート
        if (stm_send_data_out_tvalid & stm_send_data_out_tready) begin
          state <= STATE_RESULT_ENGINE_REV;
        end
      end
      STATE_RESULT_ENGINE_REV: begin  // エンジン回転数の送信結果をAXI4-Stream から受信するステート
        if (stm_result_in_tvalid & stm_result_in_tready) begin
          state <= STATE_SEND_CAR_SPEED;
        end
      end
      STATE_SEND_CAR_SPEED: begin     // 車速をAXI4-Stream に出力するステート
        if (stm_send_data_out_tvalid & stm_send_data_out_tready) begin
          state <= STATE_RESULT_CAR_SPEED;
        end
      end
      STATE_RESULT_CAR_SPEED: begin   // 車速の送信結果をAXI4-Stream から受信するステート
        if (stm_result_in_tvalid & stm_result_in_tready) begin
          state <= STATE_SLEEP;
        end
      end
      STATE_SLEEP: begin  // 次の送信までスリープするステート
        if (sleep_counter == SLEEP_CYCLE - 1) begin
          sleep_counter <= 'd0;
          state <= STATE_SEND_ENGINE_REV;
        end else begin
          sleep_counter <= sleep_counter + 'd1;
        end
      end
      default:
        state <= STATE_SEND_ENGINE_REV;
    endcase
  end

endmodule

`default_nettype wire
