library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Common.all;

entity System is
  port (
    -- Input --
    clk0:         in      std_logic;
    clk1:         in      std_logic;
    clk_key:      in      std_logic;
    rst:          in      std_logic;
    switch:       in      std_logic_vector (15 downto 0);
    key:          in      std_logic_vector (3 downto 0);
    
    -- Output --
    led:          out     std_logic_vector (15 downto 0);
    seg7_l:       out     std_logic_vector (6 downto 0);
    seg7_r:       out     std_logic_vector (6 downto 0);
    
    -- RAM --
    ram1_en:      out     std_logic;
    ram1_oe:      out     std_logic;
    ram1_rw:      out     std_logic;
    ram1_data:    inout   std_logic_vector (15 downto 0);
    ram1_addr:    out     std_logic_vector (17 downto 0);
    ram2_en:      out     std_logic;
    ram2_oe:      out     std_logic;
    ram2_rw:      out     std_logic;
    ram2_data:    inout   std_logic_vector (15 downto 0);
    ram2_addr:    out     std_logic_vector (17 downto 0);
    
    -- COM --
    com_ready:    in      std_logic;
    com_rdn:      out     std_logic;
    com_wrn:      out     std_logic;
    com_tbre:     in      std_logic;
    com_tsre:     in      std_logic;
    
    -- Flash --
    flash_byte:   out     std_logic;
    flash_vpen:   out     std_logic;
    flash_ce:     out     std_logic;
    flash_oe:     out     std_logic;
    flash_we:     out     std_logic;
    flash_rp:     out     std_logic;
    flash_data:   inout   std_logic_vector (15 downto 0);
    flash_addr:   out     std_logic_vector (22 downto 0)
    );
end System;

architecture Behavioral of System is
  component CPU
    port (
      clk          : in  std_logic;
      rst          : in  std_logic;

      -- RAM
      ram_rw       : out RwType;
      ram_length   : out LenType;
      ram_addr     : out std_logic_vector (31 downto 0);
      ram_data_in  : out std_logic_vector (31 downto 0);
      ram_data_out : in  std_logic_vector (31 downto 0));
  end component;
  component Memory is
    port (
      -- Interface --
      clk:          in      std_logic;
      rst:          in      std_logic;
      en:           in      std_logic;
      rw:           in      RwType;
      length:       in      LenType;
      addr:         in      std_logic_vector (31 downto 0);
      data_in:      in      std_logic_vector (31 downto 0);
      data_out:     out     std_logic_vector (31 downto 0);
      
      -- Import --
      ram1_en:      out     std_logic;
      ram1_oe:      out     std_logic;
      ram1_rw:      out     std_logic;
      ram1_data:    inout   std_logic_vector (15 downto 0);
      ram1_addr:    out     std_logic_vector (17 downto 0);
      ram2_en:      out     std_logic;
      ram2_oe:      out     std_logic;
      ram2_rw:      out     std_logic;
      ram2_data:    inout   std_logic_vector (15 downto 0);
      ram2_addr:    out     std_logic_vector (17 downto 0);
      com_ready:    in      std_logic;
      com_rdn:      out     std_logic;
      com_wrn:      out     std_logic;
      com_tbre:     in      std_logic;
      com_tsre:     in      std_logic;
      flash_byte:   out     std_logic;
      flash_vpen:   out     std_logic;
      flash_ce:     out     std_logic;
      flash_oe:     out     std_logic;
      flash_we:     out     std_logic;
      flash_rp:     out     std_logic;
      flash_data:   inout   std_logic_vector (15 downto 0);
      flash_addr:   out     std_logic_vector (22 downto 0);
      
      -- Debug --
      seg7_r_num:   out     std_logic_vector (3 downto 0)
    );
  end component;
  component Seg7 is
    port (
      digit:      in    std_logic_vector (3 downto 0);
      led_out:    out   std_logic_vector (6 downto 0)
    );
  end component;
  
  signal clk: std_logic;
  signal rw: RwType;
  signal length: LenType;
  signal addr, data_in, data_out: Int32;
  signal seg7_l_num, seg7_r_num: Int4;
  signal mem_en: std_logic;
  
  signal state: integer;
begin
  clk <= clk_key;
  
  seg7_left: Seg7 port map (
    seg7_l_num,
    seg7_l
  );
  seg7_right: Seg7 port map (
    seg7_r_num,
    seg7_r
  );
  memory_controller: Memory port map (
    clk, rst, mem_en,
    rw, length,
    addr, data_in, data_out,
    ram1_en, ram1_oe, ram1_rw, ram1_data, ram1_addr,
    ram2_en, ram2_oe, ram2_rw, ram2_data, ram2_addr,
    com_ready, com_rdn, com_wrn, com_tbre, com_tsre,
    flash_byte, flash_vpen, flash_ce, flash_oe, flash_we, flash_rp, flash_data, flash_addr,
    seg7_r_num
  );
  
  process (clk, rst)
  begin
    if rst = '0' then
      rw <= R;
      length <= Lword;
      state <= 0;
      mem_en <= '1';
      led <= Int16_Zero;
    elsif rising_edge(clk) then
      case state is
        when 0 =>
          mem_en <= '0';
          rw <= W;
          length <= Lword;
          addr <= x"00000010";
          data_in <= x"4321" & switch;
          state <= state + 1;
        when 1 =>
          -- Initial
          state <= state + 1;
        when 2 =>
          -- RAM_WRITE_1 3
          mem_en <= '1';
          state <= state + 1;
        when 3 =>
          -- Initial
          mem_en <= '0';
          rw <= W;
          addr <= x"00000011";
          data_in <= x"00000000";
          length <= Lbyte;
          state <= state + 1;
        when 4 =>
          -- Initial
          state <= state + 1;
        when 5 =>
          -- RAM_WRITE_BYTE_1 4 
          state <= state + 1;
        when 6 =>
          -- RAM_WRITE_BYTE_2 5
          state <= state + 1;
        when 7 =>
          -- RAM_WRITE_1 3
          mem_en <= '1';
          state <= state + 1;
        when 8 =>
          mem_en <= '0';
          rw <= R;
          addr <= x"00000010";
          length <= Lhalf;
          state <= state + 1;
        when 9 =>
          -- Initial
          state <= state + 1;
        when 10 =>
          -- RAM_READ_1 2
          mem_en <= '1';
          state <= state + 1;
        when 11 =>
          led <= data_out(15 downto 0);
          state <= state + 1;
        
        when others =>
          state <= 0;
      end case;
      seg7_l_num <= std_logic_vector(to_signed(state, 4));
    end if;
  end process;
end Behavioral;
