
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
        (63, -35, -16, -20, 62, -32, 34, 22, -44, -14),
        (44, 34, -25, 32, -3, -36, -3, -41, -26, -2),
        (3, -64, -31, 10, -2, -22, 34, 59, 3, -2),
        (54, 20, -37, 41, -20, 43, 33, 61, 26, 0)
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
    CONSTANT Layer_2_Out_Offset : INTEGER := 3;
    CONSTANT Layer_2_Offset     : INTEGER := 0;
    CONSTANT Layer_2 : CNN_Weights_T(0 to Layer_2_Filters-1, 0 to Layer_2_Inputs-1) :=
    (
        (53, 5, 59, 36, 11, -56, 69, -32, 38, -30, 46, -85, 3, -26, 17, 36, 37, -44, 19, 55, -9, -26, 19, 16, -20, 2, -3, 12, 30, -23, 3, -26, -1, -6, 28, 11, -24),
        (-29, 50, 30, 50, -34, -32, -1, 51, 18, 65, -45, 6, -10, -33, -88, 31, 12, 74, -18, 21, 6, 87, -104, -44, -44, -86, 111, -82, -109, -2, 34, -83, -80, -4, 47, -18, 13),
        (-13, 26, 21, -28, -21, 20, -10, 15, 20, 7, -10, -11, 18, 15, 4, -11, 4, 69, -6, -32, -30, -26, 46, -28, -30, -61, -1, 67, -53, -36, 51, 36, -71, -16, 102, 52, 5),
        (-62, 12, 1, 0, -40, -50, 25, -23, -30, -23, -22, 7, 1, -23, 41, 21, -34, 4, -42, 25, -7, 4, -28, 51, -24, 72, 19, 14, 3, 7, -55, 87, -7, -48, -51, 2, -2),
        (-20, 2, -44, -52, 17, -25, -39, -12, 12, 16, -49, 43, -126, -79, -20, -23, -10, 6, -70, -4, 76, 35, -50, 41, -44, -51, -26, -12, -21, -70, -115, 46, 40, 10, 3, 37, 0),
        (48, 4, -17, 28, 25, -7, -34, -20, -30, -19, -48, -21, 23, 26, -42, 21, 5, 55, -51, -11, -63, -30, 12, -62, 21, 110, -95, 75, 36, 34, -35, -50, 1, -81, -1, 16, -15)
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
    CONSTANT Layer_3_Out_Offset : INTEGER := 5;
    CONSTANT Layer_3_Offset     : INTEGER := 1;
    CONSTANT Layer_3 : CNN_Weights_T(0 to Layer_3_Filters-1, 0 to Layer_3_Inputs-1) :=
    (
        (-7, 17, -44, 5, -20, -17, 13, -15, -2, -2, 11, 13, 0, -28, -7, 16, 25, 25, -53, 1, -13, -21, -3, -13, -12, 22, 6, -40, -4, 14, -26, -2, 0, 0, 22, 14, 6, -2, -7, -9, 2, 30, 5, -1, 8, 24, 20, 26, -4, -7, -19, 14, 40, 15, -3),
        (8, -20, 1, 20, -13, -17, 1, 10, 38, 10, 5, -13, 11, 28, 27, 28, -15, -17, -3, 2, -11, -6, -13, -10, 14, 22, 6, -6, -27, -17, 13, 9, -7, -9, 7, -16, 0, 10, -8, -27, -3, 16, 2, -7, 8, 6, -7, 5, 22, -14, -17, 28, 1, -8, -12),
        (18, -13, 5, -5, -6, 19, 13, -41, 12, 18, 41, 20, -8, -64, -21, 30, 9, 13, -10, -21, -21, 11, -17, 4, -10, -30, -4, 22, 10, 22, 16, -41, 22, -1, 20, 4, 6, -1, -9, -7, -10, -2, -10, -25, -19, -18, -9, 12, 38, 6, 0, -28, -2, 3, 9),
        (6, -10, -22, -6, -4, 16, 11, -14, -15, -11, -19, 15, 15, 1, 3, -26, 8, 16, 18, -17, 36, -9, -6, -21, 13, 0, 13, -4, -5, -16, -1, 9, -4, -6, 25, 16, 19, -14, 5, 8, -19, -21, 6, -16, -8, 24, -17, 4, 8, -1, -20, 17, 6, 6, -8),
        (-4, 23, 31, 5, -6, 11, 5, -16, -2, -11, -3, -28, 5, -51, 3, -2, 1, 13, 24, 34, -36, 7, -12, -37, -44, -69, -31, 1, 32, -6, -23, -62, 19, 13, 22, -20, -33, 5, 19, -23, 22, -49, -11, -14, 13, -21, 22, -15, 30, 15, 2, 1, 6, -35, 27),
        (11, 6, -28, -21, 6, -29, 36, -23, -3, 12, 18, 11, -19, -16, 8, -6, 6, 4, 0, 4, 9, 14, 0, 4, -2, -7, -4, -13, 9, 31, 24, -32, -17, -18, -3, 19, -22, 23, -15, 9, -8, 7, -20, 13, 14, 1, -11, 26, -22, 12, 29, 15, -12, -9, 3),
        (16, -1, 10, 19, 7, -17, -2, 15, 10, 6, -47, -15, -3, 60, 7, 5, 11, -11, 2, -6, 15, -1, -22, -2, 19, -42, 1, 4, -38, 3, 25, -53, 16, 13, -18, 10, 12, -4, 4, 10, -39, -27, 15, -30, -31, 0, -2, 33, 15, -22, 2, -2, 2, 15, -3),
        (6, -36, -6, 4, -11, -61, 5, -11, 15, -12, -12, -15, 14, 4, 1, -6, 0, -2, 18, 16, 4, 14, 6, 3, 20, -1, 13, 18, -22, -30, -4, 3, 34, 15, 5, -16, -20, 11, -34, -11, -2, 9, 4, 19, -27, -26, 29, -16, -10, 58, 3, -3, -23, -6, -10)
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
    CONSTANT NN_Layer_1_Offset     : INTEGER := 1;
    CONSTANT NN_Layer_1 : CNN_Weights_T(0 to NN_Layer_1_Outputs-1, 0 to NN_Layer_1_Inputs) :=
    (
        (-8, -5, -34, -12, -21, 5, -14, -8, 16, -31, 14, 13, 8, -18, 18, -2, -30, 10, 7, 8, 24, -26, -10, 6, 2, -10, 10, 7, -3, -42, -25, -25, -13, -23, -9, -12, -23, 3, -14, -12, 23, 26, 22, -18, 3, 9, 0, 12, 18, 0, -3, -21, 20, 14, -38, -30, -42, -10, -18, 11, 31, -5, 2, 22, -24, 20, 14, 6, -63, 7, -36, 4, 1),
        (-7, 16, 37, -1, 5, -26, 0, 16, 29, 20, 28, 16, 16, -16, -9, -21, 2, -44, -1, -28, 63, 25, 6, -8, 1, 2, -51, -10, -20, 1, -18, -12, 19, 20, 28, 5, -10, -7, -1, -17, 4, -4, -8, -35, -18, 7, -30, -28, 4, -7, 0, -5, -27, -23, 35, 8, 10, 8, 6, 14, 8, -4, -7, -27, -29, 8, -15, -2, 1, 2, 1, 31, 9),
        (-19, 0, -7, 6, 4, 22, -19, 8, -10, 8, 23, 11, -1, 16, 11, 13, -33, 3, 7, -12, -55, -40, -5, -6, -7, -5, -48, 18, -15, -22, 1, 29, 24, 1, -10, 6, -25, 5, 11, -10, 19, -30, 9, -3, -7, 19, -8, 9, -10, -25, 1, 20, 26, -19, -5, 2, -35, -4, 2, -24, 19, -11, 3, 2, 11, 28, 7, 0, -23, -30, -2, 23, -5),
        (-39, -15, -2, -12, -16, 29, 3, 12, -6, 36, -9, 9, -2, 22, 13, 7, -8, -25, -8, 15, -63, -18, 12, -18, -27, -5, -26, 11, -10, -20, 27, -11, -10, 11, 5, -34, -11, -11, -23, 7, -12, -11, -2, 12, -32, -14, -4, -20, -17, 3, -14, 1, -10, 3, 27, 12, 0, -4, -16, -5, -21, 3, 6, 13, -6, -8, -2, -1, -23, 26, 24, -12, -5),
        (14, 32, -1, 7, 29, -33, 21, -36, 18, -20, -14, -9, -5, -17, -7, -24, 47, -31, 7, -44, -25, 1, 11, -5, 5, -15, 7, 14, 0, -10, 4, 18, -15, -18, 8, 12, -8, -2, -2, 11, -23, -23, 2, 14, 2, -6, 3, -20, -3, 15, 9, -18, -2, 11, -9, -9, 12, 19, 10, 14, -10, 2, 4, -26, 1, 26, -1, -14, 19, -3, -22, -11, -3),
        (8, 2, -3, -6, -9, -25, 8, -13, 22, -8, -14, 1, 8, -6, -22, 18, -25, -4, -8, -3, 21, 25, -21, 18, 3, 5, 7, 11, 17, -16, 2, -11, -9, 1, 9, -6, -10, -6, -1, 7, 3, 15, -38, -4, -21, -51, 4, 9, -22, 0, -10, 0, -13, -22, 35, 2, -8, -13, -9, 17, -18, 3, 14, 12, -1, -22, 10, 3, -4, 22, 15, -2, -6),
        (12, 9, 18, 0, -18, -18, -16, -12, 15, -19, -15, -33, -16, 27, -18, -27, -19, 16, -2, -16, 21, 54, -33, 7, 10, -16, 12, 16, -5, -14, -20, -25, 5, -21, -12, -8, -4, -15, 3, -9, 1, 6, -16, 23, -7, -20, 25, 1, 9, 9, 25, -20, 20, -3, -69, -38, -33, -1, 10, -23, 17, -10, 3, 10, -18, 5, -2, 7, -44, 13, -6, 6, -3),
        (-3, 18, 23, 5, 10, -1, -2, 12, -30, -8, 2, 8, -2, 2, 15, 19, 14, -16, -1, 6, 9, -1, 4, 5, -15, 5, -19, -3, -15, 26, 43, 12, 24, 22, -5, 3, -32, 7, -18, 2, 7, -7, 8, -5, 7, 10, -17, 20, -9, -3, -14, 19, -22, 13, 30, -22, 10, -21, 11, -14, -16, -6, -2, -32, 2, 12, 10, -46, -7, -19, -31, -6, -1),
        (8, -35, -5, 5, -7, -16, 19, -3, -10, 3, -17, 6, 12, 3, 1, 3, -11, 11, -2, -4, -37, -6, 22, -14, 5, 17, 2, -31, -11, 23, -31, 3, -10, -7, 1, 15, 18, -11, 3, 10, -24, 5, -2, -6, -1, -12, -4, -6, -14, -10, 16, 16, 18, 2, -56, -6, -31, -19, -6, -22, 31, 20, 1, 0, -23, -9, -31, -1, -32, 7, 39, -11, 7),
        (8, -25, -74, -14, -4, -11, -14, 10, -21, 2, -37, -1, 14, 16, 14, 5, -22, -6, -18, 3, -54, -30, 14, -7, -20, -26, 41, -15, 1, 11, -29, -2, -9, 5, -3, -6, 19, -27, 1, 8, -21, -5, -2, -13, -27, 7, 15, -21, -4, 3, -5, -10, -10, -4, 1, -5, 7, 7, 3, 13, -26, -6, 7, -19, 31, -27, -5, -12, 42, 1, -22, -2, 5)
    );
    
END PACKAGE CNN_Data_Package;