from sqlite3 import complete_statement
from migen import *

from litex.soc.interconnect.csr import *
# need interrupt handle?
from litex.soc.interconnect.csr_eventmanager import *

from litex.soc.integration.doc import AutoDoc, ModuleDoc

class ranc_3x2 (Module, AutoCSR, AutoDoc):
    def __init__(self, platform):
        self.intro = ModuleDoc(""" ranc_3x2""")
        # self.core_reset_ranc        = CSRStorage(1, reset=0x0, name="core_reset", description="Core Reset" )
        self.token_error_csr        = CSRStatus(1, reset=0x0, name="token_error", description="Token controller error" )
        self.scheduler_error_csr    = CSRStatus(1, reset=0x0, name="scheduler_error", description="Scheduler error" )

        self.core_reset_ranc                        = Signal()
        self.tick                                   = Signal() 
        self.input_buffer_empty                     = Signal()
        self.packet_in                              = Signal(30)
        self.packet_out                             = Signal(8)
        self.output_valid                           = Signal()
        self.ren2in_buf                             = Signal()
        self.token_controller_error                 = Signal()
        self.scheduler_error                        = Signal()
        self.grid_state                             = Signal(3)
        self.forward_north_local_buffer_empty_all   = Signal()

        self.comb += [
            self.token_error_csr.status.eq(self.token_controller_error),
            self.scheduler_error_csr.status.eq(self.scheduler_error),

        ]     

        self.specials += Instance("RANCNetworkGrid_3x2",
            i_clk                                   = ClockSignal(),
            i_reset_n                               = ResetSignal() | self.core_reset_ranc,
            i_tick                                  = self.tick,
            i_input_buffer_empty                    = self.input_buffer_empty,
            i_packet_in                             = self.packet_in,
            o_packet_out                            = self.packet_out,
            o_packet_out_valid                      = self.output_valid,
            o_ren_to_input_buffer                   = self.ren2in_buf,
            o_token_controller_error                = self.token_controller_error,
            o_scheduler_error                       = self.scheduler_error,
            o_grid_state                            = self.grid_state,
            o_forward_north_local_buffer_empty_all  = self.forward_north_local_buffer_empty_all,
            )
        platform.add_source("./ranc/RANCNetworkGrid_3x2.v")
        platform.add_source("./ranc/buffer.v")
        platform.add_source("./ranc/Core_3x2.v")
        platform.add_source("./ranc/Counter.v")
        platform.add_source("./ranc/ForwardEastWest.v")
        platform.add_source("./ranc/ForwardNorthSouth.v")
        platform.add_source("./ranc/FromLocal.v")
        platform.add_source("./ranc/LocalIn.v")
        platform.add_source("./ranc/Merge2.v")
        platform.add_source("./ranc/Merge3.v")
        platform.add_source("./ranc/neuron_block.v")
        platform.add_source("./ranc/neuron_grid_3x2.v")
        platform.add_source("./ranc/neuron_grid_controller.v")
        platform.add_source("./ranc/neuron_grid_datapath_3x2.v")
        
        platform.add_source("./ranc/OutputBus.v")
        platform.add_source("./ranc/PathDecoder2Way.v")
        platform.add_source("./ranc/PathDecoder3Way.v")
        platform.add_source("./ranc/Router.v")
        platform.add_source("./ranc/Scheduler.v")
        platform.add_source("./ranc/SchedulerSRAM.v")