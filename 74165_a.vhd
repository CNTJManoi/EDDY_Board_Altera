-- Copyright (C) 1991-2011 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II"
-- VERSION		"Version 11.0 Build 157 04/27/2011 SJ Full Version"
-- CREATED		"Sat Oct 07 12:59:13 2017"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY \74165_a\ IS 
	PORT
	(
		STLD :  IN  STD_LOGIC;
		CLK :  IN  STD_LOGIC;
		SER :  IN  STD_LOGIC;
		ENA :  IN  STD_LOGIC;
		D :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		QH :  OUT  STD_LOGIC
	);
END \74165_a\;

ARCHITECTURE bdf_type OF \74165_a\ IS 

SIGNAL	VC :  STD_LOGIC;
SIGNAL	DFFEA_inst :  STD_LOGIC;
SIGNAL	DFFEA_inst1 :  STD_LOGIC;
SIGNAL	DFFEA_inst2 :  STD_LOGIC;
SIGNAL	DFFEA_inst3 :  STD_LOGIC;
SIGNAL	DFFEA_inst4 :  STD_LOGIC;
SIGNAL	DFFEA_inst5 :  STD_LOGIC;
SIGNAL	DFFEA_inst6 :  STD_LOGIC;


BEGIN 



PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst <= D(0);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst <= SER;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst1 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst1 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst1 <= D(1);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst1 <= DFFEA_inst;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst2 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst2 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst2 <= D(2);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst2 <= DFFEA_inst1;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst3 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst3 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst3 <= D(3);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst3 <= DFFEA_inst2;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst4 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst4 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst4 <= D(4);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst4 <= DFFEA_inst3;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst5 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst5 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst5 <= D(5);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst5 <= DFFEA_inst4;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	DFFEA_inst6 <= '0';
ELSIF (VC = '0') THEN
	DFFEA_inst6 <= '1';
ELSIF (STLD = '1') THEN
	DFFEA_inst6 <= D(6);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	DFFEA_inst6 <= DFFEA_inst5;
	END IF;
END IF;
END PROCESS;


PROCESS(CLK,VC,VC)
BEGIN
IF (VC = '0') THEN
	QH <= '0';
ELSIF (VC = '0') THEN
	QH <= '1';
ELSIF (STLD = '1') THEN
	QH <= D(7);
ELSIF (RISING_EDGE(CLK)) THEN
	IF (ENA = '1') THEN
	QH <= DFFEA_inst6;
	END IF;
END IF;
END PROCESS;



VC <= '1';
END bdf_type;