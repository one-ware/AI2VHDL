
--Description: -This component calculates the outputs for one dense neural network layer
--Insertion:   -Specify the paramters with the constants in th CNN_Data file
--             -Connect the Cycle_Reg data and stream signal with the Cycle_Reg or previous layer

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.CNN_Config_Package.all;

ENTITY NN_Layer_Parallel IS
    GENERIC (
        Inputs         : NATURAL := 16;
        Outputs        : NATURAL := 8;
        Activation     : Activation_T := relu;  --Activation after dot product
        Offset         : INTEGER := 0;
        Weights        : CNN_Weights_T
    );
    PORT (
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Inputs-1 downto 0);
        
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Values_T(Outputs-1 downto 0) := (others => 0)
    );
END NN_Layer_Parallel;

ARCHITECTURE BEHAVIORAL OF NN_Layer_Parallel IS

    CONSTANT value_max     : NATURAL := 2**(CNN_Value_Resolution)-1;
    CONSTANT sum_max       : NATURAL := value_max * 2**(max_val(Offset, 0)) * (Inputs + 1);
    
BEGIN

    oStream.Data_CLK <= iStream.Data_CLK;
    
    PROCESS (iStream)
    VARIABLE sum : INTEGER range (-1)*sum_max to sum_max;
    BEGIN
        IF (rising_edge(iStream.Data_CLK)) THEN
            FOR filter in 0 to Outputs-1 LOOP
                sum := 0;
                
                --Calculate sum with all inputs and for this output
                FOR input in 0 to Inputs-1 LOOP
                    sum := sum + to_integer(shift_right(to_signed(iData(input) * Weights(filter, input), CNN_Value_Resolution+CNN_Weight_Resolution), CNN_Weight_Resolution-Offset-1));
                END LOOP;
                
                --Add Bias
                IF (Offset >= 0) THEN
                    sum := sum + to_integer(shift_left (to_signed(Weights(filter, Inputs), CNN_Weight_Resolution+Offset), Offset));
                ELSE
                    sum := sum + to_integer(shift_right(to_signed(Weights(filter, Inputs), CNN_Weight_Resolution), abs(Offset)));
                END IF;
                
                --Apply Activation
                IF (Activation = relu) THEN
                    oData(filter) <= relu_f(sum, value_max);
                ELSIF (Activation = linear) THEN
                    oData(filter) <= linear_f(sum, value_max);
                ELSIF (Activation = leaky_relu) THEN
                    oData(filter) <= leaky_relu_f(sum, value_max, integer(ceil(log2(real(sum_max)))));
                ELSIF (Activation = step_func) THEN
                    oData(filter) <= step_f(sum);
                ELSIF (Activation = sign_func) THEN
                    oData(filter) <= sign_f(sum);
                END IF;
            END LOOP;
            
            --Set output data
            oStream.Data_Valid <= iStream.Data_Valid;
        END IF;
    END PROCESS;
    
END BEHAVIORAL;