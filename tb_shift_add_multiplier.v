module tb_shift_add_multiplier;

    localparam N = 4;

    reg clk, rst_n, start;
    reg  [N-1:0]     a, b;
    wire [2*N-1:0]   p;
    wire             busy, done;

    shift_add_multiplier #(.N(N)) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .multiplicand(a), .multiplier(b),
        .product(p), .busy(busy), .done(done)
    );

    initial clk = 1'b0;
    always  #5 clk = ~clk;           

    integer errors, i, j;
    always @(posedge clk)
        if (dut.busy)
            $display("  t=%0t cnt=%0d | M=%b A=%b Q=%b | q0=%b -> %s | carry=%b",
                     $time, dut.cnt, dut.M, dut.A, dut.Q, dut.Q[0],
                     dut.Q[0] ? "ADD   " : "NO ADD", dut.carry);

    task run_mult(input [N-1:0] x, input [N-1:0] y, input verbose);
        begin
            @(negedge clk);
            a = x; b = y; start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            @(posedge done);                     
            @(negedge clk);
            if (verbose)
                $display("%0d x %0d = %0d  (A=%b Q=%b)", x, y, p, p[2*N-1:N], p[N-1:0]);
            if (p !== x * y) begin
                $display("ERROR: %0d x %0d -> %0d, expected %0d", x, y, p, x*y);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("multiplier.vcd");
        $dumpvars(0, tb_shift_add_multiplier);
        errors = 0; start = 0; a = 0; b = 0; rst_n = 0;
        #22 rst_n = 1;

        $display("== 1011 x 0111 (11 x 7) ==");  run_mult(4'b1011, 4'b0111, 1);
        $display("== 0110 x 1001 (6 x 9) ==");   run_mult(4'b0110, 4'b1001, 1);
        $display("== 1101 x 1011 (13 x 11) ==");  run_mult(4'b1101, 4'b1011, 1);
        repeat (3) @(negedge clk);
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                run_mult(i[N-1:0], j[N-1:0], 0);

        if (errors == 0) $display("RESULT: PASS (3 directed + 256 exhaustive tests)");
        else             $display("RESULT: FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
