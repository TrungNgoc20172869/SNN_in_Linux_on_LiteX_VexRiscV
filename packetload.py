from sqlite3 import complete_statement
from migen import *

from litex.soc.interconnect.csr import *
# need interrupt handle?
from litex.soc.interconnect.csr_eventmanager import *

from litex.soc.integration.doc import AutoDoc, ModuleDoc

class packetload (Module, AutoCSR, AutoDoc):
    def __init__(self, platform):
        self.intro = ModuleDoc("""packetload""")
        self.core_reset_loader                          = CSRStorage(1, reset=0x0, name="core_reset", description="Core Reset" )
        self.start_csr                                  = CSRStorage(1, reset=0x0, name="start", description="Start load packet" )
        self.packet_in_csr                              = CSRStatus(30, reset=0x0, name="packet_in", description="packet_in" )
        self.complete_csr                               = CSRStatus(1, reset=0x0, name="complete", description="All process complete")
        self.state_csr                                  = CSRStatus(3, reset=0x0, name="state", description="state loader" )
        self.tick_csr                                   = CSRStatus(1, reset=0x0, name="tick", description="tick" )
        self.input_buffer_empty_csr                     = CSRStatus(1, reset=0x1, name="input_buffer_empty", description="input buffer empty" )
        self.ren2in_buf_csr                             = CSRStatus(1, reset=0x0, name="ren2in_buf", description="ren to input buffer" )
        self.output_valid_csr                           = CSRStatus(1, reset=0x0, name="output_valid", description="Output valid" )
        self.packet_out_csr                             = CSRStatus(8, reset=0x0, name="packet_out", description="packet_out" )
        self.num_pack_csr                               = CSRStatus(32, reset=0x0, name="num_pack", description="Number packet loaded" )
        self.grid_state_csr                             = CSRStatus(3, reset=0x0, name="grid_state_csr", description="grid_state" )
        self.forward_north_local_buffer_empty_all_csr   = CSRStatus(1, reset=0x0, name="forward_north_local_buffer_empty_all_csr", description="forward_north_local_buffer_empty_all_csr")
        self.spike8_csr                                 = CSRStatus(32, reset=0x0, name="spike8", description="spike_out 8" )
        self.spike7_csr                                 = CSRStatus(32, reset=0x0, name="spike7", description="spike_out 7" )
        self.spike6_csr                                 = CSRStatus(32, reset=0x0, name="spike6", description="spike_out 6" )
        self.spike5_csr                                 = CSRStatus(32, reset=0x0, name="spike5", description="spike_out 5" )
        self.spike4_csr                                 = CSRStatus(32, reset=0x0, name="spike4", description="spike_out 4" )
        self.spike3_csr                                 = CSRStatus(32, reset=0x0, name="spike3", description="spike_out 3" )
        self.spike2_csr                                 = CSRStatus(32, reset=0x0, name="spike2", description="spike_out 2" )
        self.spike1_csr                                 = CSRStatus(32, reset=0x0, name="spike1", description="spike_out 1" )

        start                       = Signal()
        complete                    = Signal()
        state_loader                = Signal(3)
        self.ren2in_buf             = Signal()
        self.input_buffer_empty     = Signal()
        self.tick                   = Signal()
        self.output_valid           = Signal()
        self.packet_in              = Signal(30)
        self.packet_out             = Signal(8)
        self.num_pack               = Signal(32)
        self.spike_out              = Signal(250)
        self.spike1                 = Signal(32)
        self.spike2                 = Signal(32)
        self.spike3                 = Signal(32)
        self.spike4                 = Signal(32)
        self.spike5                 = Signal(32)
        self.spike6                 = Signal(32)
        self.spike7                 = Signal(32)
        self.spike8                 = Signal(32)

        self.grid_state                             = Signal(3)
        self.forward_north_local_buffer_empty_all   = Signal()

        #Spike out
        self.comb += [
            self.spike1.eq(self.spike_out[0:31]),
            self.spike2.eq(self.spike_out[32:63]),
            self.spike3.eq(self.spike_out[64:95]),
            self.spike4.eq(self.spike_out[96:127]),
            self.spike5.eq(self.spike_out[128:159]),
            self.spike6.eq(self.spike_out[160:191]),
            self.spike7.eq(self.spike_out[192:223]),
            self.spike8.eq(self.spike_out[224:250]),
        ]
        self.comb += [
            self.spike8_csr.status.eq(self.spike8),
            self.spike7_csr.status.eq(self.spike7),
            self.spike6_csr.status.eq(self.spike6),
            self.spike5_csr.status.eq(self.spike5),
            self.spike4_csr.status.eq(self.spike4),
            self.spike3_csr.status.eq(self.spike3),
            self.spike2_csr.status.eq(self.spike2),
            self.spike1_csr.status.eq(self.spike1),
        ]


        # Read from CSR
        self.comb += [
            start.eq(self.start_csr.storage),
        ]
        # Write to CSR
        self.comb += [
            self.complete_csr.status.eq(complete),
            self.state_csr.status.eq(state_loader),
            self.packet_in_csr.status.eq(self.packet_in),
            self.tick_csr.status.eq(self.tick),
            self.input_buffer_empty_csr.status.eq(self.input_buffer_empty),
            self.ren2in_buf_csr.status.eq(self.ren2in_buf),
            self.output_valid_csr.status.eq(self.output_valid),
            self.packet_out_csr.status.eq(self.packet_out),
            self.num_pack_csr.status.eq(self.num_pack),
            self.grid_state_csr.status.eq(self.grid_state),
            self.forward_north_local_buffer_empty_all_csr.status.eq(self.forward_north_local_buffer_empty_all),
        ]

        WIDTH       = 30
        NUM_PACKET  = 13910
        NUM_PIC     = 100
        self.specials += Instance("tick_gen",
            i_clk                                   = ClockSignal(),
            i_rst                                   = ResetSignal() | self.core_reset_loader.storage,
            i_state                                 = state_loader,
            i_grid_state                            = self.grid_state,
            i_input_buffer_empty                    = self.input_buffer_empty,
            i_forward_north_local_buffer_empty_all  = self.forward_north_local_buffer_empty_all,
            i_complete                              = complete,
            o_tick                                  = self.tick,
            )
        platform.add_source("./soc_snn/tick_gen.v")

        self.specials += Instance("load_packet",
            p_WIDTH                 = WIDTH,
            p_NUM_PACKET            = NUM_PACKET,
            p_NUM_PIC               = NUM_PIC,
            i_clk                   = ClockSignal(),
            i_reset_n               = ResetSignal() | self.core_reset_loader.storage,
            i_start                 = start,
            i_ren2in_buf            = self.ren2in_buf,
            i_tick                  = self.tick,
            i_packet_out_valid      = self.output_valid,
            i_packet_out            = self.packet_out,
            i_grid_state            = self.grid_state,
            o_input_buffer_empty    = self.input_buffer_empty,
            o_complete              = complete,
            o_state                 = state_loader,
            o_spike_out             = self.spike_out,
            o_packet_in             = self.packet_in,
            o_num_pack              = self.num_pack,
            )
        platform.add_source("./soc_snn/PacketLoader.v")
