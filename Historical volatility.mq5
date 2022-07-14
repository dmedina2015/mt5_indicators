//+------------------------------------------------------------------
#property copyright   "© mladen, 2018; dmedina, 2022"
#property link        "mladenfx@gmail.com; daniel.sm@gmail.com"
#property description "Historical volatility"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Historical volatility"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrSkyBlue,clrDodgerBlue
#property indicator_width1  1
//--- input parameters
input int inpVolPeriod=18; // Volatility period
input bool inpUseLogReturn=false; // Calculate daily return using LN

enum stdDevType  
  { 
   S=0,     // Sample 
   P=1,     // Population 
  }; 

input stdDevType inpStdDevType=P;

//--- buffers and global variables declarations
double val[],valc[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Historical volatility ("+(string)inpVolPeriod+")");
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   double work[]; ArrayResize(work,inpVolPeriod); ArrayInitialize(work,0);
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double avg = 0;
      double sum = 0;
      for(int k=0; k<inpVolPeriod && (i-k)>0; k++)
        {
         (inpUseLogReturn)?work[k] = MathLog(close[i-k]/close[i-k-1]):work[k] = (close[i-k]/close[i-k-1])-1;
         avg    += work[k];
        }
      avg/=inpVolPeriod;
      for(int k=0; k<inpVolPeriod; k++) sum+=(work[k]-avg)*(work[k]-avg);

      //
      //---
      //
      if(inpStdDevType) // Calculation is for Population
         val[i]  = MathSqrt(sum/inpVolPeriod); // use /(n) formula
      else //Calculation is for Sample
         val[i]  = MathSqrt(sum/(inpVolPeriod-1)); // use /(n-1) formula
      val[i] *= MathSqrt(252)*100; // annualize
      valc[i] = (i>0) ?(val[i]>val[i-1]) ? 1 :(val[i]<val[i-1]) ? 2 : valc[i-1]: 0;
     }
   return (i);
  }
//+------------------------------------------------------------------+
