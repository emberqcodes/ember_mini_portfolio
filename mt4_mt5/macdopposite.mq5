//+------------------------------------------------------------------+
//|                                                   Ember_MACD.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade Trade;

#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Math\Stat\Stat.mqh>

input int InpATRLongPeriod = 14; // ATR Long Period
input double InpATRMultiplier = 2.0; // ATR Multiplier (Double)


//MACD: 
input int InpMACDFastEMAPeriod = 12; //MACD Fast EMA Period
input int InpMACDSlowEMAPeriod = 26; //MACD Slow EMA Period
input int InpMACDSignalPeriod = 9; // MACD Signal Period
input ENUM_TIMEFRAMES InpMACDPeriod = PERIOD_CURRENT; // MACD (Entire) Period or Timeframe
input ENUM_APPLIED_PRICE InpMACDAppliedPrice = PRICE_CLOSE; // MACD Applied Price

int HandleMACD;
int HandleMACD_Main;
int HandleMACD_Signal;
double BufferMACD[];
double BufferMACD_Main[];
double BufferMACD_Signal[];

double MACDMain_0;
double MACDMain_1;
double MACDMain_2;
double MACDMain_3;
double MACDMain_4; 
double MACDMain_5;


//SL TP Multiplier
input double DecimalPointValue = 100000; // 100 for 2 decimal point assets, 100000 for 5 decimal point assets
input double StopLossMultiplier = 4.0; // S/L Value Multiplier
input double TakeProfitMultiplier = 8.0; // T/P Value Multiplier
input double BalancePercentToRisk = 0.01; // %Risk (0.01 = 1%)
input double FIXED_LOT_SIZE = 1.0; // Lot Size to Risk

//Global Variables
double TakeProfit;
double StopLoss;

//Open Trades Open and Close Time
input int openTradesOpenTime = 8;
input int openTradesCloseTime = 20;
input int closeAllTradesHour = 22; 
input int closeAllTradesMinute = 00;

//Bar Close HAndle + Buffer
int HandleBarClose;
double BufferBarClose[];

//Handles and buffers for indicators
int HandleATRShort;
int HandleATRLong;
int HandleATRMultiplied;
double BufferATRShort[];
double BufferATRLong[];
double BufferATRMultiplied[];
double ATRLongValue; 


//////
ulong OpenOrderBuy = 0;
ulong OpenOrderSell = 0;

//////
input double normalLotSize = 1.0;
double currentLotSize = normalLotSize;
input double lotSizeMultiplier = 2.0;
input double MaxLotSizeofAccount = 5.0;

double lastProfit = 0.0;
int consecutiveLosses = 0;
double lastTradeProfitorLoss;
double LOTSIZETOUSE;
double updatedLotSize;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    HandleBarClose = PRICE_CLOSE;
    ArraySetAsSeries(BufferBarClose, true);
    CopyClose(Symbol(), Period(), 0, 3, BufferBarClose);

    HandleATRLong = iATR(Symbol(), Period(), InpATRLongPeriod);
    ArraySetAsSeries(BufferATRLong, true); 
    CopyBuffer(HandleATRLong, 0, 0, 3, BufferATRLong); 

    HandleMACD = iMACD(Symbol(), InpMACDPeriod, InpMACDFastEMAPeriod, InpMACDSlowEMAPeriod, InpMACDSignalPeriod, InpMACDAppliedPrice);
    ArraySetAsSeries(BufferMACD_Main, true);
    ArraySetAsSeries(BufferMACD_Signal, true);

    CopyBuffer(HandleMACD, 0, 0, 5, BufferMACD_Main);
    CopyBuffer(HandleMACD, 1, 0, 5, BufferMACD_Signal);

    double BarCloseValue = BufferBarClose[0];
    ATRLongValue = BufferATRLong[0];

    MACDMain_0 = BufferMACD_Main[0];
    MACDMain_1 = BufferMACD_Main[1];
    MACDMain_2 = BufferMACD_Main[2];
    MACDMain_3 = BufferMACD_Main[3];
    MACDMain_4 = BufferMACD_Main[4];

    double ATRLongMultipliedValue = ATRLongValue * InpATRMultiplier;

    bool timeToOpenTrade = isTimeToOpenTrade(openTradesOpenTime, openTradesCloseTime);
    bool timeToCloseTrade = IsTimeToCloseTrade(closeAllTradesHour, closeAllTradesMinute);

    if (timeToOpenTrade || timeToCloseTrade) {
        if (PositionSelect(Symbol())) {
            ulong ticket = PositionGetTicket(0);
            double currentLotSize = PositionGetDouble(POSITION_VOLUME);
            double EntryPointValue = BarCloseValue;
            double STOPLOSSVALUE, TAKEPROFITVALUE;

            if (timeToCloseTrade) {
                Trade.PositionClose(ticket);
            } else if ((MACDMain_4 <= 0 && MACDMain_3 <= 0 && MACDMain_2 >= 0 && MACDMain_1 > 0 && MACDMain_0 > 0) ||
                       (MACDMain_4 >= 0 && MACDMain_3 >= 0 && MACDMain_2 <= 0 && MACDMain_1 < 0 && MACDMain_0 < 0)) {
                Trade.PositionClose(ticket);
                double arrowPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Adjust as per your requirement
                datetime arrowTime = TimeCurrent(); // Adjust as per your requirement
                ObjectCreate(0, "MyArrow", OBJ_ARROW_CHECK, 0, arrowTime, arrowPrice);

                double MoneyToRisk = MathFloor((AccountInfoDouble(ACCOUNT_BALANCE)) * BalancePercentToRisk);
                Print("MoneyToRisk: ", MoneyToRisk);

                double EntryandSLDifference = MathFloor((ATRLongValue * StopLossMultiplier) * DecimalPointValue);
                Print("EntryandSLDifference: ", EntryandSLDifference);

                lastTradeProfitorLoss = GetLastTradeProfit();
                LOTSIZETOUSE = onTradeResult(lastTradeProfitorLoss);

                if (MACDMain_4 <= 0 && MACDMain_3 <= 0 && MACDMain_2 >= 0 && MACDMain_1 > 0 && MACDMain_0 > 0) {
                    STOPLOSSVALUE = EntryPointValue - (ATRLongValue * StopLossMultiplier);
                    TAKEPROFITVALUE = EntryPointValue + (ATRLongValue * TakeProfitMultiplier);
                    OpenOrderBuy = Trade.Buy(LOTSIZETOUSE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);
                } else if (MACDMain_4 >= 0 && MACDMain_3 >= 0 && MACDMain_2 <= 0 && MACDMain_1 < 0 && MACDMain_0 < 0) {
                    STOPLOSSVALUE = EntryPointValue + (ATRLongValue * StopLossMultiplier);
                    TAKEPROFITVALUE = EntryPointValue - (ATRLongValue * TakeProfitMultiplier);
                    OpenOrderSell = Trade.Sell(LOTSIZETOUSE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);
                }
            }
        } else if (!PositionSelect(Symbol())) {
            double arrowPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Adjust as per your requirement
            datetime arrowTime = TimeCurrent(); // Adjust as per your requirement
            ObjectCreate(0, "MyArrow", OBJ_ARROW_CHECK, 0, arrowTime, arrowPrice);

            double EntryPointValue = BarCloseValue;
            double STOPLOSSVALUE, TAKEPROFITVALUE;

            double MoneyToRisk = MathFloor((AccountInfoDouble(ACCOUNT_BALANCE)) * BalancePercentToRisk);
            Print("MoneyToRisk: ", MoneyToRisk);

            double EntryandSLDifference = MathFloor((ATRLongValue * StopLossMultiplier) * DecimalPointValue);
            Print("EntryandSLDifference: ", EntryandSLDifference);

            lastTradeProfitorLoss = GetLastTradeProfit();
            LOTSIZETOUSE = onTradeResult(lastTradeProfitorLoss);

            if (MACDMain_4 <= 0 && MACDMain_3 <= 0 && MACDMain_2 >= 0 && MACDMain_1 > 0 && MACDMain_0 > 0) {
                STOPLOSSVALUE = EntryPointValue - (ATRLongValue * StopLossMultiplier);
                TAKEPROFITVALUE = EntryPointValue + (ATRLongValue * TakeProfitMultiplier);
                OpenOrderBuy = Trade.Buy(LOTSIZETOUSE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);
            } else if (MACDMain_4 >= 0 && MACDMain_3 >= 0 && MACDMain_2 <= 0 && MACDMain_1 < 0 && MACDMain_0 < 0) {
                STOPLOSSVALUE = EntryPointValue + (ATRLongValue * StopLossMultiplier);
                TAKEPROFITVALUE = EntryPointValue - (ATRLongValue * TakeProfitMultiplier);
                OpenOrderSell = Trade.Sell(LOTSIZETOUSE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);
            }
        }
    }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


bool IsTimeToCloseTrade(int closeAllTradesHour, int closeAllTradesMinute)
{
    closeAllTradesHour = 22; // The hour when you want to close the trade
    closeAllTradesMinute = 00; // The minute when you want to close the trade
    
    datetime    tm=TimeTradeServer();
    MqlDateTime stm;
    TimeToStruct(tm,stm);
    
    int hour = stm.hour;
    int minute = stm.min;
    
    return (hour == closeAllTradesHour && minute == closeAllTradesMinute);
}

bool isTimeToOpenTrade(int openTradesOpenTime, int openTradesCloseTime)
{
        
   datetime tmopen = TimeTradeServer();
   MqlDateTime stmopen;
   TimeToStruct(tmopen, stmopen);
   
   int hourToOpen = stmopen.hour;
   
   return (hourToOpen >= openTradesOpenTime && hourToOpen <= openTradesCloseTime);
}



// Function to close all positions for a given symbol
// Function to close all positions for a given symbol
void CloseAllPositionsForSymbol(const string symbolName)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == symbolName)
        {
            ulong ticket = PositionGetTicket(i);
            if (ticket > 0)
            {
                bool result = Trade.PositionClose(ticket);
                if (result)
                {
                    Print("Closed position for ", symbolName, " with ticket ", ticket);
                }
                else
                {
                    Print("Failed to close position for ", symbolName, " with ticket ", ticket, " Error: ", GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double GetLastTradeProfit()
  {

   ulong ticket;
   datetime closeTime=0;
   bool found=false;
    double deal_profit=0;
    //ulong order_magic;
     string   symbol;
   if(HistorySelect(0,TimeCurrent()))
     {
      for(int i=HistoryDealsTotal()-1; i>=0; i--)
        {
         ticket=HistoryDealGetTicket(i);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);

         if((HistoryDealGetInteger(ticket,DEAL_ENTRY)==DEAL_ENTRY_OUT)&&symbol==Symbol())
           {
            found=true;
            deal_profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            break;
           }
        }
     }
   return ( deal_profit);
  }

//function to handle trade results

/*

double GetLastTradeProfit()
{
   double lastProfit = 0.0;
   
   //selectthelasttrade
   int ticket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
   if (ticket >= 0)
      {
      //get the profit of the last  trade
      lastProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      }
   return lastProfit;
  
}

*/
//function to handle trade results

double onTradeResult(double profit)
{
    
   if (profit > 0)
   {
   updatedLotSize = normalLotSize;
   consecutiveLosses = 0;
   }
   else
   {
   consecutiveLosses++;
   double templotSize = MathRound((normalLotSize * MathPow(lotSizeMultiplier, consecutiveLosses)), 2);
      if (templotSize < MaxLotSizeofAccount)
         {
         updatedLotSize = templotSize;
         }
      else
         {
         updatedLotSize = MaxLotSizeofAccount;
         }
   }
   
   return updatedLotSize;
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
