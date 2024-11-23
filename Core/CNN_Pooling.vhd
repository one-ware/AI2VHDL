
--Description: -This component finds the maximum value in a matrix
--Insertion:   -Specify the paramters with the constants in th CNN_Data file
--             -Connect the input data and stream signal with the input or previous layer

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;

ENTITY CNN_Pooling IS
    GENERIC (
        Input_Columns  : NATURAL := 28; --Size in x direction of input
        Input_Rows     : NATURAL := 28; --Size in y direction of input
        Input_Values   : NATURAL := 4;  --Number of Filters in previous layer or 3 for RGB input
        Filter_Columns : NATURAL := 2;  --Size in x direction of filters
        Filter_Rows    : NATURAL := 2;  --Size in y direction of filters
        Strides        : NATURAL := 1;  --1 = Output every value, 2 = Skip every second value
        Padding        : Padding_T := valid;   --valid = use available data, same = add padding to use data on the edge
        Input_Cycles   : NATURAL := 1;  --[1 to Input_Values] Filter Cycles of previous convolution
        Value_Cycles   : NATURAL := 1;  --[1 to Input_Values] Cycles to calculate values of one element of a matrix
        Filter_Cycles  : NATURAL := 1;  --[1 to Input_Values] Cycles to output data
        Filter_Delay   : NATURAL := 1;  --Cycles between Filters
        Expand         : BOOLEAN := false;  --Spreads Row data to maximize cycles per value (needs more RAM)
        Expand_Cycles  : NATURAL := 1     --If Expand true: Sets Cycles for each pixel when expaned
    );
    PORT (
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Input_Values/Input_Cycles-1 downto 0);
        
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Values_T(Input_Values/Filter_Cycles-1 downto 0) := (others => 0)
    );
END CNN_Pooling;

ARCHITECTURE BEHAVIORAL OF CNN_Pooling IS

    CONSTANT matrix_values        : NATURAL := Filter_Columns * Filter_Rows; --Pixels in Pooling matrix
    CONSTANT Matrix_Value_Cycles  : NATURAL := Filter_Columns*Filter_Rows*Value_Cycles; --Needed Cycles for all pixels in pooling matrix and values that are calculated in individual cycles
    CONSTANT Calc_Steps           : NATURAL := Input_Values/Value_Cycles;    --Values to calculate at once for each pixel in pooling matrix
    CONSTANT Out_Values           : NATURAL := Input_Values/Filter_Cycles;   --Values that are sent at once as output data
    
    SIGNAL Expand_Stream : CNN_Stream_T;
    SIGNAL Expand_Data   : CNN_Values_T(Input_Values/Input_Cycles-1 downto 0) := (others => 0);
    
    SIGNAL Matrix_Stream : CNN_Stream_T;
    SIGNAL Matrix_Data   : CNN_Values_T(Calc_Steps-1 downto 0);
    SIGNAL Matrix_Column : NATURAL range 0 to Input_Columns-1;
    SIGNAL Matrix_Row    : NATURAL range 0 to Input_Rows-1;
    SIGNAL Matrix_Input  : NATURAL range 0 to Value_Cycles-1;
    
    --RAM for max values of current pooling matrix
    type MAX_set_t is array (0 to Calc_Steps-1) of SIGNED(CNN_Value_Resolution downto 0);
    type RAM_reg_t is array (natural range <>) of MAX_set_t;
    SIGNAL RAM_reg      : RAM_reg_t(0 to Value_Cycles-1) := (others => (others => (others => '0')));
    SIGNAL MAX_Rd_Addr  : NATURAL range 0 to Value_Cycles-1;
    SIGNAL MAX_Rd_Data  : MAX_set_t;
    SIGNAL MAX_Wr_Addr  : NATURAL range 0 to Value_Cycles-1;
    SIGNAL MAX_Wr_Data  : MAX_set_t;
    SIGNAL MAX_Wr_Ena   : STD_LOGIC := '1';
    
    --RAM for output values
    CONSTANT OUT_RAM_Elements : NATURAL := min_val(Value_Cycles,Filter_Cycles);
    type OUT_set_t is array (0 to Input_Values/OUT_RAM_Elements-1) of SIGNED(CNN_Value_Resolution downto 0);
    type OUT_ram_t is array (natural range <>) of OUT_set_t;
    SIGNAL OUT_RAM      : OUT_ram_t(0 to OUT_RAM_Elements-1) := (others => (others => (others => '0')));
    SIGNAL OUT_Rd_Addr  : NATURAL range 0 to OUT_RAM_Elements-1;
    SIGNAL OUT_Rd_Data  : OUT_set_t;
    SIGNAL OUT_Wr_Addr  : NATURAL range 0 to OUT_RAM_Elements-1;
    SIGNAL OUT_Wr_Data  : OUT_set_t;
    SIGNAL OUT_Wr_Ena   : STD_LOGIC := '1';
    
    SIGNAL   Out_Value_Cnt_Reg     : NATURAL range 0 to Filter_Cycles-1;
    SIGNAL   Out_Delay_Cnt    : NATURAL range 0 to Filter_Delay-1 := Filter_Delay-1;
    SIGNAL   Out_Ready    : STD_LOGIC;
    
    COMPONENT CNN_Row_Expander IS
        GENERIC (
            Input_Columns  : NATURAL := 28;
            Input_Rows     : NATURAL := 28;
            Input_Values   : NATURAL := 1;
            Input_Cycles   : NATURAL := 1;
            Output_Cycles  : NATURAL := 2
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values/Input_Cycles-1 downto 0);
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Values_T(Input_Values/Input_Cycles-1 downto 0)
        );
    END COMPONENT;
    
    COMPONENT CNN_Row_Buffer IS
        GENERIC (
            Input_Columns  : NATURAL := 28;
            Input_Rows     : NATURAL := 28;
            Input_Values   : NATURAL := 1;
            Filter_Columns : NATURAL := 3;
            Filter_Rows    : NATURAL := 3;
            Input_Cycles   : NATURAL := 1;
            Value_Cycles   : NATURAL := 1;
            Calc_Cycles    : NATURAL := 1;
            Strides        : NATURAL := 1;
            Padding        : Padding_T := valid
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values/Input_Cycles-1 downto 0);
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Values_T(Input_Values/Value_Cycles-1 downto 0) := (others => 0);
            oRow    : BUFFER NATURAL range 0 to Filter_Rows-1;
            oColumn : BUFFER NATURAL range 0 to Filter_Columns-1;
            oInput  : BUFFER NATURAL range 0 to Value_Cycles-1
        );
    END COMPONENT;
    
BEGIN

    --Select if input data is spread eavenly to create enought cycles for calculation
    
    Generate1 : If Expand GENERATE
        CNN_Row_Expander1 : CNN_Row_Expander
        GENERIC MAP (
            Input_Columns => Input_Columns,
            Input_Rows    => Input_Rows,
            Input_Values  => Input_Values,
            Input_Cycles  => Input_Cycles,
            Output_Cycles => MAX_val(Matrix_Value_Cycles+1, Expand_Cycles)
        ) PORT MAP (
            iStream       => iStream,
            iData         => iData,
            oStream       => Expand_Stream,
            oData         => Expand_Data
        );
    END GENERATE Generate1;
    
    Generate2 : If NOT Expand GENERATE
        Expand_Data   <= iData;
        Expand_Stream <= iStream;
    END GENERATE Generate2;
    
    --Save the last image rows and return the data to calculate the pooling maxtrix
    
    CNN_Row_Buffer1 : CNN_Row_Buffer
    GENERIC MAP (
        Input_Columns  => Input_Columns,
        Input_Rows     => Input_Rows,
        Input_Values   => Input_Values,
        Filter_Columns => Filter_Columns,
        Filter_Rows    => Filter_Rows,
        Input_Cycles   => Input_Cycles,
        Value_Cycles   => Value_Cycles,
        Strides        => Strides,
        Padding        => Padding
    ) PORT MAP (
        iStream        => Expand_Stream,
        iData          => Expand_Data,
        oStream        => Matrix_Stream,
        oData          => Matrix_Data,
        oRow           => Matrix_Row,
        oColumn        => Matrix_Column,
        oInput         => Matrix_Input
    );
    
    oStream.Data_CLK <= Matrix_Stream.Data_CLK;
    
    --RAM for maximum in pooling matrix for different input values
    
    PROCESS (iStream)
    BEGIN
        IF (rising_edge(iStream.Data_CLK)) THEN
            IF (MAX_Wr_Ena = '1') THEN
                RAM_reg(MAX_Wr_Addr) <= MAX_Wr_Data;
            END IF;
        END IF;
    END PROCESS;
    
    MAX_Rd_Data <= RAM_reg(MAX_Rd_Addr);
    
    --Output RAM to save values after pooling and send them one by one to next layer
    
    PROCESS (iStream)
    BEGIN
        IF (rising_edge(iStream.Data_CLK)) THEN
            IF (OUT_Wr_Ena = '1') THEN
                OUT_RAM(OUT_Wr_Addr) <= OUT_Wr_Data;
            END IF;
        END IF;
    END PROCESS;
    
    OUT_Rd_Data <= OUT_RAM(OUT_Rd_Addr);
    
    --Takes the matrix of values from the last convolution and calculates the maximum for each filter output
    
    PROCESS (Matrix_Stream)
    VARIABLE Max_Reg     : MAX_set_t;   --Max value from RAM for current values
    VARIABLE RAM_reg     : CNN_Value_T; --Current Values from row buffer to caclulate max value
    VARIABLE last_input  : STD_LOGIC;      --True if pooling is done and
    
    VARIABLE Out_Value_Cnt : NATURAL range 0 to Filter_Cycles-1;
    
    --Variables to write calculated outputs into the Out RAM
    CONSTANT Out_max_buf_cycles : NATURAL := Value_Cycles/OUT_RAM_Elements;
    type     Out_max_buf_t is array (Out_max_buf_cycles-1 downto 0) of MAX_set_t;
    VARIABLE Out_max_buf     : Out_max_buf_t;
    VARIABLE Out_max_buf_cnt : NATURAL range 0 to Out_max_buf_cycles-1 := 0;
    BEGIN
        IF (rising_edge(Matrix_Stream.Data_CLK)) THEN
            
            oStream.Data_Valid <= '0';
            last_input := '0';
            
            --Calculate pooling when data from last convolution is available
            IF (Matrix_Stream.Data_Valid = '1') THEN
                
                --Read last max value from ram for this filter output from last convolution
                IF (Value_Cycles > 1) THEN
                    Max_Reg := MAX_Rd_Data;
                    IF (Matrix_Input < Value_Cycles-1) THEN
                        MAX_Rd_Addr <= Matrix_Input + 1;
                    ELSE
                        MAX_Rd_Addr <= 0;
                    END IF;
                END IF;

                --Load data from row buffer and set as maximum if this is the first pixel in the pooling matrix or if the value is bigger than the lasts values in the matrix
                FOR in_offset in 0 to Calc_Steps-1 LOOP
                    RAM_reg := Matrix_Data(in_offset);
                    IF ((Matrix_Row = 0 AND Matrix_Column = 0) OR RAM_reg > to_integer(Max_Reg(in_offset))) THEN
                        Max_Reg(in_offset) := to_signed(RAM_reg, CNN_Value_Resolution+1);
                    END IF;
                END LOOP;
                
                --write data to output ram if this was the last value in the pooling matrix
                IF (Matrix_Column = Filter_Columns-1 AND Matrix_Row = Filter_Rows-1) THEN
                    --Start sending the data if this is the last value from the filters of the last convolution
                    IF (Matrix_Input = Value_Cycles-1) THEN
                        last_input := '1';
                    END IF;
                    
                    --The Output RAM has a fixed width for the number of outputs that are sent at once
                    IF (Value_Cycles = OUT_RAM_Elements) THEN
                        --The calculated output values are either written to the RAM directly
                        OUT_Wr_Addr <= Matrix_Input;
                        FOR i in 0 to Calc_Steps-1 LOOP
                            OUT_Wr_Data(i) <= Max_Reg(i);
                        END LOOP;
                    ELSE
                        --Or the last outputs are saved and then saved in the RAM at once
                        Out_max_buf_cnt := Matrix_Input mod Out_max_buf_cycles;
                        Out_max_buf(Out_max_buf_cnt) := Max_Reg;
                        IF (Out_max_buf_cnt = Out_max_buf_cycles-1) THEN
                            OUT_Wr_Addr <= Matrix_Input/Out_max_buf_cycles;
                            FOR i in 0 to Out_max_buf_cycles-1 LOOP
                                FOR j in 0 to Calc_Steps-1 LOOP
                                    OUT_Wr_Data(Calc_Steps*i + j) <= Out_max_buf(i)(j);
                                END LOOP;
                            END LOOP;
                        END IF;
                    END IF;
                END IF;
                
                --Save the maximum value in RAM if the calculation for the filters is split
                IF (Value_Cycles > 1) THEN
                    MAX_Wr_Data <= Max_Reg;
                    MAX_Wr_Addr <= Matrix_Input;
                END IF;
                
            END IF;

            Out_Ready <= '0';
            
            --Set current column and row for output and count through results for values of this pooling
            IF (last_input = '1') THEN
                Out_Value_Cnt     := 0;
                Out_Delay_Cnt     <= 0;
                oStream.Column    <= Matrix_Stream.Column;
                oStream.Row       <= Matrix_Stream.Row;
                Out_Ready         <= '1';
            ELSIF (Out_Delay_Cnt < Filter_Delay-1) THEN       --Add a delay between the output data
                Out_Delay_Cnt     <= Out_Delay_Cnt + 1;
            ELSIF (Out_Value_Cnt_Reg < Filter_Cycles-1) THEN  --Count through Filters for the output
                Out_Delay_Cnt     <= 0;
                Out_Value_Cnt     := Out_Value_Cnt_Reg + 1;
                Out_Ready         <= '1';
            END IF;
            
            --Read output value from RAM
            Out_Value_Cnt_Reg  <= Out_Value_Cnt;
            OUT_Rd_Addr <= Out_Value_Cnt / (Filter_Cycles/OUT_RAM_Elements);
            
            --If the output is calculated, read from RAM and set oStream
            IF (Out_Delay_Cnt = 0) THEN
                FOR i in 0 to Out_Values-1 LOOP
                    IF (Filter_Cycles = OUT_RAM_Elements) THEN
                        oData(i) <= to_integer(OUT_Rd_Data(i));
                    ELSE
                        oData(i) <= to_integer(OUT_Rd_Data(i+(Out_Value_Cnt_Reg mod (Filter_Cycles/OUT_RAM_Elements))*Out_Values));
                    END IF;
                END LOOP;
                
                oStream.Filter     <= Out_Value_Cnt_Reg*(Out_Values);
                oStream.Data_Valid <= Out_Ready;
            ELSE
                oStream.Data_Valid <= '0';
            END IF;
            
        END IF;
    END PROCESS;
    
END BEHAVIORAL;