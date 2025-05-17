module dut_perf #(

) (
    input logic clk_i,
    input logic rst_ni,

    // AXI Config Slave port
    input   logic               config_aw_valid_i,
    input   ariane_axi::addr_t  config_aw_addr_i,
    input   axi_pkg::len_t      config_aw_len_i,
    input   axi_pkg::size_t     config_aw_size_i,
    input   ariane_axi::id_t    config_aw_id_i,

    output  logic               config_aw_ready_o,
    
    input   logic               config_w_valid_i,
    input   ariane_axi::data_t  config_w_data_i,
    input   ariane_axi::strb_t  config_w_strb_i,
    input   logic               config_w_last_i,

    output  logic               config_w_ready_o,

    input   logic               config_ar_valid_i,
    input   ariane_axi::addr_t  config_ar_addr_i,
    input   axi_pkg::len_t      config_ar_len_i,
    input   axi_pkg::size_t     config_ar_size_i,
    input   ariane_axi::id_t    config_ar_id_i,
    
    output  logic               config_ar_ready_o,

    output  logic               config_r_valid_o,
    output  ariane_axi::data_t  config_r_data_o,
    output  axi_pkg::resp_t     config_r_resp_o,
    output  logic               config_r_last_o,
    output  ariane_axi::id_t    config_r_id_o,

    input  logic                config_r_ready_i,

    output  logic               config_b_valid_o,
    output  axi_pkg::resp_t     config_b_resp_o,
    output  ariane_axi::id_t    config_b_id_o,

    input   logic               config_b_ready_i,

    // AXI Bus Slave port
    input  logic inp_aw_valid_i,
    input  logic inp_aw_ready_i,

    // AXI Bus Master port
    input  logic oup_aw_valid_i,
    input  logic oup_aw_ready_i
);

    ariane_axi::resp_t  config_rsp;
    ariane_axi::req_t   config_req;

    always_comb begin
        // config_rsp = '{default:0};
        config_w_ready_o = config_rsp.w_ready;
        config_aw_ready_o = config_rsp.aw_ready;
        config_ar_ready_o = config_rsp.ar_ready;

        config_r_valid_o  = config_rsp.r_valid;
        config_r_data_o   = config_rsp.r.data;
        config_r_resp_o   = config_rsp.r.resp;
        config_r_last_o   = config_rsp.r.last;
        
        config_b_valid_o  = config_rsp.b_valid;
        config_b_resp_o   = config_rsp.b.resp;
        config_b_id_o     = config_rsp.b.id;

        config_req = '{default:0};
        config_req.aw_valid = config_aw_valid_i;
        config_req.aw.addr  = config_aw_addr_i;
        config_req.aw.len   = config_aw_len_i;
        config_req.aw.size  = config_aw_size_i;

        config_req.w_valid  = config_w_valid_i;
        config_req.w.data   = config_w_data_i;
        config_req.w.strb   = config_w_strb_i;
        config_req.w.last   = config_w_last_i;
        
        config_req.ar_valid = config_ar_valid_i;
        config_req.ar.addr  = config_ar_addr_i;
        config_req.ar.len   = config_ar_len_i;
        config_req.ar.size  = config_ar_size_i;
        
        config_req.b_ready  = config_b_ready_i;
        config_req.r_ready  = config_r_ready_i;
    end
    
    perf_monitor_top #(
        .DATA_WIDTH     (ariane_axi::DataWidth),
        .ADDR_WIDTH     (ariane_axi::AddrWidth),
        .USER_WIDTH     (ariane_axi::UserWidth),
        .ID_WIDTH       (ariane_axi::IdWidth),
        .ID_SLV_WIDTH   (ariane_axi::IdWidth),
        
        .axi_req_t      (ariane_axi::req_t),
        .axi_rsp_t      (ariane_axi::resp_t),

        .axi_req_slv_t  (ariane_axi::req_t ),
        .axi_rsp_slv_t  (ariane_axi::resp_t)
    ) i_perf_monitor_top (
        .clk_i,
        .rst_ni,

        // // AXI Config Slave port
        .control_req_i  (config_req),
        .control_rsp_o  (config_rsp),

        // AXI Bus Slave port
        .inp_valid_i(inp_aw_valid_i),
        .inp_ready_i(inp_aw_ready_i),

        // AXI Bus Master port
        .oup_valid_i (oup_aw_valid_i),
        .oup_ready_i (oup_aw_ready_i)
    );

endmodule