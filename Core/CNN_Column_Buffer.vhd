
--Description: -This component buffers last values in row
--Insertion:   -Set the parameters according to the cnn data package

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;

ENTITY CNN_Column_Buffer IS
    GENERIC (
        Input_Columns  : NATURAL := 28; --Size in x direction of input
        Input_Values   : NATURAL := 1;  --Number of Filters in previous layer or 3 for RGB input
        Filter_Columns : NATURAL := 3;  --Size in x direction of filters
        Strides        : NATURAL := 1;  --1 = Output every value, 2 = Skip every second value
        Padding        : Padding_T := valid --valid = use available data, same = add padding to use data on the edge
    );
    PORT (
        CLK : IN STD_LOGIC;
        iStream : IN  CNN_Stream_T;
        iData   : IN  CNN_Values_T(Input_Values-1 downto 0);
        oStream : OUT CNN_Stream_T;
        oData   : OUT CNN_Value_Matrix_T(Input_Values-1 downto 0, 0 downto 0, Filter_Columns-1 downto 0) --[0, 1, 2] <- lowest colum index is oldest data
    );
END CNN_Column_Buffer;

ARCHITECTURE BEHAVIORAL OF CNN_Column_Buffer IS
    type Value_RAM_T is array (Filter_Columns-1 downto 0) of CNN_Values_T(Input_Values-1 downto 0);
    SIGNAL Value_Out : Value_RAM_T;
BEGIN
    
    --Output same data as input
    Generate1 : if Filter_Columns = 1 GENERATE
        
        oStream <= iStream;
        Generate2 : For i in 0 to Input_Values-1 GENERATE
            oData(i,0,0) <= iData(i);
        END GENERATE Generate2;
        
    END GENERATE Generate1;
    
    Generate3 : if Filter_Columns > 1 GENERATE
        
        oStream.Data_CLK <= iStream.Data_CLK;             --Same clock
        Generate4 : For i in 0 to Input_Values-1 GENERATE --Output Data from Buffer as matrix
            Generate5 : For j in 0 to Filter_Columns-1 GENERATE
                oData(i,0,Filter_Columns-1-j) <= Value_Out(j)(i);
            END GENERATE Generate5;
        END GENERATE Generate4;
        
        PROCESS (iStream)
        VARIABLE Value_Buf : Value_RAM_T;
        VARIABLE Valid_Delay : NATURAL range 0 to Filter_Columns/2 := 0;
        BEGIN
        IF (rising_edge(iStream.Data_CLK)) THEN
            oStream.Data_Valid <= '0';
            IF (iStream.Data_Valid = '1') THEN
                Value_Buf := Value_Buf(Filter_Columns-2 downto 0) & iData; --Always save the last data
                IF (Padding = valid) THEN
                    IF (iStream.Column >= Filter_Columns-1) THEN           --Without padding, start output when ram full
                        oStream.Column     <= iStream.Column - (Filter_Columns-1);
                        oStream.Row        <= iStream.Row;
                        oStream.Data_Valid <= '1';
                        Value_Out          <= Value_Buf;
                    END IF;
                END IF;
            END IF;
            
            IF (Padding = same) THEN
                --With padding, start output when half of ram full
                IF ((iStream.Data_Valid = '1' AND iStream.Column >= (Filter_Columns-1)/2) OR Valid_Delay > 0) THEN
                    
                    IF (iStream.Data_Valid = '1' AND iStream.Column >= (Filter_Columns-1)/2) THEN
                        --Create column while input valid
                        Valid_Delay := (Filter_Columns-1)/2;
                        oStream.Column     <= iStream.Column - Valid_Delay;
                    ELSE
                        --Create column after last column received
                        oStream.Column     <= Input_Columns - Valid_Delay;
                        Valid_Delay := Valid_Delay - 1;
                    END IF;
                    
                    oStream.Row        <= iStream.Row;
                    oStream.Data_Valid <= '1';
                    Value_Out <= (others => (others => 0));
                    
                    IF (iStream.Column < Filter_Columns-1 AND iStream.Column >= (Filter_Columns-1)/2) THEN
                        --set data while ram not full
                        Value_Out(iStream.Column downto 0) <= Value_Buf(iStream.Column downto 0);
                    ELSE
                        --set data while input valid and while sending last data with padding
                        Value_Out(Filter_Columns-1 downto (Filter_Columns-1)/2-Valid_Delay) <= Value_Buf(Filter_Columns/2+Valid_Delay downto 0);
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
END GENERATE Generate3;

END BEHAVIORAL;