`timescale 1ns / 1ps

module elevator_top
(
    input clk,
    input rst,

    input electricity,
    input generator,
    input up,
    input down,
    input [3:0] floor,
    input e_stop,
    input [8:0] weight,
    input light,
    input fan,
    input request_valid,
    

    output m_up,
    output m_down,
    output d_open,
    output d_close,
    output light_on,
    output fan_on,
    output alarm_on
);

// =========================================================
// ELEVATOR SIGNALS
// =========================================================

wire elevator_idle;
wire [3:0] current_floor;
wire [3:0] current_state;


// =========================================================
// PENDING REQUESTS
// =========================================================
//
// pending_requests[0]  -> request for floor 0
// pending_requests[1]  -> request for floor 1
// ...
// pending_requests[15] -> request for floor 15
//
// 1 = request pending
// 0 = no request
//
// =========================================================

reg [15:0] pending_requests;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        pending_requests <= 16'b0;
    end

    else
    begin

        // Add new request
        if (request_valid)
            pending_requests[floor] <= 1'b1;

        // Clear request when elevator reaches target
        if ( current_floor==target_floor)
            pending_requests[current_floor] <= 1'b0;

    end
end


// =========================================================
// DIRECTION
// =========================================================
//
// s_up   = elevator currently scanning upward
// s_down = elevator currently scanning downward
//
// =========================================================

reg direction;

localparam s_up   = 1'b1;
localparam s_down = 1'b0;


// =========================================================
// REQUEST INFORMATION
// =========================================================
//
// r_above = at least one request exists above current floor
// r_below = at least one request exists below current floor
//
// =========================================================

reg r_above;
reg r_below;


integer i;


// =========================================================
// CHECK REQUESTS ABOVE / BELOW
// =========================================================

always @(*)
begin

    r_above = 16'b0;
    r_below = 16'b0;

    for (i = 0; i < 16; i = i + 1)
    begin

        // Request exists above current floor
        if ((i > current_floor) && pending_requests[i])
            r_above = 1'b1;

        // Request exists below current floor
        if ((i < current_floor) && pending_requests[i])
            r_below = 1'b1;

    end
    
   

end

// =========================================================
// DIRECTION CONTROL
// =========================================================
//
// SCAN rule:
//
// If moving UP:
//
//     requests above    -> continue UP
//     no requests above -> reverse DOWN if requests below
//
// If moving DOWN:
//
//     requests below    -> continue DOWN
//     no requests below -> reverse UP if requests above
//
// =========================================================

always @(posedge clk or posedge rst)
begin

    if (rst)
    begin
        direction <= s_up;
    end

    else if (current_floor == target_floor)
    begin

        // =============================================
        // CURRENT DIRECTION = UP
        // =============================================

    if (direction == s_up)
        begin
            if (r_above)
                 direction <= s_up;
            else if (r_below)
                 direction <= s_down;
        end
        


        // =============================================
        // CURRENT DIRECTION = DOWN
        // =============================================

        else 
        begin

            // Requests exist below
            // Continue DOWN
            if (r_below)
                direction <= s_down;

            // No request below, but request above
            // Reverse to UP
            else if (r_above)
                direction <= s_up;

        end

    end

end


// =========================================================
// SCAN ALGORITHM
// =========================================================
//
// Finds the NEXT target floor.
//
// UP:
//
//     Search from current floor toward floor 15.
//
// DOWN:
//
//     Search from current floor toward floor 0.
//
// 
//
// =========================================================

reg found;
reg [3:0] next_target;


always @(*)
begin

    found = 1'b0;

    // Default target = current floor
    next_target = current_floor;


    // =====================================================
    // SCAN UP
    // =====================================================
   
        if (direction == s_up)
        begin

        // Search floors ABOVE current floor
        //
        // Example:
        

        for (i = 0; i < 16; i = i + 1)
        begin

            if ((i > current_floor) &&
                pending_requests[i] &&
                !found)
            begin

                next_target = i;
                found = 1'b1;

            end

        end


        // =================================================
        // NO REQUEST ABOVE
        // SEARCH BELOW
        // =================================================

        if (!found)
        begin

            // Search from current floor downward.
            //
            // We use an ascending loop with:
            //
            // current_floor - 1 - i
            //
            // to avoid negative loop conditions.

            for (i = 0; i < 16; i = i + 1)
            begin

                if (i < current_floor)
                begin

                    if (pending_requests[current_floor - 1 - i] &&
                        !found)
                    begin

                        next_target = current_floor - 1 - i;
                        found = 1'b1;

                    end

                end

            end

        end

    end


    // =====================================================
    // SCAN DOWN
    // =====================================================

    else if(direction==s_down)
    begin

        // Search floors BELOW current floor.
       

        for (i = 0; i < 16; i = i + 1)
        begin

            if (i < current_floor)
            begin

                if (pending_requests[current_floor - 1 - i] &&
                    !found)
                begin

                    next_target = current_floor - 1 - i;
                    found = 1'b1;

                end

            end

        end


        // =================================================
        // NO REQUEST BELOW
        // SEARCH ABOVE
        // =================================================

        if (!found)
        begin

            // Search upward

            for (i = 0; i < 16; i = i + 1)
            begin

                if ((i > current_floor) &&
                    pending_requests[i] &&
                    !found)
                begin

                    next_target = i;
                    found = 1'b1;

                end

            end

        end

    end
end



// =========================================================
// TARGET FLOOR
// =========================================================

reg [3:0] target_floor;


// =========================================================
// TARGET FLOOR UPDATE
// =========================================================
//
// When elevator reaches the current target:
//
//     target_floor = next_target
//
// =========================================================

    

always @(posedge clk or posedge rst)
begin

    if (rst)
    begin
        target_floor <= 4'd0;
    end

    else if (current_floor == target_floor)
    begin
        target_floor <= next_target;
    end

end


// =========================================================
// ELEVATOR INSTANCE
// =========================================================

elevator elevator_inst 
(
    .clk(clk),
    .rst(rst),

    .electricity(electricity),
    .generator(generator),

    .up(up),
    .down(down),

    .e_stop(e_stop),
    .weight(weight),

    // Target floor generated by SCAN
    .floor(target_floor),

    .fan(fan),
    .light(light),

    // =====================================================
    // OUTPUTS
    // =====================================================

    .m_up(m_up),
    .m_down(m_down),

    .d_open(d_open),
    .d_close(d_close),

    .light_on(light_on),
    .fan_on(fan_on),
    .alarm_on(alarm_on),

    // =====================================================
    // STATUS
    // =====================================================

    .idle_check(elevator_idle),

    .current_floor(current_floor),
    .current_state(current_state)

);

endmodule
