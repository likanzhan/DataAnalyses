1. AgentBehavior: UnChosen
──────────────────────────────────────────────────────────────
                            Coef.  Std. Error      z  Pr(>|z|)
──────────────────────────────────────────────────────────────
(Intercept)               3.08936    0.166248  18.58    <1e-76
Box_Transparency: TT-OO  -0.49436    0.10706   -4.62    <1e-05
Box_Transparency: TO-OO   0.78526    0.150701   5.21    <1e-06
──────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼──────────────────────────────────────────────
   1 │ (Intercept)               2.79336    3.41931
   2 │ Box_Transparency: TT-OO  -0.697353  -0.2949
   3 │ Box_Transparency: TO-OO   0.471119   1.06417
2. AgentBehavior: Chosen
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               4.51187     0.102257  44.12    <1e-99
Box_Transparency: TT-OT   0.879882    0.111131   7.92    <1e-14
Box_Transparency: TO-OO  -0.512581    0.107212  -4.78    <1e-05
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower      upper
     │ String?                  Float64    Float64
─────┼──────────────────────────────────────────────
   1 │ (Intercept)               4.31374    4.7148
   2 │ Box_Transparency: TT-OT   0.647568   1.07925
   3 │ Box_Transparency: TO-OO  -0.708281  -0.29294
3. AgentBehavior: Basket
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)               4.00779     0.116397  34.43    <1e-99
Box_Transparency: TT-OO   0.216049    0.114905   1.88    0.0601
Box_Transparency: TO-OO  -0.182914    0.109269  -1.67    0.0941
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                    lower       upper
     │ String?                  Float64     Float64
─────┼────────────────────────────────────────────────
   1 │ (Intercept)               3.79971    4.25406
   2 │ Box_Transparency: TT-OO  -0.0116355  0.4214
   3 │ Box_Transparency: TO-OO  -0.384807   0.0242461
