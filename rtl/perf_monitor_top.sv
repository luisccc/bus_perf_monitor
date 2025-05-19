`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module perf_monitor_top #(
    // AXI specific parameters
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of axuser signal
    parameter int unsigned USER_WIDTH     = 2,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,
    // width of id signal
    parameter int unsigned ID_SLV_WIDTH   = 8,
    parameter int unsigned NSAID_WIDTH    = 8,
    // AXI request/response
    parameter type         axi_req_t      = logic,
    parameter type         axi_rsp_t      = logic,

    /// AXI Full Slave request struct type
    parameter type         axi_req_slv_t   = logic,
    /// AXI Full Slave response struct type
    parameter type         axi_rsp_slv_t   = logic
) (
    input   logic clk_i,
    input   logic rst_ni,

    // // AXI Config Slave port
    input  axi_req_slv_t    control_req_i,
    output axi_rsp_slv_t    control_rsp_o,

    // AXI Bus Slave port
    input  logic inp_valid_i,
    input  logic inp_ready_i,

    // AXI Bus Master port
    input  logic oup_valid_i,
    input  logic oup_ready_i
);

    `REG_BUS_TYPEDEF_ALL(cfg_reg, logic[2:0], logic[31:0], logic[3:0])

    cfg_reg_req_t reg_req;
    cfg_reg_rsp_t reg_rsp;

    perf_monitor_reg_pkg::perf_monitor_reg2hw_t reg2hw;
    perf_monitor_reg_pkg::perf_monitor_hw2reg_t hw2reg;

    logic [30:0] counter, fifo_oup_data, fifo_rslt_oup_data;

    logic fifo_inp_valid, fifo_oup_valid, fifo_oup_ready;
    logic fifo_rslt_inp_valid, fifo_rslt_oup_valid, fifo_rslt_oup_ready;


    perf_monitor_prog_if #(
        // width of data bus in bits
        .DATA_WIDTH (DATA_WIDTH),
        // width of addr bus in bits
        .ADDR_WIDTH (ADDR_WIDTH),
        // width of id signal
        .ID_WIDTH   (ID_SLV_WIDTH),
        // width of user signal
        .USER_WIDTH (USER_WIDTH),

        .reg_req_t  (cfg_reg_req_t),
        .reg_rsp_t  (cfg_reg_rsp_t),

        .axi_req_t  (axi_req_slv_t),
        .axi_rsp_t  (axi_rsp_slv_t)
    ) i_perf_monitor_prog_if (
        .clk_i,
        .rst_ni,

        // slave port
        .slv_req_i  (control_req_i),
        .slv_rsp_o  (control_rsp_o),

        .cfg_req_o  (reg_req),
        .cfg_rsp_i  (reg_rsp)
    );

    perf_monitor_reg_top #(
        .reg_req_t  (cfg_reg_req_t),
        .reg_rsp_t  (cfg_reg_rsp_t)
    ) i_regmap (
        .clk_i,
        .rst_ni,
        .reg_req_i  (reg_req),
        .reg_rsp_o  (reg_rsp),

        // To HW
        .reg2hw, // Write
        .hw2reg, // Read

        // Config
        .devmode_i ('0) // If 1, explicit error return for unmapped register access
    );


    assign hw2reg.perf_data.data.d = fifo_rslt_oup_data;
    assign hw2reg.perf_data.v.d = 1'b1;
    always_comb begin 
        fifo_inp_valid = 1'b0;
        fifo_oup_ready = 1'b0;
        fifo_rslt_inp_valid = 1'b0;
        fifo_rslt_oup_ready = 1'b0;

        hw2reg.perf_data.data.de = 1'b0;
        hw2reg.perf_data.v.de = 1'b0;

        if (inp_valid_i && inp_ready_i) begin
            fifo_inp_valid = 1'b1;
        end

        if (oup_valid_i && fifo_oup_valid) begin
            fifo_oup_ready = 1'b1;
            fifo_rslt_inp_valid = 1'b1;
        end

        if (fifo_rslt_oup_valid && !reg2hw.perf_data.v) begin
            fifo_rslt_oup_ready = 1'b1;

            hw2reg.perf_data.data.de = 1'b1;
            hw2reg.perf_data.v.de = 1'b1;
        end
    end

    stream_fifo #(
        .DATA_WIDTH (31),
        /// Depth can be arbitrary from 0 to 2**32
        .DEPTH (16)
    ) i_counter_stream_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low
        .flush_i    ('0),    // flush the fifo
        .testmode_i ('0), // test_mode to bypass clock gating
        .usage_o    (),    // fill pointer

        // input interface
        .data_i     (counter),     // data to push into the fifo
        .valid_i    (fifo_inp_valid),    // input data valid
        .ready_o    (),    // fifo is not full
        // output interface
        .data_o     (fifo_oup_data),     // output data
        .valid_o    (fifo_oup_valid),    // fifo is not empty
        .ready_i    (fifo_oup_ready)     // pop head from fifo
    );

    stream_fifo #(
        .DATA_WIDTH (31),
        /// Depth can be arbitrary from 0 to 2**32
        .DEPTH (16)
    ) i_rslt_stream_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low
        .flush_i    ('0),    // flush the fifo
        .testmode_i ('0), // test_mode to bypass clock gating
        .usage_o    (),    // fill pointer

        // input interface
        .data_i     (counter - fifo_oup_data),     // data to push into the fifo
        .valid_i    (fifo_rslt_inp_valid),    // input data valid
        .ready_o    (),    // fifo is not full
        // output interface
        .data_o     (fifo_rslt_oup_data),     // output data
        .valid_o    (fifo_rslt_oup_valid),    // fifo is not empty
        .ready_i    (fifo_rslt_oup_ready)     // pop head from fifo
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule