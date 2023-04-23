1. AgentBehavior: UnChosen
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               3.35979    0.139808   24.03    <1e-99
Box_Transparency: TT-TO  -0.649201   0.0994315  -6.53    <1e-10
Box_Transparency: TO-TO   0.87264    0.150284    5.81    <1e-08
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)               3.08807    3.62865
   2 │ Box_Transparency: TT-TO  -0.825683  -0.446337
   3 │ Box_Transparency: TO-TO   0.606507   1.18537
2. AgentBehavior: Chosen
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               4.82837    0.115693   41.73    <1e-99
Box_Transparency: TT-TT   0.94997    0.0966916   9.82    <1e-22
Box_Transparency: TO-TO  -0.315194   0.10311    -3.06    0.0022
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)               4.59222    5.04269
   2 │ Box_Transparency: TT-TT   0.756224   1.1365
   3 │ Box_Transparency: TO-TO  -0.516574  -0.106964
3. AgentBehavior: Basket
──────────────────────────────────────────────────────────────
                            Coef.  Std. Error      z  Pr(>|z|)
──────────────────────────────────────────────────────────────
(Intercept)              4.14866    0.101319   40.95    <1e-99
Box_Transparency: TT-TO  0.295037   0.0928838   3.18    0.0015
Box_Transparency: TO-TO  0.053633   0.0932765   0.57    0.5653
──────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼──────────────────────────────────────────────
   1 │ (Intercept)               3.9669    4.36649
   2 │ Box_Transparency: TT-TO   0.137089  0.489227
   3 │ Box_Transparency: TO-TO  -0.129871  0.229811
