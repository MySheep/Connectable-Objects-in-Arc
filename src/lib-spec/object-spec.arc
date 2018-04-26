;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Unit Tests - to test specification 
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; ----------------------------------------------------------------------------
;; TODOS 
;; ----------------------------------------------------------------------------

;; 2017-12-21 [x] RegisterTest, RunTests
;; 2017-12-21 [x] Create Test fn with Name and Return ('t -> ok) OR ('f , (list of errors))
;; 2017-12-19 [x] Better unit test like Assert-IsEqual(actual expected)
;; 2017-12-19 [x] Reset table not necessary
;; 2017-12-19 [x] Create and remove type 'adder at Unit Test
;; 2017-12-19 [x] Test set-up and clean-up

;; ----------------------------------------------------------------------------
;; reset-tables 
;; ----------------------------------------------------------------------------

(def reset-tables ()

    ;; (= attributes-by-type*     (table))
    ;; (= attributes-affected-by-type* (table))
    ;; (= calc-fns-by-type*       (table))

    (= values-by-object*        (table))
    (= dirties-by-object*       (table))
    (= objects-by-name*         (table))
    (= forward-connections*     (table))
    (= backward-connections*    (table))

    (= add1 nil)
    (= add2 nil)
    (= add3 nil)
)


;; ----------------------------------------------------------------------------
;; test-adder-example ()
;; ----------------------------------------------------------------------------

(def test-adder-example ()

    (= add1 (inst-obj 'adder "adder1"))

    (= attr-a (get-attr-by-name add1 'a))
    (= attr-b (get-attr-by-name add1 'b))
    (= attr-c (get-attr-by-name add1 'c))
    (= attr-d (get-attr-by-name add1 'd))

    (set-value add1 attr-a 2)
    (set-value add1 attr-b 3)

    (if (is (get-value add1 attr-c) 5)
        (prn "c is ok")
        (prn "c is not ok")
    )
    (if (is (get-value add1 attr-d) -1)
        (prn "d is ok")
        (prn "d is not ok")
    )
) 

;;(test-adder-example)

;; ----------------------------------------------------------------------------
;; test-connections-3-adders
;; ----------------------------------------------------------------------------
;;      add1
;;    --------
;;  -|> a 1   |>-        add2
;;  -|> b 2   |>-      --------
;;   |  c 3   |>------|> a 3   |>-        add3
;;   |  d 0 * |>-    -|> b 2   |>-      --------
;;    --------        |  c 5   |>------|> a 5   |>- 
;;                    |  d 0 * |>-    -|> b 2   |>-
;;                     --------        |  c 7   |>---(get-value)
;;                                     |  d 0 * |>
;;                                      --------
;; ----------------------------------------------------------------------------

(def test-connections-3-adders ()

    (reset-tables) ;; TODO: REMOVE 

    (= add1     (inst-obj 'adder "adder1"))
    (= add2     (inst-obj 'adder "adder2"))
    (= add3     (inst-obj 'adder "adder3"))

    (connect    add1 (get-attr-by-name add1 'c) 
                add2 (get-attr-by-name add2 'a)
    )

    (connect    add2 (get-attr-by-name add2 'c) 
                add3 (get-attr-by-name add2 'a)
    )

    (with 
        (
            expected    7
            actual      (get-value add3 (get-attr-by-name add3 'c))
        )
        (if (is actual expected)
            (prn "OK")
            (prn "NOT OK")
        )
    )

    ;; --------
    ;; Show all
    ;; --------

    (each ob (list add1 add2 add3) 
        (print-obj ob)
    )

    ;; --------
    ;; Clean up
    ;; --------

    (disconnect     add1 (get-attr-by-name add1 'c) 
                    add2 (get-attr-by-name add2 'a)
    )

    (disconnect     add2 (get-attr-by-name add2 'c) 
                    add3 (get-attr-by-name add2 'a)
    )

    (remove-obj add1) ; remove values, dirties, obj-by-name
    (remove-obj add2)
    (remove-obj add3)

    (= add1 nil)
    (= add2 nil)
    (= add3 nil)

)

(test-connections-3-adders)

;; ----------------------------------------------------------------------------
;; test-dirty-propagation
;; ----------------------------------------------------------------------------
;;      add1
;;    --------
;;  -|> a 1   |>-        add2
;;  -|> b 2   |>-      --------
;;   |  c 0 * |>------|> a 1   |>-     
;;   |  d 0 * |>------|> b 2   |>-     
;;    --------        |  c 0 * |>-----(get-value)
;;                    |  d 0 * |>-----(get-value)    
;;                     --------       
;; ----------------------------------------------------------------------------

(def test-dirty-propagation ()

    (reset-tables)

    (prn "test-dirty-propagation")
    (prn)

    ;; --------------------------------------
    ;; 1. create add1 add2 and clean both c's
    ;; --------------------------------------

    (prn "1. create add1 add2 and clean both c's")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 1   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 3   |>      |> a 1   |>-     
    ;;   |  d 0 * |>      |> b 2   |>-     
    ;;    --------        |  c 3   |>-
    ;;                    |  d 0 * |>    
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (= add1         (inst-obj 'adder "adder1"))
    (= add2         (inst-obj 'adder "adder2"))

    (let clean-c 
        (fn (ob)
            (with 
                (   expected    3
                    actual      (get-value add1 (get-attr-by-name add1 'c))
                )
                (if (is expected actual)
                    (prn "1. OK")
                    (prf "1. NOT OK - expected (#expected) != actual (#actual)")
                )
            )
        )
        (clean-c add1)
        (clean-c add2)
    )

    ;; -----------------------------
    ;; 2. connect add1.c with add2.a
    ;; -----------------------------

    (prn "2. connect add1.c with add2.a")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 1   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 0 * |>------|> a 1 * |>-     
    ;;   |  d 0 * |>------|> b 2   |>-     
    ;;    --------        |  c 0 * |>-
    ;;                    |  d 0 * |>-   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (connect    add1 (get-attr-by-name add1 'c)
                add2 (get-attr-by-name add2 'a)
    )

    (if (and
            (is-dirty add2 (get-attr-by-name add2 'a))
            (is-dirty add2 (get-attr-by-name add2 'c))
        )
        (prn "2. OK")
        (prn "2. NOT OK - add2.a add2.c must be dirty")
    )



    ;; -----------------
    ;; 3. set add1.a = 3
    ;; -----------------

    (prn "3. set add1.a = 3")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 3   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 0 * |>------|> a 1 * |>-     
    ;;   |  d 0 * |>------|> b 2   |>-     
    ;;    --------        |  c 0 * |>-
    ;;                    |  d 0 * |>-   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (set-value add1 (get-attr-by-name add1 'a) 3)

    (if (and
            (is-dirty add1 (get-attr-by-name add1 'c))
            (is-dirty add1 (get-attr-by-name add1 'd))

            (is-dirty add2 (get-attr-by-name add2 'a))
            (is-dirty add2 (get-attr-by-name add2 'c))
            (is-dirty add2 (get-attr-by-name add2 'd))
        )
        (prn "3. OK")
        (prn "3. NOT-OK - add1.c add2.a add2.c must be dirty")
    )

    ;; ------------------
    ;; 4. get add2.c -> 7
    ;; ------------------

    (prn "4. get add2.c -> 7")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 3   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 5   |>------|> a 5   |>-     
    ;;   |  d 0 * |>     -|> b 2   |>-     
    ;;    --------        |  c 7   |>---(get-value)
    ;;                    |  d 0 * |>-   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (with 
        (   expected    7
            actual      (get-value add2 (get-attr-by-name add2 'c))
        )
        (if (is expected actual)
            (prn "4. OK")
            (prf "4. NOT OK - expected (#expected) != actual (#actual)")
        )
    )

    ;; -----------------------------
    ;; 5. connect add1.d with add2.b
    ;; -----------------------------

    (prn "5. connect add1.d with add2.b")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 3   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 5   |>------|> a 5   |>-     
    ;;   |  d 0 * |>------|> b 2 * |>-     
    ;;    --------        |  c 7   |>- 
    ;;                    |  d 0 * |>-   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (connect    add1 (get-attr-by-name add1 'd)
                add2 (get-attr-by-name add2 'b)
    )

    (if ;; cond 
        (and
            (is-dirty add2 (get-attr-by-name add2 'b))
            (is-dirty add2 (get-attr-by-name add2 'c))
            (is-dirty add2 (get-attr-by-name add2 'd))
        )
        ;; then
        (prn "5. OK")
        ;; else
        (do 
            (prn "5. NOT-OK - add2.b add2.c add2.d must be dirty") 
            (each ob (list add1 add2) 
                (print-obj ob)
            )
        )
    )

    ;; ------------------------
    ;; 6. get add2.c -> 6 (5+1)
    ;; ------------------------

    (prn "6. get add2.c -> 6 (5+1)")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 3   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 5   |>------|> a 5   |>-     
    ;;   |  d 0 * |>------|> b 1   |>-     
    ;;    --------        |  c 6   |>---(get-value)
    ;;                    |  d 0 * |>-   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (with 
        (   expected    6
            actual      (get-value add2 (get-attr-by-name add2 'c))
        )
        (if (is expected actual)
            (prn "6. OK")
            (prf "6. NOT OK - expected (#expected) != actual (#actual)")
        )
    )

    ;; ------------------------
    ;; 7. get add2.d -> 4 (5-1)
    ;; ------------------------

    (prn "7. get add2.d -> 4 (5-1)")

    ;; ----------------------------------------------------------------------------
    ;;      add1
    ;;    --------
    ;;  -|> a 3   |>-        add2
    ;;  -|> b 2   |>-      --------
    ;;   |  c 5   |>------|> a 5   |>-     
    ;;   |  d 1   |>------|> b 1   |>-     
    ;;    --------        |  c 6   |>- 
    ;;                    |  d 4   |>---(get-value)   
    ;;                     --------       
    ;; ----------------------------------------------------------------------------

    (with 
        (   expected    4
            actual      (get-value add2 (get-attr-by-name add2 'd))
        )
        (if (is expected actual)
            (prn "OK")
            (prf "NOT OK - expected (#expected) != actual (#actual)")
        )
    )

    ;; --------
    ;; Show all
    ;; --------

    (each ob (list add1 add2) 
        (print-obj ob)
    )

    ;; --------
    ;; Clean up
    ;; --------

    (disconnect     add1 (get-attr-by-name add1 'd)
                    add2 (get-attr-by-name add2 'b)
    )
    (disconnect     add1 (get-attr-by-name add1 'c)
                    add2 (get-attr-by-name add2 'a)
    )

    (remove-obj add1) ; remove values, dirties, obj-by-name
    (remove-obj add2)

    (= add1 nil)
    (= add2 nil)
)

(test-dirty-propagation)


;; ----------------------------------------------------------------------------
;; test-set-value-on-connected-not-allowed
;; ----------------------------------------------------------------------------
;;      add1
;;    --------
;;  -|> a 1   |>-        add2
;;  -|> b 2   |>-      --------
;;   |  c 0 * |>------|> a 1   |>-     
;;   |  d 0 * |>      |> b 2   |>-     
;;    --------        |  c 0 * |>-
;;                    |  d 0 * |>-    
;;                     --------       
;; ----------------------------------------------------------------------------
(def test-set-value-on-connected-not-allowed ()


    (= add1         (inst-obj 'adder "adder1"))
    (= add2         (inst-obj 'adder "adder2"))

    (connect    add1 (get-attr-by-name add1 'c)
                add2 (get-attr-by-name add2 'a)
    )

    ;;
    ;; TODO: on-err does not work if exception is inside set-value fn
    ;;
    (on-err
        (fn (ex) (prn (string "OK - caught exception: " (details ex))))
        (set-value  add2 (get-attr-by-name add2 'a) 77)
    )

    ;; --------
    ;; Clean up
    ;; --------

    (disconnect     add1 (get-attr-by-name add1 'c)
                    add2 (get-attr-by-name add2 'a)
    )

    (remove-obj add1) ; remove values, dirties, obj-by-name
    (remove-obj add2)

    (= add1 nil)
    (= add2 nil)

)

(test-set-value-on-connected-not-allowed)

