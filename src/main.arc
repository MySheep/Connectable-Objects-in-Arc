(prn (dir "."))

(load "../Connect/lib/system.arc")
(load "../Connect/view/object-print.arc")

((fn () ;; main

;; ----------------------------------------------------------------------------
;; Register type 'adder
;; ----------------------------------------------------------------------------
;;
;;     'adder
;;    --------
;;  -|> a 1   |>- 
;;  -|> b 2   |>-
;;   |  c 0 * |>-  (c = a + b)
;;   |  d 0 * |>-  (d = a - b)
;;    --------  
;;
;; ----------------------------------------------------------------------------

(register-type 'adder 

    ;; Init
    (fn (typ)
        
        ;; Register Attributes of this type

        (with
            (   attr-a (inst 'numeric-attr 'name 'a 'value 1)
                attr-b (inst 'numeric-attr 'name 'b 'value 2)
                attr-c (inst 'numeric-attr 'name 'c 'is-writeable nil)
                attr-d (inst 'numeric-attr 'name 'd 'is-writeable nil)
            )
            (
            ;; Register attributes of type

            (add-attr typ attr-a)
            (add-attr typ attr-b)
            (add-attr typ attr-c)
            (add-attr typ attr-d)

            ;; Register attributes affeced by other attributes

            (add-attr-affects typ attr-a (list attr-c attr-d))
            (add-attr-affects typ attr-b (list attr-c attr-d))
            
            )
        ) ; with
    ) ; init fn

    ;; Calc fn
    (fn (ob attr)  
        (withs
            (   
                attr-a (get-attr-by-name ob 'a)
                attr-b (get-attr-by-name ob 'b)
                attr-c (get-attr-by-name ob 'c)
                attr-d (get-attr-by-name ob 'd)

                a (get-value ob attr-a)
                b (get-value ob attr-b)
            )   

            (prn "calc " (conn-as-string (list ob attr)) " (c = a + b, d = a - b)")

            ;; -------------
            ;; | c = a + b |
            ;; -------------

            (if (is (attr 'name) 'c)
                (do
                  
                    (set-value-intern ob attr-c (+ a b))
                   
                )
            )
            ;; -------------
            ;; | d = a - b |
            ;; -------------

            (if (is (attr 'name) 'd)
                (set-value-intern ob attr-d (- a b))
            )

        ) ; with
    ) ; calc fn
)

;;     adder1
;;    --------
;;  -|> a 1   |>-       adder2
;;  -|> b 2   |>-      --------
;;   |  c 0 * |>------|> a 1   |>-     
;;   |  d 0 * |>      |> b 2   |>-     
;;    --------        |  c 0 * |>-----(get-value)
;;                    |  d 0 * |>   
;;                     --------       

(prn)
(prn "1. create adder1 and adder2")

(= adder1 (inst-obj 'adder "adder1"))
(= adder2 (inst-obj 'adder "adder2"))

(= adder1-attr-c (get-attr-by-name adder1 'c))
(= adder1-attr-a (get-attr-by-name adder1 'a))
(= adder2-attr-a (get-attr-by-name adder2 'a))
(= adder2-attr-c (get-attr-by-name adder2 'c))
(= adder2-attr-d (get-attr-by-name adder2 'd))

(prn "2. connect adder1.c with adder2.a")

(connect adder1 adder1-attr-c adder2 adder2-attr-a)

(prn "3. get adder2.c -> " (get-value adder2 adder2-attr-c))

(prn "4. set adder1.a = 3")
(set-value adder1 adder1-attr-a 3)

(prn "5. get adder2.c -> " (get-value adder2 adder2-attr-c))
(prn "5. get adder2.d -> " (get-value adder2 adder2-attr-d))

(each o (list adder1 adder2)
    (print-obj o)
)

)) ;; main
