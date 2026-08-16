`timescale 1ns / 1ps
module elevator(
                    //input ports
                    clk,
                    rst,
                    electricity,
                    generator,
                    up,
                    down,
                    e_stop,
                    weight,
                    floor,
                    fan,
                    light,
                    //output ports
                    m_up,     //move_uo
                    m_down,  //move_down
                    d_open,  //d_open
                    d_close, //d_close
                    light_on,
                    fan_on,
                    idle_check,
                    alarm_on,
                    current_state,
                    current_floor
               );
//inputs declaration
input clk,rst,electricity,generator,up,down,e_stop,fan,light;
input [8:0]weight;
input [3:0]floor;
//outputs declaration
output reg m_up,m_down,d_open,d_close,light_on,fan_on,alarm_on;
output idle_check;
output reg [3:0] current_state;
reg [3:0] next_state;
reg [3:0] previous_state;
assign idle_check=(current_state==idle);
output reg [3:0]current_floor;
//register for count
reg [3:0]count;
//defining parameters (states)

parameter electricity_check = 4'd0,
          idle = 4'd1,
          move_up = 4'd2,
          move_down = 4'd3,
          door_open = 4'd4,
          weight_check = 4'd5,
          alarm = 4'd6,
          door_close = 4'd7,
          emergency_stop = 4'd8;

//reg [3:0] pre_previous_state;
//current state logic
always @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                current_state<=idle ;
                previous_state<=idle;
                //pre_previous_state<=idle;
            end
        else
            begin
            
                if(next_state==electricity_check && current_state!=electricity_check)
                    begin
                    //pre_previous_state<=previous_state;
                    previous_state<=current_state;
                    end
                current_state<=next_state ;//dont write this inside conditional statements bcz it need to be updated continuosly
           end
    end
//Timer for Door closing
always @(posedge clk or posedge rst)
    begin
        if (rst)
            count<=4'd0;
        else if(current_state==door_open && count<10)
            count<=count+4'd1;
        else
            count<=4'd0;
    end 
 //floor updation logic
 always @(posedge clk or posedge rst)
    begin
        if(rst)
            current_floor<=4'd0;
        else if(current_floor<floor && current_state==move_up)
            current_floor<=current_floor+4'd1;
        else if(current_floor>floor && current_state==move_down)
            current_floor<=current_floor-4'd1;
        else
            current_floor<=current_floor;
    end
//next state logic
always @(*)
    begin
        next_state=current_state;
        case(current_state)
            electricity_check : begin
                                    if ( electricity || generator )
                                        next_state=previous_state;

                                    else
                                        next_state=electricity_check;
                                end
           idle : begin
                    if (!electricity && !generator)
                        next_state=electricity_check;
                    //else if ( (electricity==1'b1 && generator==1'b0) || (electricity==1'b0 && generator==1'b1) || (electricity==1'b1) )
                      //next_state=idle;
                    else if (e_stop==1'b1)
                        next_state=emergency_stop;
                    else if(up==1'b1 && current_floor==floor)
                        next_state=weight_check;
                    else if(down==1'b1 && current_floor==floor)
                        next_state=weight_check;
                      //When people are inside the lift and selects floor
                   else if(floor>current_floor)
                        next_state=move_up;
                   else if(floor<current_floor)
                        next_state=move_down;
                     else if (up==1'b1 && floor>current_floor)
                        next_state=move_up;
                    else if (down==1'b1 && floor<current_floor)
                        next_state=move_down;
                     //To avoid incorectness when people press up instead of down
                    else if(up==1'b1 && floor<current_floor)
                        next_state=move_down;
                   //To avoid incorectness when people press down instead of up
                   else if(down==1'b1 && floor>current_floor)
                        next_state=move_up;
                   else if(up==1'b1 && down==1'b1  && floor<current_floor)
                        next_state=move_down;
                   else if(up==1'b1 && down == 1'b1 && floor>current_floor)
                        next_state=move_up;
                  
                    else
                        next_state=idle;
                  end
           move_up : begin
                        if (!electricity && !generator)
                            next_state=electricity_check;
                        else if(e_stop==1'b1)
                            next_state=emergency_stop;
                        else if(floor>current_floor)
                            next_state=move_up;
                        else if(floor==current_floor)
                            next_state=weight_check; 
                        else if(floor<current_floor)
                            next_state=move_down;   
                     end
           move_down : begin
                            if(!electricity && !generator)
                                next_state=electricity_check;
                            else if(e_stop)
                                next_state=emergency_stop;
                            else if(floor<current_floor)
                                next_state=move_down;
                            else if(floor==current_floor )
                                next_state=weight_check; 
                            else if(floor>current_floor)
                                next_state=move_up;
                       end
           
           weight_check : begin
                            if (!electricity && !generator)
                                next_state=electricity_check;
                            else if(weight<9'd500)
                                next_state=door_open;
                            else
                                next_state=alarm;
                          end
           door_open : begin 
                            if (!electricity && !generator)
                                  next_state=electricity_check;
                            //else if ( (electricity==1'b1 && generator==1'b0) || (electricity==1'b0 && generator==1'b1) || (electricity==1'b1) )
                               //next_state=door_open;
                            if(weight<9'd500)
                               begin
                                  if(count==4'd9)
                                   begin
                                     next_state=door_close;
                                   end
                                  else
                                  next_state=door_open;
                            end
                            else 
                                next_state=weight_check;
                       end
           alarm : begin
                         if (!electricity && !generator)
                            next_state=electricity_check;
                         next_state=weight_check ;
                   end
           door_close : begin
                            if (!electricity && !generator)
                                next_state=electricity_check;
                            else
                                next_state=idle;
                        end
                        
           emergency_stop : begin
                                if (!electricity && !generator)
                                    next_state=electricity_check;
                                else
                                    next_state=door_open;
                            end
           default : next_state=idle;         
        endcase
    end
    
 //output logic
 always @(*)
    begin
        m_up=1'b0;
        m_down=1'b0;
        d_open=1'b0;
        d_close=1'b1;
        light_on=1'b0;
        fan_on=1'b0;
        alarm_on=1'b0;
        case(current_state)
        
            idle :  begin
                        if(light==1'b1)
                            light_on=1'b1;
                        if(fan==1'b1)
                            fan_on=1'b1;
                    end
           move_up : begin
                        m_up=1'b1;
                        if(light==1'b1)
                            light_on=1'b1;
                        if(fan==1'b1)
                            fan_on=1'b1;
                       
                     end
           move_down : begin
                        m_down=1'b1;
                        if(light==1'b1)
                            light_on=1'b1;
                        if(fan==1'b1)
                            fan_on=1'b1;
                        
                       end
            alarm : begin
                        alarm_on=1'b1;
                        if(light==1'b1)
                            light_on=1'b1;
                        if(fan==1'b1)
                            fan_on=1'b1;
                    end
            emergency_stop : begin
                                if(light==1'b1)
                                    light_on=1'b1;
                                if(fan==1'b1)
                                    fan_on=1'b1;
                             end
                             
             door_open : begin
                            d_open=1'b1;
                            if(d_open)
                            begin
                                d_close=1'b0;
                            end
                            if(light==1'b1)
                                   light_on=1'b1;
                            if(fan==1'b1)
                                    fan_on=1'b1;
                         end
            door_close: begin
                            if(!d_open)
                                d_close=1'b1;
                            if(light==1'b1)
                                light_on=1'b1;
                            if(fan==1'b1)
                                fan_on=1'b1;
                        end
            weight_check : begin 
                                if(light==1'b1)
                                         light_on=1'b1;
                                 if(fan==1'b1)
                                        fan_on=1'b1;
                           end
           default : begin
                           m_up=1'b0;
                           m_down=1'b0;
                           d_open=1'b0;
                           d_close=1'b1;
                           light_on=1'b0;
                           fan_on=1'b0;
                           alarm_on=1'b0;
                        
                     end        
        endcase         
    end
endmodule