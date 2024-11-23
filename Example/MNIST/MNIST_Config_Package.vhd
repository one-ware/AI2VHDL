
library IEEE;  
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


PACKAGE CNN_Config_Package is
  CONSTANT CNN_Value_Resolution       : NATURAL := 10;
  CONSTANT CNN_Weight_Resolution      : NATURAL := 8;
  CONSTANT CNN_Parameter_Resolution   : NATURAL := 8;
  CONSTANT CNN_Input_Columns          : NATURAL := 28;
  CONSTANT CNN_Input_Rows             : NATURAL := 28;
  CONSTANT CNN_Max_Filters            : NATURAL := 8;
  CONSTANT CNN_Value_Negative : NATURAL := 0;
  subtype CNN_Value_T       is NATURAL range 0 to 2**(CNN_Value_Resolution)-1;
  type CNN_Values_T         is array (NATURAL range <>) of CNN_Value_T;
  type CNN_Value_Matrix_T   is array (NATURAL range <>, NATURAL range <>, NATURAL range <>) of CNN_Value_T;
  subtype CNN_Weight_T      is INTEGER range (-1)*(2**(CNN_Weight_Resolution-1)-1) to 2**(CNN_Weight_Resolution-1)-1;
  type CNN_Weights_T        is array (NATURAL range <>, NATURAL range <>) of CNN_Weight_T;
  subtype CNN_Parameter_T      is INTEGER range (-1)*(2**(CNN_Parameter_Resolution-1)-1) to 2**(CNN_Parameter_Resolution-1)-1;
  type CNN_Parameters_T        is array (NATURAL range <>, NATURAL range <>) of CNN_Parameter_T;
  TYPE CNN_Stream_T IS RECORD
  Column     : NATURAL range 0 to CNN_Input_Columns-1;
  Row        : NATURAL range 0 to CNN_Input_Rows-1;
  Filter     : NATURAL range 0 to CNN_Max_Filters-1;
  Data_Valid : STD_LOGIC;
  Data_CLK   : STD_LOGIC;
  END RECORD CNN_Stream_T;
  type Activation_T is (relu, linear, leaky_relu, step_func, sign_func);
  type Padding_T is (valid, same);
  CONSTANT leaky_relu_mult : CNN_Weight_T := (2**(CNN_Weight_Resolution-1))/10;
  FUNCTION max_val ( a : INTEGER; b : INTEGER) RETURN  INTEGER;
  FUNCTION min_val ( a : INTEGER; b : INTEGER) RETURN  INTEGER;
  FUNCTION relu_f ( i : INTEGER; max : INTEGER) RETURN  INTEGER;
  FUNCTION relu_f ( i : SIGNED; max : INTEGER) RETURN  SIGNED;
  FUNCTION linear_f ( i : INTEGER; max : INTEGER) RETURN  INTEGER;
  FUNCTION linear_f ( i : SIGNED; max : INTEGER) RETURN  SIGNED;
  FUNCTION leaky_relu_f ( i : INTEGER; max : INTEGER; max_bits : INTEGER) RETURN  INTEGER;
  FUNCTION leaky_relu_f ( i : SIGNED; max : INTEGER; max_bits : INTEGER) RETURN  SIGNED;
  FUNCTION step_f ( i : INTEGER) RETURN  INTEGER;
  FUNCTION step_f ( i : SIGNED) RETURN  SIGNED;
  FUNCTION sign_f ( i : INTEGER) RETURN  INTEGER;
  FUNCTION sign_f ( i : SIGNED) RETURN  SIGNED;
  FUNCTION Bool_Select ( Sel : BOOLEAN; Value  : NATURAL; Alternative : NATURAL) RETURN  NATURAL;

END PACKAGE CNN_Config_Package;

PACKAGE BODY CNN_Config_Package is
  FUNCTION max_val ( a : INTEGER; b : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (a > b) THEN
      return a;
    ELSE
      return b;
    END IF;
  END FUNCTION;
  FUNCTION min_val ( a : INTEGER; b : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (a < b) THEN
      return a;
    ELSE
      return b;
    END IF;
  END FUNCTION;
  FUNCTION relu_f ( i : INTEGER; max : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (i > 0) THEN
      IF (i < max) THEN
        return i;
      ELSE
        return max;
      END IF;
    ELSE
      return 0;
    END IF;
  END FUNCTION;
  FUNCTION relu_f ( i : SIGNED; max : INTEGER) RETURN  SIGNED IS
    
  BEGIN
    IF (i > 0) THEN
      IF (i < to_signed(max, i'LENGTH)) THEN
        return i;
      ELSE
        return to_signed(max, i'LENGTH);
      END IF;
    ELSE
      return to_signed(0, i'LENGTH);
    END IF;
  END FUNCTION;
  FUNCTION linear_f ( i : INTEGER; max : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (i < max) THEN
      IF (i > max*(-1)) THEN
        return i;
      ELSE
        return max*(-1);
      END IF;
    ELSE
      return max;
    END IF;
  END FUNCTION;
  FUNCTION linear_f ( i : SIGNED; max : INTEGER) RETURN  SIGNED IS
    
  BEGIN
    IF (i < to_signed(max, i'LENGTH)) THEN
      IF (abs(i) < to_signed(max, i'LENGTH)) THEN
        return i;
      ELSE
        return to_signed(max*(-1), i'LENGTH);
      END IF;
    ELSE
      return to_signed(max, i'LENGTH);
    END IF;
  END FUNCTION;
  FUNCTION leaky_relu_f ( i : INTEGER; max : INTEGER; max_bits : INTEGER) RETURN  INTEGER IS
    VARIABLE i_reg : INTEGER range (-1)*(2**max_bits-1) to (2**max_bits-1);
  BEGIN
    IF (i > 0) THEN
      IF (i < max) THEN
        return i;
      ELSE
        return max;
      END IF;
    ELSE
      i_reg := to_integer(shift_right(to_signed(i * leaky_relu_mult, max_bits+CNN_Weight_Resolution-1), CNN_Weight_Resolution-1));
      IF (i_reg > max*(-1)) THEN
        return i_reg;
      ELSE
        return max*(-1);
      END IF;
    END IF;
  END FUNCTION;
  FUNCTION leaky_relu_f ( i : SIGNED; max : INTEGER; max_bits : INTEGER) RETURN  SIGNED IS
    VARIABLE i_reg : SIGNED (max_bits-1 downto 0);
  BEGIN
    IF (i > 0) THEN
      IF (i < to_signed(max, i'LENGTH)) THEN
        return i;
      ELSE
        return to_signed(max, i'LENGTH);
      END IF;
    ELSE
      i_reg := resize(shift_right(resize(i, max_bits+CNN_Weight_Resolution-1) * to_signed(leaky_relu_mult, max_bits+CNN_Weight_Resolution-1), CNN_Weight_Resolution-1), max_bits);
      IF (i_reg > to_signed(max*(-1), i'LENGTH)) THEN
        return i_reg;
      ELSE
        return to_signed(max*(-1), i'LENGTH);
      END IF;
    END IF;
  END FUNCTION;
  FUNCTION step_f ( i : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (i >= 0) THEN
      return 2**(CNN_Weight_Resolution-1);
    ELSE
      return 0;
    END IF;
  END FUNCTION;
  FUNCTION step_f ( i : SIGNED) RETURN  SIGNED IS
    
  BEGIN
    IF (i >= 0) THEN
      return to_signed(2**(CNN_Weight_Resolution-1), i'LENGTH);
    ELSE
      return to_signed(0, i'LENGTH);
    END IF;
  END FUNCTION;
  FUNCTION sign_f ( i : INTEGER) RETURN  INTEGER IS
    
  BEGIN
    IF (i > 0) THEN
      return 2**(CNN_Weight_Resolution-1);
    ELSIF (i < 0) THEN
      return (2**(CNN_Weight_Resolution-1))*(-1);
    ELSE
      return 0;
    END IF;
  END FUNCTION;
  FUNCTION sign_f ( i : SIGNED) RETURN  SIGNED IS
    
  BEGIN
    IF (i > 0) THEN
      return to_signed(2**(CNN_Weight_Resolution-1), i'LENGTH);
    ELSIF (i < 0) THEN
      return to_signed((2**(CNN_Weight_Resolution-1))*(-1), i'LENGTH);
    ELSE
      return to_signed(0, i'LENGTH);
    END IF;
  END FUNCTION;
  FUNCTION Bool_Select ( Sel : BOOLEAN; Value  : NATURAL; Alternative : NATURAL) RETURN  NATURAL IS
  BEGIN
    IF (Sel) THEN
      return Value;
    ELSE
      return Alternative;
    END IF;
  END FUNCTION;
  
END PACKAGE BODY;


