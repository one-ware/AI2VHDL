
--Weights and parameters of neural network

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.CNN_Config_Package.all;

PACKAGE CNN_Data_Package is
    
    CONSTANT Layer_1_Columns    : NATURAL := 28;
    CONSTANT Layer_1_Rows       : NATURAL := 28;
    CONSTANT Layer_1_Strides    : NATURAL := 1;
    CONSTANT Layer_1_Activation : Activation_T := relu;
    CONSTANT Layer_1_Padding    : Padding_T := same;
    
    CONSTANT Layer_1_Values     : NATURAL := 1;
    CONSTANT Layer_1_Filter_X   : NATURAL := 3;
    CONSTANT Layer_1_Filter_Y   : NATURAL := 3;
    CONSTANT Layer_1_Filters    : NATURAL := 4;
    CONSTANT Layer_1_Inputs     : NATURAL := 10;
    CONSTANT Layer_1_Out_Offset : INTEGER := 3;
    CONSTANT Layer_1_Offset     : INTEGER := 1;
    CONSTANT Layer_1 : CNN_Weights_T(0 to Layer_1_Filters-1, 0 to Layer_1_Inputs-1) :=
    (
        (-6, -30, -13, 10, -47, -55, 28, 63, 52, -3),
        (-18, 14, 46, -10, -12, 33, 14, -2, 22, 0),
        (37, -8, -29, -45, -80, -26, -76, 58, 70, 1),
        (10, 1, -6, 1, 13, 25, 42, 38, 0, 2)
    );
    
    CONSTANT Pooling_1_Columns      : NATURAL := Layer_1_Columns;
    CONSTANT Pooling_1_Rows         : NATURAL := Layer_1_Rows;
    CONSTANT Pooling_1_Values       : NATURAL := Layer_1_Filters;
    CONSTANT Pooling_1_Filter_X     : NATURAL := 2;
    CONSTANT Pooling_1_Filter_Y     : NATURAL := Pooling_1_Filter_X;
    CONSTANT Pooling_1_Strides      : NATURAL := Pooling_1_Filter_X;
    CONSTANT Pooling_1_Padding      : Padding_T := valid;
    
    CONSTANT Layer_2_Columns        : NATURAL := Pooling_1_Columns/Pooling_1_Strides;
    CONSTANT Layer_2_Rows           : NATURAL := Pooling_1_Rows/Pooling_1_Strides;
    CONSTANT Layer_2_Strides        : NATURAL := 1;
    CONSTANT Layer_2_Activation     : Activation_T := relu;
    CONSTANT Layer_2_Padding        : Padding_T := same;
    
    CONSTANT Layer_2_Values     : NATURAL := 4;
    CONSTANT Layer_2_Filter_X   : NATURAL := 3;
    CONSTANT Layer_2_Filter_Y   : NATURAL := 3;
    CONSTANT Layer_2_Filters    : NATURAL := 6;
    CONSTANT Layer_2_Inputs     : NATURAL := 37;
    CONSTANT Layer_2_Out_Offset : INTEGER := 4;
    CONSTANT Layer_2_Offset     : INTEGER := 2;
    CONSTANT Layer_2 : CNN_Weights_T(0 to Layer_2_Filters-1, 0 to Layer_2_Inputs-1) :=
    (
        (10, 9, -10, 1, 6, 3, 1, 18, -6, 17, 20, 18, 20, -1, -15, -3, 28, 1, -7, 6, -3, -4, 21, -1, 20, -11, -12, -25, 20, -17, 11, -21, -9, -28, 24, -7, 1),
        (-2, -20, 25, -27, 28, -6, -18, -28, 7, 4, -21, -35, -4, -2, 8, 11, 9, 4, 3, 17, 9, -19, -14, 6, -17, 1, -15, -9, 2, 10, -13, -4, 6, 16, -20, 15, 0),
        (12, -5, -1, 0, 1, 4, -10, -1, -30, 14, 12, -2, 7, -2, -3, -14, -19, -12, 4, -3, -37, 19, 9, 5, -9, -12, 37, -4, -22, 1, -9, 3, -10, 26, -11, 17, -15),
        (-11, 3, 10, 8, -2, -13, -2, -5, -26, -21, -64, -20, -19, 27, 18, 2, -24, 6, -5, 7, -58, -13, -1, -3, -22, 23, 22, 21, -35, 13, 11, -6, -1, -17, 5, -9, 2),
        (-5, -8, -21, -8, 7, 7, -10, 7, -10, -24, 21, -21, 4, 5, 14, -7, -18, -20, 12, -22, -7, 3, 21, 7, -24, 13, 5, 9, -19, -2, 5, -13, 2, 17, 12, 22, 0),
        (2, 7, 4, -5, 17, 9, -20, -10, 9, -2, -17, -12, -1, -4, 16, -17, 3, -3, 13, 9, -2, 20, -3, 13, 16, 6, 4, 21, -3, -2, 24, 8, 1, 3, 8, -3, -28)
    );
    
    CONSTANT Pooling_2_Columns      : NATURAL := Layer_2_Columns;
    CONSTANT Pooling_2_Rows         : NATURAL := Layer_2_Rows;
    CONSTANT Pooling_2_Values       : NATURAL := Layer_2_Filters;
    CONSTANT Pooling_2_Filter_X     : NATURAL := 2;
    CONSTANT Pooling_2_Filter_Y     : NATURAL := Pooling_2_Filter_X;
    CONSTANT Pooling_2_Strides      : NATURAL := Pooling_2_Filter_X;
    CONSTANT Pooling_2_Padding      : Padding_T := valid;
    
    CONSTANT Layer_3_Columns        : NATURAL := Pooling_2_Columns/Pooling_2_Strides;
    CONSTANT Layer_3_Rows           : NATURAL := Pooling_2_Rows/Pooling_2_Strides;
    CONSTANT Layer_3_Strides        : NATURAL := 1;
    CONSTANT Layer_3_Activation     : Activation_T := relu;
    CONSTANT Layer_3_Padding        : Padding_T := same;
    
    CONSTANT Layer_3_Values     : NATURAL := 6;
    CONSTANT Layer_3_Filter_X   : NATURAL := 3;
    CONSTANT Layer_3_Filter_Y   : NATURAL := 3;
    CONSTANT Layer_3_Filters    : NATURAL := 8;
    CONSTANT Layer_3_Inputs     : NATURAL := 55;
    CONSTANT Layer_3_Out_Offset : INTEGER := 4;
    CONSTANT Layer_3_Offset     : INTEGER := 1;
    CONSTANT Layer_3 : CNN_Weights_T(0 to Layer_3_Filters-1, 0 to Layer_3_Inputs-1) :=
    (
        (7, -15, -19, -60, -19, 6, 10, 2, -32, -29, -55, -26, -20, 8, 3, -18, 24, -38, 2, -29, -52, -28, -29, 15, -24, -56, -2, 64, -15, 25, -4, -39, -34, 54, 13, -33, 51, -45, -47, -6, -22, -4, 23, -38, -17, 20, 19, 11, 4, -6, -27, 7, 30, 10, -2),
        (-7, 15, -2, -2, -32, -9, 6, -6, -18, -32, -84, -46, 16, -15, -14, -23, -45, 37, 31, 8, -1, -31, 31, -45, 40, 38, 1, -8, 6, -38, 16, -23, 27, 26, 8, -27, -21, 5, 0, -4, 30, -36, 3, 40, -3, 45, 28, -43, 13, 6, -2, 13, -11, -18, 1),
        (-21, 3, -4, 8, -6, 18, -6, 8, -23, 11, -27, -1, -4, 16, -9, 11, -10, -14, -27, -13, -19, -16, 3, 20, -2, 21, -6, -7, -15, -3, 19, 39, -17, -1, 9, -19, 21, 2, -22, -43, -7, 4, 26, 16, -27, -6, -30, 9, 41, 34, -30, 4, -25, 26, 2),
        (55, 21, -19, -1, -60, -6, 26, -12, -20, 3, 23, -1, 49, -38, -23, -14, -24, -45, -2, 2, -31, -75, -13, 4, -3, 23, -18, -29, 62, -10, -29, 5, -71, -43, 4, -1, -10, 18, -4, 19, 18, 6, -42, 10, 45, 11, 11, 4, -32, 0, -12, -40, 32, -11, -29),
        (-21, -21, -1, 37, 32, -8, 28, -9, -2, 49, -21, -14, 30, 32, 15, -8, -7, 1, 50, -35, -68, -6, -2, 9, -32, -15, -10, -50, 34, 2, -5, 38, -4, -7, 13, 18, -109, -50, -10, -42, 12, -43, -11, 3, -28, 14, 3, -29, 32, 35, 14, 26, 5, 14, -70),
        (-3, 28, -23, 35, 8, 21, -7, 7, 18, 19, 44, 15, -1, -27, 11, 46, 31, -2, -7, 11, -9, 11, -1, 27, -16, -27, 1, 22, 20, 27, -2, -18, -19, 15, 40, 5, -2, -9, -4, -25, -12, 1, -2, -25, -26, -41, 9, 19, 0, 1, -15, -23, 17, 10, -67),
        (12, -11, 18, 6, -7, -53, -37, 2, -4, 16, 6, 26, -24, -19, -26, -41, -2, 47, -58, -20, -24, 13, 20, -21, -50, -19, 34, 15, 31, 9, 13, -41, -25, 0, -9, -13, -19, -30, 10, 5, 33, -1, -19, -43, 18, 22, -17, -40, 23, 4, -34, 6, -98, 3, 16),
        (5, 27, -28, -13, -24, 15, -37, 8, 5, 2, -2, 22, -10, -34, 21, 15, -8, -19, 6, -10, -21, 0, -41, 10, -20, -28, 6, 29, -51, 18, 1, -34, 18, 13, -73, -15, -7, -40, 30, -7, -20, 14, 3, -51, 24, 10, -56, -10, 46, 2, 34, 22, -112, -23, -8)
    );
    
    CONSTANT Pooling_3_Columns      : NATURAL := Layer_3_Columns;
    CONSTANT Pooling_3_Rows         : NATURAL := Layer_3_Rows;
    CONSTANT Pooling_3_Values       : NATURAL := Layer_3_Filters;
    CONSTANT Pooling_3_Filter_X     : NATURAL := 2;
    CONSTANT Pooling_3_Filter_Y     : NATURAL := Pooling_3_Filter_X;
    CONSTANT Pooling_3_Strides      : NATURAL := Pooling_3_Filter_X;
    CONSTANT Pooling_3_Padding      : Padding_T := valid;
    
    CONSTANT Flatten_Columns      : NATURAL := Pooling_3_Columns/Pooling_3_Strides;
    CONSTANT Flatten_Rows         : NATURAL := Pooling_3_Rows/Pooling_3_Strides;
    CONSTANT Flatten_Values       : NATURAL := Pooling_3_Values;
    
    CONSTANT NN_Layer_1_Activation  : Activation_T := relu;
    
    CONSTANT NN_Layer_1_Inputs     : NATURAL := 72;
    CONSTANT NN_Layer_1_Outputs    : NATURAL := 10;
    CONSTANT NN_Layer_1_Out_Offset : INTEGER := 6;
    CONSTANT NN_Layer_1_Offset     : INTEGER := 2;
    CONSTANT NN_Layer_1 : CNN_Weights_T(0 to NN_Layer_1_Outputs-1, 0 to NN_Layer_1_Inputs) :=
    (
        (11, -24, 15, -8, -16, 8, 4, -12, 11, -16, 2, 11, -11, -9, 3, -5, -26, -1, -7, 3, 3, -27, 1, 7, 6, -38, 3, -11, -13, 9, 8, 15, -1, -9, 1, 11, -18, -5, 7, -5, -4, 5, -10, -24, 11, -14, -3, 5, -61, -6, 2, 8, -38, 10, -1, 27, -3, 9, 11, 19, -19, 7, -3, -13, 10, 8, -3, 19, 15, 29, -1, -25, -33),
        (-9, -2, 0, -12, 8, 2, -19, 3, 13, 21, -31, -4, 9, 11, 9, -2, -3, 6, -29, 6, 2, 0, 12, 4, 29, -12, 12, -9, 11, -11, -5, 10, -35, -6, -1, 7, 13, -5, 10, 8, -27, 8, -33, -6, 1, -8, 21, -6, 41, -19, 26, -19, 20, 3, 8, 2, -31, -8, 4, 9, 12, -11, 9, 11, -21, 19, 8, 7, -1, -22, 12, -17, 38),
        (-1, -2, 8, -12, 5, -1, -13, -27, -6, 1, 7, -10, 17, -1, -11, 7, -12, -1, -13, -22, 1, -10, -12, 11, 14, -17, 1, 11, 9, 6, -12, -23, -3, -14, 3, 4, 5, 2, -12, 2, -5, 16, -6, -17, 1, 4, -3, 3, -12, -5, 2, 15, 2, -4, 13, -3, -4, 1, 7, 9, 4, -1, 5, 3, -11, 13, 20, 5, -8, -1, -36, -1, -28),
        (-8, 2, 6, -13, 8, -13, -32, -49, -9, -1, 8, -14, 14, -1, -30, 11, -10, -16, 1, 6, 5, 22, -32, 15, -8, 7, -8, 1, 13, -5, -32, -25, 10, -5, -7, -6, 9, -1, -32, -2, 7, -10, 4, -10, -12, 11, -14, -3, 7, 1, 10, 6, 8, -17, -28, -24, 20, -5, 7, -5, 13, -3, -30, -16, 17, -6, -3, -11, 3, -1, 14, 10, -4),
        (-1, 27, -16, 4, -17, 10, -6, 9, 10, 18, -25, 27, -34, 10, -5, -7, 7, 12, -18, 9, -24, 12, 5, -15, 11, 8, -1, -7, -1, 14, 0, 2, -13, 25, 4, 15, -19, 12, -4, 5, -7, 13, 11, -14, -19, 17, 5, 0, -1, 12, -9, 4, 4, 6, -3, -2, -21, 13, -13, -26, -3, -3, -16, 4, -27, 1, -12, -26, 3, -12, -29, 15, 12),
        (-15, -6, -15, 10, 1, -18, 3, 27, 8, -1, -1, 10, -9, -1, 11, -30, 21, 6, 15, 16, -11, -1, 13, -30, -9, 2, -3, 6, 3, -17, -3, -1, 9, 2, 0, 5, -4, -4, 2, -14, 2, 4, 9, 27, -25, -16, 0, -22, -8, 5, 5, 3, 11, -8, -22, -12, 14, 2, 6, -4, 6, 4, -27, -3, 17, -9, -6, 15, 9, 1, -8, 3, -19),
        (-17, 4, -17, -24, -15, 23, 9, 20, 9, 9, 0, -20, -3, 17, 14, -30, 9, -3, -14, -5, 8, 2, 19, -33, -23, -34, -8, -23, -27, 14, 0, 18, 12, -1, -1, -8, -8, 16, 5, -21, 8, -23, 9, 22, 11, -8, 1, -13, -52, -5, -11, 3, -44, 7, 2, 23, 14, -4, 5, 18, -20, -4, -2, 0, 15, -3, 19, 5, 14, -1, -8, -1, -34),
        (4, 9, 21, 11, 1, -27, -19, -14, 0, 4, -3, -5, -3, -27, -20, 9, -5, -8, 11, -14, -87, -14, -11, 14, 14, 5, 25, 11, 19, 10, -11, 11, -23, 2, 5, 1, 11, 0, -10, -3, -17, 10, 8, -27, 14, 2, 3, 11, 16, -13, -15, -1, 19, 13, -10, -2, -36, -5, -19, -21, 16, -5, 5, 7, -30, 3, -33, -23, 1, 4, 15, -7, 6),
        (0, 1, 3, -3, -5, 1, 12, 3, -1, -7, 9, 3, -3, 2, 2, 3, 6, -9, 14, 2, 7, 9, -9, 0, -21, -3, -6, -14, -9, -15, 2, -7, 11, -11, 3, -7, -18, -3, -1, 1, 13, -11, 1, -9, -10, 10, -14, -5, -13, 2, -24, -19, -11, -8, 17, -8, 14, -8, -1, -7, -7, -9, 13, 1, 19, -13, 1, -5, -3, -7, -3, -15, 37),
        (10, -31, 6, -1, -5, -7, 9, -5, 15, -29, 3, 4, 1, -9, 7, -1, 0, -21, 9, 6, -6, -9, -12, 8, -9, 5, -12, 0, -17, -2, 8, -2, 2, 20, 4, 2, -7, -2, 7, 8, 7, -11, 3, -11, -4, -5, -7, 7, 26, 14, 4, -10, 9, 6, -3, -8, -18, 21, -14, -18, 1, 2, -13, 1, -14, -8, -34, -48, -2, -6, 3, 11, 14)
    );
    
END PACKAGE CNN_Data_Package;