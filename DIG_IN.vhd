-- DIG_IN.VHD (a peripheral for SCOMP)
-- This device counts how many times each switch is flipped
-- and send that data to SCOMP.

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE LPM.LPM_COMPONENTS.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SWITCH_CNT IS
  PORT(
    CLOCK    : IN    STD_LOGIC;
    RESETN   : IN    STD_LOGIC;
    IO_ADDR     : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
	 IO_READ     : IN    STD_LOGIC;
    IO_WRITE    : IN    STD_LOGIC;
    IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SWITCHES    : IN    STD_LOGIC_VECTOR(9 DOWNTO 0)
  );
END SWITCH_CNT;

ARCHITECTURE a OF SWITCH_CNT IS
  TYPE CNT_ARRAY IS ARRAY(0 TO 9) OF UNSIGNED(15 DOWNTO 0);
  
  SIGNAL COUNTERS     : CNT_ARRAY;
  
  SIGNAL CHIP_SELECT : STD_LOGIC;  -- selected if 0x60-0x6F
  SIGNAL REG_SEL     : STD_LOGIC_VECTOR(3 DOWNTO 0); -- CNT0-CNT9 if 0-9, SW_STATE if A, CONFIG if B, RESET_MASK if C
  
  SIGNAL CONFIG      : STD_LOGIC_VECTOR(1 DOWNTO 0);  -- '0' falling, '1' rising, 2 both
  
  SIGNAL SW_PREV     : STD_LOGIC_VECTOR(9 DOWNTO 0); -- previous switch state
  SIGNAL SW_CURR     : STD_LOGIC_VECTOR(9 DOWNTO 0); -- current switch state
  
  SIGNAL READ_DATA   : STD_LOGIC_VECTOR(15 DOWNTO 0); -- data to be sent during READ operation

  BEGIN

	 -- The peripheral is selected when the IO_ADDR is 0x6X
	 CHIP_SELECT <=
      '1' WHEN (IO_ADDR(10 DOWNTO 4) = "0000110") AND ((IO_READ = '1') OR (IO_WRITE = '1')) ELSE '0';
	
	 -- The lowest four bits decides which register is selected
	 REG_SEL <= IO_ADDR(3 DOWNTO 0);
	 
	 -- Decides what to send. Counts when 0x60 to 0x69, state of switches when 0x6A
	 READ_DATA <= STD_LOGIC_VECTOR(COUNTERS(TO_INTEGER(UNSIGNED(REG_SEL)))) WHEN UNSIGNED(REG_SEL) <= 9 ELSE
	   ("000000" & SW_CURR) WHEN UNSIGNED(REG_SEL) = 10 ELSE
		"ZZZZZZZZZZZZZZZZ";
	
	 -- Latch READ_DATA to IO_DATA during READ operation
	 IO_DATA <=
		READ_DATA WHEN CHIP_SELECT = '1' AND IO_READ = '1'
		ELSE "ZZZZZZZZZZZZZZZZ";
		
	PROCESS(CLOCK, RESETN, CHIP_SELECT)
	BEGIN
		-- Resets everything when resetn is asserted
		IF RESETN = '0' THEN
		 COUNTERS <= (OTHERS => (OTHERS => '0'));
		 CONFIG <= "00";
		 SW_PREV <= SWITCHES;
		 SW_CURR <= SWITCHES;
		
	   -- WRITE operation	
		ELSIF CHIP_SELECT = '1' AND IO_WRITE = '1' THEN
			-- Sets configuration
			IF UNSIGNED(REG_SEL) = 11 THEN
				CONFIG <= IO_DATA(1 DOWNTO 0);
			-- Resets the counters based on RESER_MASK
			ELSIF UNSIGNED(REG_SEL) = 12 THEN
				FOR i IN 0 TO 9 LOOP
					IF (IO_DATA(i) = '1')	THEN
					 COUNTERS(i) <= (OTHERS => '0');
					END IF;
				END LOOP;
			-- Resets a specific counter
			ELSE
				COUNTERS(TO_INTEGER(UNSIGNED(REG_SEL))) <= (OTHERS => '0');
			END IF;
		
		--Counter logic
		ELSIF RISING_EDGE(CLOCK) THEN
			--Update the states
			SW_PREV <= SW_CURR;
			SW_CURR <= SWITCHES;
			
			-- Detect the edges and icrement the counter
			FOR i IN 0 TO 9 LOOP
				IF ((CONFIG = "00" OR CONFIG = "10") AND SW_PREV(i) = '1' AND SW_CURR(i) = '0') OR
			((CONFIG = "01" OR CONFIG = "10") AND SW_PREV(i) = '0' AND SW_CURR(i) = '1')	THEN
				COUNTERS(i) <= COUNTERS(i) + 1;
				END IF;
			END LOOP;
		
			
		END IF;
	END PROCESS;
		
END a;

