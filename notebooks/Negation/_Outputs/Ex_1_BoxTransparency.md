1. AgentBehavior: UnChosen
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               3.85527     0.123759  31.15    <1e-99
Box_Transparency: TT-OO  -0.735348    0.113167  -6.50    <1e-10
Box_Transparency: OO-OO   0.488774    0.107513   4.55    <1e-05
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)               3.61844    4.09636
   2 │ Box_Transparency: TT-OO  -0.942163  -0.527759
   3 │ Box_Transparency: OO-OO   0.282511   0.707788
2. AgentBehavior: Chosen
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               5.00541    0.117953   42.44    <1e-99
Box_Transparency: TT-TT   0.804864   0.093367    8.62    <1e-17
Box_Transparency: OO-OO  -0.409654   0.0984622  -4.16    <1e-04
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)               4.7803     5.23204
   2 │ Box_Transparency: TT-TT   0.630132   0.983131
   3 │ Box_Transparency: OO-OO  -0.620304  -0.230011
3. AgentBehavior: Basket
──────────────────────────────────────────────────────────────
                            Coef.  Std. Error      z  Pr(>|z|)
──────────────────────────────────────────────────────────────
(Intercept)              4.1505     0.114599   36.22    <1e-99
Box_Transparency: TT-OO  0.475653   0.134618    3.53    0.0004
Box_Transparency: OO-OO  0.145686   0.0838218   1.74    0.0822
──────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower       upper
     │ String?                  Float64     Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)               3.92053    4.35506
   2 │ Box_Transparency: TT-OO   0.199245   0.737579
   3 │ Box_Transparency: OO-OO  -0.0255059  0.309433
