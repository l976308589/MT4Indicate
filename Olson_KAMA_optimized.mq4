//+------------------------------------------------------------------+
//|                                                  KAMA with trend |
//|                                      Copyright 2018, olson
//|                                       olson.work@foxmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, olson"
#property link      "olson.work@foxmail.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Gray
#property indicator_color2 Blue
#property indicator_color3 Red
//---- input parameters
extern int       periodAMA=10;
static double    nfast=2.0;
static double    nslow=30.0;
static double    G=2.0;
extern double    dK=2.0;
extern int       PriceType=0;
extern int       AMA_Trend_Type=1;

//---- buffers
double AMAbuffer[];
double upAMA[];
double downAMA[];
double AbsBuffer[];

double AMA2Buffer[];
double SumAMABuffer[];
double StdAMA[];

double slowSC,fastSC,dFS;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Price(int shift)
  {
//----
   double res;
//----
   switch(PriceType)
     {
      case PRICE_OPEN: res=Open[shift]; break;
      case PRICE_HIGH: res=High[shift]; break;
      case PRICE_LOW: res=Low[shift]; break;
      case PRICE_MEDIAN: res=(High[shift]+Low[shift])/2.0; break;
      case PRICE_TYPICAL: res=(High[shift]+Low[shift]+Close[shift])/3.0; break;
      case PRICE_WEIGHTED: res=(High[shift]+Low[shift]+2*Close[shift])/4.0; break;
      default: res=Close[shift];break;
     }
   return(res);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(7);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,AMAbuffer);
   SetIndexStyle(1,DRAW_ARROW,0,2);
   SetIndexArrow(1,159);
   SetIndexBuffer(1,upAMA);
   SetIndexEmptyValue(1,0.0);
   SetIndexStyle(2,DRAW_ARROW,0,2);
   SetIndexArrow(2,159);
   SetIndexBuffer(2,downAMA);
   SetIndexEmptyValue(2,0.0);

   SetIndexBuffer(3,AbsBuffer);
   SetIndexBuffer(4,AMA2Buffer);
   SetIndexBuffer(5,SumAMABuffer);
   SetIndexBuffer(6,StdAMA);

   slowSC=(2.0 /(nslow+1));
   fastSC=(2.0 /(nfast+1));
   dFS=fastSC-slowSC;

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//----
   int i,limit,limit2;
   double Noise,ER,SSC;
   double SredneeAMA,SumKvadratAMA;
   double val1,val2;
   double dipersion;
   bool debug=false;

   if(debug) return(0);
   if(counted_bars>0)
     {
      limit=Bars-counted_bars;
      limit2=limit;
     }
   if(counted_bars==0)
     {
      ArrayInitialize(AMAbuffer,0);
      ArrayInitialize(upAMA,0);
      ArrayInitialize(downAMA,0);
      ArrayInitialize(AbsBuffer,0);
      ArrayInitialize(AMA2Buffer,0);
      ArrayInitialize(SumAMABuffer,0);
      ArrayInitialize(StdAMA,0);

      limit=Bars-1;
      limit2=Bars-periodAMA-1;
     }
   limit--;
   limit2--;
   for(i=limit;i>=0;i--)
     {
      AbsBuffer[i]=MathAbs(Price(i)-Price(i+1));
     }
   for(i=limit2;i>=0;i--)
     {
      Noise=iMAOnArray(AbsBuffer,0,periodAMA,0,MODE_SMA,i)*periodAMA;
      if(Noise!=0) ER=MathAbs(Price(i)-Price(i+periodAMA))/Noise; else ER=0;
      SSC=MathPow(ER*dFS+slowSC,G);
      AMAbuffer[i]=Price(i)*SSC+AMAbuffer[i+1]*(1-SSC);
      AMA2Buffer[i]=AMAbuffer[i]*AMAbuffer[i]+AMA2Buffer[i+1];
      SumAMABuffer[i]=SumAMABuffer[i+1]+AMAbuffer[i];
     }
   for(i=limit2;i>=0;i--)
     {
      val1=0;
      val2=0;
      SredneeAMA=(SumAMABuffer[i]-SumAMABuffer[i+periodAMA])/periodAMA;
      SumKvadratAMA=AMA2Buffer[i]-AMA2Buffer[i+periodAMA];
      dipersion=SumKvadratAMA/periodAMA-SredneeAMA*SredneeAMA;
      if(dipersion<0) {
      StdAMA[i]=0;
      Print(i,";",Price(i),";",AbsBuffer[i],";",AMAbuffer[i],";",AMA2Buffer[i],";",SumAMABuffer[i],";",(SumAMABuffer[i]-SumAMABuffer[i+periodAMA])/periodAMA);
      debug=true;}
      else StdAMA[i]=MathSqrt(dipersion);

      if(AMA_Trend_Type!=0)
        {
         if(MathAbs(AMAbuffer[i]-AMAbuffer[i+1])>dK*Point)
           {
            if(AMAbuffer[i]-AMAbuffer[i+1]>0) val1=AMAbuffer[i];
            else val2=AMAbuffer[i];
           }
        }
      else
        {
         if(MathAbs(AMAbuffer[i]-AMAbuffer[i+1])>dK*StdAMA[i])
           {
            if(AMAbuffer[i]-AMAbuffer[i+1]>0) val1=AMAbuffer[i];
            else val2=AMAbuffer[i];
           }
        }
      upAMA[i]=val1;//0 for up if down
      downAMA[i]=val2;//0 for down if up
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
