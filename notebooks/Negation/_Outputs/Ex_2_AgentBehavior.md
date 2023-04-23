1. Box Transparency: TO-TO
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)              4.23214     0.127708   33.14    <1e-99
Agent_Behavior: Chosen   0.282452    0.0931523   3.03    0.0024
Agent_Behavior: Basket  -0.0296443   0.0613677  -0.48    0.6291
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower       upper
     │ String?                 Float64     Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)              3.98987    4.46634
   2 │ Agent_Behavior: Chosen   0.0917238  0.454675
   3 │ Agent_Behavior: Basket  -0.153417   0.0762654
2. Box Transparency: TT-TT
─────────────────────────────────────────────────────────────
                           Coef.  Std. Error      z  Pr(>|z|)
─────────────────────────────────────────────────────────────
(Intercept)             3.36011     0.141832  23.69    <1e-99
Agent_Behavior: Chosen  2.41787     0.196324  12.32    <1e-34
Agent_Behavior: Basket  0.788124    0.138604   5.69    <1e-07
─────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower     upper
     │ String?                 Float64   Float64
─────┼───────────────────────────────────────────
   1 │ (Intercept)             3.08944   3.6391
   2 │ Agent_Behavior: Chosen  2.04464   2.80173
   3 │ Agent_Behavior: Basket  0.510852  1.03564
3. Box Transparency: TT-TO
────────────────────────────────────────────────────────────
                          Coef.  Std. Error      z  Pr(>|z|)
────────────────────────────────────────────────────────────
(Intercept)             2.71045    0.138759  19.53    <1e-84
Agent_Behavior: Chosen  2.11811    0.149719  14.15    <1e-44
Agent_Behavior: Basket  1.73154    0.17028   10.17    <1e-23
────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower    upper
     │ String?                 Float64  Float64
─────┼──────────────────────────────────────────
   1 │ (Intercept)             2.45888  2.9722
   2 │ Agent_Behavior: Chosen  1.79266  2.37556
   3 │ Agent_Behavior: Basket  1.41595  2.03741
