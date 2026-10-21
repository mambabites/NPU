module tb_round_robin_arbiter;

    reg  clk, rst_n;
    reg  [3:0] req;
    wire [3:0] gnt;

    round_robin_arbiter dut (.clk(clk), .rst_n(rst_n), .req(req), .gnt(gnt));

    // 10 ns clock
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    reg [1:0] ref_ptr;
    integer   errors, cycle;
    integer   grant_count [0:3];

    function [3:0] expected_gnt(input [3:0] r, input [1:0] p);
        integer j;
        reg [1:0] i;
        reg done;
        begin
            expected_gnt = 4'b0000;
            done = 1'b0;
            for (j = 0; j < 4; j = j + 1) begin
                i = p + j[1:0];
                if (!done && r[i]) begin
                    expected_gnt[i] = 1'b1;
                    done = 1'b1;
                end
            end
        end
    endfunction

    function [1:0] onehot_to_idx(input [3:0] g);
        begin
            case (g)
                4'b0001: onehot_to_idx = 2'd0;
                4'b0010: onehot_to_idx = 2'd1;
                4'b0100: onehot_to_idx = 2'd2;
                default: onehot_to_idx = 2'd3;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst_n) begin
            cycle = cycle + 1;
            if (gnt !== expected_gnt(req, ref_ptr)) begin
                $display("ERROR @%0t: req=%b ptr=%0d gnt=%b expected=%b",
                         $time, req, ref_ptr, gnt, expected_gnt(req, ref_ptr));
                errors = errors + 1;
            end
            if ((gnt & (gnt - 1)) !== 4'b0000) begin
                $display("ERROR @%0t: grant not one-hot (%b)", $time, gnt);
                errors = errors + 1;
            end
            if ((gnt & ~req) !== 4'b0000) begin
                $display("ERROR @%0t: grant without request (req=%b gnt=%b)", $time, req, gnt);
                errors = errors + 1;
            end
            $display("cycle %2d | req=%b | ptr=%0d | gnt=%b", cycle, req, ref_ptr, gnt);
            if (gnt !== 4'b0000) begin
                grant_count[onehot_to_idx(gnt)] = grant_count[onehot_to_idx(gnt)] + 1;
                ref_ptr <= onehot_to_idx(gnt) + 2'd1;
            end
        end
    end

    task drive(input [3:0] r, input integer n);
        integer m;
        begin
            for (m = 0; m < n; m = m + 1) begin
                @(negedge clk);
                req = r;
            end
        end
    endtask

    initial begin
        $dumpfile("arbiter.vcd");
        $dumpvars(0, tb_round_robin_arbiter);

        errors = 0; cycle = 0; ref_ptr = 2'd0;
        grant_count[0] = 0; grant_count[1] = 0; grant_count[2] = 0; grant_count[3] = 0;
        req = 4'b0000; rst_n = 1'b0;
        #22 rst_n = 1'b1;                 // release reset away from clock edge

        drive(4'b1111, 8);
        // PHASE 2 : no requests -> no grant, pointer must HOLD
        drive(4'b0000, 2);
        // PHASE 3 : only req1 and req3 -> they must alternate 1,3,1,3...
        drive(4'b1010, 6);
        // PHASE 4 : single requester req0 -> always granted, pointer moves past it
        drive(4'b0001, 2);
        // PHASE 5 : req0, req2, req3 -> rotation among the three: 2,3,0,2,3,0
        drive(4'b1101, 6);
        // PHASE 6 : everybody again, shows fairness resumes from the held pointer
        drive(4'b1111, 4);
        drive(4'b0000, 2);

        @(negedge clk);
        $display("-------------------------------------------------");
        $display("Grants  : g0=%0d g1=%0d g2=%0d g3=%0d",
                 grant_count[0], grant_count[1], grant_count[2], grant_count[3]);
        if (errors == 0) $display("RESULT  : PASS (all %0d cycles matched)", cycle);
        else             $display("RESULT  : FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
