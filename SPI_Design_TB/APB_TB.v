
module tb_apb_slave_interface;

  reg PCLK;
  reg PRESETn;
  reg [2:0] PADDR;
  reg PSEL;
  reg PENABLE;
  reg PWRITE;
  reg [7:0] PWDATA;
  reg ss;
  reg receive_data;
  reg [7:0] miso_data;
  reg tip;

  wire PREADY;
  wire PSLVERR;
  wire [7:0] PRDATA;
  wire spi_interrupt_request;
  wire send_data;
  wire mstr;
  wire cpol;
  wire cpha;
  wire lsbfe;
  wire spiswai;
  wire [7:0] mosi_data;
  wire [1:0] spi_mode;
  wire [2:0] spr;
  wire [2:0] sppr;

  apb_slave_interface uut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .ss(ss),
    .receive_data(receive_data),
    .miso_data(miso_data),
    .tip(tip),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .PRDATA(PRDATA),
    .spi_interrupt_request(spi_interrupt_request),
    .send_data(send_data),
    .mstr(mstr),
    .cpol(cpol),
    .cpha(cpha),
    .lsbfe(lsbfe),
    .spiswai(spiswai),
    .mosi_data(mosi_data),
    .spi_mode(spi_mode),
    .spr(spr),
    .sppr(sppr)
  );

  // Clock Generation
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  // Stimulus
  initial begin
    // Initial values
    PRESETn = 0;
    ss = 1;
    tip = 0;
    receive_data = 0;
    miso_data = 8'h00;
    
    // Reset sequence
    #20;
    PRESETn = 1;
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;

    // APB write operations
    apb_write(3'b000, 8'hA5);    // Write to data_reg
    apb_write(3'b001, 8'b11011011); // Control register setup
    apb_write(3'b010, 8'b00111010); // Prescaler setup

    // APB read operations
    apb_read(3'b000);  // Expect miso_data (initially 0)
    apb_read(3'b001);  // Control register
    apb_read(3'b010);  // Prescaler
    apb_read(3'b011);  // Status signals

    // Simulate receiving data from SPI slave
    miso_data = 8'h5C;
    receive_data = 1;
    #10;
    receive_data = 0;

    // Read back miso_data through APB
    apb_read(3'b000);

    #50;
    $finish;
  end

  // APB Write Task
  task apb_write(input [2:0] addr, input [7:0] data);
  begin
    @(posedge PCLK);
    PSEL = 1;
    PENABLE = 0;
    PWRITE = 1;
    PADDR = addr;
    PWDATA = data;

    @(posedge PCLK);
    PENABLE = 1;

    @(posedge PCLK);
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
  end
  endtask

  // APB Read Task
  task apb_read(input [2:0] addr);
  begin
    @(posedge PCLK);
    PSEL = 1;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = addr;

    @(posedge PCLK);
    PENABLE = 1;

    @(posedge PCLK);
    PSEL = 0;
    PENABLE = 0;

    @(posedge PCLK);
    $display("Read from addr %b = %h", addr, PRDATA);
  end
  endtask

endmodule

