--mycpu.vhd
--dual core


library ieee;
use ieee.std_logic_1164.all;

entity mycpu is
        port (
                CLK                             :       in      std_logic;
                nReset                          :       in      std_logic;
                halt                            :       out     std_logic;
                ramAddr                         :       out     std_logic_vector(15 downto 0);
                ramData                         :       out     std_logic_vector(63 downto 0);
                ramWen                          :       out     std_logic;
                ramRen                          :       out     std_logic;
                ramQ                            :       in      std_logic_vector(63 downto 0);
                ramState                        :       in      std_logic_vector(1 downto 0)
        );
end mycpu;

architecture arch of mycpu is


component arbiter
        port (
                CLK             :       in      std_logic;
                nReset          :       in      std_logic;

                icacheReq       :       in      std_logic;      --core
                aiMemWait       :       out     std_logic;
                aimemAddr       :       in      std_logic_vector(31 downto 0);
                aiMemData       :       out     std_logic_vector(63 downto 0);

                memRead         :       in      std_logic;      --core
                memWrite        :       in      std_logic;
                memAddr         :       in      std_logic_vector(31 downto 0);
                memToCache      :       out     std_logic_vector(63 downto 0);
                cacheToMem      :       in      std_logic_vector(63 downto 0);
                memWait         :       out     std_logic;


                ramState        :       in      std_logic_vector(1 downto 0);   --Memory
                ramRen          :       out     std_logic;                      --Memory
                ramWen          :       out     std_logic;                      --Memory
                ramAddr         :       out     std_logic_vector(15 downto 0);  --Memory
                ramQ            :       in      std_logic_vector(63 downto 0);  --Memory
                ramData         :       out     std_logic_vector(63 downto 0);   --Memory
		procArbitWait	:	in	std_logic
        );
end component;

component core
        port(
                CLK             :       in      std_logic;
                nReset          :       in      std_logic;
                PCSelect        :       in      std_logic;
                halt            :       out     std_logic;

                aiMemWait       :       in  std_logic;                       -- arbitrator side
                aiMemRead       :       out std_logic;                       -- arbitrator side
                aiMemAddr       :       out std_logic_vector (31 downto 0);  -- arbitrator side
                aiMemData       :       in  std_logic_vector (63 downto 0) ;  -- arbitrator side

                cdMemRead       :       out std_logic;
                cdMemWrite      :       out std_logic;
                cdMemAddr       :       out std_logic_vector(31 downto 0);
                cacheToMem      :       out std_logic_vector(63 downto 0);
                memToCache      :       in std_logic_vector(63 downto 0);
                cdMemWait       :       in std_logic
        );
end component;

component processorArbiter
        port (
                CLK             :       in      std_logic;
                nReset          :       in      std_logic;

                procRead0         :       in      std_logic;      --core
                procWrite0        :       in      std_logic;
                procAddr0         :       in      std_logic_vector(15 downto 0);
                procToMem0      :       in     std_logic_vector(63 downto 0);
                memToProc0      :       out      std_logic_vector(63 downto 0);
                procWait0       :       out     std_logic;

                procRead1         :       in      std_logic;      --core
                procWrite1        :       in      std_logic;
                procAddr1         :       in      std_logic_vector(15 downto 0);
                procToMem1      :       in     std_logic_vector(63 downto 0);
                memToProc1      :       out      std_logic_vector(63 downto 0);
                procWait1         :       out     std_logic;


                ramState        :       in      std_logic_vector(1 downto 0);   --Memory
                ramRen          :       out     std_logic;                      --Memory
                ramWen          :       out     std_logic;                      --Memory
                ramAddr         :       out     std_logic_vector(15 downto 0);  --Memory
                ramQ            :       in      std_logic_vector(63 downto 0);  --Memory
                ramData         :       out     std_logic_vector(63 downto 0)   --Memory
        );
end component;
---------------------------------Signal declarations ----------------------------

---------------------------------core 0 -----------------------------------------
signal  PCSelect        :       std_logic;
signal  loadLinked0,lockSuccess0,halt0,halt1                            :       std_logic;
signal  iMemAddr0,cpuAddr0, cpuMemAddr0                                 :       std_logic_vector(31 downto 0);
signal  iMemData0, cpuToCacheData0,cacheToCpuData0                      :       std_logic_vector(31 downto 0);

--------------------------------dcache & icache----------------------------------
signal cpuReadReq0, cpuWriteReq0, memWait0                              :       std_logic;
signal memToCache0                                                      :       std_logic_vector(63 downto 0);
signal icacheReq0, dCacheReq0                                           :       std_logic;
-----------------------------------arbiter---------------------------------------
signal icacheReq, dcacheReq, instr_out, data_out                        :       std_logic;
signal aiMemData0, cacheToMem0                                          :       std_logic_vector(63 downto 0);
signal memAddr0, aiMemAddr0                                             :       std_logic_vector(31 downto 0);
signal aiMemRead0,aiMemWait0, memRead0, memWrite0                       :       std_logic;
signal aiMemData1, cacheToMem1,memToCache1	                        :       std_logic_vector(63 downto 0);
signal memAddr1, aiMemAddr1                                             :       std_logic_vector(31 downto 0);
signal aiMemRead1,aiMemWait1, memRead1, memWrite1                       :       std_logic;
-----------------------------------processArbiter----------------------------------------------
signal procRead0, procWrite0, procRead1, procWrite1, procWait0, procWait1, memWait1	:	std_logic;
signal procAddr0, procAddr1							:	std_logic_vector(15 downto 0);
signal memToProc0, procToMem0, memToProc1, procToMem1				:	std_logic_vector(63 downto 0);

begin

--------------------------------arbiter0-------------------------------------------------
        memArbiter0 : arbiter
        port map(
                        CLK             =>      CLK,
                        nReset          =>      nReset,

                        icacheReq       =>      aiMemRead0,
                        aiMemWait       =>      aiMemWait0,
                        aimemAddr       =>      aiMemAddr0,
                        aiMemData       =>      aiMemData0,

                        memRead         =>      memRead0,
                        memWrite        =>      memWrite0,
                        memAddr         =>      memAddr0,
                        memToCache      =>      memToCache0,
                        cacheToMem      =>      cacheToMem0,
                        memWait         =>      memWait0,

                        ramState        =>      ramState,
                        ramRen          =>      procRead0,
                        ramWen          =>      procWrite0,
                        ramAddr         =>      procAddr0,
                        ramQ            =>      memToProc0,
                        ramData         =>      procToMem0,

			procArbitWait	=>	procWait0
                );


-------------------------------------------core0-------------------------------
        core0 : core
        port map(
                        CLK             =>      CLK,
                        nReset          =>      nReset,
                        PCSelect        =>      '0',
                        halt            =>      halt0,

                        aiMemWait       =>      aiMemWait0,
                        aiMemRead       =>      aiMemRead0,
                        aiMemAddr       =>      aiMemAddr0,
                        aiMemData       =>      aiMemData0,

                        cdMemRead       =>      memRead0,
                        cdMemWrite      =>      memWrite0,
                        cdMemAddr       =>      memAddr0,
                        cacheToMem      =>      cacheToMem0,
                        memToCache      =>      memToCache0,
                        cdMemWait       =>      memWait0
        );

--------------------------------arbiter1-------------------------------------------------
        memArbiter1 : arbiter
        port map(
                        CLK             =>      CLK,
                        nReset          =>      nReset,

                        icacheReq       =>      aiMemRead1,
                        aiMemWait       =>      aiMemWait1,
                        aimemAddr       =>      aiMemAddr1,
                        aiMemData       =>      aiMemData1,

                        memRead         =>      memRead1,
                        memWrite        =>      memWrite1,
                        memAddr         =>      memAddr1,
                        memToCache      =>      memToCache1,
                        cacheToMem      =>      cacheToMem1,
                        memWait         =>      memWait1,

                        ramState        =>      ramState,
                        ramRen          =>      procRead1,
                        ramWen          =>      procWrite1,
                        ramAddr         =>      procAddr1,
                        ramQ            =>      memToProc1,
                        ramData         =>      procToMem1,

			procArbitWait	=>	procWait1
                );


-------------------------------------------core0-------------------------------
        core1 : core
        port map(
                        CLK             =>      CLK,
                        nReset          =>      nReset,
                        PCSelect        =>      '1',
                        halt            =>      halt1,

                        aiMemWait       =>      aiMemWait1,
                        aiMemRead       =>      aiMemRead1,
                        aiMemAddr       =>      aiMemAddr1,
                        aiMemData       =>      aiMemData1,

                        cdMemRead       =>      memRead1,
                        cdMemWrite      =>      memWrite1,
                        cdMemAddr       =>      memAddr1,
                        cacheToMem      =>      cacheToMem1,
                        memToCache      =>      memToCache1,
                        cdMemWait       =>      memWait1
        );		
        halt <= halt0 and halt1;

-----------------------------------processor arbiter ---------------------------
	procArbiter : processorArbiter
        port map(
		        CLK             =>	CLK,
		        nReset          =>	nReset,

		        procRead0       =>	procRead0,
		        procWrite0      =>	procWrite0,
		        procAddr0       =>	procAddr0,
		        procToMem0      =>	procToMem0,
		        memToProc0      =>	memToProc0,
		        procWait0       =>	procWait0,

		        procRead1       =>	procRead1,
		        procWrite1      =>	procWrite1,
		        procAddr1       =>	procAddr1,
		        procToMem1      =>	procToMem1,
		        memToProc1      =>	memToProc1,
		        procWait1       =>	procWait1,


		        ramState        =>	ramState,
		        ramRen          =>	ramRen,
		        ramWen          =>	ramWen,
		        ramAddr         =>	ramAddr,
		        ramQ            =>	ramQ,
		        ramData         =>	ramData
        );

end arch;
