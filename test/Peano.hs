fromList [("Bool",TyAlg "Bool" [("True",-5,TyConApp "Bool" [],[]),("False",-6,TyConApp "Bool" [],[])]),("Char",TyAlg "Char" [("C#",-4,TyConApp "Char#" [],[TyRawChar])]),("Double",TyAlg "Double" [("D#",-3,TyConApp "Double#" [],[TyRawDouble])]),("Float",TyAlg "Float" [("F#",-2,TyConApp "Float#" [],[TyRawFloat])]),("HugeArgs",TyAlg "HugeArgs" [("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []])]),("Int",TyAlg "Int" [("I#",-1,TyConApp "Int#" [],[TyRawInt])]),("Peano",TyAlg "Peano" [("Zero",1,TyConApp "Peano" [],[]),("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []])])]
fromList [("add",Lam "ds" (Lam "b" (Case (Var "ds" (TyConApp "Peano" [])) [((("Zero",1,TyConApp "Peano" [],[]),[]),Var "b" (TyConApp "Peano" [])),((("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []]),["a"]),App (Var "Succ" (TyFun (TyConApp "Peano" []) (TyConApp "Peano" []))) (App (App (Var "add" (TyFun (TyConApp "Peano" []) (TyFun (TyConApp "Peano" []) (TyConApp "Peano" [])))) (Var "a" (TyConApp "Peano" []))) (Var "b" (TyConApp "Peano" []))))] (TyConApp "Peano" [])) (TyConApp "Peano" [])) (TyConApp "Peano" [])),("fourth",Lam "ds" (Case (Var "ds" (TyConApp "HugeArgs" [])) [((("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []]),["ds1","ds2","ds3","a"]),Var "a" (TyConApp "Int" []))] (TyConApp "Int" [])) (TyConApp "Int" [])),("hue",App (App (Var "head" (TyForAll "a" (TyFun (TyConApp "[]" [TyVar "a"]) (TyVar "a")))) (Type (TyConApp "Integer" []))) (App (App (App (Var "enumFrom" (TyForAll "a" (TyFun (TyConApp "Enum" [TyVar "a"]) (TyFun (TyVar "a") (TyConApp "[]" [TyVar "a"]))))) (Type (TyConApp "Integer" []))) (Var "$fEnumInteger" (TyConApp "Enum" [TyConApp "Integer" []]))) (Const (CInt 1)))),("test",Lam "a" (Lam "b" (Lam "c" (Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))) (Var "c" (TyConApp "Int" []))) [((("False",1,TyConApp "Bool" [],[]),[]),Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "c" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5)))) [((("False",1,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" []))),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "b" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" [])))] (TyConApp "Int" [])),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))] (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" []))]
Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" [])))) (Var "cc" (TyConApp "Int" []))) [((("False",1,TyConApp "Bool" [],[]),[]),Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "cc" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5)))) [((("False",1,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "cc" (TyConApp "Int" []))),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "bb" (TyConApp "Int" []))) (Var "cc" (TyConApp "Int" [])))] (TyConApp "Int" [])),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" [])))] (TyConApp "Int" [])
[]
=======================
fromList [("Bool",TyAlg "Bool" [("True",-5,TyConApp "Bool" [],[]),("False",-6,TyConApp "Bool" [],[])]),("Char",TyAlg "Char" [("C#",-4,TyConApp "Char#" [],[TyRawChar])]),("Double",TyAlg "Double" [("D#",-3,TyConApp "Double#" [],[TyRawDouble])]),("Float",TyAlg "Float" [("F#",-2,TyConApp "Float#" [],[TyRawFloat])]),("HugeArgs",TyAlg "HugeArgs" [("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []])]),("Int",TyAlg "Int" [("I#",-1,TyConApp "Int#" [],[TyRawInt])]),("Peano",TyAlg "Peano" [("Zero",1,TyConApp "Peano" [],[]),("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []])])]
fromList [("add",Lam "ds" (Lam "b" (Case (Var "ds" (TyConApp "Peano" [])) [((("Zero",1,TyConApp "Peano" [],[]),[]),Var "b" (TyConApp "Peano" [])),((("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []]),["a"]),App (Var "Succ" (TyFun (TyConApp "Peano" []) (TyConApp "Peano" []))) (App (App (Var "add" (TyFun (TyConApp "Peano" []) (TyFun (TyConApp "Peano" []) (TyConApp "Peano" [])))) (Var "a" (TyConApp "Peano" []))) (Var "b" (TyConApp "Peano" []))))] (TyConApp "Peano" [])) (TyConApp "Peano" [])) (TyConApp "Peano" [])),("fourth",Lam "ds" (Case (Var "ds" (TyConApp "HugeArgs" [])) [((("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []]),["ds1","ds2","ds3","a"]),Var "a" (TyConApp "Int" []))] (TyConApp "Int" [])) (TyConApp "Int" [])),("hue",App (App (Var "head" (TyForAll "a" (TyFun (TyConApp "[]" [TyVar "a"]) (TyVar "a")))) (Type (TyConApp "Integer" []))) (App (App (App (Var "enumFrom" (TyForAll "a" (TyFun (TyConApp "Enum" [TyVar "a"]) (TyFun (TyVar "a") (TyConApp "[]" [TyVar "a"]))))) (Type (TyConApp "Integer" []))) (Var "$fEnumInteger" (TyConApp "Enum" [TyConApp "Integer" []]))) (Const (CInt 1)))),("test",Lam "a" (Lam "b" (Lam "c" (Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))) (Var "c" (TyConApp "Int" []))) [((("False",1,TyConApp "Bool" [],[]),[]),Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "c" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5)))) [((("False",1,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" []))),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "b" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" [])))] (TyConApp "Int" [])),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))] (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" []))]
App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" []))
[(App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" [])))) (Var "cc" (TyConApp "Int" [])),(("True",2,TyConApp "Bool" [],[]),[]))]
--------------
fromList [("Bool",TyAlg "Bool" [("True",-5,TyConApp "Bool" [],[]),("False",-6,TyConApp "Bool" [],[])]),("Char",TyAlg "Char" [("C#",-4,TyConApp "Char#" [],[TyRawChar])]),("Double",TyAlg "Double" [("D#",-3,TyConApp "Double#" [],[TyRawDouble])]),("Float",TyAlg "Float" [("F#",-2,TyConApp "Float#" [],[TyRawFloat])]),("HugeArgs",TyAlg "HugeArgs" [("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []])]),("Int",TyAlg "Int" [("I#",-1,TyConApp "Int#" [],[TyRawInt])]),("Peano",TyAlg "Peano" [("Zero",1,TyConApp "Peano" [],[]),("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []])])]
fromList [("add",Lam "ds" (Lam "b" (Case (Var "ds" (TyConApp "Peano" [])) [((("Zero",1,TyConApp "Peano" [],[]),[]),Var "b" (TyConApp "Peano" [])),((("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []]),["a"]),App (Var "Succ" (TyFun (TyConApp "Peano" []) (TyConApp "Peano" []))) (App (App (Var "add" (TyFun (TyConApp "Peano" []) (TyFun (TyConApp "Peano" []) (TyConApp "Peano" [])))) (Var "a" (TyConApp "Peano" []))) (Var "b" (TyConApp "Peano" []))))] (TyConApp "Peano" [])) (TyConApp "Peano" [])) (TyConApp "Peano" [])),("fourth",Lam "ds" (Case (Var "ds" (TyConApp "HugeArgs" [])) [((("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []]),["ds1","ds2","ds3","a"]),Var "a" (TyConApp "Int" []))] (TyConApp "Int" [])) (TyConApp "Int" [])),("hue",App (App (Var "head" (TyForAll "a" (TyFun (TyConApp "[]" [TyVar "a"]) (TyVar "a")))) (Type (TyConApp "Integer" []))) (App (App (App (Var "enumFrom" (TyForAll "a" (TyFun (TyConApp "Enum" [TyVar "a"]) (TyFun (TyVar "a") (TyConApp "[]" [TyVar "a"]))))) (Type (TyConApp "Integer" []))) (Var "$fEnumInteger" (TyConApp "Enum" [TyConApp "Integer" []]))) (Const (CInt 1)))),("test",Lam "a" (Lam "b" (Lam "c" (Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))) (Var "c" (TyConApp "Int" []))) [((("False",1,TyConApp "Bool" [],[]),[]),Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "c" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5)))) [((("False",1,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" []))),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "b" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" [])))] (TyConApp "Int" [])),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))] (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" []))]
App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "cc" (TyConApp "Int" []))
[(App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "cc" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5))),(("False",1,TyConApp "Bool" [],[]),[])),(App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" [])))) (Var "cc" (TyConApp "Int" [])),(("False",1,TyConApp "Bool" [],[]),[]))]
--------------
fromList [("Bool",TyAlg "Bool" [("True",-5,TyConApp "Bool" [],[]),("False",-6,TyConApp "Bool" [],[])]),("Char",TyAlg "Char" [("C#",-4,TyConApp "Char#" [],[TyRawChar])]),("Double",TyAlg "Double" [("D#",-3,TyConApp "Double#" [],[TyRawDouble])]),("Float",TyAlg "Float" [("F#",-2,TyConApp "Float#" [],[TyRawFloat])]),("HugeArgs",TyAlg "HugeArgs" [("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []])]),("Int",TyAlg "Int" [("I#",-1,TyConApp "Int#" [],[TyRawInt])]),("Peano",TyAlg "Peano" [("Zero",1,TyConApp "Peano" [],[]),("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []])])]
fromList [("add",Lam "ds" (Lam "b" (Case (Var "ds" (TyConApp "Peano" [])) [((("Zero",1,TyConApp "Peano" [],[]),[]),Var "b" (TyConApp "Peano" [])),((("Succ",2,TyConApp "Peano" [],[TyConApp "Peano" []]),["a"]),App (Var "Succ" (TyFun (TyConApp "Peano" []) (TyConApp "Peano" []))) (App (App (Var "add" (TyFun (TyConApp "Peano" []) (TyFun (TyConApp "Peano" []) (TyConApp "Peano" [])))) (Var "a" (TyConApp "Peano" []))) (Var "b" (TyConApp "Peano" []))))] (TyConApp "Peano" [])) (TyConApp "Peano" [])) (TyConApp "Peano" [])),("fourth",Lam "ds" (Case (Var "ds" (TyConApp "HugeArgs" [])) [((("Go",1,TyConApp "HugeArgs" [],[TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" [],TyConApp "Int" []]),["ds1","ds2","ds3","a"]),Var "a" (TyConApp "Int" []))] (TyConApp "Int" [])) (TyConApp "Int" [])),("hue",App (App (Var "head" (TyForAll "a" (TyFun (TyConApp "[]" [TyVar "a"]) (TyVar "a")))) (Type (TyConApp "Integer" []))) (App (App (App (Var "enumFrom" (TyForAll "a" (TyFun (TyConApp "Enum" [TyVar "a"]) (TyFun (TyVar "a") (TyConApp "[]" [TyVar "a"]))))) (Type (TyConApp "Integer" []))) (Var "$fEnumInteger" (TyConApp "Enum" [TyConApp "Integer" []]))) (Const (CInt 1)))),("test",Lam "a" (Lam "b" (Lam "c" (Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))) (Var "c" (TyConApp "Int" []))) [((("False",1,TyConApp "Bool" [],[]),[]),Case (App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "c" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5)))) [((("False",1,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" []))),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "b" (TyConApp "Int" []))) (Var "c" (TyConApp "Int" [])))] (TyConApp "Int" [])),((("True",2,TyConApp "Bool" [],[]),[]),App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "a" (TyConApp "Int" []))) (Var "b" (TyConApp "Int" [])))] (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" [])) (TyConApp "Int" []))]
App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "bb" (TyConApp "Int" []))) (Var "cc" (TyConApp "Int" []))
[(App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (Var "cc" (TyConApp "Int" []))) (App (Var "I#" (TyFun (TyConApp "Int#" []) (TyConApp "Int" []))) (Const (CInt 5))),(("True",2,TyConApp "Bool" [],[]),[])),(App (App (App (App (Var "<" (TyForAll "a" (TyFun (TyConApp "Ord" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyConApp "Bool" [])))))) (Type (TyConApp "Int" []))) (Var "$fOrdInt" (TyConApp "Ord" [TyConApp "Int" []]))) (App (App (App (App (Var "+" (TyForAll "a" (TyFun (TyConApp "Num" [TyVar "a"]) (TyFun (TyVar "a") (TyFun (TyVar "a") (TyVar "a")))))) (Type (TyConApp "Int" []))) (Var "$fNumInt" (TyConApp "Num" [TyConApp "Int" []]))) (Var "aa" (TyConApp "Int" []))) (Var "bb" (TyConApp "Int" [])))) (Var "cc" (TyConApp "Int" [])),(("False",1,TyConApp "Bool" [],[]),[]))]
Compiles!