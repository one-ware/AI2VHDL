library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.CNN_Config_Package.ALL;
use work.CNN_Data_Package.ALL;
use work.Test_Image_Package.all;

ENTITY MNIST_Simulation IS
END MNIST_Simulation;

ARCHITECTURE behavior OF MNIST_Simulation IS

    -- Component declaration for the CNN
    COMPONENT CNN
    PORT (
        CLK : IN STD_LOGIC;
        iStream : IN CNN_Stream_T;
        iData : IN CNN_Values_T(0 downto 0);
        Prediction : OUT NATURAL range 0 to NN_Layer_1_Outputs-1;
        Probability : OUT CNN_Value_T;
        Update : OUT STD_LOGIC
    );
END COMPONENT;

    -- Signals for the CNN inputs and outputs
SIGNAL CLK : STD_LOGIC := '0';
SIGNAL iStream : CNN_Stream_T;
SIGNAL iData : CNN_Values_T(0 downto 0);
SIGNAL Prediction : NATURAL range 0 to NN_Layer_1_Outputs-1;
SIGNAL Probability : CNN_Value_T;
SIGNAL Update : STD_LOGIC;

    -- Clock period definition
CONSTANT clk_period : time := 10 ns;

BEGIN

    -- Instantiate the CNN component
    uut: CNN
    PORT MAP (
        CLK => CLK,
        iStream => iStream,
        iData => iData,
        Prediction => Prediction,
        Probability => Probability,
        Update => Update
    );

    -- Clock process definitions
    clk_process :process
    begin
        CLK <= '0';
        wait for clk_period/2;
        CLK <= '1';
        wait for clk_period/2;
    end process;
    
    iStream.Data_CLK <= CLK;

    -- Stimulus process
    stim_proc: process
    begin
        for i in 0 to 3 loop
            -- Initialize inputs
            iStream.Data_Valid <= '0';
            iStream.Row <= 0;
            iStream.Column <= 0;
            iStream.Filter <= 0;
            iData(0) <= 0;
            
            -- Wait for global reset
            wait for 1000 ns;
            
            -- Apply test stimulus
            for row in 0 to 27 loop
                for col in 0 to 27 loop
                    
                    iStream.Data_Valid <= '1';
                    iStream.Row <= row;
                    iStream.Column <= col;
                    iStream.Filter <= 0;
                    iData(0) <= Image_Example(row, col); -- Example data
                    wait for clk_period;
                    iStream.Data_Valid <= '0';
                    wait for clk_period;
                    
                    -- Introduce a delay of 64 clock cycles
                    for i in 0 to 64 loop
                        wait for clk_period;
                    end loop;
                end loop;
            end loop;
            
        end loop;

        -- End simulation
        wait;
    end process;

END behavior;