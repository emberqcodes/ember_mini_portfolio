//+------------------------------------------------------------------+
//|                                       Ember_MeanReversionATR.mq5 |
//|                                        Mariceline Ember Querubin |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| INPUTS                                                            |
//+------------------------------------------------------------------+

//Bring in the trade class to make trading easier
#include <Trade/Trade.mqh>
CTrade Trade;

#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information

//ATR Long, Short, Multiplier
input int InpATRShortPeriod = 1; // ATR Short Period
input int InpATRLongPeriod = 14; // ATR Long Period
input double InpATRMultiplier = 3.5; // ATR Multiplier (Double)

//Bollinger Bands 01
input int InpBBands_01Period = 20; // Boll Bands 01 Period
input int InpBBands_01Shift = 0; // Boll Bands 01 Shift
input double InpBBands_01Deviation = 2.0; // Boll Bands 01 Deviation
input ENUM_APPLIED_PRICE InpBBands_01AppliedPrice = PRICE_CLOSE; // Boll Bands 01 Applied Price


//SL TP Multiplier
input double DecimalPointValue = 100000; // 100 for 2 decimal point assets, 100000 for 5 decimal point assets
input double StopLossMultiplier = 2.0; // S/L Value Multiplier
input double TakeProfitMultiplier = 4.0; // T/P Value Multiplier
input double BalancePercentToRisk = 0.01; // %Risk (0.01 = 1%)


//Global Variables
double TakeProfit;
double StopLoss;

//Handles and buffers for indicators
int HandleATRShort;
int HandleATRLong;
int HandleATRMultiplied;
int HandleBBands_01;
int HandleBBands_01_Upper;
int HandleBBands_01_Lower;

int HandleBBands_02;
int HandleBBands_02_Upper;
int HandleBBands_02_Lower;

int HandleSTDEV_01;
int HandleSTDEV_02;

///buffers:
double BufferATRShort[];
double BufferATRLong[];
double BufferATRMultiplied[];

//values: 
double ATRShortValue;
double ATRLongValue;
   
double MiddleBandValue_01;
double UpperBandValue_01;
double LowerBandValue_01;
   
double MiddleBandValue_02;
double UpperBandValue_02;
double LowerBandValue_02;

int HandleBarClose;
double BufferBarClose[];

// Variables to store order ticket numbers
ulong OpenOrderBuy = 0;
ulong OpenOrderSell = 0;

input double LOTSIZE = 1.0;
input double Profit_In_Dollars = 100;
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
//---
   
   HandleBarClose = PRICE_CLOSE;
   ArraySetAsSeries(BufferBarClose, true);
   CopyClose(Symbol(), Period(), 0, 3, BufferBarClose);
    
   HandleATRShort = iATR(Symbol(), Period(), InpATRShortPeriod);
   ArraySetAsSeries(BufferATRShort, true);
   CopyBuffer(HandleATRShort, 0, 0, 3, BufferATRShort);  
   
   
   HandleATRLong = iATR(Symbol(), Period(), InpATRLongPeriod);
   ArraySetAsSeries(BufferATRLong, true); 
   CopyBuffer(HandleATRLong, 0, 0, 3, BufferATRLong); 
      
   double MiddleBandArray_01[];
   double UpperBandArray_01[];
   double LowerBandArray_01[];
   
   //create an array for several prices
   double MiddleBandArray_02[];
   double UpperBandArray_02[];
   double LowerBandArray_02[];
     
    //define Bollinger Bands
   int BollingerBands_01 = iBands(Symbol(), Period(), InpBBands_01Period, InpBBands_01Shift, InpBBands_01Deviation, InpBBands_01AppliedPrice);
   ArraySetAsSeries(MiddleBandArray_01,true);
   ArraySetAsSeries(UpperBandArray_01,true);
   ArraySetAsSeries(LowerBandArray_01,true);
   
   CopyBuffer(BollingerBands_01,0,0,3,MiddleBandArray_01);
   CopyBuffer(BollingerBands_01,1,0,3,UpperBandArray_01);
   CopyBuffer(BollingerBands_01,2,0,3,LowerBandArray_01);
   
   
   
   
   double BarCloseValue = BufferBarClose[0];
   
   ATRShortValue = BufferATRShort[0];
   ATRLongValue = BufferATRLong[0]; 
   
   MiddleBandValue_01=MiddleBandArray_01[0];
   UpperBandValue_01=UpperBandArray_01[0];
   LowerBandValue_01=LowerBandArray_01[0];
   

   
   double ATRLongMultipliedValue = ATRLongValue * InpATRMultiplier;
   double MinLotRequired = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   
   Comment("MiddleBandValue_01: ", MiddleBandValue_01,"\n",
   "UpperBandValue_01: ", UpperBandValue_01,"\n","LowerBandValue_01: ", LowerBandValue_01,"\n"
   "ATRShortValue: ", ATRShortValue, "\n" "ATRLongValue: ", ATRLongValue, "\n", 
   "ATRLongMULTIPLIEDValue: ", ATRLongMultipliedValue, "\n",
   "MinLotRequired: ", MinLotRequired, "/n",
   "BarCloseValue: ", BarCloseValue);
    
    {
 
   
    if (ATRShortValue > ATRLongMultipliedValue)
        {
         if (BarCloseValue > UpperBandValue_01 && PositionSelect(Symbol()) == false)
         {
           // Calculate the coordinates for arrow placement
           double arrowPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Adjust as per your requirement
           datetime arrowTime = TimeCurrent(); // Adjust as per your requirement
   
           // Draw the arrow object
           ObjectCreate(0, "MyArrow", OBJ_ARROW_CHECK, 0, arrowTime, arrowPrice);
           
           double EntryPointValue = BarCloseValue;        
                                    
           double STOPLOSSVALUE = EntryPointValue + (ATRLongValue * StopLossMultiplier);
           double TAKEPROFITVALUE = EntryPointValue - (ATRLongValue * TakeProfitMultiplier);
           
           double MoneyToRisk = MathFloor((AccountInfoDouble(ACCOUNT_BALANCE)) * BalancePercentToRisk);
           Print ("MoneyToRisk: ", MoneyToRisk);
           
           double EntryandSLDifference = MathFloor((ATRLongValue * StopLossMultiplier) * DecimalPointValue);
           Print("EntryandSLDifference: ", EntryandSLDifference);
           
           //double ValuePerPoint = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
           //Print("SymbolValuePerPoint: ", ValuePerPoint);
           
                     
           double TradePosSizeVar = NormalizeDouble((MoneyToRisk / EntryandSLDifference), 2);
           Print ("TradePosSizeVar: ", TradePosSizeVar);
            
           //double RoundedTradePosSizeVar = NormalizeDouble(TradePosSizeVar, 2);
           //Print ("RoundedTradePosSize: ", RoundedTradePosSizeVar); 
            
           OpenOrderSell = Trade.Sell(LOTSIZE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);
           
                               
           }
          else if (BarCloseValue < LowerBandValue_01 && PositionSelect(Symbol()) == false)
          {
            double arrowPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Adjust as per your requirement
            datetime arrowTime = TimeCurrent(); // Adjust as per your requirement
   
            ObjectCreate(0, "MyArrow", OBJ_ARROW_CHECK, 0, arrowTime, arrowPrice);
            
            double EntryPointValue = BarCloseValue;    
           
            double STOPLOSSVALUE = EntryPointValue - (ATRLongValue * StopLossMultiplier);
            double TAKEPROFITVALUE = EntryPointValue + (ATRLongValue * TakeProfitMultiplier);
            
            double MoneyToRisk = MathFloor((AccountInfoDouble(ACCOUNT_BALANCE)) * BalancePercentToRisk);
            Print ("MoneyToRisk: ", MoneyToRisk);
            
            double EntryandSLDifference = MathFloor((ATRLongValue * StopLossMultiplier) * DecimalPointValue);
            Print("EntryandSLDifference: ", EntryandSLDifference);
            
            //double ValuePerPoint = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
            //Print("SymbolValuePerPoint: ", ValuePerPoint);
                  
            double TradePosSizeVar =  NormalizeDouble((MoneyToRisk / EntryandSLDifference), 2);
            Print ("TradePosSizeVar: ", TradePosSizeVar);
            
            //double RoundedTradePosSizeVar = NormalizeDouble(TradePosSizeVar, 2);
            //Print ("RoundedTradePosSize: ", RoundedTradePosSizeVar);
            
            OpenOrderBuy = Trade.Buy(LOTSIZE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE, TAKEPROFITVALUE, NULL);

 
          }
         }






if (PositionsTotal() == 1 && PositionsTotal() < 2 && PositionGetDouble(POSITION_PROFIT) > Profit_In_Dollars && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
   
   double EntryPointValue2 = BarCloseValue;    
   double STOPLOSSVALUE2 = EntryPointValue2 - (ATRLongValue * StopLossMultiplier);
   double TAKEPROFITVALUE2 = EntryPointValue2 + (ATRLongValue * TakeProfitMultiplier);
   
   ulong OpenOrderBuy2 = Trade.Buy(LOTSIZE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE2, TAKEPROFITVALUE2, "2ND TRADE");
      
   }

   else if (PositionsTotal() == 1 && PositionsTotal() < 2 && PositionGetDouble(POSITION_PROFIT) > Profit_In_Dollars && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
      
      double EntryPointValue2 = BarCloseValue;    
      double STOPLOSSVALUE2 = EntryPointValue2 + (ATRLongValue * StopLossMultiplier);
      double TAKEPROFITVALUE2 = EntryPointValue2 - (ATRLongValue * TakeProfitMultiplier);
      
      ulong OpenOrderSell2 = Trade.Sell(LOTSIZE, Symbol(), PRICE_CLOSE, STOPLOSSVALUE2, TAKEPROFITVALUE2, "2ND TRADE");
         
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
/*
void PrintOrderDetails(const ulong ticket)
{
    if (OrderSelect(ticket))
    {
        Print("Order Details for Ticket: ", ticket);
        Print("Symbol: ", Symbol());
        Print("Type: ", POSITION_TYPE);
        Print("Lots: ", POSITION_VOLUME);
        Print("Open Price: ", POSITION_PRICE_OPEN);
        Print("Stop Loss: ", POSITION_SL);
        Print("Take Profit: ", POSITION_TP);
        Print("Comment: ", POSITION_COMMENT);
    }
    else
    {
        Print("Failed to select order with ticket ", ticket);
    }
}
*/
