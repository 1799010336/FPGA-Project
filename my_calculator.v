`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/23 19:19:34
// Design Name: 
// Module Name: Input
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module my_calculator(
    input plus,//+
    input minus,//-
    input equal,//=
    input clk,//时钟
    input num_0,//0
    input num_1,//1
    input reset,//复位
    output [7:0] duan1,//左边四个数码管段显示
    output [7:0] duan2,//右边四个数码管段显示
    output [7:0] led_bits//数码管使能
    );
    reg [1:0] operator;//运算符
    reg [4:0] cnt;//输入到第几位，从msb至lsb
    reg [3:0] firstn;//第一个数
    reg [3:0] secondn;//第二个数
    reg [7:0] f_led_bits;//数码管使能中间状态，只作为标志，不作为输出
    reg [7:0] t_led_bits;//数码管使能输出
    reg [7:0] t_duan1;//左边四个数码管段显示状态输出
    reg [7:0] t_duan2;//右边四个数码管段显示状态输出
    reg [35:0] clk_cnt;//计数器
    reg num1;//左边四个数码管某一时刻显示的数字
    reg num2;//右边四个数码管某一时刻显示的数字
    reg [3:0] show1;//左边四个数码管的显示
    reg [3:0] show2;//右边四个数码管的显示
    reg flag;//计数器2是否计数的标志
    reg [32:0] clk_cnt2;//计数器2，防抖动
    reg error;//溢出标志
    assign led_bits=t_led_bits;
    assign duan1=t_duan1;
    assign duan2=t_duan2;

    always@(posedge clk or posedge reset)//计数器模块
    begin
        if (reset)//将两个计数器置零
        begin
            clk_cnt<=0;
            clk_cnt2<=33'b0;
        end
        else 
        begin
            clk_cnt<=clk_cnt+1;
            if (flag)//计数器2计数
                clk_cnt2<=clk_cnt2+1;
            else if (flag==0)
                clk_cnt2<=33'b0;
        end
    end
    
    always@(posedge clk or posedge reset)//使能输出模块
    begin
        if (reset)
            t_led_bits<=8'b00000000;
        else
        begin
            case(clk_cnt[15:13])//不停切换使能状态，使不同位显示不同数字
                0:
                    if (f_led_bits[0]==1)
                        t_led_bits<=8'b00000001;
                1:
                    if (f_led_bits[1]==1)
                        t_led_bits<=8'b00000010; 
                2:
                    if (f_led_bits[2]==1)         
                        t_led_bits<=8'b00000100;
                3:
                    if (f_led_bits[3]==1)           
                        t_led_bits<=8'b00001000;
                4:
                    if (f_led_bits[4]==1)
                        t_led_bits<=8'b00010000;
                5:
                    if (f_led_bits[5]==1)  
                        t_led_bits<=8'b00100000;
                6:
                    if (f_led_bits[6]==1)
                        t_led_bits<=8'b01000000;
                7:
                    if (f_led_bits[7]==1)        
                        t_led_bits<=8'b10000000;      
            endcase
        end
    end
      
    always@(t_led_bits)//数字选择模块
    begin
        case(t_led_bits[7:0])
            8'b00000001:
                num2<=show2[0];
            8'b00000010:
                num2<=show2[1];
            8'b00000100:
                num2<=show2[2];
            8'b00001000:
                num2<=show2[3];
            8'b00010000:
                num1<=show1[0];     
            8'b00100000:
                num1<=show1[1];
            8'b01000000:
                num1<=show1[2];
            8'b10000000:
                num1<=show1[3];
        endcase
    end
    
    always@(num1 or num2 or error)//字形显示模块
    begin
        if (error==1)//溢出则显示E
        begin
            t_duan1[7:0]<=8'b01001111;
            t_duan2[7:0]<=8'b01001111;
        end
        else//否则显示运算结果
        begin
            if (num1==0)
            begin
                if (operator==1)
                    t_duan1[7:0]<=8'b11111110;
                else t_duan1[7:0]<=8'b01111110;
            end
            else if (num1==1)
            begin
                if (operator==1)
                    t_duan1[7:0]<=8'b10110000;
                else t_duan1[7:0]<=8'b00110000;
            end
            if (num2==0)
            begin
                if (operator==2)
                    t_duan2[7:0]<=8'b11111110;
                else t_duan2[7:0]<=8'b01111110;
            end
            else if (num2==1)
            begin
                if (operator==2)
                    t_duan2[7:0]<=8'b10110000;
                else t_duan2[7:0]<=8'b00110000;
            end
        end
    end
    
    always@(posedge clk or posedge reset)//输入模块
    begin
        if (reset)
        begin
            error<=0;
            operator<=0;
            cnt<=0;
            f_led_bits[7:0]<=8'b00000000;
        end
        else
        begin
            if (plus)
                operator<=1;//+为1
            else if (minus)
                operator<=2;//-为2
            else if (equal)
            begin 
                if (operator==1)
                begin
                    if (firstn+secondn>15)//加法溢出
                    begin
                        error<=1;
                        f_led_bits<=8'b11111111;
                    end
                    else
                    begin
                        show1[3:0]=firstn[3:0]+secondn[3:0];
                        f_led_bits<=8'b11110000;
                    end
                end     
                else if (operator==2)
                begin   
                    if (firstn[3:0]<secondn[3:0])//减法溢出
                    begin
                        error<=1;
                        f_led_bits<=8'b11111111;
                    end
                    else
                    begin
                        show1[3:0]<=firstn[3:0]-secondn[3:0];   
                        f_led_bits<=8'b11110000;   
                    end
                end            
                operator<=0;
            end
            if (num_0||num_1)//激活标志
                flag<=1;
            if (clk_cnt2[32:0]==8000000)//计数器2为80ms时
            begin
                if (num_0&&cnt[4:0]<5'b00100)//输入0且是第一个数字中的某位
                begin 
                    f_led_bits[5'b00111-cnt]<=1;//对应位置亮灯
                    firstn[5'b00011-cnt]<=0;//记录数字
                    show1[5'b00011-cnt]<=0;//记录显示
                    cnt<=cnt+1;//后移一位
                end
                else if (num_0&&cnt[4:0]>=5'b00100)
                begin
                    f_led_bits[5'b00111-cnt]<=1;
                    secondn[5'b00111-cnt]<=0;
                    show2[5'b00111-cnt]<=0;
                    cnt<=cnt+1;
                end               
                else if (num_1&&cnt[4:0]<5'b00100)
                begin
                    f_led_bits[5'b00111-cnt]<=1;
                    firstn[5'b00011-cnt]<=1;
                    show1[5'b00011-cnt]<=1;
                    cnt<=cnt+1;
                end
                else if (num_1&&cnt[4:0]>=5'b00100)
                begin
                    f_led_bits[5'b00111-cnt]<=1;
                    secondn[5'b00111-cnt]<=1;
                    show2[5'b00111-cnt]<=1;
                    cnt<=cnt+1;
                end              
                flag<=0;//标志失活
            end
        end
    end
        
endmodule
