//+------------------------------------------------------------------+
//|                                                RetracementBO.mq5 |
//|                                        Mariceline Ember Querubin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


//Bring in the trade class to make trading easier
#include <Trade/Trade.mqh>
CTrade Trade;

#include <C:\Users\pcuser\AppData\Roaming\MetaQuotes\Terminal\73B7A2420D6397DFF9014A20F1201F97\MQL5\Experts\RetracementBO\CNewCandle.mqh>
#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Math\Stat\Stat.mqh>

//inputs
input int rangeStartHour = 0;
input int rangeStartMinutes = 0;
input int rangeEndHour = 9;
input int rangeEndMinutes = 15;

input double PricePercentforLongs = 0.30; //Retracement in Percentage for Longs
input double PricePercentforShorts = 0.30; //Retracemnt in Percentage for Shorts

input double stopFromLowPoints = 0.00100;
input double stopFromHighPoints = 0.00100;

input double tPRangeMultiplier = 2.0;

input double fixedLotSize = 2.0;

input int openTradesOpenTime = 10;
input int openTradesCloseTime = 15;

input int closeAllTradesHour = 22; 
input int closeAllTradesMinute = 00;

//variables
double highestofRange;
double lowestofRange; 

datetime starttimeofrange;
datetime endtimeofrange;

int HandleBarClose;
double BufferBarClose[];

CNewCandle newCandleorBar(Symbol(), PERIOD_CURRENT);
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

// highestofRange = iHigh(Symbol(), PERIOD_CURRENT, iBarShift(Symbol(), PERIOD_CURRENT, StringToTime("0:00")));
// lowestofRange = iLow(Symbol(), PERIOD_CURRENT, iBarShift(Symbol(), PERIOD_CURRENT, StringToTime("0:00")));

   starttimeofrange = ConvertToDateTime(rangeStartHour, rangeStartMinutes);
   endtimeofrange = ConvertToDateTime(rangeEndHour, rangeEndMinutes);
   
   MqlRates ratesarray[];
   ArraySetAsSeries(ratesarray, true);
   CopyRates(Symbol(), PERIOD_CURRENT, starttimeofrange, endtimeofrange, ratesarray);
   
   highestofRange = GetHighestPrice(starttimeofrange, endtimeofrange);
   lowestofRange = GetLowestPrice(starttimeofrange, endtimeofrange);
   
   Comment("low: ", lowestofRange, "\n", "high: ", highestofRange, "\n", "starttimeofrange: ", starttimeofrange, "\n", "endtimeofrange: ", endtimeofrange); 
      
   HandleBarClose = PRICE_CLOSE;
   ArraySetAsSeries(BufferBarClose, true);
   CopyClose(Symbol(), Period(), 0, 3, BufferBarClose); 
   
   // Create an instance of CNewCandle
   


if (isTimeToOpenTrade(openTradesOpenTime, openTradesCloseTime))
 {
     
      
      if (newCandleorBar.IsNewCandle() == true && BufferBarClose[1] > highestofRange && PositionSelect(Symbol()) == false && OrdersTotal() == 0)
         {
           Print("Long position ready!", " High: ", highestofRange, " Low: ", lowestofRange);
           double openPriceLong = GetOpenPriceforLongs(lowestofRange, highestofRange, PricePercentforLongs);
           double stopLossValue = lowestofRange;
           
           double rangesize = NormalizeDouble(highestofRange - lowestofRange, _Digits);
           double tpsize = NormalizeDouble (rangesize * tPRangeMultiplier, _Digits);
           double tpValueLong = NormalizeDouble(openPriceLong + tpsize, _Digits);
           
           Trade.BuyLimit(fixedLotSize, openPriceLong, NULL, stopLossValue, tpValueLong, ORDER_TIME_GTC, 0, NULL);
           
         }
       else if (newCandleorBar.IsNewCandle() == true && BufferBarClose[1] < lowestofRange && PositionSelect(Symbol()) == false && OrdersTotal() == 0)
         {
         Print("Short position ready!");
         double openPriceShort = GetOpenPriceforShorts(lowestofRange, highestofRange, PricePercentforShorts);
         double stopLossValue = highestofRange;
         
         double rangesize = NormalizeDouble(highestofRange - lowestofRange, _Digits);
         double tpsize = NormalizeDouble (rangesize * tPRangeMultiplier, _Digits);
         double tpValueShort = NormalizeDouble(openPriceShort - tpsize, _Digits);
         
         Trade.SellLimit(fixedLotSize, openPriceShort, NULL, stopLossValue, tpValueShort, ORDER_TIME_GTC, 0, NULL);
         
         }
         
 }
 
 
if (IsTimeToClosePendingTrade(closeAllTradesHour, closeAllTradesMinute) && hasPendingOrder() == true)
   {
   PendingOrderDelete();
   }
    
/*

   if (isTimeToOpenTrade(openTradesOpenTime, openTradesCloseTime))
      {
 
      }
   
     }
     
     */
     
     
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


// Function to check if a candle has closed for a given timeframe
bool CandleClosed(const ENUM_TIMEFRAMES PERIOD_CURRENT)
{
   // Get the current time
   datetime current_time = TimeCurrent();

   // Calculate the timeframe in seconds
   int period_seconds = PeriodSeconds(PERIOD_CURRENT);

   // Check if the current time is divisible by the period's timeframe
   if((current_time % period_seconds) == 0)
   {
      return true; // Candle has closed
   }

   return false; // Candle is still open
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool isTimeToOpenTrade(int openTradesOpenTime, int openTradesCloseTime)
{
        
   datetime tmopen = TimeTradeServer();
   MqlDateTime stmopen;
   TimeToStruct(tmopen, stmopen);
   
   int hourToOpen = stmopen.hour;
   
   return (hourToOpen >= openTradesOpenTime && hourToOpen <= openTradesCloseTime);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


// Define a function to convert input variables to datetime
datetime ConvertToDateTime(int hour, int minute)
 {
    MqlDateTime dt;
    
    // Initialize dt structure
    TimeToStruct(TimeCurrent(), dt);
    
    // Set year, month, day, hour, minute, and second based on the input
    //dt.day = TIME_DATE;
    dt.hour = hour;   // Set hour from input
    dt.min = minute;  // Set minute from input
    dt.sec = 0;       // Set seconds to 0

    // Convert MqlDateTime structure back to datetime
    return StructToTime(dt);
}



double GetHighestPrice(datetime x, datetime y) {
    double highestPrice;
    
    int startBar = iBarShift(NULL, 0, x, true);
    int endBar = iBarShift(NULL, 0, y, true);
    
    if (startBar < 0 || endBar < 0) {
        Print("Error: Invalid time range");
        return 0.0;
    }
    
    int bufferSize = endBar - startBar + 1;
    
    double highBuffer[];
    ArraySetAsSeries(highBuffer, true);
    ArrayResize(highBuffer, bufferSize);
    
    int copiedBars = CopyHigh(NULL, 0, x, y, highBuffer);
    if (copiedBars < 0) {
        Print("Error copying high prices");
        return 0.0;
    }
    
    for (int i = 0; i < copiedBars; i++) {
        double high = highBuffer[i];
        if (high > highestPrice) {
            highestPrice = high;
        }
    }
    
    return highestPrice;
}

double GetLowestPrice(datetime x, datetime y) {
    double lowestPrice;
    
    int startBar = iBarShift(NULL, 0, x, true);
    int endBar = iBarShift(NULL, 0, y, true);
    
    if (startBar < 0 || endBar < 0) {
        Print("Error: Invalid time range");
        return 0.0;
    }
    
    int bufferSize = endBar - startBar + 1;
    
    double lowBuffer[];
    ArraySetAsSeries(lowBuffer, true);
    ArrayResize(lowBuffer, bufferSize);
    
    int copiedBars = CopyLow(NULL, 0, x, y, lowBuffer);
    if (copiedBars < 0) {
        Print("Error copying low prices");
        return 0.0;
    }
    
    for (int i = 0; i < copiedBars; i++) {
        double low = lowBuffer[i];
        if (low < lowestPrice) {
            lowestPrice = low;
        }
    }
    
    return lowestPrice;
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double GetOpenPriceforLongs(double low, double high, double PricePercentforLongs)
{
   double multiplier = 1.0 - PricePercentforLongs;
   double priceToAdd = low + ((high - low) * multiplier) ;
   double OpenPriceLong = NormalizeDouble(priceToAdd, _Digits);
   return OpenPriceLong;
}

double GetOpenPriceforShorts(double low, double high, double PricePercentforShorts)
{
   double multiplier = 1.0 - PricePercentforShorts;
   double priceToSubtract = high - ((high - low) * multiplier);
   double OpenPriceShort = NormalizeDouble(priceToSubtract, _Digits);
   return OpenPriceShort;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool IsTimeToClosePendingTrade(int closeAllTradesHour, int closeAllTradesMinute)
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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool hasPendingOrder() {
   for (int i=0; i < OrdersTotal(); i++) {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket)) {
         if (OrderGetString(ORDER_SYMBOL) == _Symbol && ticket != 0){
            return true;
            break;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PendingOrderDelete() 
{  
         CTrade mytrade;
         int o_total=OrdersTotal();
         for(int j=o_total-1; j>=0; j--)
         {
            ulong o_ticket = OrderGetTicket(j);
            if(o_ticket != 0)
            {
             // delete the pending order
             mytrade.OrderDelete(o_ticket);
             Print("Pending order deleted sucessfully!");
          }
      }     
}
