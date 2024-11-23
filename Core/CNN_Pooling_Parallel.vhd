
--Description: -This component finds the maximum value in a matrix
--Insertion:   -Specify the paramters with the constants in th CNN_Data file
--             -Connect the input data and stream signal with the input or previous layer

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;

ENTITY CNN_Pooling_Parallel IS
    GENERIC (
        Input_Columns  : NATURAL := 28; --Size in x direction of input
        Input_Rows     : NATURAL := 28; --Size in y direction of input
        Input_Values   : NATURAL := 4;  --Number of Filters in previous layer or 3 for RGB input
        Filter_Columns : NATURAL := 2;  --Size in x direction of filters
        Filter_Rows    : NATURAL := 2;  --Size in y direction of filters
        Strides        : NATURAL := 1;  --1 = Output every value, 2 = Skip every second value
        Padding        : Padding_T := valid;   --valid = use available data, same = add padding to use data on the edge
        Calc_Cycles    : NATURAL := 1   --In deeper layers, the clock is faster than the new data. So the operation can be done in seperate cycles
    );
    PORT (
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
        
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Values_T(Input_Values-1 downto 0) := (others => 0)
    );
END CNN_Pooling_Parallel;

ARCHITECTURE BEHAVIORAL OF CNN_Pooling_Parallel IS

    SIGNAL Matrix_Stream : CNN_Stream_T;
    SIGNAL Matrix_Data   : CNN_Value_Matrix_T(Input_Values-1 downto 0, Filter_Rows-1 downto 0, Filter_Columns-1 downto 0);
    
    COMPONENT CNN_Row_Buffer_Parallel IS
        GENERIC (
            Input_Columns  : NATURAL := 28;
            Input_Rows     : NATURAL := 28;
            Input_Values   : NATURAL := 1;
            Filter_Columns : NATURAL := 3;
            Filter_Rows    : NATURAL := 3;
            Strides        : NATURAL := 1;
            Padding        : Padding_T := valid
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Value_Matrix_T(Input_Values-1 downto 0, Filter_Rows-1 downto 0, Filter_Columns-1 downto 0) := (others => (others => (others => 0)))
        );
    END COMPONENT;
    
    COMPONENT CNN_Column_Buffer IS
        GENERIC (
            Input_Columns  : NATURAL := 28;
            Input_Values   : NATURAL := 1;
            Filter_Columns : NATURAL := 3;
            Strides        : NATURAL := 1;
            Padding        : Padding_T := valid
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Value_Matrix_T(Input_Values-1 downto 0, 0 downto 0, Filter_Columns-1 downto 0)
        );
    END COMPONENT;
    
BEGIN
    
    --Save the last image rows and return the data to calculate the pooling maxtrix
    Generate1 : if Filter_Rows > 1 GENERATE
        CNN_Row_Buffer_Parallel1 : CNN_Row_Buffer_Parallel
        GENERIC MAP (
            Input_Columns  => Input_Columns,
            Input_Rows     => Input_Rows,
            Input_Values   => Input_Values,
            Filter_Columns => Filter_Columns,
            Filter_Rows    => Filter_Rows,
            Strides        => Strides,
            Padding        => Padding
        ) PORT MAP (
            iStream        => iStream,
            iData          => iData,
            oStream        => Matrix_Stream,
            oData          => Matrix_Data
        );
    END GENERATE Generate1;
    
    --If there is only one row, just the last column is saved
    Generate2 : if Filter_Rows = 1 GENERATE
        CNN_Column_Buffer1 : CNN_Column_Buffer
        GENERIC MAP (
            Input_Columns  => Input_Columns,
            Input_Values   => Input_Values,
            Filter_Columns => Filter_Columns,
            Strides        => Strides,
            Padding        => Padding
        ) PORT MAP (
            iStream        => iStream,
            iData          => iData,
            oStream        => Matrix_Stream,
            oData          => Matrix_Data
        );
    END GENERATE Generate2;
    
    oStream.Data_CLK <= Matrix_Stream.Data_CLK;
    
    --Takes the matrix of values from the last convolution and calculates the maximum for each filter output
    
    PROCESS (Matrix_Stream)
    VARIABLE max : CNN_Value_T := 0; --Current Values from row buffer to caclulate max value
    BEGIN
        IF (rising_edge(Matrix_Stream.Data_CLK)) THEN
            
            --Get maximum value for each Filter of last convolution
            FOR input in 0 to Input_Values-1 LOOP
                max := Matrix_Data(input, 0, 0);
                --Look for maximum value in all columns and rows
                FOR x in 0 to Filter_Columns-1 LOOP
                    FOR y in 0 to Filter_Rows-1 LOOP
                        IF (Matrix_Data(input, y, x) > max) THEN
                            max := Matrix_Data(input, y, x);
                        END IF;
                    END LOOP;
                END LOOP;
                
                --Set output data
                oData(input) <= max;
            END LOOP;
            
            --Set output stream
            oStream.Column     <= Matrix_Stream.Column;
            oStream.Row        <= Matrix_Stream.Row;
            oStream.Data_Valid <= Matrix_Stream.Data_Valid;
        END IF;
    END PROCESS;
    
END BEHAVIORAL;