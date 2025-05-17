import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import axi_master
import logging

class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.INFO)

        cocotb.start_soon(Clock(dut.clk_i, 10, units="ns").start())

    async def cycle_reset(self):
        self.dut.rst_ni.setimmediatevalue(1)
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)
        self.dut.rst_ni.value = 0
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)
        self.dut.rst_ni.value = 1
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)

async def handshake(clk, valid, ready):
    await RisingEdge(clk)
    valid.value = 1
    ready.value = 1
    await RisingEdge(clk)
    valid.value = 0
    ready.value = 0
    await RisingEdge(clk)

@cocotb.test()
async def test(dut):
    tb = TB(dut)

    config_intf = axi_master.Master(dut, "config", dut.clk_i, False)

    await tb.cycle_reset()
    await config_intf.init()

    await handshake(dut.clk_i, dut.inp_aw_valid_i, dut.inp_aw_ready_i)
    await RisingEdge(dut.clk_i)
    await handshake(dut.clk_i, dut.oup_aw_valid_i, dut.oup_aw_ready_i)

    await handshake(dut.clk_i, dut.inp_aw_valid_i, dut.inp_aw_ready_i)
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await handshake(dut.clk_i, dut.oup_aw_valid_i, dut.oup_aw_ready_i)

    attr = axi_master.AxMsg(0x4, 0, 2, 0)
    await config_intf.read(attr)

    await Timer(500, units='ns')
