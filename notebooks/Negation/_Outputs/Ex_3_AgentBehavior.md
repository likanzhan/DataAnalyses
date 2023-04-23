1. Box Transparency: TO-OO
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)              3.87442     0.119862   32.32    <1e-99
Agent_Behavior: Chosen   0.124872    0.0564989   2.21    0.0271
Agent_Behavior: Basket  -0.0495605   0.0651116  -0.76    0.4466
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower      upper
     │ String?                 Float64    Float64
─────┼──────────────────────────────────────────────
   1 │ (Intercept)              3.64513   4.09283
   2 │ Agent_Behavior: Chosen   0.020615  0.235687
   3 │ Agent_Behavior: Basket  -0.163129  0.0906197
2. Box Transparency: TT-OT
─────────────────────────────────────────────────────────────
                           Coef.  Std. Error      z  Pr(>|z|)
─────────────────────────────────────────────────────────────
(Intercept)             3.08936     0.16637   18.57    <1e-76
Agent_Behavior: Chosen  2.3024      0.197323  11.67    <1e-30
Agent_Behavior: Basket  0.918396    0.153116   6.00    <1e-08
─────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower     upper
     │ String?                 Float64   Float64
─────┼───────────────────────────────────────────
   1 │ (Intercept)             2.74343   3.39503
   2 │ Agent_Behavior: Chosen  1.96253   2.70902
   3 │ Agent_Behavior: Basket  0.646142  1.23509
3. Box Transparency: TT-OO
────────────────────────────────────────────────────────────
                          Coef.  Std. Error      z  Pr(>|z|)
────────────────────────────────────────────────────────────
(Intercept)             2.59487    0.160301  16.19    <1e-58
Agent_Behavior: Chosen  1.91701    0.145389  13.19    <1e-38
Agent_Behavior: Basket  1.62897    0.141725  11.49    <1e-29
────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower    upper
     │ String?                 Float64  Float64
─────┼──────────────────────────────────────────
   1 │ (Intercept)             2.30176  2.87751
   2 │ Agent_Behavior: Chosen  1.64057  2.18638
   3 │ Agent_Behavior: Basket  1.36621  1.90116
