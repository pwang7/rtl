`define DATAWIDTH 8
/*
`define
作用：宏定义，用一个标识符(即名字)代表一个字符串；
形式: `define 标识符(宏名) 字符串(宏内容)
*/
`timescale 1 ps/ 1 ps
/*
`timescale
作用：用于仿真程序中时间单位和仿真精度；
*/
module LPL_Sobel_vlg_tst();
 
reg eachvec;
reg clk_i;
reg iStart;
reg rst_n;
reg  [`DATAWIDTH-1:0] iData;
wire [`DATAWIDTH-1:0] oData;
wire oStart;
wire [9:0]data121;
                        
LPL_Sobel TB(
	.clk_i(clk_i),    //时钟
	.rst_n(rst_n),    //复位
	.iData(iData),    //输入数据
	.iStart(iStart),  //输入开始控制信号
	.oData(oData),    //输出数据
	.oStart(oStart),  //输出开始控制信号
	.data121(data121) //中间变量
);
 
reg [`DATAWIDTH-1:0]image_rom[307199:0];
integer SDRAM_addr = 0;
integer fileoutput;
integer InputImage;
 
initial begin
	$display("Running TestBench");
	InputImage = $fopen("Oct16_InputImage.txt","r");
	fileoutput = $fopen("../Ap16_ImageData/out.txt");
	$readmemh("../Ap16_ImageData/1.txt", image_rom);
/*
 $random %b;
{$random}%b ；
作用：产生有符号数（-b+1~b-1)和无符号数（0~b-1)；
*/
/*
$readmemb
$readmemh
作用：文件的输入（存储器的初始化）；
格式：$readmemb("mem_file.txt", mema);
*/
/*
$fopen
作用：打开文件
 
$fclose
作用：关闭文件
 
格式：
integer MCD;
MCD = $fopen("<name_of_file>");
$fdisplay(MCD, P1, P2, .., Pn);
$fwrite  (MCD, P1, P2, .., Pn);
$fstrobe (MCD, P1, P2, .., Pn);
$fmonitor(MCD, P1, P2, .., Pn);
$fclose  (MCD);
*/
	clk_i = 0;
	iData = 0;
	iStart = 0;
	rst_n = 0;
    #100 rst_n = 1;
    #25 iStart = 1;
	iData = image_rom[SDRAM_addr];
	repeat(307199)begin
	#10 SDRAM_addr = SDRAM_addr +1;
		iData = image_rom[SDRAM_addr];
	end
	iStart = 0;
end           
/*
initial
begin
...
end
作用：
1、只执行一次，用于测试电路；
2、在仿真的初始状态对各变量进行初始化；
3、在测试文件中生成激励波形作为电路的仿真信号。
提示：产生激励只是完成了一半的工作，另外一部分工作就是验证输出是否期待的结果，而后者是更加耗时且易错的。
*/
/*
	Verilog读取当前仿真时间的系统函数：
$time
$stime
$realtime
	Verilog支持文本输出的系统任务：
$display
$strobe
$write
$monitor
 
	$time、$stime和$realtime函数返回当前仿真时间；
• 这些函数返回值使用`timescale定义的时间单位
• $time    返回一个64位整数时间值；
• $stime   返回一个32位整数时间值；
• $realtime返回一个实数时间值；
 
$display
作用：输出参数列表中信号的当前值，且输出时自动换行。
语法：$display([“ format_specifiers”,] <argument_ list>)
$display 支持二进制、八进制、十进制（默认）和十六进制；
$display、$displayb、$displayo、$displayh;
（与$display唯一的区别）
$write不会自动换行；
$strobe在所有赋值语句都完成时，才输出相应的文本。
*/
always #5 clk_i = ~clk_i; 
 
always @ (posedge clk_i or negedge rst_n)begin
	if(!rst_n)begin
	end
	else begin
		if(oStart)begin
			$fscanf(InputImage,"%H",Rd_Data);
			$fwrite(fileoutput,"%h\n",oData);
			$monitor($time,"%h \t",oData);
			$display("oData <= %d",oData);
		end
	end
end
/*
$monitor
作用：持续监视参数列表中的变量，是唯一不断输出信号值的系统任务。其它系统任务在返回值之后就结束。
格式：$monitor($time,“%b \t %h \t %d \t %o”, sig1, sig2, sig3, sig4);
*/
always @ (negedge oStart)begin
	if($realtime > 1000)begin
		$display("End");
		$fclose(fileoutput);
		$stop;
	end
end
/*
$stop;
$stop(n);
作用：暂停仿真器，提交用户控制权，即暂停仿真过程；
根据参数值(0、1或2)的不同，输出不同的信息：参数值越大，输出的信息越多。
 
$finish;
$finish(n);
作用：退出仿真器，返回主操作系统，即结束仿真过程；
根据参数值(0、1或2)的不同，输出不同的信息：
0 不输出任何信息；
1 输出当前仿真时刻和位置；
2 输出当前仿真时刻、位置和在仿真过程中所用的 Memory 及 CPU 时间的统计；
*/
endmodule
/*
%h  %o    %d      %b     %c    %s    %m      %t   \t  \n   \\     \"
Hex Octal Decimal Binary ASCII String Module Time Tab 换行 反斜杠 双引号
*/

