module shift_add_multiplier #(
    parameter N = 4
)(
    input  wire clk,
    input  wire rst_n,         
    input  wire start,        
    input  wire [N-1:0] multiplicand,  // M
    input  wire [N-1:0] multiplier,    // Q
    output wire [2*N-1:0] product,// {A,Q}
    output reg busy,
    output reg done
);

    reg [N-1:0] M;
    reg [N-1:0] A;
    reg [N-1:0] Q;
    reg [$clog2(N+1)-1:0] cnt;// control sequencer: cycles left


    wire [N-1:0] mux_out = Q[0] ? M : {N{1'b0}};
    wire [N:0] add_out = {1'b0, A} + {1'b0, mux_out};
    wire carry = add_out[N];

    assign product = {A, Q};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M    <= {N{1'b0}};
            A    <= {N{1'b0}};
            Q    <= {N{1'b0}};
            cnt  <= 0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;                          // default: done is a pulse
            if (!busy) begin
                if (start) begin                   // load initial configuration
                    M    <= multiplicand;
                    Q    <= multiplier;
                    A    <= {N{1'b0}};             // A initially 0, C = 0
                    cnt  <= N;
                    busy <= 1'b1;
                end
            end else begin
                {A, Q} <= {add_out, Q[N-1:1]};
                cnt    <= cnt - 1'b1;
                if (cnt == 1) begin                // that was the N-th cycle
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule
