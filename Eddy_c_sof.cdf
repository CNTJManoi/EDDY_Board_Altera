/* Direct volatile FPGA configuration for hardware validation. */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EP4CE115F23C8) Path("C:/Users/lecha/OneDrive/Desktop/Eddy_c_arm/") File("Eddy_c.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
