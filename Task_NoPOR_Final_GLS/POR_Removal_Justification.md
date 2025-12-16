### Signal Flow of dummy_por:

    +-----------------+
    |    vdd3v3      |
    +-----------------+
            |
            v
    +-----------------+
    |   dummy_por    |
    | porb_h,porb_l, |
    |     por_l      |
    +-----------------+
            |
            v
    +-----------------+
    | caravel_core.v |
    | porb_h,porb_l, |
    |     por_l      |
    +-----------------+
        |          |
        v          v
    +-----------+ +-----------------+
    |caravel_   | |  housekeeping   |
    |clocking   | |   (porb_l→porb) |
    |porb_l→porb| +-----------------+
    +-----------+         |
                        v
                +-----------------+
                |housekeeping_spit|
                | porb + Internal |
                |   Logic         | 
                +-----------------+

### Signal flow of resetb from TestBench:

    +-----------------+
    |      tb        |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |  vsdcaravel    |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |   chip_io      |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |   pc3de PAD    |
    |    resetb      |
    +-----------------+
            |
            v (PAD delay)
    +-----------------+
    |   chip_io      |
    | resetb_core_h  |
    +-----------------+
            |
            v
    +-----------------+
    |  caravel.v     |
    |    rstb_h      |
    +-----------------+
            |
            v
    +-----------------+
    |caravel_core.v  |
    |    rstb_h      |
    +-----------------+
            |
            v
    +-----------------+
    |  xres_bef      |
    |    rstb_l      |
    +-----------------+
            |
            v
        (continues...)

### Removal of dummy_por :

The three signals porb_h,porb_l,por_l come from dummy_por to  caravel_core.v. From that it goes to the other modules as porh_l signal no other propogates from this module out of the three signal.

-  Deletion of Dummy_por module

![](img/1_dport.png)


- After deletion In cravel_core.v the three signals is assigned as output but there is no source for that signal so we need to give the external reset from the testbench.

![](img/40.png)
- the signal from testbench given to vsdcaravel.v so we need to propogate the external signal to the caravel_core.v through the vsdcaravel.The vsdcaravel has alread a instantiation to caravel_core as it get the porb_h and por_l from vsdcaravel.The porh_l is used in caravel_core so i remove the other two signal and only porh_l is modified as inout port and named as reset_n for reference .

- now caravel_core signal is reduced so we need to change the signals initialization in all of instatiated module 

![](img/5.png)

 - from this it is clear that caravel.v and vsdcaravel.v so we need to modify instantiation
![](img/17.png)

- then in vsdcaravel assigning the signals to resetb from testbench 

![](img/41.png)

- assigning the reset_n of caravel_core to resetb of testbench this is actual connection between the testbench and caravel_core. From there it goes to every module which replace the signal of the dummy_por.

![](img/15.png)

## RTL of Caravel_SoC:

```
csh
source tool_directory

# VCS command to run RTL simulation
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
+incdir+../ +incdir+../../rtl +incdir+../../rtl/scl180_wrapper \
+incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/6M1L/verilog/tsl18cio250/zero \
+define+FUNCTIONAL +define+SIM \
hkspi_tb.v -o simv

![](img/7.png)

```
./simv

![](img/8.png)

## Waveform Using GTKWave :

    gtkwave hksim.vcd


![](img/9.png)

## Synthesis:

-->file.tcl<---


    csh
    source /home/rbalajis/toolRC_iitgntapeout
    dc_shell -f ../synth.tcl

### Synthesised Netlist:

![](img/21.png)

![](img/22.png)

there is no dummy_por in netlist since we have removed dummy_por


## Gate Level Simulation(GLS):

commenting out the blackbox module RAM128 and RAM256 and adding the verilog model of the module to check the functionlity in GLS.

![](img/23.png)
![](img/24.png)

    ./simv

### Simulation Result:

![](img/25.png)

### Waveform:

![](img/27.png)
![](img/28.png)
this is place were reset is triggered again to check the functionality of our reset.

## Testing the external Reset :

Added this in testbench

    // Ritesh Balaji S

	    $display("Writing the value 0x00 to register 0x08 and 0x09");

	    start_csb();
	    write_byte(8'h80);	// Write stream command
	    write_byte(8'h08);	// Address (register 8 default value =0x02)
	    write_byte(8'h00);	// Data = 0x00 giving external value
	    end_csb();

	   start_csb();
	    write_byte(8'h40);	// Read stream command
	    write_byte(8'h08);	
	    read_byte(tbdata);
	    end_csb();
	    #10;
	    $display("Read data = 0x%08x (should be 0x00) ", tbdata);

	    start_csb();
	    write_byte(8'h80);	// Write stream command
	    write_byte(8'h09);	// Address (register 9 default value =0x01)
	    write_byte(8'h00);	// Data = 0x00 giving external value
	    end_csb();

            start_csb();
	    write_byte(8'h40);	// Read stream command
	    write_byte(8'h09);	
	    read_byte(tbdata);
	    end_csb();
	    #10;
	    $display("Read data = 0x%09x (should be 0x00) ", tbdata);

	//reset is applied again

	    RSTB <= 1'b0;

	    // Delay, then bring chip out of reset
	    #500;
	    RSTB <= 1'b1;
	    #500;
	   
            $display("Reset is applied now the values of 0x08 and 0x09 should to be default value to register 8 default value =0x02 register 9 default value =0x01");


to check whether our reset workds correctly we have modified the values of register 0x08 and 0x09 to 0x00 it is clearly displayed in simulation also. Then the reset is applied the values of 0x08 and 0x09 is succesfully resetted. 


![](img/26.png)

it is seen in output that after reset  the value of the register are in default value.

![](img/27.png)
![](img/30.png)
