`default_nettype none

// CAN にデータを送信するモジュール
module can_sender (
  input  wire clk,  // クロック入力
  output wire txd,  // データ送信線
  input  wire rxd_synced,     // クロック同期されたデータ受信線
  output wire can_sending,    // データ送信中を示すステータス出力
  input  wire can_bus_idle,   // バスアイドル状態を示すステータス入力
  input  wire sync_point,     // データ送信タイミング信号
  input  wire sampling_point, // データ受信タイミング信号
  output wire status_warning, // ワーニング出力 (エラーカウンタ >= 96)
  output wire status_bus_off, // バスオフ状態出力 (エラーカウンタ == 255)
  // AXI4-Stream 入力
  input  wire [63:0] stm_send_data_in_tdata,  // 送信データ
  input  wire [10:0] stm_send_data_in_tid,    // 送信ID
  input  wire [7:0]  stm_send_data_in_tkeep,  // 送信データのサイズを指定
  input  wire        stm_send_data_in_tvalid,
  output wire        stm_send_data_in_tready,
  // AXI4-Stream 出力
  output wire [2:0]  stm_result_out_tdata,    // 送信結果:
                                              // {アービトレーション負けの有無,
                                              //  ACK チェックエラーの有無,
                                              //  ビットモニタリングエラーの有無}
  output wire        stm_result_out_tvalid,
  input  wire        stm_result_out_tready
);

  localparam DATA_WIDTH = 64;
  localparam ID_WIDTH = 11;
  localparam DLC_WIDTH = 4;
  localparam CRC_WIDTH = 15;
  localparam SEND_FRAME_WIDTH = 1 + ID_WIDTH + 3 + DLC_WIDTH + DATA_WIDTH + CRC_WIDTH + 3 + 7 + 3;
  localparam ID_POS = ID_WIDTH + 3 + DLC_WIDTH + DATA_WIDTH + CRC_WIDTH + 3 + 7 + 3;
  localparam RTR_POS = 3 + DLC_WIDTH + DATA_WIDTH + CRC_WIDTH + 3 + 7 + 3;
  localparam DATA_POS = DATA_WIDTH + CRC_WIDTH + 3 + 7 + 3;
  localparam CRC_DELIMITER_POS = 3 + 7 + 3;
  localparam ACK_POS = 2 + 7 + 3;
  localparam SEND_ERROR_FRAME_WIDTH = 6 + 6 + 8 + 3;

  // 入出力との接続
  assign txd = txd_reg;
  assign can_sending = (state == STATE_SEND_FRAME);
  assign stm_send_data_in_tready = (state == STATE_READ_DATA) & can_bus_idle & !status_bus_off;
  wire [ID_WIDTH-1:0] id = stm_send_data_in_tid;
  wire [DATA_WIDTH-1:0] data = stm_send_data_in_tdata;
  assign stm_result_out_tdata = {arbitration_lost, ack_check_error, bit_monitoring_error};
  assign stm_result_out_tvalid = (state == STATE_RETURN_RESULT);

  // 入力tkeep からデータサイズ(dlc) への変換ロジック
  wire [DLC_WIDTH-1:0] dlc = (stm_send_data_in_tkeep[7])? 8:
                             (stm_send_data_in_tkeep[6])? 7:
                             (stm_send_data_in_tkeep[5])? 6:
                             (stm_send_data_in_tkeep[4])? 5:
                             (stm_send_data_in_tkeep[3])? 4:
                             (stm_send_data_in_tkeep[2])? 3:
                             (stm_send_data_in_tkeep[1])? 2:
                             (stm_send_data_in_tkeep[0])? 1:
                                                          0;

  ///////// ステートマシン /////////
  localparam STATE_READ_DATA = 0;
  localparam STATE_SEND_FRAME = 1;
  localparam STATE_SEND_ERROR_FRAME = 2;
  localparam STATE_WAIT_TO_NEXT_SEND = 3;
  localparam STATE_RETURN_RESULT = 4;
  localparam STATE_NUM = 5;
  logic [$clog2(STATE_NUM)-1:0] state = STATE_READ_DATA;
  logic [ID_WIDTH-1:0] id_reg   = 'd0;
  logic [DATA_WIDTH-1:0] data_reg = 'd0;
  logic [DLC_WIDTH-1:0] dlc_reg  = 'd0;
  always_ff @ (posedge clk) begin
    case(state)
      STATE_READ_DATA: begin  // 送信データをAXI4-Stream 入力から読み込むステート
        if (stm_send_data_in_tvalid & stm_send_data_in_tready) begin
          // 入力値をレジスタに保存
          id_reg <= id;
          data_reg <= data;
          dlc_reg <= dlc;
          state <= STATE_SEND_FRAME;
        end
      end
      STATE_SEND_FRAME: begin // CAN に標準フォーマットのデータフレームを送信するステート
        if (ack_check_error | bit_monitoring_error) begin
          // エラー検出時 -> エラーフレームを送信
          state <= STATE_SEND_ERROR_FRAME;
        end else if (arbitration_lost | (sync_point & (send_frame_counter == 'd0))) begin
          // アービトレーション負け検出、または送信正常終了時
          if (status_passive) begin
            state <= STATE_WAIT_TO_NEXT_SEND;
          end else begin
            state <= STATE_RETURN_RESULT;
          end
        end
      end
      STATE_SEND_ERROR_FRAME: begin // CAN にエラーフレームを送信するステート
        if (sync_point & (send_error_frame_counter == 'd0)) begin
          if (status_passive) begin
            state <= STATE_WAIT_TO_NEXT_SEND;
          end else begin
            state <= STATE_RETURN_RESULT;
          end
        end
      end
      STATE_WAIT_TO_NEXT_SEND: begin // Passive 状態時に次の送信を遅延させるステート
        if (sync_point & (wait_to_next_send_counter == 'd0)) begin
          state <= STATE_RETURN_RESULT;
        end
      end
      STATE_RETURN_RESULT: begin
        // 送信結果をAXI4-Stream に出力するステート
        if (stm_result_out_tvalid & stm_result_out_tready) begin
          state <= STATE_READ_DATA;
        end
      end
      default:
        state <= STATE_READ_DATA;
    endcase
  end

  ///////// send_frame_counter の更新ロジック /////////
  logic [$clog2(SEND_FRAME_WIDTH)-1:0] send_frame_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_FRAME) begin
      if (sync_point & !insert_bit_staff) begin
        send_frame_counter <= (send_frame_counter == DATA_POS - 'd1)?
                                send_frame_counter - (DATA_WIDTH - dlc_reg * 8) - 'd1:
                                send_frame_counter - 'd1;
      end
    end else begin
      send_frame_counter <= SEND_FRAME_WIDTH - 'd1;
    end
  end

  ///////// send_error_frame_counter の更新ロジック /////////
  logic [$clog2(SEND_ERROR_FRAME_WIDTH)-1:0] send_error_frame_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_ERROR_FRAME) begin
      if (sync_point) begin
        send_error_frame_counter <= send_error_frame_counter - 'd1;
      end
    end else begin
      send_error_frame_counter <= SEND_ERROR_FRAME_WIDTH - 'd1;
    end
  end

  ///////// wait_to_next_send_counter の更新ロジック /////////
  logic [2:0] wait_to_next_send_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (state == STATE_WAIT_TO_NEXT_SEND) begin
      if (sync_point) begin
        wait_to_next_send_counter <= wait_to_next_send_counter - 'd1;
      end
    end else begin
      wait_to_next_send_counter <= 'd7;
    end
  end

  ///////// CAN フレーム送信ロジック /////////
  // 標準データフレームフォーマット
  wire [SEND_FRAME_WIDTH-1:0] send_frame = {1'b0,
                                            id_reg,
                                            3'b000,
                                            dlc_reg,
                                            data_reg,
                                            crc,
                                            3'b111,
                                            7'b1111111,
                                            3'b111};
  // エラーフレームフォーマット
  wire [SEND_ERROR_FRAME_WIDTH-1:0] send_error_frame = {{6{status_passive}},
                                                        6'b111111,
                                                        8'b11111111,
                                                        3'b111};
  logic txd_reg = 1'b1;
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_FRAME) begin
      if (sync_point) begin
        if (!insert_bit_staff) begin
          // 標準データフレームを送信
          txd_reg <= send_frame[send_frame_counter];
        end else begin
          // ビットスタッフを挿入
          txd_reg <= ~txd_reg;
        end
      end
    end else if (state == STATE_SEND_ERROR_FRAME) begin
      if (sync_point) begin
        // エラーフレームを送信
        txd_reg <= send_error_frame[send_error_frame_counter];
      end
    end else begin
      txd_reg <= 1'b1;
    end
  end

  ///////// 同一レベルビットの連続検出ロジック /////////
  logic [3:0] continuous_of_same_level_bit = 'd0;
  // CRC フィールド以前に同一レベルビットが5回連続したとき、ビットスタッフを挿入
  wire insert_bit_staff = (send_frame_counter >= CRC_DELIMITER_POS - 'd1) &
                          (continuous_of_same_level_bit == 'd5);
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_FRAME) begin
      if (sync_point) begin
        if ((txd_reg == send_frame[send_frame_counter])) begin
          // 同一レベルのビットが連続したとき、continuous_of_same_level_bit をインクリメント
          continuous_of_same_level_bit <= continuous_of_same_level_bit + 'd1;
        end else begin
          // 同一レベルのビットが連続しなかった場合は、continuous_of_same_level_bit を1 にリセット
          continuous_of_same_level_bit <= 'd1;
        end
      end
    end else begin
      continuous_of_same_level_bit <= 'd0;
    end
  end

  ///////// CRC 計算ロジック /////////
  localparam CRC_DIVISOR_WIDTH = CRC_WIDTH + 1;
  localparam [CRC_DIVISOR_WIDTH-1:0] CRC_DIVISOR = 16'hC599;
  wire  [CRC_WIDTH-1:0] crc = (crc_counter < CRC_DELIMITER_POS)? crc_reg: 'd0;
  logic [CRC_WIDTH-1:0] crc_reg = 'd0;
  logic [$clog2(SEND_FRAME_WIDTH)-1:0] crc_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_FRAME) begin
      if (sync_point & !insert_bit_staff &
          (crc_counter > CRC_DELIMITER_POS - 'd1)) begin
        // CRC 値の更新
        crc_reg <= (crc_reg[CRC_WIDTH-1])?
                      {crc_reg, send_frame[crc_counter]} ^ CRC_DIVISOR:
                      {crc_reg, send_frame[crc_counter]};
        // CRC カウンタの更新
        crc_counter <= (crc_counter == DATA_POS - 'd1)?
                          crc_counter - (DATA_WIDTH - dlc_reg * 8) - 'd1:
                          crc_counter - 'd1;
      end
    end else begin
      crc_reg <= {1'b0, id, 3'b0};
      crc_counter <= SEND_FRAME_WIDTH - CRC_WIDTH - 'd1;
    end
  end

  ///////// アービトレーション、エラーチェックロジック /////////
  logic arbitration_lost = 1'b0;
  logic ack_check_error = 1'b0;
  logic bit_monitoring_error = 1'b0;
  always_ff @ (posedge clk) begin
    if (state == STATE_READ_DATA) begin
      arbitration_lost <= 1'b0;
      ack_check_error <= 1'b0;
      bit_monitoring_error <= 1'b0;
    end else if (state == STATE_SEND_FRAME) begin
      if (sampling_point & (send_frame_counter != SEND_FRAME_WIDTH - 'd1)) begin
        if ((send_frame_counter + 'd1 <= ID_POS - 'd1) &
            (send_frame_counter + 'd1 >= RTR_POS - 'd1)) begin
          // アービトレーション結果の保存
          arbitration_lost <= (rxd_synced != txd_reg);
        end else if (send_frame_counter + 'd1 == ACK_POS - 'd1) begin
          // ACK チェック結果の保存
          ack_check_error <= rxd_synced;
        end else begin
          // ビットモニタリングの結果の保存
          bit_monitoring_error <= (rxd_synced != txd_reg);
        end
      end
    end
  end

  ///// 送信エラーカウンタ /////
  logic [7:0] send_error_counter = 'd0;
  wire status_passive = (send_error_counter >= 'd128);
  assign status_warning = (send_error_counter >= 'd96);
  assign status_bus_off = (send_error_counter == 'd255);
  always_ff @ (posedge clk) begin
    if (state == STATE_SEND_FRAME) begin
      if ((ack_check_error & !status_passive) | bit_monitoring_error) begin
        // エラー検出時: 8 インクリメント
        // ただし、ACK チェックエラーはPassive 状態でないときのみインクリメント
        if (send_error_counter < 'd248) begin
          send_error_counter <= send_error_counter + 'd8;
        end else begin
          send_error_counter <= 'd255;
        end
      end else if (sync_point & (send_frame_counter == 'd0)) begin
        // 送信正常終了時: 1 デクリメント
        if (send_error_counter != 'd0) begin
          send_error_counter <= send_error_counter - 'd1;
        end
      end
    end
  end

endmodule

`default_nettype wire
