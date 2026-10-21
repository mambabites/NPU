module round_robin_arbiter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] req,
    output reg  [3:0] gnt
);

    reg [1:0] ptr;

    reg [1:0] win_idx;   
    reg       found;     
    reg [1:0] idx;
    integer   k;

    always @(*) begin
        gnt     = 4'b0000;
        win_idx = ptr;
        found   = 1'b0;
        idx     = 2'd0;
        for (k = 0; k < 4; k = k + 1) begin
            idx = ptr + k[1:0];            
            if (!found && req[idx]) begin
                found      = 1'b1;
                gnt[idx]   = 1'b1;
                win_idx    = idx;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ptr <= 2'd0;
        else if (found)
            ptr <= win_idx + 2'd1;         
        
    end

endmodule
