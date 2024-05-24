`default_nettype none

// CAN コントローラ
module can_controller #(
  parameter CLK_FREQ_HZ = 50_000_000, // 入力クロック周波数
  parameter CAN_BITRATE_HZ = 500_000  // CAN のビットレート
) (
  input  wire clk,  // クロック入力
  output wire status_warning, // ワーニング出力 (エラーカウンタ >= 96)
  output wire status_bus_off, // バスオフ状態出力 (エラーカウンタ == 255)
  // CAN トランシーバ(TJA1441AT) とのインターフェース
  output wire txd,  // データ送信線
  input  wire rxd,  // データ受信線
  output wire s,    // モードセレクト: 0 -> Normal mode / 1 -> Silent mode
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

  // Normal mode に固定
  assign s = 1'b0;

  // モジュール間の接続に使用する変数
  wire rxd_synced;
  wire can_sending;
  wire can_bus_idle;
  wire sync_point;
  wire sampling_point;

  ///////// CAN にデータを送信するモジュール /////////
  can_sender can_sender_i (
    .*
  );

  ///////// CAN のデータ送受信タイミングを決定するモジュール /////////
  can_synchronizer #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .CAN_BITRATE_HZ(CAN_BITRATE_HZ)
  ) can_synchronizer_i (
    .*
  );

endmodule

`default_nettype wire
