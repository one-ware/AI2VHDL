
--    Description: -This component calculates the outputs for one convolution layer
--    
--    Insertion:   -Specify the paramters with the constants in th CNN_Data file
--                 -Connect the input data and stream signal with the input or previous layer

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.CNN_Config_Package.all;

ENTITY CNN_Convolution_Parallel IS
    GENERIC (
        Input_Columns  : NATURAL := 28; --Size in x direction of input
        Input_Rows     : NATURAL := 28; --Size in y direction of input
        Input_Values   : NATURAL := 1;  --Number of Filters in previous layer or 3 for RGB input
        Filter_Columns : NATURAL := 3;  --Size in x direction of filters
        Filter_Rows    : NATURAL := 3;  --Size in y direction of filters
        Filters        : NATURAL := 4;  --Number of filters in this layer
        Strides        : NATURAL := 1;  --1 = Output every value, 2 = Skip every second value
        Activation     : Activation_T := relu; --Activation after dot product
        Padding        : Padding_T := valid;   --valid = use available data, same = add padding to use data on the edge
        Prunning_Limit : NATURAL := 0;  --Set parameters to 0 below this value to reduce needed calculations
        Offset         : INTEGER := 0;
        Weights        : CNN_Weights_T
    );
    PORT (
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
        
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Values_T(Filters-1 downto 0) := (others => 0)
    );
END CNN_Convolution_Parallel;

ARCHITECTURE BEHAVIORAL OF CNN_Convolution_Parallel IS

    SIGNAL Matrix_Stream : CNN_Stream_T;
    SIGNAL Matrix_Data   : CNN_Value_Matrix_T(Input_Values-1 downto 0, Filter_Rows-1 downto 0, Filter_Columns-1 downto 0);
    
    CONSTANT matrix_values : NATURAL := Filter_Columns * Filter_Rows;
    CONSTANT value_max     : NATURAL := 2**(CNN_Value_Resolution)-1; --128 = 1 for floating point, but outputs are from 0 to 255
    CONSTANT sum_max       : NATURAL := value_max * 2**(max_val(Offset, 0)) * (matrix_values * Input_Values + 1);
    
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
    
    --Save the last image rows and return the data to calculate the convolution maxtrix
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
    
    --Calculate convolution
    PROCESS (Matrix_Stream)
    VARIABLE sum : INTEGER range (-1)*sum_max to sum_max;
    BEGIN
        IF (rising_edge(Matrix_Stream.Data_CLK)) THEN
            
            --Calculates dot product for all filters and applies bias and activation function
            FOR f in 0 to Filters-1 LOOP
                sum := 0;
                
                --Calculate sum with all inputs, rows and columns of this convolution and for this filter
                FOR input in 0 to Input_Values-1 LOOP
                    FOR x in 0 to Filter_Columns-1 LOOP
                        FOR y in 0 to Filter_Rows-1 LOOP
                            sum := sum + to_integer(shift_right(to_signed(Matrix_Data(input, y, x) * Weights(f, y*Filter_Columns*Input_Values + x*Input_Values + input), CNN_Value_Resolution+CNN_Weight_Resolution), CNN_Weight_Resolution-Offset-1));
                        END LOOP;
                    END LOOP;
                END LOOP;
                
                --Add Bias
                IF (Offset >= 0) THEN
                    sum := sum + to_integer(shift_left (to_signed(Weights(f, matrix_values*Input_Values), CNN_Weight_Resolution+Offset), Offset));
                ELSE
                    sum := sum + to_integer(shift_right(to_signed(Weights(f, matrix_values*Input_Values), CNN_Weight_Resolution), abs(Offset)));
                END IF;
                
                --Apply Activation
                IF (Activation = relu) THEN
                    oData(f) <= relu_f(sum, value_max);
                ELSIF (Activation = linear) THEN
                    oData(f) <= linear_f(sum, value_max);
                ELSIF (Activation = leaky_relu) THEN
                    oData(f) <= leaky_relu_f(sum, value_max, integer(ceil(log2(real(sum_max)))));
                ELSIF (Activation = step_func) THEN
                    oData(f) <= step_f(sum);
                ELSIF (Activation = sign_func) THEN
                    oData(f) <= sign_f(sum);
                END IF;
            END LOOP;
            
            --Set output data
            oStream.Data_Valid <= Matrix_Stream.Data_Valid;
            oStream.Column     <= Matrix_Stream.Column;
            oStream.Row        <= Matrix_Stream.Row;
        END IF;
    END PROCESS;
    
END BEHAVIORAL;