//+------------------------------------------------------------------+
//|                                       TrendBreakV30.mq4 |
//|                   Copyright 2005-2017, Copyright. Personal Keep  |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2017, Xuejiayong."
#property link        "http://www.mql14.com"


//发送电子邮件，参数subject为邮件主题，some_text为邮件内容 void SendMail( string subject, string some_text)

//通用宏定义
//////////////////////////////////////////
// 定义boolcross数组的长度
#define HCROSSNUMBER  16
#define MAINMAGIC  1000
#define HSLBUYSELLREORD 5000


#define HBUYSELLALGNUM 24
//外汇商专用宏定义
//定义外汇商的交易服务器
//////////////////////////////////////////

//交易零点帐号
#define HXMSERVER "XMUK-Real 15"


//传统帐号，多次订单拒绝交易
//#define HXMSERVER "XM.COM-Real 15"

#define HFXCMSERVER "FXCM-USDReal04"
#define HFXPROSERVER "FxPro.com-Real06"
#define HMARKETSSERVER "STAGlobalInvestments-HK"
#define HEXNESSSERVER "Exness-Real3"
#define HICMARKETSSERVER "ICMarkets-Live07"
#define HTHINKMARKETSSERVER "ThinkForexUK-Live"
#define HLMAXSERVER "LMAX-LiveUK"
#define HFXOPENSERVER "FXOpenUK-ECN Live Server"
#define HTICKMILLSERVER "TickmillUK-Live03"
#define HDRAWINEXSERVER "Darwinex-Live"



#define HEXNESSSERVERDEMO "Exness-Trial2"
#define HTHINKMARKETSSERVERDEMO "ThinkForexAU-Demo"
//#define HICMARKETSSERVER "ICMarkets-Demo03"
#define HFXPOENSERVERDEMO "FXOpenUK-ECN Demo Server"
#define HTICKMILLSERVERDEMO "Tickmill-DemoUK"
#define HDRAWINEXSERVERDEMO "Darwinex-Demo"



#define HOANDASERVER ""

//结束外汇商专用宏定义
//////////////////////////////////////////

#define HENABLESENDORDERHUNG 1
#define HDISABLEORDERHUNG -1

//定义成不用sendorder hung方式，代码检测
int sendorderhungstatus = HDISABLEORDERHUNG;

/////////////////////////////////////////

//定义买卖单的状态，空仓、挂单、开仓
#define HPENDINGSTATEEMPTY -1
#define HPENDINGSTATEHUNGSTOP 0
#define HPENDINGSTATEOPEN 1
#define HPENDINGSTATEING 2
//这个状态表明是一次成功的交易状态
#define HPENDINGSTATECLOSED 3
#define HPENDINGSTATEHUNGLIMIT 4

/*定义全局交易指标，确保每天只会交易一波，true为使能，false为禁止全局交易*/
bool globaltradeflag = true;

//全局变量定义
//////////////////////////////////////////
//input double TakeProfit    =50;

//input double TrailingStop  =30;	

//定义服务器时间和本地时间（北京时间）差
int globaltimezonediff = 5;	
	


// 外汇商服务器名称
string g_forexserver;



int Move_Av = 2;
int iBoll_B = 60;
//input int iBoll_S = 20;

// 定义时间周期
int timeperiod[16];
int TimePeriodNum = 6;

// 定义外汇对
string MySymbol[50];
int symbolNum;



//定义开始自学习的测试数据时间
datetime startselflearntime= D'2002.01.19 12:30:27'; 

//定义结束自学习的测试数据时间
datetime endselflearntime= D'2014.11.19 12:30:27'; 

//当前时间
//datetime endselflearntime= 0; 

/*重大重要数据时间，每个周末落实第二周的情况*/
//重大重要数据期间，现有所有订单以一分钟周期重新设置止损，放大止盈，不做额外的买卖

datetime feinongtime1= D'1980.07.19 12:30:27';  // Year Month Day Hours Minutes Seconds
int feilongtimeoffset1 = 30*60;

datetime feinongtime2= D'1980.07.19 12:30:27';  // Year Month Day Hours Minutes Seconds
int feilongtimeoffset2 = 30*60;

datetime yixitime1 =   D'1980.07.19 12:30:27'; 
int yixitimeoffset1 = 2*60*60;

datetime yixitime2 =   D'1980.07.19 12:30:27'; 
int yixitimeoffset2 = 2*60*60;

datetime bigeventstime = D'1980.07.19 12:30:27'; 
int bigeventstimeoffset = 12*60*60;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

/////////////////////////////////////////////////////////////////////


//后面改为局部变量，尚未改动？？？？？
double ma_pre;
double boll_up_B_pre,boll_low_B_pre,boll_mid_B_pre;
//!!!!!!!!!!!!!!!!!!!!!!!!!


// 定义避免因错误导致的瞬间反复购买探测变量
int Freq_Count = 0;
int TwentyS_Freq = 0;
int OneM_Freq = 0;
int ThirtyS_Freq = 0;
int FiveM_Freq = 0;
int ThirtyM_Freq = 0;


//结束全局变量定义
//////////////////////////////////////////




//结构体定义
//////////////////////////////////////////

struct stForexIndex
{
	//一个标准手使用资金
	double lotsize;
	//最小手数
	double minlot;
	//最大手数
	double maxlot;
	//改变标准手步幅
	double lotstep;
	//多头隔夜利息
	double swaplong;
	//空头隔夜利息
	double swapshort;

	//将其他货币或者商品兑换成美元的比值，用于计算一手交易的美元量
	double forexexchangevalue;

};

stForexIndex ForexIndex[50];

// 定义每一次交易发生时所记录下来的相关变量
struct stBuySellPosRecord
{	
	string MagicName;
	int magicnumber;
	int timeperiodnum;

	//设置为1为买类型，设置为-1为卖类型
	int buysellflag;

	datetime opentime;

	//记录买卖的手数
	double orderlots;
	//定义开仓价格
	double openprice;
	//定义止损价格
	double stoploss;
	//定义止盈价格
	double takeprofit;

	//开单对应的位置，仅用于挂单的时候计算超时时间
	int OneMOpenPos;

	//定义一个虚假的止损和止盈值，并设置到订单中去，实际的止损和止盈自动检测货币值，由代码发起；
	//防止恶意平台知道头寸后恶意止损，不给止盈；于此同时真出现黑天鹅事件时还能触发止损，该值定义为真正止损和止盈的2.5倍空间
	double fakedstoploss;
	double fakedtakeprofit;

	//测试挂单，实际上还是直接买卖
	int fakedtimeexp;


	//伪装值为正常值的2.5倍
	double fakedlevel;

	//定义买卖状态，初步定义 -1空单状态 0为挂单状态 1为开单状态
	int pendingstate;

	//定义循环止损值
	double stoptailing;

	//设置为2.1倍的stopless，将止损值降低为零	
	double stoptailtimes;

	//挂单开始计时设置，替换buystop和sellstop
	int timestart;
	//挂单超时设置	
	int timeexp;


	//录入订单经过一段时间以后再进入monitor程序；避免订单一直持有，寻找退出机制
	int keepperiod;

	//定义每个订单最大止损值，对应于当时账户值的百分比，作为设置止损值的依据
	double maxlose;

	//定义止损的尺度，统一设置为5倍的bool值，尽量不要出现止损情况出现，因为入场点通常都是在强弩之末的位置，最后还可以通过全部订单平仓的方式实现。
	double stoplossleverage;

	//定义盈亏比，统一按照5倍的盈亏比
	double stoplossprofitleverage;


};

//第一维度是外汇，第二维度是第几买卖点，当前共有16个买卖点
//第三个维度是每个买卖点最多可以交易几次？原则上可以交易5次，每天最多交易一次，确保不会出现密集交易点。

stBuySellPosRecord BuySellPosRecord[50][2*HBUYSELLALGNUM+1][8];

string SubMagicName[2*HBUYSELLALGNUM+1];

////////////////////////////////////////////////////////////////////////

// 定义每次均线交叉bool轨道期间对应的状态描述
struct stBoolCrossRecord
{	
	int CrossFlag[HCROSSNUMBER];//5 表示上穿上轨；4表示下穿上轨 1表示上穿中线 -1表示下穿中线 -5表示下穿下轨 -4表示上穿下轨
	double CrossStrongWeak[HCROSSNUMBER];	
	double CrossTrend[HCROSSNUMBER];
	int CrossBoolPos[HCROSSNUMBER];
	
	int CrossFlagL[HCROSSNUMBER];//5 表示上穿上轨；4表示下穿上轨 1表示上穿中线 -1表示下穿中线 -5表示下穿下轨 -4表示上穿下轨
	double CrossStrongWeakL[HCROSSNUMBER];	
	double CrossTrendL[HCROSSNUMBER];
	int CrossBoolPosL[HCROSSNUMBER];
	double BoolFlagL;	
	int CrossFlagChangeL;	
				
	
	double StrongWeak;	//多头空头状态
	double Trend;//定义上涨下跌趋势
	double MoreTrend;//定义上涨下跌加速趋势
	double BoolIndex;
	double BoolFlag;	
	int CrossFlagChange;
	int CrossFlagTemp;	
	int CrossFlagTempPre;	
	int ChartEvent;
};
stBoolCrossRecord BoolCrossRecord[50][HCROSSNUMBER+1];



////////////////////////////////////////////
//结束结构体定义
//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////



// 连接到不同外汇商的实体服务器上，并针对不同的外汇商定义对应的外汇操作集合
void initsymbol()
{
	string subject="";
	g_forexserver = AccountServer();

	subject = g_forexserver +"Init Email Send Test is Good!";
	SendMail( subject, "");
	//Print(subject);

	if(AccountServer() == HXMSERVER)
	{		
		MySymbol[0] = "EURUSD.";
		MySymbol[1] = "AUDUSD.";
		MySymbol[2] = "USDJPY.";         
		MySymbol[3] = "GOLD.";         
		MySymbol[4] = "GBPUSD.";         
		MySymbol[5] = "CADCHF."; 
		MySymbol[6] = "EURCAD."; 	
		MySymbol[7] = "GBPAUD."; 	
		MySymbol[8] = "AUDJPY.";         
		MySymbol[9] = "EURJPY."; 
		MySymbol[10] = "GBPJPY."; 	
		MySymbol[11] = "USDCAD."; 
		MySymbol[12] = "AUDCAD."; 	
		MySymbol[13] = "AUDCHF."; 
		MySymbol[14] = "CADJPY."; 
		MySymbol[15] = "EURAUD."; 
		MySymbol[16] = "GBPCHF."; 
		MySymbol[17] = "NZDCAD."; 
		MySymbol[18] = "NZDUSD."; 
		MySymbol[19] = "NZDJPY."; 
		MySymbol[20] = "USDCHF."; 	
		MySymbol[21] = "EURGBP."; 	
		MySymbol[22] = "EURCHF."; 	
		MySymbol[23] = "AUDNZD."; 	
		MySymbol[24] = "CHFJPY."; 	
		MySymbol[25] = "EURNZD."; 		
		MySymbol[26] = "GBPCAD."; 	
		MySymbol[27] = "GBPNZD."; 		
		MySymbol[28] = "USDSGD."; 	
		MySymbol[29] = "USDZAR."; 	
	
		
		symbolNum = 30;
		
	}
	else if(AccountServer() == HFXCMSERVER)
	{

		MySymbol[0] = "EURCAD"; 		
		MySymbol[1] = "AUDJPY"; 		
		MySymbol[2] = "EURNZD"; 	
		MySymbol[3] = "GBPUSD";     
		MySymbol[4] = "USDCHF"; 	
		MySymbol[5] = "AUDNZD"; 
		MySymbol[6] = "EURCHF"; 	
		MySymbol[7] = "EURUSD";
		MySymbol[8] = "NZDJPY"; 
		MySymbol[9] = "USDJPY";    	
		MySymbol[10] = "AUDUSD";				
		MySymbol[11] = "EURGBP"; 	
		MySymbol[12] = "GBPCHF"; 
		MySymbol[13] = "NZDUSD"; 		
		MySymbol[14] = "EURAUD"; 
		MySymbol[15] = "EURJPY"; 				
		MySymbol[16] = "GBPJPY"; 	
		MySymbol[17] = "USDCAD"; 
		MySymbol[18] = "GBPAUD"; 		
		MySymbol[19] = "GBPNZD"; 		
		MySymbol[20] = "CADJPY"; 		     
		MySymbol[21] = "XAUUSD";  
		
		/*           
		MySymbol[5] = "CADCHF"; 
		MySymbol[12] = "AUDCAD"; 	
		MySymbol[13] = "AUDCHF"; 
		MySymbol[17] = "NZDCAD"; 	
		MySymbol[24] = "CHFJPY"; 			
		MySymbol[26] = "GBPCAD"; 	
		MySymbol[28] = "USDSGD"; 	
		MySymbol[29] = "USDZAR"; 	
		*/
		
		
		symbolNum = 22;
	}		
	else if(AccountServer() == HFXPROSERVER)
	{
		MySymbol[0] = "AUDUSD";
		MySymbol[1] = "EURCHF";
		MySymbol[2] = "EURGBP";         
		MySymbol[3] = "EURJPY";         
		MySymbol[4] = "EURUSD";         
		MySymbol[5] = "GBPCHF"; 
		MySymbol[6] = "GBPJPY"; 	
		MySymbol[7] = "GBPUSD"; 	
		MySymbol[8] = "NZDUSD";         
		MySymbol[9] = "USDCAD"; 
		MySymbol[10] = "USDCHF"; 	
		MySymbol[11] = "USDJPY"; 
		MySymbol[12] = "AUDCAD"; 	
		MySymbol[13] = "AUDCHF"; 
		MySymbol[14] = "AUDJPY"; 
		MySymbol[15] = "AUDNZD"; 
		MySymbol[16] = "CADCHF"; 
		MySymbol[17] = "CADJPY"; 
		MySymbol[18] = "CHFJPY"; 
		MySymbol[19] = "EURAUD"; 
		MySymbol[20] = "EURCAD"; 	
		MySymbol[21] = "EURNZD"; 	
		MySymbol[22] = "GBPAUD"; 	
		MySymbol[23] = "GBPCAD"; 	
		MySymbol[24] = "GBPNZD"; 	
		MySymbol[25] = "NZDCAD"; 		
		MySymbol[26] = "NZDCHF"; 	
		MySymbol[27] = "GOLD"; 			
				
		symbolNum = 28;
		
	}	
	else if(AccountServer() == HMARKETSSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";         
		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 	
		MySymbol[7] = "CHFJPY"; 	
		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 
		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 	
		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 	
		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSD"; 			
				
		symbolNum = 29;
	}	
	else if(AccountServer() == HEXNESSSERVER)
	{
		MySymbol[0] = "AUDCADe";
		MySymbol[1] = "AUDCHFe";
		MySymbol[2] = "AUDJPYe";         
		MySymbol[3] = "AUDNZDe";         
		MySymbol[4] = "AUDUSDe";         
		MySymbol[5] = "CADCHFe"; 
		MySymbol[6] = "CADJPYe"; 	
		MySymbol[7] = "CHFJPYe"; 	
		MySymbol[8] = "EURAUDe";         
		MySymbol[9] = "EURCADe"; 
		MySymbol[10] = "EURCHFe"; 	
		MySymbol[11] = "EURGBPe"; 
		MySymbol[12] = "EURJPYe"; 	
		MySymbol[13] = "EURNZDe"; 
		MySymbol[14] = "EURUSDe"; 
		MySymbol[15] = "GBPAUDe"; 
		MySymbol[16] = "GBPCADe"; 
		MySymbol[17] = "GBPCHFe"; 	
		MySymbol[18] = "GBPJPYe"; 
		MySymbol[19] = "GBPNZDe"; 
		MySymbol[20] = "GBPUSDe"; 	
		MySymbol[21] = "NZDJPYe"; 	
		MySymbol[22] = "NZDUSDe"; 	
		MySymbol[23] = "USDCADe"; 	
		MySymbol[24] = "USDCHFe"; 	
		MySymbol[25] = "USDJPYe"; 	
		MySymbol[26] = "USDSGDe"; 		
					
		//MySymbol[26] = "XAUUSDe";  
					
		
		//MySymbol[28] = "NZDCADe"; 
				
		symbolNum = 27;
	}	
	else if(AccountServer() == HEXNESSSERVERDEMO)
	{
		MySymbol[0] = "AUDCADm";
		MySymbol[1] = "AUDCHFm";
		MySymbol[2] = "AUDJPYm";         
		MySymbol[3] = "AUDNZDm";         
		MySymbol[4] = "AUDUSDm";         
		MySymbol[5] = "CADCHFm"; 
		MySymbol[6] = "CADJPYm"; 	
		MySymbol[7] = "CHFJPYm"; 	
		MySymbol[8] = "EURAUDk";         
		MySymbol[9] = "EURCADk"; 
		MySymbol[10] = "EURCHFk"; 	
		MySymbol[11] = "EURGBPf"; 
		MySymbol[12] = "EURJPYm"; 	
		MySymbol[13] = "EURNZDm"; 
		MySymbol[14] = "EURUSDk"; 
		MySymbol[15] = "GBPAUDk"; 
		MySymbol[16] = "GBPCADm"; 
		MySymbol[17] = "GBPCHFm"; 	
		MySymbol[18] = "GBPJPYm"; 
		MySymbol[19] = "GBPNZDm"; 
		MySymbol[20] = "GBPUSDm"; 	
		MySymbol[21] = "NZDJPYm"; 	
		MySymbol[22] = "NZDUSDm"; 	
		MySymbol[23] = "USDCADm"; 	
		MySymbol[24] = "USDCHFm"; 	
		MySymbol[25] = "USDJPYm"; 	
		MySymbol[26] = "USDSGDm"; 		
					
		MySymbol[27] = "XAUUSDm";  
					
		
		MySymbol[28] = "NZDCADm"; 
				
		symbolNum = 29;
	}		
	else if(AccountServer() == HICMARKETSSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD"; 

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSD"; 			
				
		symbolNum = 29;


		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);	

	}		
		
	else if(AccountServer() == HTHINKMARKETSSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD"; 

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 	

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	

		MySymbol[28] = "XAUUSDp"; 			
				
		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	


		}
	

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);	

	}		
	else if(AccountServer() == HTHINKMARKETSSERVERDEMO)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";         
		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 	
		MySymbol[7] = "CHFJPY"; 	
		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 
		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 	
		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 	
		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSDp"; 			
				
		symbolNum = 29;
	}		
	else if(AccountServer() == HFXOPENSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";  

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 	

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 	

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";

		MySymbol[28] = "XAUUSD"; 			
				
		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}
	

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);			

	}	
	else if(AccountServer() == HFXPOENSERVERDEMO)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";  

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 	

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 	

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";

		MySymbol[28] = "XAUUSD"; 			
				
		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);			

	}	

	else if(AccountServer() == HTICKMILLSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";   

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 	

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSD"; 	



		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);				

	}	


	else if(AccountServer() == HDRAWINEXSERVER)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";   

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 	

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSD"; 			

		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);				

	}	
	else if(AccountServer() == HDRAWINEXSERVERDEMO)
	{
		MySymbol[0] = "AUDCAD";
		MySymbol[1] = "AUDCHF";
		MySymbol[2] = "AUDJPY";         
		MySymbol[3] = "AUDNZD";         
		MySymbol[4] = "AUDUSD";   

		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "CADJPY"; 

		MySymbol[7] = "CHFJPY"; 

		MySymbol[8] = "EURAUD";         
		MySymbol[9] = "EURCAD"; 
		MySymbol[10] = "EURCHF"; 	
		MySymbol[11] = "EURGBP"; 
		MySymbol[12] = "EURJPY"; 	
		MySymbol[13] = "EURNZD"; 
		MySymbol[14] = "EURUSD"; 

		MySymbol[15] = "GBPAUD"; 
		MySymbol[16] = "GBPCAD"; 
		MySymbol[17] = "GBPCHF"; 
		MySymbol[18] = "GBPJPY"; 
		MySymbol[19] = "GBPNZD"; 
		MySymbol[20] = "GBPUSD"; 	

		MySymbol[21] = "NZDCAD"; 	
		MySymbol[22] = "NZDCHF"; 	
		MySymbol[23] = "NZDJPY"; 	
		MySymbol[24] = "NZDUSD"; 

		MySymbol[25] = "USDCAD"; 	
		MySymbol[26] = "USDCHF"; 			
		MySymbol[27] = "USDJPY";	
		MySymbol[28] = "XAUUSD"; 			

		symbolNum = 29;

		ForexIndex[0].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[1].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[2].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);
		ForexIndex[3].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);		
		ForexIndex[4].forexexchangevalue =  MarketInfo(MySymbol[4],MODE_ASK);

		if(MarketInfo(MySymbol[25],MODE_ASK) > 0.001)
		{
			ForexIndex[5].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);
			ForexIndex[6].forexexchangevalue =  1/MarketInfo(MySymbol[25],MODE_ASK);

		}
		else
		{
			ForexIndex[5].forexexchangevalue =  1;
			ForexIndex[6].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[25] +"; value = "+ MarketInfo(MySymbol[25],MODE_ASK));	
		}
	

		if(MarketInfo(MySymbol[26],MODE_ASK) > 0.001)
		{

			ForexIndex[7].forexexchangevalue =  1/MarketInfo(MySymbol[26],MODE_ASK);

		}
		else
		{
			ForexIndex[7].forexexchangevalue =  1;

			Print("Something was wrong with forex "+MySymbol[26] +"; value = "+ MarketInfo(MySymbol[26],MODE_ASK));	
		}

		ForexIndex[8].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[9].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[10].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[11].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);		
		ForexIndex[12].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[13].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);
		ForexIndex[14].forexexchangevalue =  MarketInfo(MySymbol[14],MODE_ASK);

		ForexIndex[15].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);	
		ForexIndex[16].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[17].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[18].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);
		ForexIndex[19].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);		
		ForexIndex[20].forexexchangevalue =  MarketInfo(MySymbol[20],MODE_ASK);

		ForexIndex[21].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[22].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);
		ForexIndex[23].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);	
		ForexIndex[24].forexexchangevalue =  MarketInfo(MySymbol[24],MODE_ASK);

		ForexIndex[25].forexexchangevalue =  1;
		ForexIndex[26].forexexchangevalue =  1;
		ForexIndex[27].forexexchangevalue =  1;	
		ForexIndex[28].forexexchangevalue =  MarketInfo(MySymbol[28],MODE_ASK);				

	}	
		


	else if(AccountServer() == HLMAXSERVER)
	{
		MySymbol[0] = "AUDCAD.lmx";
		MySymbol[1] = "AUDCHF.lmx";
		MySymbol[2] = "AUDJPY.lmx";         
		MySymbol[3] = "AUDNZD.lmx";         
		MySymbol[4] = "AUDUSD.lmx";         
		MySymbol[5] = "CADCHF.lmx"; 
		MySymbol[6] = "CADJPY.lmx"; 	
		MySymbol[7] = "CHFJPY.lmx"; 	
		MySymbol[8] = "EURAUD.lmx";         
		MySymbol[9] = "EURCAD.lmx"; 
		MySymbol[10] = "EURCHF.lmx"; 	
		MySymbol[11] = "EURGBP.lmx"; 
		MySymbol[12] = "EURJPY.lmx"; 	
		MySymbol[13] = "EURNZD.lmx"; 
		MySymbol[14] = "EURUSD.lmx"; 
		MySymbol[15] = "GBPAUD.lmx"; 
		MySymbol[16] = "GBPCAD.lmx"; 
		MySymbol[17] = "GBPCHF.lmx"; 
		MySymbol[18] = "GBPJPY.lmx"; 
		MySymbol[19] = "GBPNZD.lmx"; 
		MySymbol[20] = "GBPUSD.lmx"; 	
		MySymbol[21] = "NZDCAD.lmx"; 	
		MySymbol[22] = "NZDCHF.lmx"; 	
		MySymbol[23] = "NZDJPY.lmx"; 	
		MySymbol[24] = "NZDUSD.lmx"; 	
		MySymbol[25] = "USDCAD.lmx"; 	
		MySymbol[26] = "USDCHF.lmx"; 			
		MySymbol[27] = "USDJPY.lmx";	
		MySymbol[28] = "XAUUSD.lmx"; 			
				
		symbolNum = 29;
	}				
		
	else if(AccountServer() == HOANDASERVER)
	{
		MySymbol[0] = "EURUSD";
		MySymbol[1] = "AUDUSD";
		MySymbol[2] = "USDJPY";         
		MySymbol[3] = "XAUUSD-2";         
		MySymbol[4] = "GBPUSD";         
		MySymbol[5] = "CADCHF"; 
		MySymbol[6] = "EURCAD"; 	
		MySymbol[7] = "GBPAUD"; 	
		MySymbol[8] = "AUDJPY";         
		MySymbol[9] = "EURJPY"; 
		MySymbol[10] = "GBPJPY"; 	
		MySymbol[11] = "USDCAD"; 
		MySymbol[12] = "AUDCAD"; 	
		MySymbol[13] = "AUDCHF"; 
		MySymbol[14] = "CADJPY"; 
		MySymbol[15] = "EURAUD"; 
		MySymbol[16] = "GBPCHF"; 
		MySymbol[17] = "NZDCAD"; 
		MySymbol[18] = "NZDUSD"; 
		MySymbol[19] = "NZDJPY"; 
		MySymbol[20] = "USDCHF";
	 	
		MySymbol[21] = "EURGBP"; 	
		MySymbol[22] = "EURCHF"; 	
		MySymbol[23] = "AUDNZD"; 	
		MySymbol[24] = "CHFJPY"; 	
		MySymbol[25] = "EURNZD"; 	
		
		MySymbol[26] = "GBPCAD"; 	
		MySymbol[27] = "GBPNZD"; 	
		
		MySymbol[28] = "USDSGD"; 	
		MySymbol[29] = "USDZAR"; 	
	
			
		symbolNum = 4;
	}	
	
	else
	{		


		symbolNum = 0;	
		Print("Bad Connect;Server name is ", AccountServer());	
				
	}
			
}


/*定义操作的时间周期集合*/
//只用到了日线，不再引入周线，也是便于后期海量的测试。
void inittiimeperiod()
{
	timeperiod[0] = PERIOD_M1;
	timeperiod[1] = PERIOD_M5;
	timeperiod[2] = PERIOD_M30;
	timeperiod[3] = PERIOD_H4;
	timeperiod[4] = PERIOD_D1;
	timeperiod[5] = PERIOD_W1;
	
	TimePeriodNum = 5;
	
}

// 外汇商服务器连接测试，针对不同的服务器配置不同的初始参数，如时差
bool forexserverconnect()
{
	
	bool connectflag = false;
	int timezonecalcu;
	
	if(AccountServer() == HXMSERVER)
	{		
		
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;			
		
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}
	
	else if(AccountServer() == HFXCMSERVER)
	{
		
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;			
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}		
	else if(AccountServer() == HFXPROSERVER)
	{
		
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else if(AccountServer() == HMARKETSSERVER)
	{

	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 8;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else if(AccountServer() == HEXNESSSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 8;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else if(AccountServer() == HEXNESSSERVERDEMO)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 8;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}		
		
	else if(AccountServer() == HICMARKETSSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}		
	else if(AccountServer() == HTHINKMARKETSSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}			
	else if(AccountServer() == HTHINKMARKETSSERVERDEMO)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}
		
	else if(AccountServer() == HFXOPENSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else if(AccountServer() == HFXPOENSERVERDEMO)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	

	else if(AccountServer() == HTICKMILLSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}		

	else if(AccountServer() == HTICKMILLSERVERDEMO)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}
	else if(AccountServer() == HDRAWINEXSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else if(AccountServer() == HDRAWINEXSERVERDEMO)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 6;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}

				
	else if(AccountServer() == HLMAXSERVER)
	{
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 8;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}				
	
	else if(AccountServer() == HOANDASERVER)
	{
		
	
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;	
				
		Print("Good Connect;Server name is ", AccountServer());	
		connectflag = true;				
	}	
	else
	{
		//定义服务器时间和本地时间（北京时间）差
		globaltimezonediff = 5;							
		Print("Bad Connect;Server name is ", AccountServer());	
		connectflag = false;				
	}
	
	timezonecalcu = int((TimeLocal()-TimeCurrent())/(60*60));
	if(timezonecalcu == globaltimezonediff)
	{
		Print("Set TimeZone success, globaltimezonediff = " + globaltimezonediff);
		connectflag = true;			
	}
	else
	{
		Print("Set TimeZone error, globaltimezonediff = " + globaltimezonediff+"But RealTimeZone timezonecalcu = "+timezonecalcu);
		globaltimezonediff = timezonecalcu;
		connectflag = true;			
	}
	return connectflag;

}


// 打开所有需要交易的外汇集合，打开后才能进行交易，ducascopy也是有同样要求
void openallsymbo()
{
   
	int SymPos;

	string my_symbol;
	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{
		
		my_symbol =   MySymbol[SymPos];
		
   	if(SymbolSelect(my_symbol,true)==false)
   	{
   	      Print("Open symbo error :" + my_symbol);
   	}
   }

}


// 设置正常交易的全局交易开关，关闭的情况下不进行任何交易，一波交易完成后当天不再进行任何交易
void setglobaltradeflag(bool flag)
{

	globaltradeflag = flag;
}

// 获取正常交易的全局交易开关
bool getglobaltradeflag(void)
{

	return globaltradeflag ;
}


/*启动时初始化正常交易的全局交易标记*/
void initglobaltradeflag()
{

	datetime timelocal;	

	/*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
	timelocal = TimeCurrent() + globaltimezonediff*60*60;

	//14点前不做趋势单，主要针对1分钟线和五分钟线，非欧美时间趋势不明显，针对趋势突破单，要用这个来检测
	//最原始的是下午4点前不做趋势单，通过扩大止损来寻找更多机会

	if ((TimeHour(timelocal) >= 8 )&& (TimeHour(timelocal) <22 )) 
	{
		
		setglobaltradeflag(true);		
				
	}	
	else
	{
		setglobaltradeflag(false);				
	}

}


/*在交易时间段来临前确保使能全局交易标记*/
// 下午13点开始使能正常交易
void enableglobaltradeflag()
{
	int SymPos;
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;
		
	datetime timelocal;	

	SymPos = 0;
	/*每隔五分钟算一次*/
	timeperiodnum = 1;
	
	my_symbol =   MySymbol[SymPos];	
	my_timeperiod = timeperiod[timeperiodnum];	
	

	/*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
	timelocal = TimeCurrent() + globaltimezonediff*60*60;


	/*确保交易时间段，来临前开启全局交易交易标记*/
	if ((TimeHour(timelocal) >= 8 )&& (TimeHour(timelocal) <9 )) 
	{			
		//确保是每个周期五分钟计算一次，而不是每个tick计算一次
		if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
		{		
			//if(false == getglobaltradeflag())
			{
				setglobaltradeflag(true);		
				Print("Enable Global Trade!");	 					
			}
			
		}
	}	
	
}

void initforexindex()
{
	int SymPos;
	string my_symbol;
	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{
		
		my_symbol =   MySymbol[SymPos];
		ForexIndex[SymPos].lotsize = MarketInfo(my_symbol,MODE_LOTSIZE)*ForexIndex[SymPos].forexexchangevalue;
		ForexIndex[SymPos].minlot = MarketInfo(my_symbol,MODE_MINLOT);
		ForexIndex[SymPos].maxlot = MarketInfo(my_symbol,MODE_MAXLOT);
		ForexIndex[SymPos].lotstep = MarketInfo(my_symbol,MODE_LOTSTEP);
		ForexIndex[SymPos].swaplong = MarketInfo(my_symbol,MODE_SWAPLONG);
		ForexIndex[SymPos].swapshort = MarketInfo(my_symbol,MODE_SWAPSHORT);

		Print(my_symbol+" ForexIndex["+SymPos+"][" +"lotsize = "+ForexIndex[SymPos].lotsize +";minlot = "+ForexIndex[SymPos].minlot
				+";maxlot = "+ForexIndex[SymPos].maxlot+";lotstep = "+ForexIndex[SymPos].lotstep+";swaplong = "+ForexIndex[SymPos].swaplong
				+";swapshort = "+ForexIndex[SymPos].swapshort);	

	}

}

//根据账户总额设置交易的风险偏好，原则上账户总额越大，承受的MaxLoses比例越小
//原则上账户每次提升500美金，风险降低0.2%

void autoadjustmaxlose()
{
	
	int SymPos;
	int buysellpoint;
	int subbuysellpoint;

	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;
		
	datetime timelocal;	

	SymPos = 0;
	/*每隔五分钟算一次*/
	timeperiodnum = 1;
	
	my_symbol =   MySymbol[SymPos];	
	my_timeperiod = timeperiod[timeperiodnum];	
	

	/*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
	timelocal = TimeCurrent() + globaltimezonediff*60*60;


	//确保是每个周期五分钟计算一次，而不是每个tick计算一次,8-22点寻找交易点
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
	{		
		initglobaltradeflag();
	}


	/*确保交易时间段，来临前开启全局交易交易标记*/
	if ((TimeHour(timelocal) >= 8 )&& (TimeHour(timelocal) <9 )) 
	{	
		
		//确保是每个周期五分钟计算一次，而不是每个tick计算一次
		if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
		{					

			for(SymPos = 0; SymPos < symbolNum;SymPos++)
			{
				
				for(subbuysellpoint = 0; subbuysellpoint <= 7;subbuysellpoint++)
				{
					for(buysellpoint = 1; buysellpoint <= 20;buysellpoint++)
					{
					

						//定义时间周期，一分钟的买卖点
						if ((buysellpoint <= 8)&&(buysellpoint > 0))
						{

							//每单允许损失的最大账户金额比例2%
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.02 - 0.001*(int((int(AccountBalance()))/500)))/2;											

						}
						//定义时间周期，五分钟及以上的买卖点
						else if((buysellpoint <= 20)&&(buysellpoint > 8))
						{	

							//每单允许损失的最大账户金额比例5%
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.04- 0.002*(int((int(AccountBalance()))/500)))/2;		

						}
						else
						{
							;
						}

					}

				}	
														
			}

	
		}		
		
	}	


}



/*初始化交易手数*/
// 根据不同的账户金额值来定义不同的单独交易允许的止损百分比

double autocalculateamount(int SymPos,int buysellpoint,int subbuysellpoint)
{

	double devidedamount;
	double maxlossamount;
	double stoplosspercent;
	double lastamount;
	
	double accountbalance = 0;

	accountbalance = AccountBalance();

	if(accountbalance < 300)
	{
		lastamount = ForexIndex[SymPos].minlot;
	}
	else if((accountbalance >= 300)&&(accountbalance < 600))
	{
		lastamount = ForexIndex[SymPos].minlot*2;		
	}
	else if((accountbalance >= 600)&&(accountbalance < 1000))
	{
		lastamount = ForexIndex[SymPos].minlot*3;		
	}	
	else if((accountbalance >= 1000)&&(accountbalance < 1500))
	{
		lastamount = ForexIndex[SymPos].minlot*4;		
	}	
	else if((accountbalance >= 1500)&&(accountbalance < 2000))
	{
		lastamount = ForexIndex[SymPos].minlot*5;		
	}	
	else if((accountbalance >= 2000)&&(accountbalance < 2600))
	{
		lastamount = ForexIndex[SymPos].minlot*6;		
	}		
	else
	{
		//确保能够均分出symbolNum/3份以上，可实现多次交易的目的。
		devidedamount = (AccountBalance()*myaccountleverage())/((symbolNum/3)*ForexIndex[SymPos].lotsize);

		//止损百分比
		stoplosspercent = ((BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
					*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag)/BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice;	

		maxlossamount = (AccountBalance()*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose)/(ForexIndex[SymPos].lotsize*stoplosspercent);


		//寻找更小的amount
		if(devidedamount > maxlossamount)
		{

			lastamount = maxlossamount;
		}
		else
		{
			lastamount = devidedamount;

		}

		//在可交易手的范围内
		if(lastamount > ForexIndex[SymPos].maxlot)
		{
			lastamount = ForexIndex[SymPos].maxlot;
		}
		if(lastamount < ForexIndex[SymPos].minlot)
		{
			lastamount = ForexIndex[SymPos].minlot;
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" autocalculateamount AccountBalance No Enough Money,But we still trade!");

		}

		//归一化；
		lastamount = (int(lastamount/ForexIndex[SymPos].lotstep))*ForexIndex[SymPos].lotstep;

		if(lastamount < ForexIndex[SymPos].minlot)
		{
			lastamount = ForexIndex[SymPos].minlot;
		}

		Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"autocalculateamount:" + "AccountBalance=" 
					+ AccountBalance() +"stoplosspercent ="+stoplosspercent);
		Print("devidedamount="+devidedamount+"maxlossamount="+maxlossamount+"lastamount:"+lastamount);	
	}
	return lastamount;

}


/*每天交易前计算交易手数，只在下午一点计算，每隔5分钟算一次*/
// 根据不同的账户金额值来定义不同的交易手数
void autoadjustglobalamount()
{
	
	int SymPos;
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;
		
	datetime timelocal;	

	SymPos = 0;
	/*每隔五分钟算一次*/
	timeperiodnum = 1;
	
	my_symbol =   MySymbol[SymPos];	
	my_timeperiod = timeperiod[timeperiodnum];	
	

	/*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
	timelocal = TimeCurrent() + globaltimezonediff*60*60;


	//确保是每个周期五分钟计算一次，而不是每个tick计算一次,8-22点寻找交易点
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
	{		
		initglobaltradeflag();
	}


	/*确保交易时间段，来临前开启全局交易交易标记*/
	if ((TimeHour(timelocal) >= 8 )&& (TimeHour(timelocal) <9 )) 
	{	
		
		//确保是每个周期五分钟计算一次，而不是每个tick计算一次
		if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
		{					

			//根据不同的账户值定义允许的单交易最大止损百分比
			if(AccountBalance() <= 2000)
			{
	
				//Print("autoadjustglobalamount Amount is = "+MyLotsH+":"+MyLotsL);	 				
			}	

			else
			{
				//Print("default autoadjustglobalamount Amount is = "+MyLotsH+":"+MyLotsL);	 							
			}		
			




			//每日刷新一次
			for(SymPos = 0; SymPos < symbolNum;SymPos++)
			{
				
				my_symbol =   MySymbol[SymPos];
				ForexIndex[SymPos].lotsize = MarketInfo(my_symbol,MODE_LOTSIZE);
				ForexIndex[SymPos].minlot = MarketInfo(my_symbol,MODE_MINLOT);
				ForexIndex[SymPos].maxlot = MarketInfo(my_symbol,MODE_MAXLOT);
				ForexIndex[SymPos].lotstep = MarketInfo(my_symbol,MODE_LOTSTEP);
				ForexIndex[SymPos].swaplong = MarketInfo(my_symbol,MODE_SWAPLONG);
				ForexIndex[SymPos].swapshort = MarketInfo(my_symbol,MODE_SWAPSHORT);

				//Print(my_symbol+" ForexIndex["+SymPos+"][" +"lotsize = "+ForexIndex[SymPos].lotsize +";minlot = "+ForexIndex[SymPos].minlot
				//		+";maxlot = "+ForexIndex[SymPos].maxlot+";lotstep = "+ForexIndex[SymPos].lotstep+";swaplong = "+ForexIndex[SymPos].swaplong
				//		+";swapshort = "+ForexIndex[SymPos].swapshort);	

			}




	
		}		
		
	}

	
}



// 判断MagicNumber是否已经存在交易，没有交易时返回true，挂单也是定义为open
// 确保每个买卖点只有一个交易存在,包含挂掉也放在里面，确保不会出现重复挂单
bool OneMOrderCloseStatus(int MagicNumber)
{
	bool status;
	int i;
	status = true;

	if ( OrdersTotal() > 200)
	{
		Print("OneMOrderKeepNumber exceed 200");
		return false;
	}
	
	for (i = 0; i < OrdersTotal(); i++)
	{
       if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
       {
   			//未平仓的订单和挂单交易的平仓时间等于0
			if((OrderCloseTime() == 0)&&(OrderMagicNumber()== MagicNumber))
			{

			  status= false;
			  break;

			}
                
       }
	}
   return status;
}


// 判断MagicNumber是否已经存在交易，没有交易时返回true，挂单定义为close
// 确保每个买卖点只有一个交易存在,包含挂掉也放在里面，确保不会出现重复挂单
bool OneMOrderRealCloseStatus(int MagicNumber)
{
	bool status;
	int i;
	status = true;

	if ( OrdersTotal() > 200)
	{
		Print("OneMOrderKeepNumber exceed 200");
		return false;
	}
	
	for (i = 0; i < OrdersTotal(); i++)
	{
       if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
       {

			if((OrderType()==OP_BUY)||(OrderType()==OP_SELL))
			{      	
	   			//未平仓的订单和挂单交易的平仓时间等于0
				if((OrderCloseTime() == 0)&&(OrderMagicNumber()== MagicNumber))
				{

				  status= false;
				  break;

				}
			}
                
       }
	}
   return status;
}




// 初始化定义boolcross的值
int  InitcrossValue(int SymPos,int timeperiodnum)
{	
	double myma,myboll_up_B,myboll_low_B,myboll_mid_B;
	double myma_pre,myboll_up_B_pre,myboll_low_B_pre,myboll_mid_B_pre;

	double StrongWeak;
	double MAFive,MAThentyOne,MASixty;	
	string my_symbol;

	int my_timeperiod;
	
	int crossflag;
	int j ;
	int i;
	int countnumber = 0;
	my_symbol =   MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];	
	
	/*确保覆盖最近6年以内数据*/
	if(timeperiodnum<5)
	{
		countnumber = 500;
	}
	else if(timeperiodnum==5)
	{
		countnumber = 400;
	}
	else
	{
		countnumber = 100;
	}
		
	if(iBars(my_symbol,my_timeperiod) <countnumber)
	{
		Print(my_symbol + ":"+my_timeperiod+":Bar Number less than "+countnumber+"which is :" + iBars(my_symbol,my_timeperiod));
		countnumber = iBars(my_symbol,my_timeperiod) - 100;
		//return -1;
	}


	j = 0;
	for (i = 2; i< countnumber;i++)
	{
		
		crossflag = 0;     
		myma=iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,i-1);  
		myboll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,i-1);   
		myboll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,i-1);
		myboll_mid_B = (	myboll_up_B +  myboll_low_B)/2;

		myma_pre = iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,i); 
		myboll_up_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,i);      
		myboll_low_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,i);
		myboll_mid_B_pre = (myboll_up_B_pre + myboll_low_B_pre)/2;

		if((myma >myboll_up_B) && (myma_pre < myboll_up_B_pre ) )
		{
				crossflag = 5;		
		}
		
		if((myma <myboll_up_B) && (myma_pre > myboll_up_B_pre ) )
		{
				crossflag = 4;
		}
			
		if((myma < myboll_low_B) && (myma_pre > myboll_low_B_pre ) )
		{
				crossflag = -5;
		}
			
		if((myma > myboll_low_B) && (myma_pre < myboll_low_B_pre ) )
		{
				crossflag = -4;	
		}
	
		if((myma > myboll_mid_B) && (myma_pre < myboll_mid_B_pre ))
		{
				crossflag = 1;				
		}	
		if( (myma < myboll_mid_B) && (myma_pre > myboll_mid_B_pre ))
		{
				crossflag = -1;								
		}			
		
		if(0 != 	crossflag)		
		{

			MAFive=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,i); 
			MAThentyOne=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,i); 
			MASixty=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,i); 

		 	//定义多空状态指标
			StrongWeak =0.5;

			if(MAFive > MAThentyOne)
			{			
				/*多均线多头向上*/
				if(MASixty < MAThentyOne)
				{
					 StrongWeak =0.9;
				}
				else if ((MASixty >= MAThentyOne) &&(MASixty <MAFive))
				{
					 StrongWeak =0.6;
				}
				else
				{
					 StrongWeak =0.5;
				}
			
			}
			else if (MAFive < MAThentyOne)
			{
				/*多均线多头向下*/
				if(MASixty > MAThentyOne)
				{
					 StrongWeak =0.1;
				}
				else if ((MASixty <= MAThentyOne) &&(MASixty > MAFive))
				{
					 StrongWeak =0.4;
				}
				else
				{
					 StrongWeak =0.5;
				}  	
			
			}
			else
			{
				StrongWeak =0.5;

			}

			BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[j] = StrongWeak;
			BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[j] = crossflag;
			//BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[j] = TimeCurrent() - i*Period()*60;
			BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPos[j] = iBars(my_symbol,my_timeperiod)-i;
			j++;
			if (j >= (HCROSSNUMBER-1))
			{
				break;
			}
		}

	}
	

	j = 0;
	for (i = 2; i< countnumber;i++)
	{
		
		crossflag = 0;     
		myma=iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,i-1);  
		myboll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_UPPER,i-1);   
		myboll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_LOWER,i-1);
		myboll_mid_B = (	myboll_up_B +  myboll_low_B)/2;

		myma_pre = iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,i); 
		myboll_up_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_UPPER,i);      
		myboll_low_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_LOWER,i);
		myboll_mid_B_pre = (myboll_up_B_pre + myboll_low_B_pre)/2;

		if((myma >myboll_up_B) && (myma_pre < myboll_up_B_pre ) )
		{
				crossflag = 5;		
		}
		
		if((myma <myboll_up_B) && (myma_pre > myboll_up_B_pre ) )
		{
				crossflag = 4;
		}
			
		if((myma < myboll_low_B) && (myma_pre > myboll_low_B_pre ) )
		{
				crossflag = -5;
		}
			
		if((myma > myboll_low_B) && (myma_pre < myboll_low_B_pre ) )
		{
				crossflag = -4;	
		}
	
		if((myma > myboll_mid_B) && (myma_pre < myboll_mid_B_pre ))
		{
				crossflag = 1;				
		}	
		if( (myma < myboll_mid_B) && (myma_pre > myboll_mid_B_pre ))
		{
				crossflag = -1;								
		}			
		
		if(0 != 	crossflag)		
		{


			MAFive=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,i); 
			MAThentyOne=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,i); 
			MASixty=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,i); 

		 	//定义多空状态指标
			StrongWeak =0.5;

			if(MAFive > MAThentyOne)
			{			
				/*多均线多头向上*/
				if(MASixty < MAThentyOne)
				{
					 StrongWeak =0.9;
				}
				else if ((MASixty >= MAThentyOne) &&(MASixty <MAFive))
				{
					 StrongWeak =0.6;
				}
				else
				{
					 StrongWeak =0.5;
				}
			
			}
			else if (MAFive < MAThentyOne)
			{
				/*多均线多头向下*/
				if(MASixty > MAThentyOne)
				{
					 StrongWeak =0.1;
				}
				else if ((MASixty <= MAThentyOne) &&(MASixty > MAFive))
				{
					 StrongWeak =0.4;
				}
				else
				{
					 StrongWeak =0.5;
				}  	
			
			}
			else
			{
				StrongWeak =0.5;

			}

			BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[j] = StrongWeak;
			BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[j] = crossflag;
			//BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[j] = TimeCurrent() - i*Period()*60;
			BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[j] = iBars(my_symbol,my_timeperiod)-i;
			j++;
			if (j >= (HCROSSNUMBER-1))
			{
				break;
			}
		}

	}
	
	return 0;

}


// 初始化定义买卖点的状态参数，同时将此前的交易状态录入
void InitBuySellPos()
{
	int SymPos;
	int i ;
	string my_symbol;

	double vbid;
	int buysellpoint;
	int subbuysellpoint;
	int magicnumber,NowMagicNumber;

	SubMagicName[1] = "TrendBreakNumberOne";
	SubMagicName[2] = "TrendBreakNumberTwo";
	SubMagicName[3] = "TrendBreakNumberThree";
	SubMagicName[4] = "TrendBreakNumberFour";
	SubMagicName[5] = "TrendBreakNumberFive";
	SubMagicName[6] = "TrendBreakNumberSix";
	SubMagicName[7] = "TrendBreakNumberSeven";
	SubMagicName[8] = "TrendBreakNumberEight";
	SubMagicName[9] = "TrendBreakNumberNine";
	SubMagicName[10] = "TrendBreakNumberTen";
	SubMagicName[11] = "TrendBreakNumberEleven";
	SubMagicName[12] = "TrendBreakNumberTwelve";
	SubMagicName[13] = "TrendBreakNumberThirteen";
	SubMagicName[14] = "TrendBreakNumberFourteen";
	SubMagicName[15] = "TrendBreakNumberFifteen";
	SubMagicName[16] = "TrendBreakNumberSixteen";
	SubMagicName[17] = "TrendBreakNumberseventeen";
	SubMagicName[18] = "TrendBreakNumbereighteen";
	SubMagicName[19] = "TrendBreakNumbernineteen";
	SubMagicName[20] = "TrendBreakNumbertwenty";
	SubMagicName[21] = "TrendBreakNumbertwentyone";
	SubMagicName[22] = "TrendBreakNumbertwentytwo";
	SubMagicName[23] = "TrendBreakNumbertwentythree";
	SubMagicName[24] = "TrendBreakNumbertwentyfour";
	SubMagicName[25] = "TrendBreakNumber25";
	SubMagicName[26] = "TrendBreakNumber26";
	SubMagicName[27] = "TrendBreakNumber27";
	SubMagicName[28] = "TrendBreakNumber28";
	SubMagicName[29] = "TrendBreakNumber29";
	SubMagicName[30] = "TrendBreakNumber30";
	SubMagicName[31] = "TrendBreakNumber31";
	SubMagicName[32] = "TrendBreakNumber32";
	SubMagicName[33] = "TrendBreakNumber33";
	SubMagicName[34] = "TrendBreakNumber34";
	SubMagicName[35] = "TrendBreakNumber35";
	SubMagicName[36] = "TrendBreakNumber36";	
	SubMagicName[37] = "TrendBreakNumber37";
	SubMagicName[38] = "TrendBreakNumber38";
	SubMagicName[39] = "TrendBreakNumber39";
	SubMagicName[40] = "TrendBreakNumber40";
	SubMagicName[41] = "TrendBreakNumber41";
	SubMagicName[42] = "TrendBreakNumber42";
	SubMagicName[43] = "TrendBreakNumber43";
	SubMagicName[44] = "TrendBreakNumber44";
	SubMagicName[45] = "TrendBreakNumber45";
	SubMagicName[46] = "TrendBreakNumber46";
	SubMagicName[47] = "TrendBreakNumber47";
	SubMagicName[48] = "TrendBreakNumber48";

	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{
		
		my_symbol =   MySymbol[SymPos];
		vbid    = MarketInfo(my_symbol,MODE_BID);	
		for(subbuysellpoint = 0; subbuysellpoint <= 7;subbuysellpoint++)
		{
			for(buysellpoint = 1; buysellpoint <= HBUYSELLALGNUM;buysellpoint++)
			{


				//定义买卖点名称
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName =SubMagicName[buysellpoint]+IntegerToString(subbuysellpoint)+my_symbol;

				//定义 MagicNumber
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber = (SymPos+1)*MAINMAGIC + buysellpoint*10 + subbuysellpoint;

				//默认状态下设置所有的买卖状态为空仓状态
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;				

				//定义stoptailing为2.1
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes = 1.1;

				//定义伪装止损止盈值和实际止损止盈值之间的比值，防止黑平台根据你的头寸恶意止损和止盈
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel = 2.5;




				//记录当前一分钟的ibar位置
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);


				//定义时间周期，一分钟的买卖点,顺势交易的回调，回调已经很深，大概率回到正轨，因此止损稍微大一点
				if ((buysellpoint <= 8)&&(buysellpoint > 0))
				{
					//定义止损额度，这个值最为关键，计划通过自学习的方式获取，默认设置为16
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage = 20;
					//按照1.5倍的止损止盈比计算
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage = 0.5;						
				}
				//定义时间周期，五分钟及以上的买卖点
				else if((buysellpoint <= HBUYSELLALGNUM)&&(buysellpoint > 8))
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage = 16;
					//按照1.5倍的止损止盈比计算
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage = 0.5;											
				}
				else
				{
					;
				}

				//定义时间周期，一分钟的买卖点
				if ((buysellpoint <= 12)&&(buysellpoint > 0))
				{

					//挂单开始时间设置5分钟，或者5根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart = 15;	
					//挂单超时时间设置4个小时，或者60根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp = 60*4;	

					//定义伪装挂单超时时间，单位是分钟，或者是1分钟线；统一为4分钟，确保不好成交，但是又在交易系统中有痕迹
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp = 60;					
					
					//持用4个小时以后进入monitor
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod = 60*60*4;	

					//每单允许损失的最大账户金额比例2%
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.02 - 0.001*(int((int(AccountBalance()))/500)))/2;											

				}
				//定义时间周期，五分钟及以上的买卖点
				else if((buysellpoint <= HBUYSELLALGNUM)&&(buysellpoint > 12))
				{

					//挂单开始时间设置20分钟，或者20根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart = 15;	
					//挂单超时时间设置12个小时
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp = 60*12;	

					//定义伪装挂单超时时间，单位是分钟，或者是1分钟线；统一为4分钟，确保不好成交，但是又在交易系统中有痕迹
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp = 60*4;	

					//持用12个小时以后进入monitor
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod = 60*60*12;		

					//每单允许损失的最大账户金额比例5%
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.04- 0.002*(int((int(AccountBalance()))/500)))/2;		

				}
				else
				{
					;
				}


				//定义时间周期，一分钟的买卖点
				if ((buysellpoint <= 16)&&(buysellpoint > 0))
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeperiodnum = PERIOD_M1;										

				}
				//定义时间周期，五分钟及以上的买卖点
				else if((buysellpoint <= HBUYSELLALGNUM)&&(buysellpoint > 16))
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeperiodnum = PERIOD_M5;
	

				}
				else
				{
					;
				}
				//奇数定义为买点，偶数定义为卖点
				if((buysellpoint%2) ==1)
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag = 1;

				}
				else
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag = -1;

				}


			}

			for(buysellpoint = HBUYSELLALGNUM+1; buysellpoint <= HBUYSELLALGNUM*2;buysellpoint++)
			{


				//定义买卖点名称
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName =SubMagicName[buysellpoint]+IntegerToString(subbuysellpoint)+my_symbol;

				//定义 MagicNumber
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber = (SymPos+1)*MAINMAGIC + buysellpoint*10 + subbuysellpoint;

				//默认状态下设置所有的买卖状态为空仓状态
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;				

				//定义stoptailing为2.1
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes = 1.1;

				//定义伪装止损止盈值和实际止损止盈值之间的比值，防止黑平台根据你的头寸恶意止损和止盈
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel = 2.5;




				//记录当前一分钟的ibar位置
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);



				//定义时间周期，一分钟的买卖点,顺势交易的回调，回调已经很深，大概率回到正轨，因此止损稍微大一点
				if ((buysellpoint <= (HBUYSELLALGNUM+8))&&(buysellpoint >HBUYSELLALGNUM+0))
				{

					//定义止损额度，这个值最为关键，计划通过自学习的方式获取，默认设置为16
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage = 20;
					//按照1.5倍的止损止盈比计算
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage = 0.5;						
				}
				//定义时间周期，五分钟及以上的买卖点
				else if((buysellpoint <= HBUYSELLALGNUM*2)&&(buysellpoint >HBUYSELLALGNUM+8))
				{	
					//定义止损额度，这个值最为关键，计划通过自学习的方式获取，默认设置为16
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage = 16;
					//按照1.5倍的止损止盈比计算
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage = 0.5;										
				}
				else
				{
					;
				}

				//定义时间周期，一分钟的买卖点
				if ((buysellpoint <= HBUYSELLALGNUM+12)&&(buysellpoint >HBUYSELLALGNUM))
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeperiodnum = PERIOD_M1;

					//挂单开始时间设置5分钟，或者5根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart = 15;	
					//挂单超时时间设置1个小时，或者60根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp = 60;	

					//定义伪装挂单超时时间，单位是分钟，或者是1分钟线；统一为4分钟，确保不好成交，但是又在交易系统中有痕迹
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp = 60;					
					
					//持用2个小时以后进入monitor
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod = 60*60*2;	

					//每单允许损失的最大账户金额比例2%
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.02 - 0.001*(int((int(AccountBalance()))/500)))/2;											

				}
				//定义时间周期，五分钟及以上的买卖点
				else if((buysellpoint <= HBUYSELLALGNUM*2)&&(buysellpoint >HBUYSELLALGNUM+12))
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeperiodnum = PERIOD_M5;

					//挂单开始时间设置20分钟，或者20根1分钟线
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart = 15;	
					//挂单超时时间设置4个小时
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp = 60*4;	

					//定义伪装挂单超时时间，单位是分钟，或者是1分钟线；统一为4分钟，确保不好成交，但是又在交易系统中有痕迹
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp = 60*4;	

					//持用6个小时以后进入monitor
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod = 60*60*6;		

					//每单允许损失的最大账户金额比例5%
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].maxlose = (0.04- 0.002*(int((int(AccountBalance()))/500)))/2;		

				}
				else
				{
					;
				}

				//奇数定义为买点，偶数定义为卖点
				if((buysellpoint%2) ==1)
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag = 1;

				}
				else
				{
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag = -1;

				}


			}


		}	
												
	}


	//当前订单参数导入
	for (i = 0; i < OrdersTotal(); i++)
	{
   		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   		{
   	
			magicnumber = OrderMagicNumber();
			SymPos = ((int)magicnumber) /MAINMAGIC-1;
			NowMagicNumber = magicnumber - (SymPos+1)*MAINMAGIC;
		
			if((SymPos>=0)&&(SymPos<symbolNum))
			{
				my_symbol = MySymbol[SymPos];

				subbuysellpoint = (NowMagicNumber%10);  
				if((subbuysellpoint>= 0)&&(subbuysellpoint<= 7))
				{
					buysellpoint = ((int)NowMagicNumber) /10;
					if((buysellpoint>=1)&&(buysellpoint<=HBUYSELLALGNUM*2))
					{

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = OrderOpenTime();
						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = OrderOpenPrice();

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = OrderStopLoss();
						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = OrderTakeProfit();

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel = 2.5;	
												
						//BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = OrderStopLoss();
						//BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = OrderTakeProfit();	


						//买单，根据facked推算出实际值
						if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
						{
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
								(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss)
									/BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
								(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
									/BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

						}
						//卖单
						else
						{
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
								(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
									/BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
								(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit  )
									/BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

						}

						if((OrderType()==OP_BUY)||(OrderType()==OP_SELL))
						{
							//设置该订单状态为开仓状态
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;		

						}
						else if((OrderType()==OP_BUYLIMIT)||(OrderType()==OP_SELLLIMIT))
						{

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

						}

						else if((OrderType()==OP_BUYSTOP)||(OrderType()==OP_SELLSTOP))
						{

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

						}						
						else
						{
							;
						}

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(OrderOpenPrice()-OrderStopLoss())*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																		

						Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderLoad:" + "openprice=" + OrderOpenPrice() +"OrderStopLoss ="
									+OrderStopLoss()+"OrderTakeProfit="+OrderTakeProfit()+"stoptailing="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing);	
					}



				}	
				
			}


		}



	}
	
}

// 初始化定义当前的MA强弱情况，由trend和strongweak分别定义
void InitMA(int SymPos,int timeperiodnum)
{

	double MAThree,MAFive,MAThen,MAThentyOne,MASixty;
	double MAThreePre,MAFivePre,MAThenPre,MAThentyOnePre,MASixtyPre;
	double MAThreePrePre,MAThenPrePre;
	double StrongWeak;
	int my_timeperiod;	
	string my_symbol;
	
	my_symbol = MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];	
	
	MAThree=iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,1); 
	MAThen=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,1); 

	MAThreePre = iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,2); 
	MAThenPre=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,2); 

	MAThreePrePre = iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,3); 
	MAThenPrePre=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,3); 

	
	MAFive=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,1); 
	MAThentyOne=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,1); 
	MASixty=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,1); 
 
	MAFivePre=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,2); 
	MAThentyOnePre=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,2); 
	MASixtyPre=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,2); 
 



	//定义上升下降加速指标
 
 	StrongWeak =0.5;
 

	if(((MAThree-MAThreePre) > (MAThen-MAThenPre))&&((MAThenPre-MAThenPrePre)<(MAThen-MAThenPre)))
	{		
		StrongWeak =0.9;	
	}
	if(((MAThree-MAThreePre) < (MAThen-MAThenPre))&&((MAThenPre-MAThenPrePre)>(MAThen-MAThenPre)))
	{
		StrongWeak =0.1;
	
	}
	else
	{
		StrongWeak =0.5;

	}

	//MoreTrend用来定义加速上涨或者加速下跌 
	BoolCrossRecord[SymPos][timeperiodnum].MoreTrend = StrongWeak;


	//定义上升下降指标
 	StrongWeak =0.5;
 

	if((MAThree > MAThen)&&(MAThenPre<MAThen))
	{		
		StrongWeak =0.9;	
	}
	else if ((MAThree < MAThen)&&(MAThenPre>MAThen))
	{
		StrongWeak =0.1;
	
	}
	else
	{
		StrongWeak =0.5;

	}

	//Trend用来定义上涨，或者下跌趋势，非加速上涨或者加速下跌 
	BoolCrossRecord[SymPos][timeperiodnum].Trend = StrongWeak;

 
 	//定义多空状态指标
	StrongWeak =0.5;

	if(MAFive > MAThentyOne)
	{			
		/*多均线多头向上*/
		if(MASixty < MAThentyOne)
		{
			 StrongWeak =0.9;
		}
		else if ((MASixty >= MAThentyOne) &&(MASixty <MAFive))
		{
			 StrongWeak =0.6;
		}
		else
		{
			 StrongWeak =0.5;
		}
	
	}
	else if (MAFive < MAThentyOne)
	{
		/*多均线多头向下*/
		if(MASixty > MAThentyOne)
		{
			 StrongWeak =0.1;
		}
		else if ((MASixty <= MAThentyOne) &&(MASixty > MAFive))
		{
			 StrongWeak =0.4;
		}
		else
		{
			 StrongWeak =0.5;
		}  	
	
	}
	else
	{
		StrongWeak =0.5;

	}

	BoolCrossRecord[SymPos][timeperiodnum].StrongWeak = StrongWeak;	
	
}



// 定义穿越bool点标准差为2时的值、位置、强弱值，并且保留前一个穿越位置的值
void ChangeCrossValue( int mvalue,double  mstrongweak,int SymPos,int timeperiodnum)
{

	int i;
	int my_timeperiod;
	string symbol;
    symbol = MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];

		
	if (mvalue == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])
	{
		BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0] = mvalue;
	//	BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[0] = TimeCurrent();
		BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPos[0] = iBars(symbol,my_timeperiod);	
		
		BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[0] = mstrongweak;		
	
		
		return;
	}
	for (i = 0 ; i <(HCROSSNUMBER-1); i++)
	{
		BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[(HCROSSNUMBER-2)-i];
	//	BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[(HCROSSNUMBER-2)-i];
		BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPos[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPos[(HCROSSNUMBER-2)-i] ;		
		BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[(HCROSSNUMBER-2)-i];
	}
	
	BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0] = mvalue;
	//BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[0] = TimeCurrent();
	BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPos[0] = iBars(symbol,my_timeperiod);
	
	BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[0] = mstrongweak;

	return;
}


// 定义穿越bool点标准差为1.7时的值、位置、强弱值，并且保留前一个穿越位置的值
void ChangeCrossValueL( int mvalue,double  mstrongweak,int SymPos,int timeperiodnum)
{

	int i;
	int my_timeperiod;
	string symbol;
    symbol = MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];

		
	if (mvalue == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])
	{
		BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[0] = mvalue;
	//	BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[0] = TimeCurrent();
		BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[0] = iBars(symbol,my_timeperiod);	
		
		BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[0] = mstrongweak;		
		
		return;
	}
	for (i = 0 ; i <(HCROSSNUMBER-1); i++)
	{
		BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[(HCROSSNUMBER-2)-i];
	//	BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[(HCROSSNUMBER-2)-i];
		BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[(HCROSSNUMBER-2)-i] ;		
		BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[(HCROSSNUMBER-1)-i] = BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[(HCROSSNUMBER-2)-i];
	}
	
	BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[0] = mvalue;
	//BoolCrossRecord[SymPos][timeperiodnum].CrossDatetime[0] = TimeCurrent();
	BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[0] = iBars(symbol,my_timeperiod);
	
	BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[0] = mstrongweak;

	return;
}


/*非Openday期间不新开单*/
// 考虑了周六和周日的特俗情况，约束不大
bool opendaycheck(int SymPos)
{
	//	int i;
	string symbol;
	bool tradetimeflag;
	datetime timelocal;

	symbol = MySymbol[SymPos];
	tradetimeflag = true;

		
    timelocal = TimeCurrent() + globaltimezonediff*60*60;


	//	Print("opendaycheck:" + "timelocal=" + TimeToString(timelocal,TIME_DATE)
	//				 +"timelocal=" + TimeToString(timelocal,TIME_SECONDS));	

	//	Print("opendaycheck:" + "timecur=" + TimeToString(TimeCurrent(),TIME_DATE)
	//					 +"timecur=" + TimeToString(TimeCurrent(),TIME_SECONDS));	
		
					
	
	//周一早5点前不下单	
	if (TimeDayOfWeek(timelocal) == 1)
	{
		if (TimeHour(timelocal) < 5 ) 
		{
			tradetimeflag = false;
		}
	}
	
	//周六凌晨2点后不下单		
	if (TimeDayOfWeek(timelocal) == 6)
	{
		if (TimeHour(timelocal) > 2 )  
		{
			tradetimeflag = false;		
		}
	}	

	//周日不下单		
	if (TimeDayOfWeek(timelocal) == 0)
	{
			tradetimeflag = false;		
	}		
	return tradetimeflag;
}

/*欧美交易时间段多以趋势和趋势加强为主，非交易时间多以震荡为主，以此区分一些小周期的交易策略*/
/*因为三倍佣金的问题，周三的交易策略比较保守*/
bool tradetimecheck(int SymPos)
{
	//	int i;
	string symbol;
	bool tradetimeflag ;
	datetime timelocal;	
  	symbol = MySymbol[SymPos];
	tradetimeflag = false;


    /*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
    timelocal = TimeCurrent() + globaltimezonediff*60*60;


	//13点前不做趋势单，主要针对1分钟线和五分钟线，非欧美时间趋势不明显，针对趋势突破单，要用这个来检测
	//最原始的是下午1点前不做趋势单，通过扩大止损来寻找更多机会

	if (TimeDayOfWeek(timelocal) == 3)
	{	
		/*周三为了规避三倍佣金问题，因此20点以后不交易*/
		if ((TimeHour(timelocal) >= 13 )&& (TimeHour(timelocal) <20 )) 
		{
			tradetimeflag = true;		
		}	
	}
	else
	{
		if ((TimeHour(timelocal) >= 13 )&& (TimeHour(timelocal) <22 )) 
		{
			tradetimeflag = true;		
		}			
		
	}
	/*测试期间全时间段交易*/
	tradetimeflag = true;		
	
	return tradetimeflag;
	
}


// exness外汇商显示的杠杆跟实际杠杆比是1:2，因此需要修正
int myaccountleverage()
{
	int leverage;
	
	
	leverage = AccountLeverage();
	
	/*规避exness实际显示杠杆错误的问题*/
	if(AccountServer() == HEXNESSSERVER)
	{
		leverage = leverage*2;
		
	}
	return leverage;
}

/*仓位检测，确保账户总余额可以交易4次以上*/
// 正常交易的全局交易开关关闭的情况下不交易
bool accountcheck()
{
	bool accountflag ;
	int leverage ;
	accountflag = true;
	leverage = myaccountleverage();
	if(leverage < 20)
	{
		Print("Account leverage is to low leverage = ",leverage);		
		accountflag = false;		
	}


	/*全局交易开关关闭的情况下不交易*/
	if(false == getglobaltradeflag())
	{
		//accountflag = false;
	}

	//账户低于100美金的时候直接交易
	if(AccountFreeMargin()<100)
	{
		accountflag = true;
	}

	return accountflag;	
	
}


// 正常交易有效magicnumber，判断因素包括有效外汇、有效时间周一-周五、正常交易买卖点1-10
// 后面改进方式为将出现快速大幅变化的产生大幅盈利的交易排除在该交易点之外，处理起来比较复杂；也就是池塘捞到的大鱼要持续持有。
// 其中一个做法是如果当前大幅止损价格已经盈利，或者已经设置了大幅止损价格盈利的止损点。
bool isvalidmagicnumber(int magicnumber)
{
		
	bool flag = true;
	int SymPos,NowMagicNumber;
	
	SymPos = ((int)magicnumber) /MAINMAGIC-1;
	NowMagicNumber = magicnumber - (SymPos+1) *MAINMAGIC;

	if((SymPos<0)||(SymPos>=symbolNum))
	{
	 	flag = false;
	}	
	
	//周一到周五的单子
	if((6<=(NowMagicNumber%10))||(0>=(NowMagicNumber%10)))
	{
	 	flag = false;
	}	
	
	NowMagicNumber = ((int)NowMagicNumber) /10;
	if((NowMagicNumber<=0)||(NowMagicNumber>HBUYSELLALGNUM*2))
	{
	 	flag = false;
	}	
	
	//flag = true;

	return flag;
	
}


// 当前实际盈亏值，按照盈亏的百分比求和来计算。sum((ask-orderopenprice)/orderopenprice)
//去除近期成交单和设置成无止盈的手工单
double  ordersrealprofitall( )
{
	double profit = 0;
	int i,SymPos,NowMagicNumber;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单，可动态改变止损值
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{
						if(OrderType()==OP_BUY)
						{
							profit += (vask - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)/
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice;
						}
						
						if(OrderType()==OP_SELL)
						{
			 
							profit += (BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice - vask)/
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice;				
						}

					}

				}				

			
			}
			
		}
	}

	return profit;
}

// 期望最大止盈值，是按照盈利百分比来计算的，设想每个单都达到了止盈值的盈利百分比。sum(|ordertakeprofit-orderopenprice|/orderopenprice)
//去除近期成交单和设置成无止盈的手工单
double  ordersexpectedmaxprofitall( )
{
	double profit = 0;
	int i,SymPos,NowMagicNumber;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单，可以手动改变止损值
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{
						if(OrderType()==OP_BUY)
						{
							profit += (BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)/
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice;
						}
						
						if(OrderType()==OP_SELL)
						{
			 
							profit += (BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit)/
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice;				
						}

					}

				}				

			
			}
			
		}
	}

	return profit;
}



// 交易单的总数量，去除近期成交单和设置成无止盈的手工单
int ordercountall( )
{
	int count = 0;
	int i,SymPos,NowMagicNumber;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{

						if((OrderType()==OP_BUY)||(OrderType()==OP_SELL))
						{

							//if((OrderProfit()+OrderCommission())>myprofit)
							{
								count++;
							}	

						}

					}

				}				

			
			}
			
		}
	}
	
	return count;
}

// 交易单的总数量，去除近期成交单和设置成无止盈的手工单
int profitedordercountall(double  myprofit)
{
	int count = 0;
	int i,SymPos,NowMagicNumber;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{
						if((OrderType()==OP_BUY)||(OrderType()==OP_SELL))
						{

							if((OrderProfit()+OrderCommission())>myprofit)
							{
								count++;
							}	

						}


					}

				}				

			
			}
			
		}
	}
	
	return count;
}



// 正常交易单全部关闭掉；去除近期成交单和设置成无止盈的手工单
void ordercloseall()
{
	int i,SymPos,NowMagicNumber,ticket;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{
						if(OrderType()==OP_BUY)
						{
							ticket =OrderClose(OrderTicket(),OrderLots(),vbid,5,Red);
							  
							 if(ticket <0)
							 {
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose buy ordercloseall with vbid failed with error #",GetLastError());
							 }
							 else
							 {     
								BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;				        
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose buy ordercloseall with vbid  successfully");
							 }    	
							Sleep(1000); 
					
						}
						
						if(OrderType()==OP_SELL)
						{
							ticket =OrderClose(OrderTicket(),OrderLots(),vask,5,Red);
							  
							 if(ticket <0)
							 {
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose sell ordercloseall with vask  failed with error #",GetLastError());
							 }
							 else
							 {      
								BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;							       
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose sell ordercloseall with vask   successfully");
							 }  
							Sleep(1000);				 
					
						}

					}

				}				

			
			}
			
		}
	}
	
	return;
}


// 正常交易单全部关闭掉；去除近期成交单和设置成无止盈的手工单
void ordercloseall2()
{
	int i,SymPos,NowMagicNumber,ticket;
	string my_symbol;
	double vbid,vask;

	int buysellpoint;
	int subbuysellpoint;

	for (i = 0; i < OrdersTotal(); i++)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
			if(isvalidmagicnumber((int)OrderMagicNumber()) == true)
			{			

				SymPos = ((int)OrderMagicNumber()) /MAINMAGIC-1;
				NowMagicNumber = OrderMagicNumber() - (SymPos+1) *MAINMAGIC;

				buysellpoint = ((int)NowMagicNumber) /10;				
				subbuysellpoint = (NowMagicNumber%10);  	
					
				my_symbol = MySymbol[SymPos];
				
				vbid    = MarketInfo(my_symbol,MODE_BID);						  
				vask    = MarketInfo(my_symbol,MODE_ASK);	

				//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单
				//一般情况下不触发
				if(OrderTakeProfit()>0.01)
				{
					if((TimeCurrent()-OrderOpenTime())>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].keepperiod)
					{
						if(OrderType()==OP_BUY)
						{
							ticket =OrderClose(OrderTicket(),OrderLots(),vask,5,Red);
							  
							if(ticket <0)
							{
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose buy ordercloseall with vbid failed with error #",GetLastError());
							}
							else
							{    
								BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;							        
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose buy ordercloseall with vbid  successfully");
							}    	
							Sleep(1000); 
					
						}
						
						if(OrderType()==OP_SELL)
						{
							ticket =OrderClose(OrderTicket(),OrderLots(),vbid,5,Red);
							  
							if(ticket <0)
							{
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose sell ordercloseall with vask  failed with error #",GetLastError());
							}
							else
							{       
								BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;								     
								Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderClose sell ordercloseall with vask   successfully");
							}  
							Sleep(1000);				 
					
						}

					}

				}				

			
			}
			
		}
	}
	
	return;
}

// 正常交易出现大幅盈利的情况下平掉所有交易，去除近期成交单和设置成无止盈的手工单
void monitoraccountprofit()
{

	double mylots = 0;	
	double mylots0 = 0;
	
	datetime timelocal;	

	string subject="";
	string some_text="";

	bool turnoffflag = false;

	int allordernumbers;
	/*原则上采用服务器交易时间，为了便于人性化处理，做了一个转换*/	
	timelocal = TimeCurrent() + globaltimezonediff*60*60;

	allordernumbers = ordercountall();
	/*当天订单已经平掉的情况下就不走这个分支了*/
	if(allordernumbers<=2)
	{
		return;
	}

	
	if((allordernumbers>=(symbolNum/3))&&(ordercountall() == profitedordercountall(0)))
	{
		Print("1 This turn Own more than "+(symbolNum/3)+" orders witch is "+allordernumbers+" all profit order,Close all");				
		turnoffflag = true;						
	}
	


	/*订单数量11个，且获利超过300美元，落袋为安*/
	if(ordersrealprofitall()>(ordersexpectedmaxprofitall()*250/(allordernumbers*allordernumbers*allordernumbers+allordernumbers*allordernumbers+10*allordernumbers+400)))
	{
		
		turnoffflag = true;						
		Print("2 successfully Close All: allordernumbers = " + allordernumbers + "ordersexpectedmaxprofitall = " + ordersexpectedmaxprofitall()
				+"ordersrealprofitall = "+ordersrealprofitall());		
	}	
	
	
	/*关闭所有在监控的货币，去掉止盈的货币和近期刚进入的货币不在监控范围内*/
	if(turnoffflag == true)
	{			
		int j=0;
		int k = 0;		
		
		/*一波做完后，手工禁止交易；第二天继续做*/					
		for(j = 0;j < 24; j++)
		{
			if(ordercountall()>0)
			{
				Sleep(1000); 
				ordercloseall();
				Sleep(1000); 
				ordercloseall2();					
				Sleep(1000); 
				k++;				
			}
			
		}
		if(k>=(j-1))
		{		
			Print("!!monitoraccountprofit Something Serious Error by colse all order,pls close handly");			
			//SendMail( "!!monitoraccountprofit Something Serious Error by colse all order,pls close handly","");		
		}
						
	}
	
}


// 主程序初始化
int init()
{

	int SymPos;
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;
	int symbolvalue;

	string MailTitlle ="";

	symbolvalue = 0;

	// 判断链接的外汇服务器是否正确
	if(false == forexserverconnect())
	{
		
		Print("connect to wrong server,and disable autotrade");			
		/*关闭自动交易*/
		return -1;
		
	}	
	else
	{
		Print("connect to right server,and enable autotrade");			
		/*打开自动交易*/
		//return 0;		
	}
	
	// 初始化外汇集合
	initsymbol();  

	// 打开外汇集合
	openallsymbo();

	//初始化外汇特性参数
	initforexindex();	

	// 初始化magicnumber
	//initmagicnumber();
	
	// 初始化时间周期
	inittiimeperiod();
	
	/*初始化正常交易全局交易指标，交易时间段使能，非交易时间段禁止*/
	initglobaltradeflag();	

	
	// 初始化买卖点的位置，当前未起作用
	InitBuySellPos();
	
	// 防止错误导致的重复交易
	Freq_Count = 0;
	TwentyS_Freq = 0;
	OneM_Freq = 0;
	ThirtyS_Freq = 0;
	FiveM_Freq = 0;
	ThirtyM_Freq = 0;
	
	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{	
		for(timeperiodnum = 0; timeperiodnum < TimePeriodNum;timeperiodnum++)
		{	
	

			my_symbol =   MySymbol[SymPos];
			my_timeperiod = timeperiod[timeperiodnum];			 

			// 初始化外汇集、周期集下的穿越bool集合
			InitcrossValue(SymPos,timeperiodnum);
			// 初始化当前外汇、周期下的短期强弱trend和多头强弱
			InitMA(SymPos,timeperiodnum);


			Print(my_symbol+"CrossFlag["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);		

			//注释掉部分供测试使用
			/*
			Print(my_symbol+"CrossStrongWeak["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeak[9]);		
				


			Print(my_symbol+"CrossFlagL["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9]);	

			Print(my_symbol+"CrossStrongWeakL["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossStrongWeakL[9]);	

			*/
		}
	
	}
 
	// 打印账户信息情况
	Print("Server name is ", AccountServer());	  
	Print("Account #",AccountNumber(), " leverage is ", AccountLeverage());
	Print("Account Balance= ",AccountBalance());		
	Print("Account free margin = ",AccountFreeMargin());	  

	return 0;
  
}


// 主程序退出
int deinit()
{

	return 0;
}



int ChartEvent = 0;
bool PrintFlag = false;



// 每个时间周期调用一次，计算当前周期强弱等相关值，寻找bool穿越点，并记录当时的值
void calculateindicator()
{
	
	int SymPos;
	int timeperiodnum;
	int my_timeperiod;

	double ma;
	double boll_up_B,boll_low_B,boll_mid_B,bool_length;
	
	double MAThree,MAFive,MAThen,MAThentyOne,MASixty;
	double MAThreePre,MAFivePre,MAThenPre,MAThentyOnePre,MASixtyPre;
	double MAThreePrePre,MAThenPrePre;	
	double StrongWeak;
	double vbid,vask; 
	string my_symbol;
	double boolindex;
	
	int crossflag;	


	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{	
		
		for(timeperiodnum = 0; timeperiodnum < TimePeriodNum;timeperiodnum++)
		{
			
			my_symbol =   MySymbol[SymPos];
			my_timeperiod = timeperiod[timeperiodnum];			
			//确保指标计算是每个周期计算一次，而不是每个tick计算一次
			if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,my_timeperiod))
			{
				
				ma=iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,1); 
				// ma = Close[0];  
				boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
				boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
				boll_mid_B = (boll_up_B + boll_low_B )/2;
				/*point*/
				bool_length =(boll_up_B - boll_low_B )/2;
	
				ma_pre = iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,2); 
				boll_up_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,2);      
				boll_low_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,2);
				boll_mid_B_pre = (boll_up_B_pre + boll_low_B_pre )/2;
	
				crossflag = 0;
				
			
				StrongWeak = BoolCrossRecord[SymPos][timeperiodnum].StrongWeak;
				
				/*本周期突破高点，观察如小周期未衰竭可追高买入，或者等待回调买入*/
				/*原则上突破bool线属于偏离价值方向太大，是要回归价值中枢的*/
				if((ma >boll_up_B) && (ma_pre < boll_up_B_pre ) )
				{
				
					crossflag = 5;		
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);
					//  Print(mMailTitlle + Symbol()+"::本周期突破高点，除(1M、5M周期bool口收窄且快速突破追高，移动止损），其他情况择机反向做空:"
					//  + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      
	
				}
				
				/*本周期突破高点后回调，观察如小周期长时间筑顶，寻机卖出*/
				else if((ma <boll_up_B) && (ma_pre > boll_up_B_pre ) )
				{
					crossflag = 4;
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol()+"::本周期突破高点后回调，观察小周期如长时间筑顶，寻机做空:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      
	
		   
				}
					
				
				/*本周期突破低点，观察如小周期未衰竭可追低卖出，或者等待回调卖出*/
				else if((ma < boll_low_B) && (ma_pre > boll_low_B_pre ) )
				{
				
					
					crossflag = -5;
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol() + "::本周期突破低点，除(条件：1M、5M周期bool口收窄且快速突破追低，移动止损），其他情况择机反向做多:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
		   
				}
					
				/*本周期突破低点后回调，观察如长时间筑底，寻机买入*/
				else if((ma > boll_low_B) && (ma_pre < boll_low_B_pre ) )
				{
					crossflag = -4;	
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol() + "::本周期突破低点后回调，观察如小周期长时间筑底，寻机买入:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
	
				}
			
				/*本周期上穿中线，表明本周期趋势开始发生变化为上升，在下降大趋势下也可能是回调杀入机会*/
				else if((ma > boll_mid_B) && (ma_pre < boll_mid_B_pre ))
				{
				
					crossflag = 1;				
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);			
					//    Print(mMailTitlle + Symbol() + "::本周期上穿中线变化为上升，大周期下降大趋势下可能是回调做空机会："
					//    + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
	   
				}	
				/*本周期下穿中线，表明趋势开始发生变化，在上升大趋势下也可能是回调杀入机会*/
				else if( (ma < boll_mid_B) && (ma_pre > boll_mid_B_pre ))
				{
					crossflag = -1;								
					ChangeCrossValue(crossflag,StrongWeak,SymPos,timeperiodnum);			
					 //     Print(mMailTitlle + Symbol() + "::本周期下穿中线变化为下降，大周期上升大趋势下可能是回调做多机会："
					 //     + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
				}							
				else
				{
					 crossflag = 0;   
	       
				}
	
				BoolCrossRecord[SymPos][timeperiodnum].BoolFlag = BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0];
				BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange = crossflag;


				////////////////////////////////////////////////////////////////////////////
				
				ma=iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,1); 
				// ma = Close[0];  
				boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_UPPER,1);   
				boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_LOWER,1);
				boll_mid_B = (boll_up_B + boll_low_B )/2;
				/*point*/
				//bool_length =(boll_up_B - boll_low_B )/2;
	
				ma_pre = iMA(my_symbol,my_timeperiod,Move_Av,0,MODE_SMA,PRICE_CLOSE,2); 
				boll_up_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_UPPER,2);      
				boll_low_B_pre = iBands(my_symbol,my_timeperiod,iBoll_B,1.7,0,PRICE_CLOSE,MODE_LOWER,2);
				boll_mid_B_pre = (boll_up_B_pre + boll_low_B_pre )/2;
	
				crossflag = 0;
							
				StrongWeak = BoolCrossRecord[SymPos][timeperiodnum].StrongWeak;
				
				/*本周期突破高点，观察如小周期未衰竭可追高买入，或者等待回调买入*/
				/*原则上突破bool线属于偏离价值方向太大，是要回归价值中枢的*/
				if((ma >boll_up_B) && (ma_pre < boll_up_B_pre ) )
				{
				
					crossflag = 5;		
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);
					//  Print(mMailTitlle + Symbol()+"::本周期突破高点，除(1M、5M周期bool口收窄且快速突破追高，移动止损），其他情况择机反向做空:"
					//  + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      
	
				}
				
				/*本周期突破高点后回调，观察如小周期长时间筑顶，寻机卖出*/
				else if((ma <boll_up_B) && (ma_pre > boll_up_B_pre ) )
				{
					crossflag = 4;
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol()+"::本周期突破高点后回调，观察小周期如长时间筑顶，寻机做空:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      
	
		   
				}
					
				
				/*本周期突破低点，观察如小周期未衰竭可追低卖出，或者等待回调卖出*/
				else if((ma < boll_low_B) && (ma_pre > boll_low_B_pre ) )
				{
				
					
					crossflag = -5;
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol() + "::本周期突破低点，除(条件：1M、5M周期bool口收窄且快速突破追低，移动止损），其他情况择机反向做多:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
		   
				}
					
				/*本周期突破低点后回调，观察如长时间筑底，寻机买入*/
				else if((ma > boll_low_B) && (ma_pre < boll_low_B_pre ) )
				{
					crossflag = -4;	
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);
					//   Print(mMailTitlle + Symbol() + "::本周期突破低点后回调，观察如小周期长时间筑底，寻机买入:"
					//   + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
	
				}
			
				/*本周期上穿中线，表明本周期趋势开始发生变化为上升，在下降大趋势下也可能是回调杀入机会*/
				else if((ma > boll_mid_B) && (ma_pre < boll_mid_B_pre ))
				{
				
					crossflag = 1;				
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);			
					//    Print(mMailTitlle + Symbol() + "::本周期上穿中线变化为上升，大周期下降大趋势下可能是回调做空机会："
					//    + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
	   
				}	
				/*本周期下穿中线，表明趋势开始发生变化，在上升大趋势下也可能是回调杀入机会*/
				else if( (ma < boll_mid_B) && (ma_pre > boll_mid_B_pre ))
				{
					crossflag = -1;								
					ChangeCrossValueL(crossflag,StrongWeak,SymPos,timeperiodnum);			
					 //     Print(mMailTitlle + Symbol() + "::本周期下穿中线变化为下降，大周期上升大趋势下可能是回调做多机会："
					 //     + DoubleToString(bool_length)+":"+DoubleToString(bool_length/Point));  	  	      	      	      
	
				}							
				else
				{
					 crossflag = 0;   
	       
				}
	
				BoolCrossRecord[SymPos][timeperiodnum].BoolFlagL = BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0];
				BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL = crossflag;
				
				
				
				
				//////////////////////////////////////////////////////////////////////////////


				
				vask    = MarketInfo(my_symbol,MODE_ASK);
				vbid    = MarketInfo(my_symbol,MODE_BID);	
				if(((bool_length <0.00001)&&(bool_length >=0))||((bool_length >-0.00001)&&(bool_length <0))	)
				{
					Print(my_symbol+":"+my_timeperiod+"bool_length is Zero,ERROR!!");
				}			
				else
				{
					boolindex = ((vask + vbid)/2 - boll_mid_B)/bool_length;
					BoolCrossRecord[SymPos][timeperiodnum].BoolIndex = boolindex;
				}
	
		   
		   
				MAThree=iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,1); 
				MAThen=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,1);  

				MAThreePre = iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,2); 
				MAThenPre=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,2); 

				MAThreePrePre = iMA(my_symbol,my_timeperiod,3,0,MODE_SMA,PRICE_CLOSE,3); 
				MAThenPrePre=iMA(my_symbol,my_timeperiod,10,0,MODE_SMA,PRICE_CLOSE,3); 
		 
					
				MAFive=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,1); 
				MAThentyOne=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,1); 
				MASixty=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,1); 
			 
				MAFivePre=iMA(my_symbol,my_timeperiod,5,0,MODE_SMA,PRICE_CLOSE,2); 
				MAThentyOnePre=iMA(my_symbol,my_timeperiod,21,0,MODE_SMA,PRICE_CLOSE,2); 
				MASixtyPre=iMA(my_symbol,my_timeperiod,60,0,MODE_SMA,PRICE_CLOSE,2); 
				 

				//定义上升下降加速指标
			 
			 	StrongWeak =0.5;
			 

				if(((MAThree-MAThreePre) > (MAThen-MAThenPre))&&((MAThenPre-MAThenPrePre)<(MAThen-MAThenPre)))
				{		
					StrongWeak =0.9;	
				}
				if(((MAThree-MAThreePre) < (MAThen-MAThenPre))&&((MAThenPre-MAThenPrePre)>(MAThen-MAThenPre)))
				{
					StrongWeak =0.1;
				
				}
				else
				{
					StrongWeak =0.5;

				}

				//MoreTrend用来定义加速上涨或者加速下跌 
				BoolCrossRecord[SymPos][timeperiodnum].MoreTrend = StrongWeak;

	
				StrongWeak =0.5;
			 
	
				if((MAThree > MAThen)&&(MAThenPre<MAThen))
				{		
					StrongWeak =0.9;	
				}
				else if ((MAThree < MAThen)&&(MAThenPre>MAThen))
				{
					StrongWeak =0.1;
				
				}
				else
				{
					StrongWeak =0.5;
	
				}
	
				
				BoolCrossRecord[SymPos][timeperiodnum].Trend = StrongWeak;
				
	
				 
				 
				 
				StrongWeak =0.5;
		   
				if(MAFive > MAThentyOne)
				{
						
					/*多均线多头向上*/
					if(MASixty < MAThentyOne)
					{
						 StrongWeak =0.9;
					}
					else if ((MASixty >= MAThentyOne) &&(MASixty <MAFive))
					{
						 StrongWeak =0.6;
					}
					else
					{
						 StrongWeak =0.5;
					}
				
				}
				else if (MAFive < MAThentyOne)
				{
					/*多均线多头向下*/
					if(MASixty > MAThentyOne)
					{
						 StrongWeak =0.1;
					}
					else if ((MASixty <= MAThentyOne) &&(MASixty > MAFive))
					{
						 StrongWeak =0.4;
					}
					else
					{
						 StrongWeak =0.5;
					}  	
				
				}
				else
				{
					StrongWeak =0.5;
		   
				}
		   
		   
				BoolCrossRecord[SymPos][timeperiodnum].StrongWeak = StrongWeak;
	
		   
	
		
			}
		}	
		
	}	
	
	return;
}


/*一分钟具有相当的不稳定性，因此1分钟交易是有时间段的，主要在交易活跃期间进行，这个期间容易形成小周期的趋势*/
void orderbuyselltypeone(int SymPos)
{
	
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;

	double boll_up_B,boll_low_B,boll_mid_B,bool_length;	
	double vbid,vask; 
	double MinValue3 = 100000;
	double MaxValue4=-1;

	double orderStopLevel;
	double orderpoint;
	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;
	datetime timelocal,timeexp;	
	double bool_length_upperiod;

	int buysellpoint;
	int subbuysellpoint;

	int i,ticket;
 	int ttick;
	int    vdigits ;
	
	/*一分钟周期寻找买卖点*/
	timeperiodnum = 0;	

	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;



	my_symbol =   MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];		
	
	//确保寻找买卖点是每个周期计算一次，而不是每个tick计算一次
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent == iBars(my_symbol,my_timeperiod))
	{
		return;
	}


	/*原则上采用GMT时间，为了便于人性化处理，做了一个转换*/	
	//timelocal = TimeCurrent() + globaltimezonediff*60*60-8*60*60; 

	timelocal = TimeCurrent() ;
	subbuysellpoint = (TimeDayOfWeek(timelocal))%7;  		
	


	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);	
	bool_length_upperiod = (boll_up_B - boll_low_B )/2;
	
	boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
	boll_mid_B = (boll_up_B + boll_low_B )/2;
	/*point*/
	bool_length =(boll_up_B - boll_low_B )/2;	



	//一分钟小周期回调大概率不破大趋势，并且挂单、小止损、迅速平保，找到顺势回调的好的介入点
	buysellpoint = 1;
	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])				
			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))									
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);


			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
					
				}

			}


		}

	}			
	

	buysellpoint = 3;

	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)	
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)					
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);	

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");

				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
				
			}


		}

	}			
	

	buysellpoint = 5;
	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.8)						
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])				
			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))									
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;


			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);


			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
	

	buysellpoint = 7;

	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.8)		
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)					
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);	

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{

					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	






	buysellpoint = 9;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
	

	buysellpoint = 11;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);		

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 13;

	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);	


			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;




			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 15;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);


			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	



	
	////////////////////////////////////////////////////////////////////////
	//多空分界线
	////////////////////////////////////////////////////////////////////////



	buysellpoint = 2;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)				
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			

			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 4;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)	
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)							
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
			
	buysellpoint = 6;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.2)					
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{


				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	

	buysellpoint = 8;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.2)		

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)							
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
			




	buysellpoint = 10;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 12;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	

	buysellpoint = 14;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			

			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
 			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 16;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			

			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;


			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}						
						
}


/*五分钟具有相当的不稳定性，因此1分钟交易是有时间段的，主要在交易活跃期间进行，这个期间容易形成小周期的趋势*/
void orderbuyselltypetwo(int SymPos)
{
	
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;

	double boll_up_B,boll_low_B,boll_mid_B,bool_length;	
	double vbid,vask; 
	double MinValue3 = 100000;
	double MaxValue4=-1;

	double orderStopLevel;
	double orderpoint;
	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;
	datetime timelocal,timeexp;	
	double bool_length_upperiod;

	int buysellpoint;
	int subbuysellpoint;
	
	int i,ticket;
 	int ttick;
	int    vdigits ;
	
	/*实际上是五分钟周期寻找买卖点*/
	timeperiodnum = 0;	

	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;

		
	/*原则上采用GMT时间，为了便于人性化处理，做了一个转换*/	
	//	timelocal = TimeCurrent() + globaltimezonediff*60*60-8*60*60; 
	timelocal = TimeCurrent(); 	
	subbuysellpoint = (TimeDayOfWeek(timelocal))%7;  

	my_symbol =   MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];	
	
	
	//确保寻找买卖点是每个周期计算一次，而不是每个tick计算一次
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent == iBars(my_symbol,my_timeperiod))
	{
		return;
	}
	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+2],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+2],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);	
	bool_length_upperiod = (boll_up_B - boll_low_B )/2;
	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
	boll_mid_B = (boll_up_B + boll_low_B )/2;
	/*point*/
	bool_length =(boll_up_B - boll_low_B )/2;	
	

	//定义买点11
	buysellpoint = 17;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					

							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);					
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");

						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}			
	

	buysellpoint = 19;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
		

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	


	buysellpoint = 21;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+2],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	

	buysellpoint = 23;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+2],i);
				}
				
			}	


			//突破新低后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;




			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	
	
	////////////////////////////////////////////////////////////////////////
	//多空分界线
	////////////////////////////////////////////////////////////////////////

	

	buysellpoint = 18;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;


			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					


						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);					
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = 20;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);			

			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;


			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	

	buysellpoint = 22;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			
			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+2],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
									
			}


		}

	}			
	

	buysellpoint = 24;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+2],i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;


			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);


			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
		

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{
				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLLIMIT,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;

							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGLIMIT;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}						
						
}


/*一分钟具有相当的不稳定性，因此1分钟交易是有时间段的，主要在交易活跃期间进行，这个期间容易形成小周期的趋势*/
void orderbuyselltypethree(int SymPos)
{
	
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;

	double boll_up_B,boll_low_B,boll_mid_B,bool_length;	
	double vbid,vask; 
	double MinValue3 = 100000;
	double MaxValue4=-1;

	double orderStopLevel;
	double orderpoint;
	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;
	datetime timelocal,timeexp;	
	double bool_length_upperiod;

	int buysellpoint;
	int subbuysellpoint;

	int i,ticket;
 	int ttick;
	int    vdigits ;
	
	/*一分钟周期寻找买卖点*/
	timeperiodnum = 0;	

	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;



	my_symbol =   MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];		
	
	//确保寻找买卖点是每个周期计算一次，而不是每个tick计算一次
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent == iBars(my_symbol,my_timeperiod))
	{
		return;
	}


	/*原则上采用GMT时间，为了便于人性化处理，做了一个转换*/	
	//timelocal = TimeCurrent() + globaltimezonediff*60*60-8*60*60; 

	timelocal = TimeCurrent() ;
	subbuysellpoint = (TimeDayOfWeek(timelocal))%7;  		
	


	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);	
	bool_length_upperiod = (boll_up_B - boll_low_B )/2;
	
	boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
	boll_mid_B = (boll_up_B + boll_low_B )/2;
	/*point*/
	bool_length =(boll_up_B - boll_low_B )/2;	



	//一分钟小周期回调大概率不破大趋势，并且挂单、小止损、迅速平保，找到顺势回调的好的介入点
	buysellpoint = HBUYSELLALGNUM+1;
	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])				
			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))									
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						



			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);


			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
					
				}

			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+3;

	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)		
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)					
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");

				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
				
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+5;
	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.8)						
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])				
			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))									
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						



			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);


			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+7;

	//市场结构发生变化的回调结束的时候转多介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)	
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.8)		
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)					
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.2)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak<0.2))

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{

					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	






	buysellpoint = HBUYSELLALGNUM+9;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);			
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						



			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+11;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,my_timeperiod,i))
				{
					MaxValue4 = iHigh(my_symbol,my_timeperiod,i);
				}					
			}						

			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+13;

	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+15;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}							


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	



	
	////////////////////////////////////////////////////////////////////////
	//多空分界线
	////////////////////////////////////////////////////////////////////////



	buysellpoint = HBUYSELLALGNUM+2;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)	
							
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}		

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+4;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)							
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}					

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
			
	buysellpoint = HBUYSELLALGNUM+6;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.2)					
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}		

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{


				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+8;
	//市场结构发生变化的回调结束的时候转空介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.2)		

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)							
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[9])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[10])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[11])	
			&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[12])	
			&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[13])

			&&((BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.8)
				||(BoolCrossRecord[SymPos][timeperiodnum+1].StrongWeak>0.8))	

			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}					

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
								
			}


		}

	}			
			




	buysellpoint = HBUYSELLALGNUM+10;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}		

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+12;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+2].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+1].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,my_timeperiod) -BoolCrossRecord[SymPos][timeperiodnum].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,my_timeperiod,i))
				{
					MinValue3 = iLow(my_symbol,my_timeperiod,i);
				}
				
			}					

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
						

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);		
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	

	buysellpoint = HBUYSELLALGNUM+14;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}				

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
 			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+16;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[8]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}				

			//突破新高后下单
			orderPrice = MinValue3*2-(vbid+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单1个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			

						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}						
						
}


/*五分钟具有相当的不稳定性，因此1分钟交易是有时间段的，主要在交易活跃期间进行，这个期间容易形成小周期的趋势*/
void orderbuyselltypefour(int SymPos)
{
	
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;

	double boll_up_B,boll_low_B,boll_mid_B,bool_length;	
	double vbid,vask; 
	double MinValue3 = 100000;
	double MaxValue4=-1;

	double orderStopLevel;
	double orderpoint;
	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;
	datetime timelocal,timeexp;	
	double bool_length_upperiod;

	int buysellpoint;
	int subbuysellpoint;
	
	int i,ticket;
 	int ttick;
	int    vdigits ;
	
	/*实际上是五分钟周期寻找买卖点*/
	timeperiodnum = 0;	

	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;

		
	/*原则上采用GMT时间，为了便于人性化处理，做了一个转换*/	
	//	timelocal = TimeCurrent() + globaltimezonediff*60*60-8*60*60; 
	timelocal = TimeCurrent(); 	
	subbuysellpoint = (TimeDayOfWeek(timelocal))%7;  

	my_symbol =   MySymbol[SymPos];
	my_timeperiod = timeperiod[timeperiodnum];	
	
	
	//确保寻找买卖点是每个周期计算一次，而不是每个tick计算一次
	if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent == iBars(my_symbol,my_timeperiod))
	{
		return;
	}
	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+2],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+2],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);	
	bool_length_upperiod = (boll_up_B - boll_low_B )/2;
	
	boll_up_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
	boll_low_B = iBands(my_symbol,timeperiod[timeperiodnum+1],iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
	boll_mid_B = (boll_up_B + boll_low_B )/2;
	/*point*/
	bool_length =(boll_up_B - boll_low_B )/2;	
	

	//定义买点11
	buysellpoint = HBUYSELLALGNUM+17;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					

							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);					
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");

						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+19;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+1],i);
				}					
			}						
			


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
		

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	


	buysellpoint = HBUYSELLALGNUM+21;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[0]<0.55)
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[0])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (-3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+2],i);
				}					
			}						
				


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}
				}		
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+23;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak<0.2)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak>0.8)				
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[1]<0.55)
		&& (5== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlag[0])	
		&& (1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])			
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])	
		&& (3> BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 < BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (0.5 < BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);

			MaxValue4 = -1;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[5]+5);i++)
			{
				if(MaxValue4 < iHigh(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MaxValue4 = iHigh(my_symbol,timeperiod[timeperiodnum+2],i);
				}					
			}						
				
				


			//突破新高后下单
			orderPrice = MaxValue4*2-(vask+MaxValue4*3)/4;			 			
			orderStopless =orderPrice -    bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice + bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderPrice - orderStopless) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice - orderStopLevel*orderpoint;
			 }
			 if ((orderTakeProfit - orderPrice) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice + orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{	

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{					
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_BUYSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);


							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	
	
	////////////////////////////////////////////////////////////////////////
	//多空分界线
	////////////////////////////////////////////////////////////////////////

	

	buysellpoint = HBUYSELLALGNUM+18;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}				
	

			//突破新高后下单
			orderPrice = MinValue3*2-(vask+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					


						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);					
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	



							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+20;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+3].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+2].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+2].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);			

			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+1]) -BoolCrossRecord[SymPos][timeperiodnum+1].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+1],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+1],i);
				}
				
			}				

			//突破新高后下单
			orderPrice = MinValue3*2-(vask+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
					

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
								
			}


		}

	}			
	

	

	buysellpoint = HBUYSELLALGNUM+22;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[0]>0.45)
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[0])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])								
		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		
		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+2],i);
				}
				
			}				
	

			//突破新高后下单
			orderPrice = MinValue3*2-(vask+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);



			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);
			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;
			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
			

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{

				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{						
					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}	
				}	
									
			}


		}

	}			
	

	buysellpoint = HBUYSELLALGNUM+24;
	//市场结构发生变化的转多初期介入进去，采用小止损、限时、挂单的方式
	if((BoolCrossRecord[SymPos][timeperiodnum+4].StrongWeak>0.8)
		&&(BoolCrossRecord[SymPos][timeperiodnum+5].StrongWeak<0.2)			
		&&(BoolCrossRecord[SymPos][timeperiodnum+3].CrossStrongWeakL[1]>0.45)
		&& (-5== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlag[0])	
		&& (-1== BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[1])			
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[2])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[3])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[4])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[5])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[6])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[7])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[8])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[9])	
		&& (-3< BoolCrossRecord[SymPos][timeperiodnum+3].CrossFlagL[10])	

		&&(opendaycheck(SymPos) == true)
		&&(tradetimecheck(SymPos) ==true)				
		&&((OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
			||(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true))
		)
	{
		

		/*五分钟超级强势势，等待再次突破，挂单小止损*/
		if((-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlagChangeL)				
			&& (-4 == BoolCrossRecord[SymPos][timeperiodnum+1].CrossFlag[0])	
			&& (0 > BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])				
			&& (-0.5 > BoolCrossRecord[SymPos][timeperiodnum+1].BoolIndex)	
			&&(OneMOrderCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)				
			)			
					
		{
			
			vask    = MarketInfo(my_symbol,MODE_ASK);
			vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS);
			vbid    = MarketInfo(my_symbol,MODE_BID);
			MinValue3 = 100000;
			for (i= 0;i < (iBars(my_symbol,timeperiod[timeperiodnum+2]) -BoolCrossRecord[SymPos][timeperiodnum+2].CrossBoolPosL[5]+5);i++)
			{
				if(MinValue3 > iLow(my_symbol,timeperiod[timeperiodnum+2],i))
				{
					MinValue3 = iLow(my_symbol,timeperiod[timeperiodnum+2],i);
				}
				
			}			

			//突破新高后下单
			orderPrice = MinValue3*2-(vask+MinValue3*3)/4;		 			
			orderStopless =orderPrice +   bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage; 		
			orderTakeProfit = orderPrice - bool_length_upperiod*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossleverage*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoplossprofitleverage;



			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
			//买单，根据facked推算出实际值
			if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;												

			}
			//卖单
			else
			{
				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

				BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
					(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit  )
						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;	

			}

			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);
			BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,vdigits);




			orderLots = autocalculateamount(SymPos,buysellpoint,subbuysellpoint);

			
			/*参数修正*/ 
			orderStopLevel =MarketInfo(my_symbol,MODE_STOPLEVEL);	
			orderpoint = MarketInfo(my_symbol,MODE_POINT);
			orderStopLevel = 1.2*orderStopLevel;

			 if ((orderStopless-orderPrice) < orderStopLevel*orderpoint)
			 {
					orderStopless = orderPrice + orderStopLevel*orderpoint;
			 }
			 if ((orderPrice-orderTakeProfit) < orderStopLevel*orderpoint)
			 {
					orderTakeProfit = orderPrice - orderStopLevel*orderpoint;
			 }
			
			orderPrice = NormalizeDouble(orderPrice,vdigits);		 	
			orderStopless = NormalizeDouble(orderStopless,vdigits);		 	
			orderTakeProfit = NormalizeDouble(orderTakeProfit,vdigits);

			//挂单4个小时，尽量成交
			timeexp = TimeCurrent() + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtimeexp*60;
			
		

			//orderTakeProfit = 0;
																
			Print(my_symbol+"BoolCrossRecord["+SymPos+"][" +timeperiodnum+"]:"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0]+":" 
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[1]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[2]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[3]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[4]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[5]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[6]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[7]+":"+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[8]+":"
			+ BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[9]);
				    			 	 		 			 	 		 			 	
			
			Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"OrderSend:" + "orderLots=" + orderLots +"orderPrice ="
						+orderPrice+"orderStopless="+orderStopless+"orderTakeProfit="+orderTakeProfit);	
						
			if(true == accountcheck())
			{
				if(sendorderhungstatus == HDISABLEORDERHUNG)
				{
				   
					TwentyS_Freq++;
					OneM_Freq++;
					ThirtyS_Freq++;
					FiveM_Freq++;
					ThirtyM_Freq++;	
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	

					//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEHUNGSTOP;								
					//记录当前一分钟的ibar位置
					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

					BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																						*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
					Print("OrderSend hung by hand! "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");


				}	
				else
				{

					ttick = 0;
					ticket = -1;
					while((ticket<0)&&(ttick<20))
					{
						vask    = MarketInfo(my_symbol,MODE_ASK);	
						//orderPrice = vask;					
							
						ticket = OrderSend(my_symbol,OP_SELLSTOP,orderLots,orderPrice,3,
							           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
									   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,timeexp,Blue);
			
						 if(ticket <0)
						 {
						 	ttick++;

							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());
							
							if(GetLastError()!=134)
							{
								 //---- 5 seconds wait
								 Sleep(5000);
								 //---- refresh price data
								 RefreshRates();						
							}
							else 
							{
								Print("There is no enough money!");						
							}					
						 }
						 else
						 {       
						 	ttick = 100;     
							TwentyS_Freq++;
							OneM_Freq++;
							ThirtyS_Freq++;
							FiveM_Freq++;
							ThirtyM_Freq++;	
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit = orderTakeProfit;
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots = orderLots;	


							//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEING;								
							//记录当前一分钟的ibar位置
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos = 	iBars(MySymbol[SymPos],timeperiod[0]);

							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailtimes*(orderPrice-orderStopless)
																								*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag;																											 				 
							Print("OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
							
						 }													
						Sleep(1000);	
					}
					if((ttick>= 19)	&&(ttick<25))
					{
							Print("!!Fatel error encouter please check your platform right now!");					
					}		
				}
									
			}


		}

	}						
						
}







//检测挂单，确定是否开单
void monitorsendorder()
{

	int SymPos;
	int ttick ,ticket;
	string my_symbol;

	double vask;
	double vbid;
	int buysellpoint;
	int subbuysellpoint;
   double orderPrice;

	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{
		
		my_symbol =   MySymbol[SymPos];

		for(subbuysellpoint = 0; subbuysellpoint <= 7;subbuysellpoint++)
		{
			for(buysellpoint = 1; buysellpoint <= HBUYSELLALGNUM*2;buysellpoint++)
			{
				//挂Limit单状态
				if(HPENDINGSTATEHUNGLIMIT == BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate)
				{
					//确实未曾有打开的订单
					if(OneMOrderRealCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
					{

						//挂单有效期内，进行侦测
						if((((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart)
						  &&(((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							<BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp))
						{

							vbid    = MarketInfo(my_symbol,MODE_BID);	
							vask    = MarketInfo(my_symbol,MODE_ASK);
							//买单挂单侦测
							if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag == 1)
							{
								//当前价格下行突破buylimit点
								if(vask < BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)
								{

									//发送当前价格的买单请求

									Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" BuyLimit trip ！！" );															
									ttick = 0;
									ticket = -1;
									while((ticket<0)&&(ttick<20))
									{
										orderPrice = vask;																
										ticket = OrderSend(my_symbol,OP_BUY,BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots,
													   orderPrice,3,
											           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,0,Blue);

										 if(ticket <0)
										 {
										 	ttick++;
											Print("BUYLimit OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
											if(GetLastError()!=134)
											{
												 //---- 5 seconds wait
												 Sleep(5000);
												 //---- refresh price data
												 RefreshRates();						
											}
											else 
											{
												Print("BUYLimit There is no enough money!");						
											}					
										 }
										 else
										 {       
										 	ttick = 100;     
											TwentyS_Freq++;
											OneM_Freq++;
											ThirtyS_Freq++;
											FiveM_Freq++;
											ThirtyM_Freq++;	

											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;	

											//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;								
																										 				 
											Print("OrderSend BUYLIMIT"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
										 }													
										Sleep(1000);	
									}
									if((ttick>= 19)	&&(ttick<25))
									{
											Print("!!BUYLIMIT Fatel error encouter please check your platform right now!");					
									}	


								}

							}	
							//卖单挂单侦测						
							else if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag == -1)
							{

								//当前价格上行突破selllimit点
								if(vbid > BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)
								{

									//发送当前价格的买单请求

									Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" SellLimit trip ！！" );															
									ttick = 0;
									ticket = -1;
									while((ticket<0)&&(ttick<20))
									{
										orderPrice = vbid;																
										ticket = OrderSend(my_symbol,OP_SELL,BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots,
													   orderPrice,3,
											           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,0,Blue);

										 if(ticket <0)
										 {
										 	ttick++;
											Print("SELLLIMIT OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
											if(GetLastError()!=134)
											{
												 //---- 5 seconds wait
												 Sleep(5000);
												 //---- refresh price data
												 RefreshRates();						
											}
											else 
											{
												Print("SELLLIMIT There is no enough money!");						
											}					
										 }
										 else
										 {       
										 	ttick = 100;     
											TwentyS_Freq++;
											OneM_Freq++;
											ThirtyS_Freq++;
											FiveM_Freq++;
											ThirtyM_Freq++;	

											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;	

											//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;								
																										 				 
											Print("OrderSend SELLLIMIT"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
										 }													
										Sleep(1000);	
									}
									if((ttick>= 19)	&&(ttick<25))
									{
											Print("!!SELLLIMIT Fatel error encouter please check your platform right now!");					
									}	


								}


							}
							else
							{

							}

						}
						//超时以后撤掉挂单
						else if(((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp)  
						{
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;
							Print("BUYSELLLIMIT OrderSend expired"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName);						

						}
						else
						{
							;
						}

					}
					else
					{

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;						
					}

				}

				//挂Stop单状态
				if(HPENDINGSTATEHUNGSTOP == BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate)
				{
					//确实未曾有打开的订单
					if(OneMOrderRealCloseStatus(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber)==true)
					{

						//挂单有效期内，进行侦测
						if((((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timestart)
						  &&(((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							<BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp))
						{

							vbid    = MarketInfo(my_symbol,MODE_BID);	
							vask    = MarketInfo(my_symbol,MODE_ASK);
							//买单挂单侦测
							if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag == 1)
							{
								//当前价格上行突破buystop点
								if(vask > BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)
								{

									//发送当前价格的买单请求

									Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" BuyStop trip ！！" );															
									ttick = 0;
									ticket = -1;
									while((ticket<0)&&(ttick<20))
									{
										orderPrice = vask;																
										ticket = OrderSend(my_symbol,OP_BUY,BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots,
													   orderPrice,3,
											           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,0,Blue);

										 if(ticket <0)
										 {
										 	ttick++;
											Print("BUYSTOP OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
											if(GetLastError()!=134)
											{
												 //---- 5 seconds wait
												 Sleep(5000);
												 //---- refresh price data
												 RefreshRates();						
											}
											else 
											{
												Print("BUYSTOP There is no enough money!");						
											}					
										 }
										 else
										 {       
										 	ttick = 100;     
											TwentyS_Freq++;
											OneM_Freq++;
											ThirtyS_Freq++;
											FiveM_Freq++;
											ThirtyM_Freq++;	

											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;	

											//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;								
																										 				 
											Print("OrderSend BUYSTOP"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
										 }													
										Sleep(1000);	
									}
									if((ttick>= 19)	&&(ttick<25))
									{
											Print("!!BUYSTOP Fatel error encouter please check your platform right now!");					
									}	


								}

							}	
							//卖单挂单侦测						
							else if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag == -1)
							{

								//当前价格上行突破buystop点
								if(vbid < BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice)
								{

									//发送当前价格的买单请求

									Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" SellStop trip ！！" );															
									ttick = 0;
									ticket = -1;
									while((ticket<0)&&(ttick<20))
									{
										orderPrice = vbid;																
										ticket = OrderSend(my_symbol,OP_SELL,BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].orderlots,
													   orderPrice,3,
											           BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedtakeprofit,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName,
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].magicnumber,0,Blue);

										 if(ticket <0)
										 {
										 	ttick++;
											Print("SELLSTOP OrderSend "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+" failed with error #",GetLastError());						
											if(GetLastError()!=134)
											{
												 //---- 5 seconds wait
												 Sleep(5000);
												 //---- refresh price data
												 RefreshRates();						
											}
											else 
											{
												Print("SELLSTOP There is no enough money!");						
											}					
										 }
										 else
										 {       
										 	ttick = 100;     
											TwentyS_Freq++;
											OneM_Freq++;
											ThirtyS_Freq++;
											FiveM_Freq++;
											ThirtyM_Freq++;	

											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].opentime = TimeCurrent();
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice = orderPrice;	

											//设置该订单状态为Stop类的挂单状态，处于该状态下的订单需要持续监控，但是开始时间设置为当前的一分钟ibar
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;								
																										 				 
											Print("OrderSend SELLSTOP"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName+"  successfully");
										 }													
										Sleep(1000);	
									}
									if((ttick>= 19)	&&(ttick<25))
									{
											Print("!!SELLSTOP Fatel error encouter please check your platform right now!");					
									}	


								}


							}
							else
							{

							}

						}
						//超时以后撤掉挂单
						else if(((iBars(MySymbol[SymPos],timeperiod[0])) - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].OneMOpenPos)
							>BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].timeexp)  
						{
							BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;
							Print("BUYSELLSTOP OrderSend expired"+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName);						

						}
						else
						{
							;
						}

					}
					else
					{

						BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEOPEN;						
					}

				}

			}


		}	
												
	}

}

// 每秒调用一次，反复执行的主体函数
//int start()
void OnTick(void)
{


	string mMailTitlle = "";

	int SymPos;
	double orderStopLevel;
	
	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;

	string my_symbol;
	
	double MinValue3 = 100000;
	double MaxValue4=-1;
	///////////
	int my_timeperiod = 0;
	int timeperiodnum = 0;
	///////////
	

	
	//---
	// initial data checks
	// it is important to make sure that the expert works with a normal
	// chart and the user did not make any mistakes setting external 
	// variables (Lots, StopLoss, TakeProfit, 
	// TrailingStop) in our case, we check TakeProfit
	// on a chart of less than 100 bars
	//---

	if(iBars(NULL,0) <500)
	{
	  Print("Bar Number less than 500");
	  return;
	}


	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;


	/*异常大量交易检测*/
	Freq_Count++;

	if(TwentyS_Freq > 9)
	{
		 Print("detect ordersend unnormal");
		 return;
	}
	else
	{
		if (0== (Freq_Count%20))
		{
			 TwentyS_Freq = 0;
		}
	}

	if(ThirtyS_Freq > 15)
	{
      Print("detect ordersend unnorma2");
		 return;
	}
	else
	{
		if (0== (Freq_Count%30))
		{
			 ThirtyS_Freq = 0;
		}
	}

	if(OneM_Freq > 21)
	{
      Print("detect ordersend unnorma3");
		 return;
	}
	else
	{
		if (0== (Freq_Count%60))
		{
			 OneM_Freq = 0;
		}
	}

	if(FiveM_Freq > 37)
	{
      Print("detect ordersend unnorma4");
		 return;
	}
	else
	{
		if (0== (Freq_Count%300))
		{
			 FiveM_Freq = 0;
		}
	}

	if(ThirtyM_Freq > 55)
	{
      Print("detect ordersend unnorma5");
		 return;
	}
	else
	{
		if (0== (Freq_Count%1800))
		{
			 ThirtyM_Freq = 0;
		}
	}
	


	/*自动调整交易手数，即下午1-2点之间每隔5分钟检查一次设计*/
	autoadjustglobalamount();
	
	/*自动调整交易风险指数，即下午1-2点之间每隔5分钟检查一次设计*/
	autoadjustmaxlose();


	/*在交易时间段来临前确保使能全局交易标记，即下午1-2点之间每隔5分钟检查一次设计*/
	enableglobaltradeflag();
	
	/*每周三的深夜晚上强行清盘*/
	/*原因是周三晚上要收三天的隔夜费用，对于短线操作来说不可接受*/
	//all_forcecloseall();	
	
	
	
	
	/*所有货币对所有周期指标计算*/	
	calculateindicator();
      
	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{	
		
		
		/*特定货币一分钟寻找买卖点*/
		orderbuyselltypeone(SymPos);		
				
		/*特定货币五分钟寻找买卖点*/		
		orderbuyselltypetwo(SymPos);		

		
		/*特定货币一分钟寻找买卖点*/
		orderbuyselltypethree(SymPos);		
				
		/*特定货币五分钟寻找买卖点*/		
		orderbuyselltypefour(SymPos);			

	}
   

	//对于挂单，侦测满足条件的情况下开订单！
	monitorsendorder();
  
   ////////////////////////////////////////////////////////////////////////////////////////////////
   //订单管理优化，包括移动止损、直接止损、订单时间管理
   //暂时还没有想清楚该如何移动止损优化  
   ////////////////////////////////////////////////////////////////////////////////////////////////

   /*短线获利清盘针对一分钟盘面*/
   monitoraccountprofit();

   checkbuysellorder();

	/////////////////////////////////////////////////
   PrintFlag = true;
   ChartEvent = iBars(NULL,0);     
	for(SymPos = 0; SymPos < symbolNum;SymPos++)
	{	
		for(timeperiodnum = 0; timeperiodnum < TimePeriodNum;timeperiodnum++)
		{
			my_symbol =   MySymbol[SymPos];
			my_timeperiod = timeperiod[timeperiodnum];		
			BoolCrossRecord[SymPos][timeperiodnum].ChartEvent = iBars(my_symbol,my_timeperiod);
		}
   }
   
   return;
   
   
}
//+------------------------------------------------------------------+


/////////////////////////////////////////////////////////////////////////
//该函数作用是追踪止损，直到平保
void checkbuysellorder()
{
	
	int SymPos;
	int timeperiodnum;
	int my_timeperiod;
	string my_symbol;
	int NowMagicNumber,magicnumber;	


	double boll_up_B,boll_low_B,boll_mid_B,bool_length;		
	double vbid,vask; 
	double MinValue3 = 100000;
	double MaxValue4=-1;

	double orderStopLevel;

	double orderLots ;   
	double orderStopless ;
	double orderTakeProfit;
	double orderPrice;	
	int i;
 	int ticket;
 	
	int buysellpoint;
	int subbuysellpoint;

	int    vdigits ;
	int res;
	
	
	timeperiodnum = 0;	

	orderStopLevel=0;
	orderLots = 0;   
	orderStopless = 0;
	orderTakeProfit = 0;
	orderPrice = 0;
	my_timeperiod = timeperiod[timeperiodnum];	

	//定义移动止损和平保
	for (i = 0; i < OrdersTotal(); i++)
	{
   		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   		{
   	
			magicnumber = OrderMagicNumber();
			SymPos = ((int)magicnumber) /MAINMAGIC-1;
			NowMagicNumber = magicnumber - (SymPos+1) *MAINMAGIC;
		
			if((SymPos>=0)&&(SymPos<symbolNum))
			{
				my_symbol = MySymbol[SymPos];

				subbuysellpoint = (NowMagicNumber%10);  
				if((subbuysellpoint>= 0)&&(subbuysellpoint<= 7))
				{
					buysellpoint = ((int)NowMagicNumber) /10;
					if((buysellpoint>=1)&&(buysellpoint<=HBUYSELLALGNUM*2))
					{

						timeperiodnum = 0;	
						my_timeperiod = timeperiod[timeperiodnum];							
						//当去掉止盈的时候，程序对该单放弃监控，转为手动监控，通常是指那些基本面同步发生了重大同方向的变化，且适合长期持有的单子；改为手工持单
						//一般情况下不触发
						if(OrderTakeProfit()>0.01)
						{

							//实际止盈和止损探测，每时每刻都要探测
							vbid    = MarketInfo(my_symbol,MODE_BID);		
							vask    = MarketInfo(my_symbol,MODE_ASK);	

							//买单，根据实际止损止盈值确定是否发送止损和止盈的指令
							if(OrderType()==OP_BUY)
							{

								//触发止盈
								if(vask > BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit)
								{
									Print(my_symbol+" Buy Order takeprofit Closeing:" + "orderLots=" + OrderLots() +"OpenPrice ="+OrderOpenPrice() 
									+"OrderCurPrice = "+vbid+"orderStopless="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss 
									+"orderprofit = "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit+"orderprofit="+OrderProfit());

									ticket =OrderClose(OrderTicket(),OrderLots(),vbid,5,Red);
									  
									 if(ticket <0)
									 {
										Print("Buy Order Closed takeprofit failed with error #",GetLastError());
									 }
									 else
									 {      

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;	
										Print("Buy Order Closed takeprofit  successfully ");
									 }    							 																												
								
									 Sleep(1000);  										

								}

								//触发止损
								if(vbid < BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
								{
									Print(my_symbol+" Buy Order StopLoss Closeing:" + "orderLots=" + OrderLots() +"OpenPrice ="+OrderOpenPrice() 
									+"OrderCurPrice = " + vbid
									+"orderStopless="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss 
									+"orderprofit = "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit+"orderprofit="+OrderProfit());	
																
									ticket =OrderClose(OrderTicket(),OrderLots(),vbid,5,Red);
									  
									 if(ticket <0)
									 {
										Print("Buy Order Closed StopLoss failed with error #",GetLastError());
									 }
									 else
									 {    

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;	
										Print("Buy Order Closed StopLoss  successfully ");
									 }    							 																												
								
									 Sleep(1000);  										

								}								

							}
							//卖单，根据实际止损止盈值确定是否发送止损和止盈的指令
					 		else if(OrderType()==OP_SELL)
							{


								//触发止盈
								if(vbid < BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit)
								{
									Print(my_symbol+" Sell Order takeprofit Closeing:" + "orderLots=" + OrderLots() +"OpenPrice ="+OrderOpenPrice() 
									+"OrderCurPrice = " + vask
									+"orderStopless="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss 
									+"orderprofit = "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit+"orderprofit="+OrderProfit());	

									ticket =OrderClose(OrderTicket(),OrderLots(),vask,5,Red);
									  
									 if(ticket <0)
									 {
										Print("Sell Order Closed takeprofit failed with error #",GetLastError());
									 }
									 else
									 {  

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;										           
										Print("Sell Order Closed takeprofit  successfully ");
									 }    							 																												
								
									 Sleep(1000);  											

								}	

								//触发止损
								if(vask > BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
								{
									Print(my_symbol+" Sell Order StopLoss Closeing:" + "orderLots=" + OrderLots() +"OpenPrice ="+OrderOpenPrice() 
									+"OrderCurPrice = " + vask
									+"orderStopless="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss 
									+"orderprofit = "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].takeprofit+"orderprofit="+OrderProfit());	

									ticket =OrderClose(OrderTicket(),OrderLots(),vask,5,Red);
									  
									 if(ticket <0)
									 {
										Print("Sell Order Closed StopLoss failed with error #",GetLastError());
									 }
									 else
									 {      

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].pendingstate = HPENDINGSTATEEMPTY;										       
										Print("Sell Order Closed StopLoss  successfully ");
									 }    							 																												
								
									 Sleep(1000);  									

								}


							}
							else
							{
								;
							}

							//移动止损到平保
							//确保寻找买卖点是每个一分钟周期计算一次，而不是每个tick计算一次
							if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,timeperiod[timeperiodnum]))
							{
				 				
								vbid    = MarketInfo(my_symbol,MODE_BID);		
								vask    = MarketInfo(my_symbol,MODE_ASK);												
								vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	
					 			
					 			//买交易
					 			if(OrderType()==OP_BUY)
					 			{


									orderPrice = vask;				 
									orderStopless = vask - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing;	 	
									orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

									//不扩大亏损额度，且平保
									if((orderStopless<OrderOpenPrice())
										&&(orderStopless > BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss))
									{

										//设置实际止损值
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

										//设置faked止损值，
										//买单，根据facked推算出实际值
										if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

										}
										//卖单
										else
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

										}

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);


										//orderTakeProfit = 0;
										//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless stoptrailling Modify:"
										//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
										
										res=OrderModify(OrderTicket(),OrderOpenPrice(),
											   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
											   
										 if(false == res)
										 {

											Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
												+"orderStopless stoptrailling OrderModify. Error code=",GetLastError());									
										 }
										 else
										 {        
										   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

											//经常性修改，只有在测试期间打开
											//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
											//	"orderStopless successfully stoptailing ="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing);
										 }								
										Sleep(1000);		

									}
									//平保
									else if((orderStopless>OrderOpenPrice())&&((OrderOpenPrice() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss>0.001)))
									{
										//设置
										orderStopless = OrderOpenPrice();
										orderStopless = NormalizeDouble(orderStopless,vdigits);	


										//设置实际止损值
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

										//设置faked止损值，
										//买单，根据facked推算出实际值
										if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

										}
										//卖单
										else
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

										}

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);



										//orderTakeProfit = 0;
										//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless stoptrailling pingbao Modify:"
										//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
										
										res=OrderModify(OrderTicket(),OrderOpenPrice(),
											   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
											   
										 if(false == res)
										 {

											Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
												+"orderStopless stoptrailling pingbao OrderModify. Error code=",GetLastError());									
										 }
										 else
										 {        
										   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

											//经常性修改，只有在测试期间打开
											//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
											//	"orderStopless successfully pingbao stoptailing ="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing);
										 }								
										Sleep(1000);	

									}
									else
									{
										;
									}



					 			}
					 			else if(OrderType()==OP_SELL)
					 			{

				 
									orderPrice = vask;				 
									orderStopless = vask + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing;	 	
									orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

									//不扩大亏损额度，且平保
									if((orderStopless>OrderOpenPrice())
										&&(orderStopless < BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss))
									{



										//设置实际止损值
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

										//设置faked止损值，
										//买单，根据facked推算出实际值
										if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

										}
										//卖单
										else
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

										}

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);



										//orderTakeProfit = 0;
										//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless stoptrailling Modify:"
										//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
										
										res=OrderModify(OrderTicket(),OrderOpenPrice(),
											   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
											   
										 if(false == res)
										 {

											Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
												+"orderStopless stoptrailling OrderModify. Error code=",GetLastError());									
										 }
										 else
										 {        
										   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	 								 
											//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
											//	"orderStopless stoptrailling successfully stoptailing = "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing);
										 }								
										Sleep(1000);		

									}	
									//平保
									else if((orderStopless<OrderOpenPrice())&&((BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss - OrderOpenPrice())>0.001))
									{
										//设置
										orderStopless = OrderOpenPrice();
										orderStopless = NormalizeDouble(orderStopless,vdigits);	

										//设置实际止损值
										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

										//设置faked止损值，
										//买单，根据facked推算出实际值
										if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

										}
										//卖单
										else
										{
											BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
												(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
													*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

										}

										BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);




										//orderTakeProfit = 0;
										//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless stoptrailling pingbao Modify:"
										//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
										
										res=OrderModify(OrderTicket(),OrderOpenPrice(),
											   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
											   
										 if(false == res)
										 {

											Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
												+"orderStopless stoptrailling pingbao OrderModify. Error code=",GetLastError());									
										 }
										 else
										 {        
										   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

											//经常性修改，只有在测试期间打开
											//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
											//	"orderStopless successfully pingbao stoptailing ="+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoptailing);
										 }								
										Sleep(1000);	

									}
									else
									{
										;
									}									


					 			}
					 			else
					 			{
					 				;
					 			}
							
							}	

							//结构发生反方向变化后无条件重新设置止损值
							//确保寻找买卖点是每个一分钟周期计算一次，而不是每个tick计算一次
							if ( BoolCrossRecord[SymPos][timeperiodnum].ChartEvent != iBars(my_symbol,timeperiod[timeperiodnum]))
							{

								//一分钟
								if((buysellpoint>0)&&(buysellpoint<=12))
								{
									timeperiodnum = 0;	
									my_timeperiod = timeperiod[timeperiodnum];			
									//买点处理止损点
									if(OrderType()==OP_BUY)
									{


										if((-5 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (-5== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vask - bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless > OrderOpenPrice())
												&&((OrderOpenPrice() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{



												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);




												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross low change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross low change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross low change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
										if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (3<  BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vask - bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless > OrderOpenPrice())
												&&((OrderOpenPrice() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{


												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);




												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross mid change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross mid change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross mid change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
									}
									//卖单处理止损点
									else if (OrderType()==OP_SELL)
									{

										if((5 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (5== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vbid + bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	


											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless < OrderOpenPrice())
												&&((OrderStopLoss() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{



												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);



												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross up change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross up change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross up change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
										if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (-3>  BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vbid + bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	


											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless < OrderOpenPrice())
												&&((BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss - OrderOpenPrice())>-0.001))
											{



												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);


												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross mid change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross mid change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross mid change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
												

									}
									else
									{
										;
									}


								}
								//五分钟
								else if((buysellpoint <= HBUYSELLALGNUM)&&(buysellpoint > 12))
								{


									timeperiodnum = 1;	
									my_timeperiod = timeperiod[timeperiodnum];			
									//买点处理止损点
									if(OrderType()==OP_BUY)
									{


										if((-5 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (-5== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (-3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vask - bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless > OrderOpenPrice())
												&&((OrderOpenPrice() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{


												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);



												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross low change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross low change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross low change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
										if((-1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (-1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (3<  BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (3< BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vask - bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless > OrderOpenPrice())
												&&((OrderOpenPrice() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{



												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);


												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross mid change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross mid change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross mid change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
									}
									//卖单处理止损点
									else if (OrderType()==OP_SELL)
									{

										if((5 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (5== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vbid + bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	

											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless < OrderOpenPrice())
												&&((BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss - OrderOpenPrice())>-0.001))
											{




												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);


												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross up change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross up change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross up change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
															
										if((1 == BoolCrossRecord[SymPos][timeperiodnum].CrossFlagChange)
											&& (1== BoolCrossRecord[SymPos][timeperiodnum].CrossFlag[0])	
											&& (-3>  BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[1])			
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[2])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[3])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[4])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[5])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[6])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[7])	
											&& (-3> BoolCrossRecord[SymPos][timeperiodnum].CrossFlagL[8])	
											
											)
										{

											boll_up_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,1);   
											boll_low_B = iBands(my_symbol,my_timeperiod,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,1);
											boll_mid_B = (boll_up_B + boll_low_B )/2;
											/*point*/
											bool_length =(boll_up_B - boll_low_B )/2;	
											vbid    = MarketInfo(my_symbol,MODE_BID);		
											vask    = MarketInfo(my_symbol,MODE_ASK);												
											vdigits = (int)MarketInfo(my_symbol,MODE_DIGITS); 	

											orderStopless = vbid + bool_length*3;	 	
											orderStopless = NormalizeDouble(orderStopless,vdigits);		 	


											//只有在第一次巨幅盈利回调时设置止损值，以后不再设置止损值了
											//因为亏损已经切断了，剩下的就是让利润奔跑了，以后通过止盈或者monitor方式平仓
											if((orderStopless < OrderOpenPrice())
												&&((OrderStopLoss() - BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)>-0.001))
											{


												//设置实际止损值
												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;

												//设置faked止损值，
												//买单，根据facked推算出实际值
												if(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].buysellflag ==1)
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice -BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss)
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;														

												}
												//卖单
												else
												{
													BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice +
														(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss-BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].openprice )
															*BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedlevel;		

												}

												BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss = NormalizeDouble(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,vdigits);



												//orderTakeProfit = 0;
												//Print(BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName + "orderStopless struct cross mid change Modify:"
												//				+ "fakedstoploss=" + BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss +"orderPrice ="+OrderOpenPrice()+"orderStopless="+orderStopless);									
												
												res=OrderModify(OrderTicket(),OrderOpenPrice(),
													   BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].fakedstoploss,OrderTakeProfit(),0,clrPurple);
													   
												 if(false == res)
												 {

													Print("Error in "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName 
														+"orderStopless cross mid change OrderModify. Error code=",GetLastError());									
												 }
												 else
												 {        
												   	BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].stoploss = orderStopless;	

													//Print("OrderModify "+BuySellPosRecord[SymPos][buysellpoint][subbuysellpoint].MagicName +
													//	"orderStopless cross mid change successfully "+OrderMagicNumber());
												 }								
												Sleep(1000);		

											}	

										}
												

									}
									else
									{
										;
									}


								}
								else
								{
									;
								}

							}
							//恢复原状
							timeperiodnum = 0;	
							my_timeperiod = timeperiod[timeperiodnum];	


						}


					}	
				}	
			}   	
		
		}				
	}


}
	



