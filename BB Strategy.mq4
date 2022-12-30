//+------------------------------------------------------------------+
//|                                                  BB strategy.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs
#include <CourseFunctions.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
   
//int magicNumber = 8888;
int openOrderID;
 
int magicNB = 55555;
input int bbPeriod = 50;

input int bandStdEntry = 2;
input int bandStdProfitExit = 1;
input int bandStdLossExit = 6;

int rsiPeriod = 14;
input double riskPerTrade = 0.02;
input int rsiLowerLevel = 40;
input int rsiUpperLevel = 60;

int OnInit()
  {
//---
   
//---
   Alert("Init");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Alert("Destroyed");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   // 2 std Bollinger Bands for detecting entry signals
   double bbLowerEntry = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperEntry = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,MODE_UPPER,0);
   
   //
   double bbMid = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,0,0);
   
   double bbLowerProfitExit = iBands(NULL,0,bbPeriod,bandStdProfitExit,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperProfitExit = iBands(NULL,0,bbPeriod,bandStdProfitExit,0,PRICE_CLOSE,MODE_UPPER,0);
   
   // Bands for setting the stopLoss,has 6 std
   double bbLowerLossExit = iBands(NULL,0,bbPeriod,bandStdLossExit,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperLossExit = iBands(NULL,0,bbPeriod,bandStdLossExit,0,PRICE_CLOSE,MODE_UPPER,0);
   
   // calculating the RSI 
   double rsiValue = iRSI(NULL,0,rsiPeriod,PRICE_CLOSE,0);
   
   if(!CheckOpenOrdersByMagicNumber(magicNB))//if no open orders try to enter new position
   {
   
   /*
   * If the Ask is lower thab bbEntryBand and the last tick is above the entry band and RSI is oversold
   *then we buy
   */
      if(Ask < bbLowerEntry && Open[0] > bbLowerEntry && rsiValue < rsiLowerLevel)  //buying
      {
         Print("Price is below bbLower and rsiValue is lower than " + rsiLowerLevel+ " , Sending buy order");
         double stopLossPrice = NormalizeDouble(bbLowerLossExit,Digits);
         double takeProfitPrice = NormalizeDouble(bbUpperProfitExit,Digits);;
         Print("Entry Price = " + Ask);
         Print("Stop Loss Price = " + stopLossPrice);
         Print("Take Profit Price = " + takeProfitPrice);
         
         // Getting the OtimalLotSize depending on our account Balance
         double lotSize = OptimalLotSize(riskPerTrade,Ask,stopLossPrice);
         
         
         openOrderID = OrderSend(NULL,OP_BUYLIMIT,lotSize,Ask,10,stopLossPrice,takeProfitPrice,NULL,magicNB);
         // Then an error has occured
         if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
      }
      /*
      * If the Bid is outside the upperBand and the opening price is lower than the upperBand
      * And the RSI is overbought then we short
      */
      else if(Bid > bbUpperEntry && Open[0] < bbUpperEntry && rsiValue > rsiUpperLevel)//shorting
      {
         Print("Price is above bbUpper and rsiValue is above " + rsiUpperLevel + " Sending short order");
         double stopLossPrice = NormalizeDouble(bbUpperLossExit,Digits);
         double takeProfitPrice = NormalizeDouble(bbLowerProfitExit,Digits);
         Print("Entry Price = " + Bid);
         Print("Stop Loss Price = " + stopLossPrice);
         Print("Take Profit Price = " + takeProfitPrice);
   	  
   	  double lotSize = OptimalLotSize(riskPerTrade,Bid,stopLossPrice);

   	  openOrderID = OrderSend(NULL,OP_SELLLIMIT,lotSize,Bid,10,stopLossPrice,takeProfitPrice,NULL,magicNB);
   	  if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
      }
   }
   else //else if you already have a position, update orders if need too.
   {
      if(OrderSelect(openOrderID,SELECT_BY_TICKET)==true) // Then we selected the order
      {
            int orderType = OrderType();  // Short = 1, Long = 0

            double optimalTakeProfit;
            
            if(orderType == 0)   // We are in a long position
            {
               // getting the updated takeProfit from the BB indicator
               optimalTakeProfit = NormalizeDouble(bbUpperProfitExit,Digits);
               
            }
            else //if short
            {
               optimalTakeProfit = NormalizeDouble(bbLowerProfitExit,Digits);
            }

            double TP = OrderTakeProfit();
            double TPdistance = MathAbs(TP - optimalTakeProfit);
            // If the BB indicator TakeProift changed by more than 1 PIP then we update the TakeProfit
            if(TP != optimalTakeProfit && TPdistance > 0.0001)
            {
               bool Ans = OrderModify(openOrderID,OrderOpenPrice(),OrderStopLoss(),optimalTakeProfit,0);
            
               if (Ans==true)                     
               {
                  Print("Order modified: ",openOrderID);
                  return;                           
               }else
               {
                  Print("Unable to modify order: ",openOrderID);
               }   
            }
         }
      }
   }
