
--Description: -This component buffers rows to output a matrix
--             -Output: For Columns and Rows lower number = older data
--              00, 01, 02
--              10, 11, 12
--              20, 21, 22

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;

ENTITY CNN_Row_Buffer_Parallel IS
    GENERIC (
        Input_Columns  : NATURAL := 28; --Size in x direction of input
        Input_Rows     : NATURAL := 28; --Size in y direction of input
        Input_Values   : NATURAL := 1;  --Number of Filters in previous layer or 3 for RGB input
        Filter_Columns : NATURAL := 3;  --Size in x direction of filters
        Filter_Rows    : NATURAL := 3;  --Size in y direction of filters
        Strides        : NATURAL := 1;  --1 = Output every value, 2 = Skip every second value
        Padding        : Padding_T := valid --valid = use available data, same = add padding to use data on the edge
    );
    PORT (
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
        
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Value_Matrix_T(Input_Values-1 downto 0, Filter_Rows-1 downto 0, Filter_Columns-1 downto 0) := (others => (others => (others => 0)))
    );
END CNN_Row_Buffer_Parallel;

ARCHITECTURE BEHAVIORAL OF CNN_Row_Buffer_Parallel IS

    type Value_Row_T is array (Filter_Rows-1 downto 0) of CNN_Values_T(Input_Values-1 downto 0);
    type Value_Matrix_T is array (Filter_Columns-1 downto 0) of Value_Row_T;
    
    type RAM_T is array (Input_Values-1 downto 0, 0 to Input_Columns-1, 0 to Filter_Rows-2) of STD_LOGIC_VECTOR(CNN_Value_Resolution+CNN_Value_Negative-1 downto 0);
    SIGNAL ROW_RAM : RAM_T;
    
BEGIN

    oStream.Data_CLK <= iStream.Data_CLK;
    
    PROCESS (iStream)
    VARIABLE iStream_Row_Reg    : NATURAL range 0 to CNN_Input_Rows-1 := 0;  --Last input row to detect a change
    VARIABLE RAM_In_Row         : NATURAL range 0 to Filter_Rows-2;       --Current row in the RAM that is written to
    VARIABLE Row_Offset         : NATURAL range 0 to Filter_Rows-2 := 0;  --Matrix Row that is calculated from the current row in the RAM that is written to
    
    VARIABLE iData_Reg          : CNN_Values_T(Input_Values-1 downto 0);  --Data that is written in the RAM
    VARIABLE iStream_Column_Reg : NATURAL range 0 to Input_Columns-1;     --Column as RAM input adress
    VARIABLE RAM_In_Row_Reg     : NATURAL range 0 to Filter_Rows-2;       --Row as RAM input adress
    
    VARIABLE Current_Column     : Value_Row_T;    --Values from RAM at same comlumn like the input data and from the last rows
    VARIABLE Current_Matrix     : Value_Matrix_T; --Lasts colums to get the current matrix that is used for a convolution or pooling
    VARIABLE Current_Matrix_Reg : Value_Matrix_T; --Current_Matrix with padding
    
    VARIABLE Valid_Reg          : STD_LOGIC;      --Saves if the output data is valid depending on new input data and the padding type
    VARIABLE Out_Column_Center  : NATURAL range 0 to CNN_Input_Columns-1; --Column of current matrix (Center of matrix in input image)
    VARIABLE Out_Row_Center     : NATURAL range 0 to CNN_Input_Rows-1;    --Row of current matrix (Center of matrix in input image)
    
    --Counters for lasts rows and columns if the input data starts with a new image
    VARIABLE Last_Columns_Delay : NATURAL range 0 to Filter_Columns/2 := Filter_Columns/2;
    VARIABLE Last_Row_Delay     : NATURAL range 0 to Filter_Rows/2 := 0;
    VARIABLE Last_Row_Delay_Reg : NATURAL range 0 to Filter_Rows/2 := 0;
    
    VARIABLE iStream_Row_Valid_Reg : NATURAL range 0 to CNN_Input_Rows-1 := 0; --Last input row to detect a change if the data is valid
    VARIABLE Row_Min            : NATURAL range 0 to Filter_Rows-1; --Start of data that is valid in the matrix
    VARIABLE Last_iStream_Row   : NATURAL range 0 to Input_Rows-1;  --Calculated row that came before the current row
    BEGIN
        IF (rising_edge(iStream.Data_CLK)) THEN
            
            --Count through rows in RAM for current row to be saved
            IF (iStream_Row_Reg /= iStream.Row) THEN
                IF (RAM_In_Row < Filter_Rows-2) THEN
                    RAM_In_Row := RAM_In_Row + 1;
                ELSE
                    RAM_In_Row := 0;
                END IF;
            END IF;

            Valid_Reg := '0';
            
            --Load output data when the input data is valid
            IF (iStream.Data_Valid = '1') THEN
                
                --Load values from RAM at same comlumn like the input data and from the last rows
                FOR i in 0 to Input_Values-1 LOOP
                    FOR j in 0 to Filter_Rows-2 LOOP
                        Row_Offset := (j+Filter_Rows-1-RAM_In_Row) mod (Filter_Rows-1);
                        IF (CNN_Value_Negative = 0) THEN
                            Current_Column(Row_Offset)(i) := TO_INTEGER(UNSIGNED(ROW_RAM(i, iStream.Column, j)));
                        ELSE
                            Current_Column(Row_Offset)(i) := TO_INTEGER(SIGNED(ROW_RAM(i, iStream.Column, j)));
                        END IF;
                    END LOOP;
                    Current_Column(Filter_Rows-1)(i) := iData(i);
                END LOOP;
                
                --Save the values from the lasts columns to get the matrix for the convolution
                Current_Matrix := Current_Matrix(Filter_Columns-2 downto 0) & Current_Column;
                
                --Correct column and row by rows and columns that are ignored with the missing padding
                IF (Padding = valid) THEN
                    IF (iStream.Column >= Filter_Columns-1 AND iStream.Row >= Filter_Rows-1) THEN
                        Out_Column_Center  := iStream.Column - (Filter_Columns-1);
                        Out_Row_Center     := iStream.Row - (Filter_Rows-1);
                        Valid_Reg          := '1';
                        Current_Matrix_Reg := Current_Matrix;
                    END IF;
                END IF;

                --Buffer data to allways set the RAM, even if the input isn't valid
                iData_Reg          := iData;
                iStream_Column_Reg := iStream.Column;
                RAM_In_Row_Reg     := RAM_In_Row;
            END IF;
            
            --Save current input data in RAM
            FOR i in 0 to Input_Values-1 LOOP
                IF (CNN_Value_Negative = 0) THEN
                    ROW_RAM(i, iStream_Column_Reg,RAM_In_Row_Reg) <= STD_LOGIC_VECTOR(TO_UNSIGNED(iData_Reg(i), CNN_Value_Resolution));
                ELSE
                    ROW_RAM(i, iStream_Column_Reg,RAM_In_Row_Reg) <= STD_LOGIC_VECTOR(TO_SIGNED(iData_Reg(i), CNN_Value_Resolution+CNN_Value_Negative));
                END IF;
            END LOOP;
            
            IF (Padding = same) THEN
                IF (iStream.Data_Valid = '1') THEN
                    --Count through the last columns if the new input column started
                    IF (iStream.Column >= (Filter_Columns-1)/2) THEN
                        Last_Columns_Delay := (Filter_Columns-1)/2;
                        Out_Column_Center  := iStream.Column - Last_Columns_Delay;
                    ELSE
                        Out_Column_Center  := Input_Columns - Last_Columns_Delay;
                        Last_Columns_Delay := Last_Columns_Delay - 1;
                    END IF;
                    
                    Last_Row_Delay_Reg := Last_Row_Delay;
                    
                    --Count through last rows if the new input image started
                    IF (iStream.Row >= (Filter_Rows-1)/2) THEN
                        Last_Row_Delay     := (Filter_Rows-1)/2;
                        IF (iStream.Column >= (Filter_Columns-1)/2) THEN
                            Out_Row_Center       := iStream.Row - Last_Row_Delay;
                        END IF;
                    ELSE
                        IF (iStream_Row_Valid_Reg /= iStream.Row) THEN
                            Last_Row_Delay     := Last_Row_Delay - 1;
                        END IF;
                        IF (iStream.Column >= (Filter_Columns-1)/2) THEN
                            Out_Row_Center       := Input_Rows-1 - Last_Row_Delay;
                        END IF;
                    END IF;
                    
                    iStream_Row_Valid_Reg := iStream.Row;
                    Valid_Reg             := '1';
                    
                    --First set everything to 0 for 0 padding
                    Current_Matrix_Reg    := (others => (others => (others => 0)));

                    Row_Min   := 0;

                    Last_iStream_Row := iStream.Row;
                    
                    --Set the matrix, only where the data is valid. Other values are 0
                    IF (iStream.Column < (Filter_Columns-1)/2) THEN
                        IF (Last_iStream_Row > 0) THEN
                            Last_iStream_Row := Last_iStream_Row - 1;
                        ELSE
                            Last_iStream_Row := Input_Rows-1;
                        END IF;
                    END IF;
                    
                    IF (Last_iStream_Row < Filter_Rows-1 AND Last_iStream_Row >= (Filter_Rows-1)/2) THEN
                        Row_Min   := Filter_Rows-1-Last_iStream_Row;
                    END IF;
                    
                    IF (iStream.Column < Filter_Columns-1 AND iStream.Column >= (Filter_Columns-1)/2) THEN
                        FOR i in 0 to Filter_Columns-1 LOOP
                            IF (i <= iStream.Column) THEN
                                Current_Matrix_Reg(i)(Filter_Rows/2+Last_Row_Delay_Reg downto Row_Min) := Current_Matrix(i)(Filter_Rows/2+Last_Row_Delay_Reg downto Row_Min);
                            END IF;
                        END LOOP;
                    ELSE
                        FOR i in 0 to Filter_Columns-1 LOOP
                            IF (i >= (Filter_Columns-1)/2-Last_Columns_Delay) THEN
                                Current_Matrix_Reg(i)(Filter_Rows/2+Last_Row_Delay_Reg downto Row_Min) := Current_Matrix(i)(Filter_Rows/2+Last_Row_Delay_Reg downto Row_Min);
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            END IF;
            
            --Set Output data
            IF (Out_Column_Center mod Strides = 0 AND Out_Row_Center mod Strides = 0) THEN
                oStream.Column <= Out_Column_Center/Strides;
                oStream.Row    <= Out_Row_Center/Strides;
                oStream.Data_Valid <= Valid_Reg;
                IF (Valid_Reg = '1') THEN
                    FOR i in 0 to Input_Values-1 LOOP
                        FOR j in 0 to Filter_Rows-1 LOOP
                            FOR k in 0 to Filter_Columns-1 LOOP
                                oData(i,j,Filter_Columns-1-k) <= Current_Matrix_Reg(k)(j)(i);
                            END LOOP;
                        END LOOP;
                    END LOOP;
                END IF;
            ELSE
                oStream.Data_Valid <= '0';
            END IF;
            
            iStream_Row_Reg := iStream.Row;
        END IF;
    END PROCESS;
    
END BEHAVIORAL;