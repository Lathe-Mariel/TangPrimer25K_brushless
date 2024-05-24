`default_nettype none

// CAN のデータ送受信タイミングを決定するモジュール
module can_synchronizer #(
  parameter CLK_FREQ_HZ = 50_000_000, // 入力クロック周波数
  parameter CAN_BITRATE_HZ = 500_000  // CAN のビットレート
) (
  input  wire clk,            // クロック入力
  input  wire rxd,            // データ受信線
  output wire rxd_synced,     // クロック同期されたデータ受信線
  input  wire can_sending,    // データ送信中を示すステータス入力
  output wire can_bus_idle,   // バスアイドル状態を示すステータス出力
  output wire sync_point,     // データ送信タイミング信号
  output wire sampling_point  // データ受信タイミング信号
);

  // 入出力との接続
  assign rxd_synced = rxd_acc_reg[1];
  assign can_bus_idle = (state == STATE_IDLE);
  assign sync_point = (segment_counter == 'd0) | hard_synchronize;
  assign sampling_point = (segment_counter == (SYNC_CYCLE + tseg1_cycle) - 'd1);

  // メタステーブル防止のため、データ受信線からの入力を2段のフリップフロップで受ける
  logic [1:0] rxd_reg = '0;
  always_ff @ (posedge clk) begin
    rxd_reg[0] <= rxd;
    rxd_reg[1] <= rxd_reg[0];
  end

  // データ受信線からの入力を2段のフリップフロップに記憶する
  logic [1:0] rxd_acc_reg = '0;
  always @ (posedge clk) begin
    rxd_acc_reg[0] <= rxd_reg[1];
    rxd_acc_reg[1] <= rxd_acc_reg[0];
  end

  // 2段のフリップフロップの値からエッジを検出する
  wire rxd_negedge =  rxd_acc_reg[1] & ~rxd_acc_reg[0];

  ///////// ステートマシン /////////
  localparam STATE_IDLE = 0;
  localparam STATE_SENDING = 1;
  localparam STATE_RECEIVING = 2;
  localparam STATE_NUM = 3;
  logic [$clog2(STATE_NUM)-1:0] state = STATE_IDLE;
  always_ff @ (posedge clk) begin
    case(state)
      STATE_IDLE: begin // 待機ステート
        if (can_sending) begin
          state <= STATE_SENDING;
        end else if (rxd_negedge) begin
          state <= STATE_RECEIVING;
        end
      end
      STATE_SENDING: begin  // データ送信中ステート
        if (continuous_of_recessive_level == 'd20) begin
          // レセシブレベルが20 回連続したとき、送信終了とみなす
          state <= STATE_IDLE;
        end
      end
      STATE_RECEIVING: begin  // データ受信中ステート
        if (continuous_of_recessive_level == 'd20) begin
          // レセシブレベルが20 回連続したとき、受信終了とみなす
          state <= STATE_IDLE;
        end
      end
      default:
        state <= STATE_IDLE;
    endcase
  end

  ///////// レセシブレベルビットの連続検出ロジック /////////
  logic [7:0] continuous_of_recessive_level = 'd0;
  always_ff @ (posedge clk) begin
    if (state == STATE_IDLE) begin
      continuous_of_recessive_level <= 'd0;
    end else begin
      if (sampling_point) begin
        if (rxd_synced) begin
          // レセシブレベルを検出したとき、continuous_of_recessive_level をインクリメント
          continuous_of_recessive_level <= continuous_of_recessive_level + 'd1;
        end else begin
          // ドミナントレベルを検出したとき、continuous_of_recessive_level を0 にリセット
          continuous_of_recessive_level <= 'd0;
        end
      end
    end
  end

  ///////// ハード同期、再同期機能を含むセグメントカウンタロジック /////////
  localparam TQ_PER_BIT = 10;
  localparam TQ_CYCLE = CLK_FREQ_HZ / CAN_BITRATE_HZ / TQ_PER_BIT;
  localparam SYNC_CYCLE = 1 * TQ_CYCLE;
  localparam TSEG1_CYCLE_BASE = 5 * TQ_CYCLE;
  localparam TSEG2_CYCLE_BASE = 4 * TQ_CYCLE;
  localparam MAX_SEGMENT_CYCLE = (TQ_PER_BIT + TQ_SJW) * TQ_CYCLE;

  // ハード同期を行う条件: バスアイドル中に立ち下がりエッジを検出したとき、ハード同期を実行
  wire hard_synchronize = (state == STATE_IDLE) & !can_sending & rxd_negedge;

  // 再同期ロジック
  localparam TQ_SJW = 2;
  localparam SJW_CYCLE = 2 * TQ_CYCLE;
  logic [$clog2(MAX_SEGMENT_CYCLE)-1:0] tseg1_cycle_increment = 'd0;
  logic [$clog2(MAX_SEGMENT_CYCLE)-1:0] tseg2_cycle_decrement = 'd0;
  wire  [$clog2(MAX_SEGMENT_CYCLE)-1:0] tseg1_cycle = TSEG1_CYCLE_BASE + tseg1_cycle_increment;
  logic [$clog2(MAX_SEGMENT_CYCLE)-1:0] tseg2_cycle = TSEG2_CYCLE_BASE - tseg2_cycle_decrement;
  wire  [$clog2(MAX_SEGMENT_CYCLE)-1:0] total_segment_cycle = SYNC_CYCLE + tseg1_cycle + tseg2_cycle;
  always_ff @ (posedge clk) begin
    if (state == STATE_RECEIVING) begin
      if (rxd_negedge) begin
        // レセシブ->ドミナントのタイミング次第で、tseg1とtseg2 を調整
        if (segment_counter < SYNC_CYCLE) begin
          // 正しいタイミング: 調整なし
          tseg1_cycle_increment <= 'd0;
          tseg2_cycle_decrement <= 'd0;
        end else if (segment_counter < SYNC_CYCLE + tseg1_cycle) begin
          // 遅すぎる: tseg1 を増やす
          if (segment_counter - SYNC_CYCLE < SJW_CYCLE) begin
            tseg1_cycle_increment <= segment_counter - SYNC_CYCLE;
          end else begin
            tseg1_cycle_increment <= SJW_CYCLE;
          end
          tseg2_cycle_decrement <= 'd0;
        end else begin
          // 早すぎる: tseg2 を減らす
          if (total_segment_cycle - segment_counter < SJW_CYCLE) begin
            tseg2_cycle_decrement <= total_segment_cycle - segment_counter;
          end else begin
            tseg2_cycle_decrement <= SJW_CYCLE;
          end
          tseg1_cycle_increment <= 'd0;
        end
      end else if (sync_point) begin
        tseg2_cycle <= TSEG2_CYCLE_BASE - tseg2_cycle_decrement;
        tseg1_cycle_increment <= 'd0;
        tseg2_cycle_decrement <= 'd0;
      end
    end else begin
      tseg2_cycle <= TSEG2_CYCLE_BASE - tseg2_cycle_decrement;
      tseg1_cycle_increment <= 'd0;
      tseg2_cycle_decrement <= 'd0;
    end
  end

  // セグメントカウンタ
  logic [$clog2(MAX_SEGMENT_CYCLE)-1:0] segment_counter = 'd0;
  always_ff @ (posedge clk) begin
    if (hard_synchronize) begin
      segment_counter <= 'd1;
    end else if (segment_counter < total_segment_cycle - 'd1) begin
      segment_counter <= segment_counter + 'd1;
    end else begin
      segment_counter <= 'd0;
    end
  end

endmodule

`default_nettype wire
