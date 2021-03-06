
//+------------------------------------------------------------------+
//|                                             Ibond.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2015, My1 DtDream."
#property link        "http://www.mql14.com"

//input double TakeProfit    =50;
input double Lots          =0.1;
//input double TrailingStop  =30;


input int Move_Av = 3;
input int iBoll_B = 60;
input int iBoll_S = 20;

//input double MACDOpenLevel =3;
//input double MACDCloseLevel=2;
//input int    MATrendPeriod =26;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

/////////////////////////////////////////////////////////////////////

//extern double g_HL_Direction ;
double ma_pre;
double boll_up_B_pre,boll_low_B_pre,boll_mid_B_pre;
double boll_up_S_pre,boll_low_S_pre,boll_mid_S_pre;


//当前周期，最大值上穿60 boll周期上轨，或者下穿boll周期下轨，邮件提醒关注。

int init()
{

      string MailTitlle ="";
      double HL_Direction;
      if(GlobalVariableCheck("g_HL_Direction") == TRUE)
      {      
          HL_Direction = GlobalVariableGet("g_HL_Direction");
          HL_Direction = HL_Direction + 1;
          GlobalVariableSet("g_HL_Direction",HL_Direction);
          HL_Direction = GlobalVariableGet("g_HL_Direction");      
          SendNotification("init it is a True g_HL_Direction = "+DoubleToString(HL_Direction));        
      }
      else
      {
          SendNotification("init it is a False");       
      }
      if (240 == Period() )
      {
          MailTitlle = MailTitlle +"4H";
      
      }
      else if (30 == Period() )
      {
         MailTitlle = MailTitlle +"30M";
      
      }
      else
      {
         MailTitlle = MailTitlle + "Bad Time period，should 30M or 4H";
      }
      MailTitlle = "Init:" + MailTitlle +  Symbol();
   // OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"macd sample",16384,0,Red);
//   SendMail("Start watching:"+Symbol()+IntegerToString(Period())," ");  	 
   
      SendNotification(MailTitlle);    
      return 0;
}


int deinit()
{
   return 0;
}


void OnTick(void)
{

   double ma;
   double boll_up_B,boll_low_B,boll_mid_B;
   double boll_up_S,boll_low_S,boll_mid_S;
   string mMailTitlle = "";
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---

   if(iBars(NULL,0) <100)
   {
      Print("TimeFrame 5 min bars less than 10");
      return;
   }

  ma=iMA(NULL,0,Move_Av,0,MODE_SMA,PRICE_CLOSE,0); 
 // ma = Close[0];  
  boll_up_B = iBands(NULL,0,iBoll_B,2,0,PRICE_CLOSE,MODE_UPPER,0);   
  boll_low_B = iBands(NULL,0,iBoll_B,2,0,PRICE_CLOSE,MODE_LOWER,0);
  boll_mid_B = (boll_up_B + boll_low_B )/2;
  
  boll_up_S = iBands(NULL,0,iBoll_S,2,0,PRICE_CLOSE,MODE_UPPER,0);   
  boll_low_S = iBands(NULL,0,iBoll_S,2,0,PRICE_CLOSE,MODE_LOWER,0);
  boll_mid_S = (boll_up_S+ boll_low_S )/2;


  
    
    if((ma <= 0.0000001) && (ma >= -0.0000001))
    {
       //剔除脏数据
       Print("Input ma : ",ma);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       
       return ;
    }
 
    if((ma_pre <= 0.0000001) && (ma_pre >= -0.0000001))
    {
       //剔除脏数据
       Print("Input my ma_pre : ",ma_pre);
       Print("Input my ma : ",ma);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       

       return ;
    }
    if((boll_up_B <= 0.0000001) && (boll_up_B >= -0.0000001))
    {
       //剔除脏数据
       Print("Input boll_up_B : ",boll_up_B);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       
       
       return ;
    }

    if((boll_up_S <= 0.0000001) && (boll_up_S >= -0.0000001))
    {
       //剔除脏数据
       Print("Input boll_up_S : ",boll_up_S);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       

       return ;
    }


    if((boll_up_B_pre <= 0.0000001) && (boll_up_B_pre >= -0.0000001))
    {
       //剔除脏数据
       Print("Input boll_up_B_pre : ",boll_up_B_pre);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       

       return ;
    }

    if((boll_up_S_pre <= 0.0000001) && (boll_up_S_pre >= -0.0000001))
    {
       //剔除脏数据
       Print("Input boll_up_S_pre : ",boll_up_S_pre);
        ma_pre = ma;
        boll_up_B_pre = boll_up_B;     
        boll_low_B_pre = boll_low_B;
        boll_mid_B_pre = boll_mid_B;
        boll_up_S_pre = boll_up_S;
        boll_low_S_pre = boll_low_S;
        boll_mid_S_pre = boll_mid_S;       

       return ;
    }
      
      if (240 == Period() )
      {
         mMailTitlle = mMailTitlle +"!!"+"4H ";
      
      }
      else if (30 == Period() )
      {
         mMailTitlle = mMailTitlle + "30M ";
      
      }
      else
      {
         return;
      }
            
		/*本周期长线突破高点，更更可能本周期回调或者形成更高周期的趋势(一定要待回调失败后再做多)*/
		if((ma >boll_up_B) && (ma_pre < boll_up_B_pre ) )
		{

	      SendNotification("!"+ mMailTitlle + Symbol()+" LH:"
	      +"::Long term Higher,Mostly rool back,strongly Sell;Only after Sell failed,Then Buy");  	  	      
		}
		
		/*本周期短线突破高点，可能本周期趋势，小周期强势时短期可追*/
		if((ma >boll_up_S) && (ma_pre < boll_up_S_pre ) && 0 )
		{
	      SendNotification(mMailTitlle + Symbol()+" SH:"
	      +"::Short term Higher,If short term stornger ,Then Buy Little");  	  	      	      
		}
		
			/*本周期长线突破低点，更更可能本周期回调或者形成更高周期的趋势(待回调失败后再做空)*/
		if((ma < boll_low_B) && (ma_pre > boll_low_B_pre ) )
		{
	      SendNotification("!"+ mMailTitlle + Symbol() + " LL:"
	      +"::Long term Lower,Mostly rool back,strongly Buy;Only after Buy failed,Then Sell");  	  	      	      	      
		}
		
		/*本周期短线突破低点，可能本周期趋势，小周期强势时短期可追*/
		if((ma <boll_low_S) && (ma_pre > boll_low_S_pre ) && 0 )
		{
	      SendNotification(mMailTitlle + Symbol()+" SL:"+"::Short term Lower,If short term stornger ,Then Sell Little");
		}
		

     ma_pre = ma;
     boll_up_B_pre = boll_up_B;     
     boll_low_B_pre = boll_low_B;
     boll_mid_B_pre = boll_mid_B;
     boll_up_S_pre = boll_up_S;
     boll_low_S_pre = boll_low_S;
     boll_mid_S_pre = boll_mid_S;
     
   return;

  }
//+------------------------------------------------------------------+
