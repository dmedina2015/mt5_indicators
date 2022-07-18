//+------------------------------------------------------------------+
//|                                                      Dist_MA.mq5 |
//|                                         Copyright 2022, innovaGP |
//|                                       mailto:daniel.sm@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, innovaGP"
#property link      "mailto:daniel.sm@gmail.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#include <MovingAverages.mqh>

//--- plot Dist_MA
#property indicator_label1  "Dist_MA"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrGold,clrOrangeRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- set the maximum and minimum values ​​for the indicator window
#property indicator_minimum  -70
#property indicator_maximum  75
//--- plot Levels
#property indicator_level1 30
#property indicator_level2 -30
#property indicator_level3 50
#property indicator_level4 -50

//--- input parameters
input int      inpLen=21; // Length of HV and MA
input int      inpAnnualize=252; // Days to annualize
input bool inpUseLogReturn=false; // Calculate daily return using LN
enum stdDevType  
  { 
   S=0,     // Sample 
   P=1,     // Population 
  }; 
input stdDevType inpStdDevType=P; // Std Dev Calculation

//--- indicator buffers
double         HVBuffer[];
double         Dist_MABuffer[],ColorBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set descriptions of horizontal levels
   IndicatorSetString(INDICATOR_LEVELTEXT,0,"Safe Line");
   IndicatorSetString(INDICATOR_LEVELTEXT,1,"Safe Line");
   IndicatorSetString(INDICATOR_LEVELTEXT,2,"No Go");
   IndicatorSetString(INDICATOR_LEVELTEXT,3,"No Go");
   
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrYellow);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrYellow);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrRed);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,3,clrRed);
   
//--- indicator buffers mapping
   SetIndexBuffer(0,Dist_MABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,HVBuffer,INDICATOR_CALCULATIONS);
   
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
         (inpUseLogReturn)?work[k] = MathLog(close[i-k]/close[i-k-1]):work[k] = (close[i-k]/close[i-k-1])-1;
         avg    += work[k];
        }
      avg/=inpLen;
      for(int k=0; k<inpLen; k++) sum+=(work[k]-avg)*(work[k]-avg);

      //
      //---
      //
      if(inpStdDevType) // Calculation is for Population
         HVBuffer[i]  = MathSqrt(sum/inpLen); // use /(n) formula
      else //Calculation is for Sample
         HVBuffer[i]  = MathSqrt(sum/(inpLen-1)); // use /(n-1) formula
         
      HVBuffer[i] *= MathSqrt(inpAnnualize)*100; //Annualize and convert to %
      
      double HV_MA = SimpleMA(i,inpLen,HVBuffer);
      double Price_MA = SimpleMA(i,inpLen,close);
      double distPriceFromMA = (close[i]-Price_MA)*100/close[i];
      Dist_MABuffer[i] = distPriceFromMA*100/HV_MA;
      ColorBuffer[i] = (MathAbs(Dist_MABuffer[i])>50) ? 2 : (MathAbs(Dist_MABuffer[i])>30) ? 1 : 0;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
