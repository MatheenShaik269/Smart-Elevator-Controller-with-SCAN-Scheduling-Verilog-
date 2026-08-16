`timescale 1ns / 1ps

module elevator_top_tb();

//====================================================
// INPUTS
//====================================================
reg clk,rst,electricity,generator,up,down,e_stop,fan,light,request_valid;
reg [8:0] weight;
reg [3:0] floor;

//====================================================
// OUTPUTS
//====================================================
wire m_up,m_down,d_open,d_close,light_on,fan_on,alarm_on;
 //assigning strings (Names) to current state to use them in output            
reg [30*8-1:0] state;

always @(*) begin
    case(dut.current_state)
        4'd0 : state = "electricity_check";
        4'd1 : state = "idle";
        4'd2 : state = "move_up";
        4'd3 : state = "move_down";
        4'd4 : state = "door_open";
        4'd5 : state = "weight_check";
        4'd6 : state = "alarm";
        4'd7 : state = "door_close";
        4'd8 : state = "emergency_stop";
        default : state = "UNKNOWN";
    endcase
end
//====================================================
// DUT
//====================================================
elevator_top dut(
    .clk(clk),
    .rst(rst),
    .electricity(electricity),
    .generator(generator),
    .up(up),
    .down(down),
    .e_stop(e_stop),
    .weight(weight),
    .floor(floor),
    .fan(fan),
    .light(light),
    .request_valid(request_valid),
    
    .m_up(m_up),
    .m_down(m_down),
    .d_open(d_open),
    .d_close(d_close),
    .light_on(light_on),
    .fan_on(fan_on),
    .alarm_on(alarm_on)
);

//====================================================
// CLOCK
//====================================================
always #5 clk = ~clk;

//====================================================
// DISPLAY (WITH CURRENT FLOOR)
//====================================================
// ️ Using hierarchical access (simulation only)
always @(posedge clk)
begin
    $display("T=%0t | rst=%b elec=%b gen=%b |floor=%0d CUR_FLOOR=%0d TARGET=%0d next_target=%0d direction=%0d r_above=%0d r_below=%0d req=%b current_state=%s | UP=%b DOWN=%b | DO=%b DC=%b | L=%b F=%b ALARM=%b | estop=%b weight=%0d",
        $time,rst,electricity,generator,
        floor,
        dut.current_floor,   // current floor
        dut.target_floor,
        dut.next_target,
        dut.direction,
        dut.r_above,
        dut.r_below,                  //  target floor
        request_valid,
        state,
        m_up,m_down,d_open,d_close,light_on,fan_on,alarm_on,e_stop,weight);
end

//====================================================
// TASK: SEND REQUEST
//====================================================
task send_request(input [3:0] f);
begin
    @(posedge clk);
    floor = f;
    request_valid = 1;
    @(posedge clk);
    request_valid = 0;
end
endtask

//====================================================
// INITIAL
//====================================================
initial begin

// INIT
clk=0; rst=1; electricity=0; generator=0;
up=0; down=0; e_stop=0; fan=0; light=0;
request_valid=0; weight=0; floor=0;

#20 rst=0;

//====================================================
// TEST CASES
//====================================================

// TC1
$display("\n=== TC1: Idle with electricity ===");
electricity=1; #50;

// TC2
$display("\n=== TC2: No electricity & no generator ===");
electricity=0; generator=0; #50;

// TC3
$display("\n=== TC3: Generator backup ===");
generator=1; #50;

// TC4
$display("\n=== TC4: Door open at same floor ===");
electricity=1; generator=0;
up=1; send_request(4'd0); up=0; #100;

// TC5
$display("\n=== TC5: Move to 5th floor ===");
up=1'b1;light=1; fan=1; weight=400;
send_request(4'd5); #400
up=1'b0;

// TC6
$display("\n=== TC6: Move down to ground ===");
down=1; send_request(4'd0); down=0; #400;

// TC7
$display("\n=== TC7: Move to 15th floor ===");
 send_request(4'd15);  #800;

// TC8
$display("\n=== TC8: Move to 1st floor fron 15th floor even though up=1 instead of down=1 ===");
up=1; send_request(4'd1); up=0; #400;

// TC9
$display("\n=== TC9:Moving from 1st floor to second floor even though  Down request to 2nd floor ===");
down=1; send_request(4'd2); down=0; #300;

// TC10
$display("\n=== TC10: Overweight condition ===");
weight=500;#600;send_request(4'd9); #200;
weight=400; #300;

// TC11
$display("\n=== TC11: Down request ===");
down=1; send_request(4'd2); down=0; #300;

// TC12
$display("\n=== TC12: Emergency stop during movement ===");
send_request(4'd9); #80;
e_stop=1; #200; e_stop=0; #500;

// TC13
$display("\n=== TC13: Emergency stop at idle ===");
e_stop=1; #100; e_stop=0;

// TC14
$display("\n=== TC14: Inside + outside request same time ===");
send_request(4'd0);
up=1; send_request(4'd11); up=0; #800;

// TC15
$display("\n=== TC15: Requests at different times ===");
send_request(4'd0); #200;
send_request(4'd15); #800;

// TC16
$display("\n=== TC16: Two floors same time ===");
send_request(4'd0);
send_request(4'd13); #800;

// TC17
$display("\n=== TC17: Two floors sequential ===");
send_request(4'd4); #200;
send_request(4'd0); #300;

// TC18
$display("\n=== TC18: up=1 down=1 then down=0 ===");
up=1; down=1; send_request(4'd5);
down=0; #500; up=0;

// TC19
$display("\n=== TC19: up=1 and down=1 ===");
up=1; down=1; send_request(4'd8);
up=0; down=0; #500;


// TC20
$display("\n=== TC20: Multiple calls ===");
 send_request(4'd7);
 send_request(4'd10);
 send_request(4'd15);
 send_request(4'd6);
 send_request(4'd2);
 send_request(4'd14);
 
 
 #800;
//TC21
$display("\n=== TC21: Multiple calls from outside the lift ===");
up=1'b1;send_request(4'd4);up=1'b0;
down=1'b1;send_request(4'd5);down=1'b0;
up=1'b1;send_request(4'd9);up=1'b0;
up=1'b1;send_request(4'd6);up=1'b0;
up=1'b1;send_request(4'd9);up=1'b0;
#800;
$display("\n===TC22: Multiple calls inside the lift===");
send_request(4'd12);
send_request(4'd11);
send_request(4'd10);
send_request(4'd14);
send_request(4'd13);
#900;
$display("\n===TC23: Multiple calls inside the lift===");
send_request(4'd11);
send_request(4'd12);
send_request(4'd4);
send_request(4'd9);
send_request(4'd6);
send_request(4'd2);
send_request(4'd6);
send_request(4'd15);



#900;





$display("\n=== ALL TEST CASES COMPLETED ===");

$finish;

end

endmodule






