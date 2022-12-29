//+------------------------------------------------------------------+
//|                                              CourseFunctions.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


int movingAvgperiod = 20;
int bPeriod = 20;
int rPeriod = 20;
int bStd = 2;
int bShift = 0;

enum ENUM_SELECT_INDICATOR{

      MovingAvg,
      RSI,
      ATR
   
};

input int BBStdSmaller = 1;
input int BBStdLarger = 1;

  
  double GetStopLoss(bool isLong,double entryPrice,int stopLossPips)
  {
  double stopLoss;
   if(isLong){
     stopLoss = entryPrice - stopLossPips * 0.0001;
   }else{
      stopLoss = entryPrice + stopLossPips * 0.0001;
   }
   
   return stopLoss;
  }
  
  
  
  double GetPipValue(){
   
   if(_Digits >= 4){
   
   return 0.0001;
   }else{
   return 0.001;
   }
  
  }
  
  
  void bollingerBands(){
  
    Alert("");

   int takeProfitPips = 40;
   int stopLossPips = 30;
   
   // The code for the inner BB
   
   double smallerBBLowerBand = iBands(NULL,0,bPeriod,BBStdSmaller,0,PRICE_CLOSE,MODE_LOWER,0);
   double smallerBBUpperBand = iBands(NULL,0,bPeriod,BBStdSmaller,0,PRICE_CLOSE,MODE_UPPER,0);
   double smallerBBMidBand = iBands(NULL,0,bPeriod,  BBStdSmaller,0,PRICE_CLOSE,0,0); 
   
   // Outer BB
   
   double largerBBLowerBand = iBands(NULL,0,bPeriod,BBStdLarger,0,PRICE_CLOSE,MODE_LOWER,0);
   double largerBBUpperBand = iBands(NULL,0,bPeriod,BBStdLarger,0,PRICE_CLOSE,MODE_UPPER,0);
   double largerBBMidBand =   iBands(NULL,0,bPeriod,BBStdLarger,0,PRICE_CLOSE,0,0); 
   
   if(Ask < smallerBBLowerBand)//buying
   {
      Alert("Price is below inner lower band, Sending buy order");
      double stopLossPrice = largerBBLowerBand;
      double takeProfitPrice = smallerBBMidBand;
      Alert("Entry Price = " + Ask);
      Alert("Stop Loss Price = " + stopLossPrice);
      Alert("Take Profit Price = " + takeProfitPrice);
      
      //Send buy order
   }
   else if(Bid > smallerBBUpperBand)//shorting
   {
      Alert("Price is above signalPrice, Sending short order");
      double stopLossPrice = largerBBUpperBand;
      double takeProfitPrice = smallerBBMidBand;
      Alert("Entry Price = " + Bid);
      Alert("Stop Loss Price = " + stopLossPrice);
      Alert("Take Profit Price = " + takeProfitPrice);
	  
	  //Send short order
   }
   
  }
  
//+------------------------------------------------------------------+


double CalculateTakeLoss(int lossPips,bool buy, double entryPrice)
  {

   double takeLoss;

   if(buy)
     {

      takeLoss = entryPrice -  lossPips * GetPipValue();

     }
   else
     {


      takeLoss = entryPrice + lossPips * GetPipValue();

     }

   return takeLoss;

  }
  
  
  double CalculateTakeProfit(int pips,bool buying, double entryPrice)
  {

   double takeProfit;
   if(buying)
     {
      takeProfit =  entryPrice + pips * GetPipValue();

     }
   else
     {

      takeProfit = entryPrice - pips * GetPipValue();
     }

   return takeProfit;



  }
  
  
  
   void indicators()
  {
  
      
        
      double mvgAvg = iMA(NULL,0,movingAvgperiod,0,MODE_SMA,PRICE_CLOSE,bShift);
      
      // Alert(NormalizeDouble(mvgAvg,Digits));
      
      double bbLowerBand = iBands(NULL,0,bPeriod,bStd,0,PRICE_CLOSE,MODE_LOWER,bShift);
      
      double bbMidBand = iBands(NULL,0,bPeriod,bStd,0,PRICE_CLOSE,0,bShift);
      
      double bbUpperBand = iBands(NULL,0,bPeriod,bStd,0,PRICE_CLOSE,MODE_UPPER,bShift);
      
       //Alert( "bbLowerBand :" + NormalizeDouble(bbLowerBand,Digits));
      //Alert( "bbMidBand :" + NormalizeDouble(bbMidBand,Digits));
       //Alert( "bbUpperBand  :" + NormalizeDouble(bbUpperBand ,Digits));
      
      
      // RSI
      double rsiValue = iRSI(NULL,0,rPeriod,0,0);
      Alert("RSI: " +  NormalizeDouble(rsiValue,2)); 
  }
  
    /*  
  A Method that checks if trading is allowed or not
  */
  bool isTradingAllowed()
  {
   if(!IsTradeAllowed())
     {
      Alert(" Trading is not Allowed Because AutoTrade is Off ");
      return false;
     }
     
     if(!IsTradeAllowed(Symbol(),TimeCurrent()))
       {
        Alert("Trading is not allowed at the current time or the current symbol");
        return false;
       }
       
       return true;
   
  }
  
  /*
  ** A function for getting the optimal lotsize given the entry price, Max risk per trade
  *  max loss in pips
  */
  
  double OptimalLotSize(double maxRiskPrc, int maxLossInPips)
{

   // Getting the account balance
  double accEquity = AccountEquity();
  Alert("accEquity: " + accEquity);
  
  double lotSize = MarketInfo(NULL,MODE_LOTSIZE);
  Alert("lotSize: " + lotSize);
  
  // Convert the account currency to quote currency
  double tickValue = MarketInfo(NULL,MODE_TICKVALUE);
  
  if(Digits <= 3)
  {
   tickValue = tickValue /100;
  }
  
  Alert("tickValue: " + tickValue);
  
  double maxLossDollar = accEquity * maxRiskPrc;
  Alert("maxLossDollar: " + maxLossDollar);
  
  double maxLossInQuoteCurr = maxLossDollar / tickValue;
  Alert("maxLossInQuoteCurr: " + maxLossInQuoteCurr);
  
  double optimalLotSize = NormalizeDouble(maxLossInQuoteCurr /(maxLossInPips * GetPipValue())/lotSize,2);
  
  return optimalLotSize;
 
}


double OptimalLotSize(double maxRiskPrc, double entryPrice, double stopLoss)
{
   int maxLossInPips = MathAbs(entryPrice - stopLoss)/GetPipValue();
   return OptimalLotSize(maxRiskPrc,maxLossInPips);
}