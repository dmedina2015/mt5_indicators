//+------------------------------------------------------------------+
//|                                                      Dist_MA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#include <MovingAverages.mqh>

//--- plot Dist_MA
#property indicator_label1  "Dist_MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen,clrGold,clrOrangeRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      inpLen=21; // Length of HV and MA
//--- indicator buffers
double         HVBuffer[];
double         Dist_MABuffer[],ColorBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Dist_MABuffer,INDICATOR_DATA);
   SetIndexBuffer(2,HVBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   double work[]; ArrayResize(work,inpLen); ArrayInitialize(work,0);
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double avg = 0;
      double sum = 0;
      for(int k=0; k<inpLen && (i-k)>0; k++)
        {
         work[k] = close[i-k]/close[i-k-1];
         avg    += work[k];
        }
      avg/=inpLen;
      for(int k=0; k<inpLen; k++) sum+=(work[k]-avg)*(work[k]-avg);

      //
      //---
      //

      HVBuffer[i] = MathSqrt(sum/(inpLen-1)); //Using "Sample" formula (n-1)
      HVBuffer[i] *= MathSqrt(252)*100; //Annualize and convert to %
      
      double HV_MA = SimpleMA(i,inpLen,HVBuffer);
      double Price_MA = SimpleMA(i,inpLen,close);
      double distPriceFromMA = (close[i]-Price_MA)*100/close[i];
      Dist_MABuffer[i] = distPriceFromMA*100/HV_MA;
      ColorBuffer[i] = 1;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+