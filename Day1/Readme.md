# Day 1 - RTL Simulation Vs GLS Simulation Using Synopsys

## Cloning GITHUB Files

    git clone -b iitgn https://github.com/vsdip/vsdRiscvScl180.git

## Project Directory Structure:

    VsdRiscvScl180/
        dv/           - Functional verification files
        gl/           - GLS support files
        gls/          - Testbench + synthesized netlists
        rtl/          - Verilog source files
        synthesis/
            output/   - Synthesis output
            report/   - Area, power & QoR reports
            work/     - Synthesis work directory
     


## Required file:

- SCL_180 Lib
- vsdRiscvSc1180
- Synopsys
- iverilog,GTKWave

## RTL Simulation:

- RTL Simulation is run by make file inside the directory dv/hkspi

### Command:

    cd VsdRiscvSc1180/dv/hkspi
    
    // if vvp file present clear it 
    rm hkspi.vvp
    
    make
    vvp hkspi.vvp
    
![](img/rtl_c.png)


## Waveform:

### Command:

    gtkwave hkspi.vcd
    
![](img/rtl_wave1.png)
