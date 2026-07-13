import sys
import os
import re

if len(sys.argv) < 3:
    print("Usage: python3 generate_post_synth_tb.py <input_vectors.txt> <output_tb.v>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

if not os.path.exists(input_file):
    print(f"Error: Input file {input_file} not found.")
    sys.exit(1)

vectors = []
with open(input_file, 'r') as f:
    for line_num, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 4:
            print(f"Error: Line {line_num} does not have exactly 4 fields.")
            sys.exit(1)
        data_in_bin = parts[0]
        try:
            class_val = int(parts[1])
            uncertain_val = int(parts[2])
            margin_val = int(parts[3])
        except ValueError:
            print(f"Error: Line {line_num} has invalid numeric fields.")
            sys.exit(1)
        
        # Check constraints
        if len(data_in_bin) != 32 or not re.match(r'^[01]+$', data_in_bin):
            print(f"Error: Line {line_num} data field must be 32-bit binary string.")
            sys.exit(1)
        if class_val not in [0, 1, 2]:
            print(f"Error: Line {line_num} class must be 0, 1, or 2.")
            sys.exit(1)
        if uncertain_val not in [0, 1]:
            print(f"Error: Line {line_num} uncertain must be 0 or 1.")
            sys.exit(1)
        if not (0 <= margin_val <= 16777215):
            print(f"Error: Line {line_num} margin must be between 0 and 2^24-1.")
            sys.exit(1)
        
        vectors.append((data_in_bin, class_val, margin_val, uncertain_val))

if len(vectors) != 150:
    print(f"Error: Expected exactly 150 vectors, but found {len(vectors)}.")
    sys.exit(1)

out_dir = os.path.dirname(output_file)
if out_dir:
    os.makedirs(out_dir, exist_ok=True)

with open(output_file, 'w') as f:
    f.write("""`timescale 1ns/1ps
module tb_mlp_phase4_post;

    reg clk;
    reg rst;
    reg valid_in;
    reg [31:0] data_in;
    
    wire valid_out;
    wire [1:0] class_out;
    wire uncertain_out;
    wire [23:0] confidence_margin_out;
    
    integer match_count = 0;
    
    mlp_phase4 uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .class_out(class_out),
        .uncertain_out(uncertain_out),
        .confidence_margin_out(confidence_margin_out)
    );

    initial begin
        clk = 0;
        forever #41.666 clk = ~clk; // 12 MHz
    end
    
    initial begin
        $dumpfile("../../build/phase4/reports/tb_mlp_phase4_post.vcd");
        $dumpvars(0, tb_mlp_phase4_post);
        rst = 1;
        valid_in = 0;
        data_in = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        
""")
    
    for i, (data, expected_class, expected_margin, expected_uncertain) in enumerate(vectors):
        f.write(f"        // Vector {i+1}\n")
        f.write(f"        valid_in = 1;\n")
        f.write(f"        data_in = 32'b{data};\n")
        f.write(f"        @(negedge clk);\n")
        f.write(f"        valid_in = 0;\n")
        f.write(f"        @(negedge clk);\n")
        f.write(f"        if (valid_out !== 1 || class_out !== {expected_class} || uncertain_out !== {expected_uncertain} || confidence_margin_out !== {expected_margin}) begin\n")
        f.write(f"            $display(\"Mismatch at vector {i+1}: expected class={expected_class}, margin={expected_margin}, uncertain={expected_uncertain}\");\n")
        f.write(f"            $display(\"Got: valid_out=%b class=%d margin=%d uncertain=%b\", valid_out, class_out, confidence_margin_out, uncertain_out);\n")
        f.write(f"        end else begin\n")
        f.write(f"            match_count = match_count + 1;\n")
        f.write(f"        end\n")
        f.write(f"        @(negedge clk);\n\n")

    f.write(f"""
        if (match_count == {len(vectors)}) begin
            $display("POST_SYNTH PASSED: {len(vectors)}/{len(vectors)} vectors");
        end else begin
            $display("POST_SYNTH FAILED: %0d/{len(vectors)} vectors matched", match_count);
        end
        $finish;
    end
endmodule
""")

print("Successfully generated post-synthesis testbench.")
