1. Box Transparency: OO-OO
───────────────────────────────────────────────────────────────
                             Coef.  Std. Error      z  Pr(>|z|)
───────────────────────────────────────────────────────────────
(Intercept)              4.34359     0.0947424  45.85    <1e-99
Agent_Behavior: Chosen   0.252255    0.082843    3.04    0.0023
Agent_Behavior: Basket  -0.0480263   0.0771025  -0.62    0.5334
───────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower       upper
     │ String?                 Float64     Float64
─────┼───────────────────────────────────────────────
   1 │ (Intercept)              4.13482    4.52772
   2 │ Agent_Behavior: Chosen   0.0993254  0.409677
   3 │ Agent_Behavior: Basket  -0.215373   0.0979368
2. Box Transparency: TT-TT
─────────────────────────────────────────────────────────────
                           Coef.  Std. Error      z  Pr(>|z|)
─────────────────────────────────────────────────────────────
(Intercept)             3.85586    0.124443   30.99    <1e-99
Agent_Behavior: Chosen  1.95651    0.157252   12.44    <1e-34
Agent_Behavior: Basket  0.294759   0.0924236   3.19    0.0014
─────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower     upper
     │ String?                 Float64   Float64
─────┼───────────────────────────────────────────
   1 │ (Intercept)             3.60112   4.08892
   2 │ Agent_Behavior: Chosen  1.63902   2.28102
   3 │ Agent_Behavior: Basket  0.100245  0.46096
3. Box Transparency: TT-OO
────────────────────────────────────────────────────────────
                          Coef.  Std. Error      z  Pr(>|z|)
────────────────────────────────────────────────────────────
(Intercept)             3.11931    0.172293  18.10    <1e-72
Agent_Behavior: Chosen  1.8859     0.183745  10.26    <1e-23
Agent_Behavior: Basket  1.50637    0.185792   8.11    <1e-15
────────────────────────────────────────────────────────────
Coverage Intervals
3×3 DataFrame
 Row │ names                   lower    upper
     │ String?                 Float64  Float64
─────┼──────────────────────────────────────────
   1 │ (Intercept)             2.74159  3.40537
   2 │ Agent_Behavior: Chosen  1.55258  2.27549
   3 │ Agent_Behavior: Basket  1.12906  1.84775
