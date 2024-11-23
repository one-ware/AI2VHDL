
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;
use work.CNN_Data_Package.all;


ENTITY CNN IS
    PORT (
        CLK : IN STD_LOGIC;
        iStream     : CNN_Stream_T;
        iData       : CNN_Values_T(0 downto 0);

        Prediction  : OUT NATURAL range 0 to NN_Layer_1_Outputs-1;
        Probability : OUT CNN_Value_T;
        Update      : OUT STD_LOGIC
    );
END CNN;

ARCHITECTURE BEHAVIORAL OF CNN IS

    SIGNAL oStream_12 : CNN_Stream_T;
    SIGNAL oData_12   : CNN_Values_T(Layer_1_Filters/4-1 downto 0);
    SIGNAL oStream_P12 : CNN_Stream_T;
    SIGNAL oData_P12   : CNN_Values_T(Pooling_1_Values/4-1 downto 0);
    SIGNAL oStream_22 : CNN_Stream_T;
    SIGNAL oData_22   : CNN_Values_T(Layer_2_Filters/6-1 downto 0);
    SIGNAL oStream_P22 : CNN_Stream_T;
    SIGNAL oData_P22   : CNN_Values_T(Pooling_2_Values/6-1 downto 0);
    SIGNAL oStream_32 : CNN_Stream_T;
    SIGNAL oData_32   : CNN_Values_T(Layer_3_Filters/8-1 downto 0);
    SIGNAL oStream_P32 : CNN_Stream_T;
    SIGNAL oData_P32   : CNN_Values_T(Pooling_3_Values/8-1 downto 0);
    SIGNAL oStream_F : CNN_Stream_T;
    SIGNAL oData_F   : CNN_Values_T(0 downto 0);
    SIGNAL iStream_1N : CNN_Stream_T;
    SIGNAL iData_1N   : CNN_Values_T(0 downto 0);
    SIGNAL oStream_1N : CNN_Stream_T;
    SIGNAL oData_1N  : CNN_Values_T(NN_Layer_1_Outputs/10-1 downto 0);
    SIGNAL iCycle_1N : NATURAL range 0 to Flatten_Columns*Flatten_Rows*8 - 1;
    SIGNAL oCycle_1N : NATURAL range 0 to NN_Layer_1_Outputs-1;

    COMPONENT CNN_Convolution IS
        GENERIC (
            Input_Columns  : NATURAL := 28;
            Input_Rows     : NATURAL := 28;
            Input_Values   : NATURAL := 1;
            Filter_Columns : NATURAL := 3;
            Filter_Rows    : NATURAL := 3;
            Filters        : NATURAL := 4;
            Strides        : NATURAL := 1;
            Activation     : Activation_T := relu;
            Padding        : Padding_T := valid;
            Input_Cycles   : NATURAL := 1;
            Value_Cycles   : NATURAL := 1;
            Calc_Cycles    : NATURAL := 1;
            Filter_Cycles  : NATURAL := 1;
            Filter_Delay   : NATURAL := 1;
            Expand         : BOOLEAN := true;
            Expand_Cycles  : NATURAL := 0;
            Offset_In       : NATURAL := 0;
            Offset_Out      : NATURAL := 0;
            Offset         : INTEGER := 0;
            Weights        : CNN_Weights_T
            
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values/Input_Cycles-1 downto 0);
            
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Values_T(Filters/Filter_Cycles-1 downto 0) := (others => 0)
            
        );
    END COMPONENT;

    COMPONENT CNN_Pooling_Efficient IS
        GENERIC (
            Input_Columns  : NATURAL := 28; --Size in x direction of input
            Input_Rows     : NATURAL := 28; --Size in y direction of input
            Input_Values   : NATURAL := 1;  --Number of Filters in previous layer or 3 for RGB input
            Filter_Columns : NATURAL := 3;  --Size in x direction of filters
            Filter_Rows    : NATURAL := 3;  --Size in y direction of filters
            Input_Cycles   : NATURAL := 1;  --Filter Cycles of previous convolution
            Filter_Delay   : NATURAL := 1   --Cycles between Filters
            
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Input_Values/Input_Cycles-1 downto 0);
            
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Values_T(Input_Values/Input_Cycles-1 downto 0) := (others => 0)
            
        );
    END COMPONENT;

    COMPONENT NN_Layer IS
        GENERIC (
            Inputs          : NATURAL := 16;
            Outputs         : NATURAL := 8;
            Activation      : Activation_T := relu;
            Input_Cycles    : NATURAL := 1;
            Calc_Cycles     : NATURAL := 1;
            Output_Cycles   : NATURAL := 1;
            Output_Delay    : NATURAL := 1;
            Offset_In       : NATURAL := 0;
            Offset_Out      : NATURAL := 0;
            Offset          : INTEGER := 0;
            Weights         : CNN_Weights_T
            
        );
        PORT (
            iStream : IN  CNN_Stream_T;
            iData   : IN  CNN_Values_T(Inputs/Input_Cycles-1 downto 0);
            iCycle  : IN  NATURAL range 0 to Input_Cycles-1;
            
            oStream : OUT CNN_Stream_T;
            oData   : OUT CNN_Values_T(Outputs/Output_Cycles-1 downto 0) := (others => 0);
            oCycle  : OUT NATURAL range 0 to Output_Cycles-1
            
        );
    END COMPONENT;
    
BEGIN

    CNN_Convolution1 : CNN_Convolution
    GENERIC MAP (
        Input_Columns  => Layer_1_Columns,
        Input_Rows     => Layer_1_Rows,
        Input_Values   => Layer_1_Values,
        Filter_Columns => Layer_1_Filter_X,
        Filter_Rows    => Layer_1_Filter_Y,
        Filters        => Layer_1_Filters,
        Strides        => Layer_1_Strides,
        Activation     => Layer_1_Activation,
        Padding        => Layer_1_Padding,
        Value_Cycles   => 1,
        Calc_Cycles    => 4,
        Filter_Cycles  => 4,
        Expand_Cycles  => 56, -- 224/4
        Offset_In      => 0,
        Offset_Out     => Layer_1_Out_Offset-3,
        Offset         => Layer_1_Offset,
        Weights        => Layer_1
    ) PORT MAP (
        iStream        => iStream,
        iData          => iData,
        oStream        => oStream_12,
        oData          => oData_12
    );
    
    CNN_Pooling1 : CNN_Pooling_Efficient
    GENERIC MAP (
        Input_Columns  => Pooling_1_Columns,
        Input_Rows     => Pooling_1_Rows,
        Input_Values   => Pooling_1_Values,
        Filter_Columns => Pooling_1_Filter_X,
        Filter_Rows    => Pooling_1_Filter_Y,
        Input_Cycles   => 4,
        Filter_Delay   => 1
    ) PORT MAP (
        iStream        => oStream_12,
        iData          => oData_12,
        oStream        => oStream_P12,
        oData          => oData_P12
    );
    
    CNN_Convolution2 : CNN_Convolution
    GENERIC MAP (
        Input_Columns  => Layer_2_Columns,
        Input_Rows     => Layer_2_Rows,
        Input_Values   => Layer_2_Values,
        Filter_Columns => Layer_2_Filter_X,
        Filter_Rows    => Layer_2_Filter_Y,
        Filters        => Layer_2_Filters,
        Strides        => Layer_2_Strides,
        Activation     => Layer_2_Activation,
        Padding        => Layer_2_Padding,
        Input_Cycles   => 4,
        Value_Cycles   => 4,
        Calc_Cycles    => 6,
        Filter_Cycles  => 6,
        Expand_Cycles  => 224, -- 3*3*4*6 = 216 (224 for short delay) (most calculations per input from all layers)
        Offset_In      => Layer_1_Out_Offset,
        Offset_Out     => Layer_2_Out_Offset,
        Offset         => Layer_2_Offset,
        Weights        => Layer_2
    ) PORT MAP (
        iStream        => oStream_P12,
        iData          => oData_P12,
        oStream        => oStream_22,
        oData          => oData_22
    );
    
    CNN_Pooling2 : CNN_Pooling_Efficient
    GENERIC MAP (
        Input_Columns  => Pooling_2_Columns,
        Input_Rows     => Pooling_2_Rows,
        Input_Values   => Pooling_2_Values,
        Filter_Columns => Pooling_2_Filter_X,
        Filter_Rows    => Pooling_2_Filter_Y,
        Input_Cycles   => 6,
        Filter_Delay   => 1
    ) PORT MAP (
        iStream        => oStream_22,
        iData          => oData_22,
        oStream        => oStream_P22,
        oData          => oData_P22
    );
    
    CNN_Convolution3 : CNN_Convolution
    GENERIC MAP (
        Input_Columns  => Layer_3_Columns,
        Input_Rows     => Layer_3_Rows,
        Input_Values   => Layer_3_Values,
        Filter_Columns => Layer_3_Filter_X,
        Filter_Rows    => Layer_3_Filter_Y,
        Filters        => Layer_3_Filters,
        Strides        => Layer_3_Strides,
        Activation     => Layer_3_Activation,
        Padding        => Layer_3_Padding,
        Input_Cycles   => 6,
        Value_Cycles   => 6,
        Calc_Cycles    => 8,
        Filter_Cycles  => 8,
        Expand_Cycles  => 896, -- 4*224
        Offset_In      => Layer_2_Out_Offset,
        Offset_Out     => Layer_3_Out_Offset,
        Offset         => Layer_3_Offset,
        Weights        => Layer_3
    ) PORT MAP (
        iStream        => oStream_P22,
        iData          => oData_P22,
        oStream        => oStream_32,
        oData          => oData_32
    );
    
    CNN_Pooling3 : CNN_Pooling_Efficient
    GENERIC MAP (
        Input_Columns  => Pooling_3_Columns,
        Input_Rows     => Pooling_3_Rows,
        Input_Values   => Pooling_3_Values,
        Filter_Columns => Pooling_3_Filter_X,
        Filter_Rows    => Pooling_3_Filter_Y,
        Input_Cycles   => 8,
        Filter_Delay   => NN_Layer_1_Outputs
    ) PORT MAP (
        iStream        => oStream_32,
        iData          => oData_32,
        oStream        => oStream_P32,
        oData          => oData_P32
    );
    
    oStream_F <= oStream_P32;
    oData_F   <= oData_P32;

    PROCESS (oStream_F)
    BEGIN
        IF (rising_edge(oStream_F.Data_CLK)) THEN
            iCycle_1N             <= (oStream_F.Row*Flatten_Columns+oStream_F.Column)*Flatten_Values + oStream_F.Filter;
            iStream_1N.Data_Valid <= oStream_F.Data_Valid;
            iData_1N              <= oData_F;
        END IF;
    END PROCESS;

    
    iStream_1N.Data_CLK <= oStream_F.Data_CLK;
    
    NN_Layer1 : NN_Layer
    GENERIC MAP (
        Inputs          => NN_Layer_1_Inputs,
        Outputs         => NN_Layer_1_Outputs,
        Activation      => NN_Layer_1_Activation,
        Input_Cycles    => Flatten_Columns*Flatten_Rows*8,
        Calc_Cycles     => NN_Layer_1_Outputs,
        Output_Cycles   => NN_Layer_1_Outputs,
        Offset_In       => Layer_3_Out_Offset,
        Offset_Out      => NN_Layer_1_Out_Offset,
        Offset          => NN_Layer_1_Offset,
        Weights         => NN_Layer_1
    ) PORT MAP (
        iStream         => iStream_1N,
        iData           => iData_1N,
        iCycle          => iCycle_1N,
        oStream         => oStream_1N,
        oData           => oData_1N,
        oCycle          => oCycle_1N
    );
    
    PROCESS (oStream_1N)
    VARIABLE max        : CNN_Value_T;
    VARIABLE max_number : NATURAL range 0 to NN_Layer_1_Outputs-1;
    BEGIN
        IF (rising_edge(oStream_1N.Data_CLK)) THEN
            IF (oStream_1N.Data_Valid = '1') THEN
                IF (oCycle_1N = 0) THEN
                    max := 0;
                    max_number := 0;
                END IF;
                IF (oData_1N(0) > max) THEN
                    max        := oData_1N(0);
                    max_number := oCycle_1N;
                END IF;
                IF (oCycle_1N = NN_Layer_1_Outputs-1) THEN
                    Prediction   <= max_number;
                    Probability  <= max;
                    Update       <= '1';
                END IF;
            ELSE
                Update       <= '0';
            END IF;
        END IF;
    END PROCESS;
    
END BEHAVIORAL;