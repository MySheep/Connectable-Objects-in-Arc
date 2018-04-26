

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Global Variables
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; TODO: List of attributes instead of table

(= attrs-by-type* (table))

;; 'adder ->  ( attr-a 
;;              attr-b 
;;              attr-c
;;              attr-d )

(= attrs-affected-by-type* (table))

;; 'adder -> attr-a -> (attr-c attr-d)
;;           attr-b -> (attr-c attr-d)

;; this is done when you instantiate a new object

(= calc-fns-by-type* (table))

;; 'adder   -> (fn (ob attr)
;;                  ...
;;             )

(= values-by-object* (table))

;; 'obj1 ->     attr-a ->  1
;;              attr-b ->  2
;;              attr-c ->  3
;;              attr-d -> -1

;; this is done when you instantiate a new object

(= dirties-by-object* (table))

;; 'obj1 ->     attr-a -> nil
;;              attr-b -> nil
;;              attr-c ->  't
;;              attr-d ->  't

;; this is done when you instantiate a new object

(= objects-by-name* (table))

;; "obj1" -> obj1
;; "obj2" -> obj2 

(= forward-connections*  (table))

;; add1.c ---> add2.a
;;         |-> add2.b
;;
;; add1.c ---> add3.a
;;         |-> add3.b
;;
;; 'add1 -> attr.c -> ((add2 a)(add2 b))
;;       -> attr.d -> ((add3 a)(add3 b))

(= backward-connections*  (table))

;; add1.c <--- add2.a
;; add1.c <--- add2.b

;; ----------------------------------------------------------------------------
;; add-obj-by-name
;; ----------------------------------------------------------------------------

(def add-obj-by-name (ob name)
    (= (objects-by-name* name) ob)
)

;; ----------------------------------------------------------------------------
;; remove-obj-by-name
;; ----------------------------------------------------------------------------

(def remove-obj-by-name (name)
    (= (objects-by-name* name) nil)
)

;; ----------------------------------------------------------------------------
;; get-obj-by-name
;; ----------------------------------------------------------------------------
(def get-obj-by-name (name)
    (let ob (objects-by-name* name)
        (if (is oo nil)
            (nil-object)
            ob
        ) 
    )
)

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Register Types
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


;; ----------------------------------------------------------------------------
;; ensure-if-not-exits
;; ----------------------------------------------------------------------------
(def ensure-if-not-exits (tl o)
    (if (is (tl o) nil    )
        (=  (tl o) (table))
    )
)

;; TODO: Attributes are a list not HASH table

;; ----------------------------------------------------------------------------
;; add-attr
;; ----------------------------------------------------------------------------
(def add-attr (typ attr)

    (ensure-if-not-exits attrs-by-type* typ)
 
    (let t (attrs-by-type* typ)
        (= (t (attr 'name)) attr)
    )
)

;; a affects (c d)
;; b affects (c d)

;; attr-a -> (attr-c attr-d)
;; attr-b -> (attr-c attr-d)

;; ----------------------------------------------------------------------------
;; add-attr-affects
;; ----------------------------------------------------------------------------
(def add-attr-affects (typ attr-affect attrs-affected) 

    (ensure-if-not-exits attrs-affected-by-type* typ)

    (let aa (attrs-affected-by-type* typ) 
        (= (aa attr-affect) attrs-affected)  
    )
)


;; ----------------------------------------------------------------------------
;; get-attr-by-name
;; ----------------------------------------------------------------------------
(def get-attr-by-name (ob attr-name)
    (withs
        ( typ   (ob 'type)
          attrs (attrs-by-type* typ)
        )
        (attrs attr-name)
    )
)

;; ----------------------------------------------------------------------------
;; conn-as-string
;; ----------------------------------------------------------------------------
(def conn-as-string (conn)
    (with
        (   ob    (car  conn)
            attr  (cadr conn)
        )
        (string (ob 'name) "." (attr 'name))
    )
)



;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Inst objects by registered type
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; ----------------------------------------------------------------------------
;; Template "object"
;; ----------------------------------------------------------------------------
(deftem object
    name            "unknown"
    type            'undefined
)

;; ----------------------------------------------------------------------------
;; Singleton "Nil"-object 
;; ----------------------------------------------------------------------------
(= nil-obj (inst 'object 'name "empty" type 'empty))

(def nil-object()
    nil-obj
)

;; ----------------------------------------------------------------------------
;; is-type-registered
;; ----------------------------------------------------------------------------
(def set-default-values (ob typ)

    (ensure-if-not-exits values-by-object* ob)

    (with
        (   vbo   (values-by-object*    ob)
            attrs (vals (attrs-by-type* typ))
        )
        (each attr attrs 
            (= (vbo attr) (attr 'value))
        )
    )
)

; c = a + b
; a,b affects c
; if a or b change c is dirty

; d = a - b
; a,b affects c
; if a or b change c is dirty

;   --------
; -|> a 1   |>-
; -|> b 2   |>-
;  |  c 0 * |>-
;  |  d 0 * |>-
;   --------

;; ----------------------------------------------------------------------------
;; is-affected-attr
;; ----------------------------------------------------------------------------
(def is-affected-attr (ob attr)
    (withs 
        (
            aa      (attrs-affected-by-type* (ob 'type))
            attrs   (flat (vals aa)) ; ((c d)(c d)) -> (c d c d)
        )
        (find attr attrs)
    )
)

;; ----------------------------------------------------------------------------
;; set-default-dirties
;; ----------------------------------------------------------------------------
(def set-default-dirties (ob typ)

    (ensure-if-not-exits dirties-by-object* ob)

    (with
        (   dt    (dirties-by-object* ob)
            attrs (vals (attrs-by-type* typ))
        )
        (each attr attrs 
            (if (is-affected-attr ob attr)
                (= (dt attr) 't) 
            )
        )
    )
)

;; ----------------------------------------------------------------------------
;; is-type-registered
;; ----------------------------------------------------------------------------
(def is-type-registered (typ)
    (no 
        (is (attrs-by-type* typ) nil)
    )
)

;; ----------------------------------------------------------------------------
;; inst-obj-intern
;; ----------------------------------------------------------------------------
(def inst-obj-intern (typ name)

    ;; TODO Check if name already exits else error

    (let ob (inst 'object 'name name 'type typ)

        (set-default-values  ob typ )
        (set-default-dirties ob typ )
        (add-obj-by-name     ob name) 
        ob
    )

)




;; ----------------------------------------------------------------------------
;; remove-obj-intern
;; ----------------------------------------------------------------------------

(def remove-values-of-obj (ob)
    (= (values-by-object* ob) nil)
)

(def remove-dirties-of-obj (ob)
    (= (dirties-by-object* ob) nil)
)

(def remove-obj-intern (ob)
    (remove-values-of-obj  ob)
    (remove-dirties-of-obj ob)
    (remove-obj-by-name (ob 'name))
)


;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Get or set values with Dirty Propagation 
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


(def set-dirty-affected-intern (ob attr)
    (prn "set-dirty-affected-intern for " (conn-as-string (list ob attr))) 
    (let attrs (get-affected-attrs (ob 'type) attr)   
        (each attr-affected attrs
            (set-dirty ob attr-affected)
        ) 
    )
)

(def set-dirty-or-clean-intern (ob attr is-dirty)
    (let dts (dirties-by-object* ob)
        (= (dts attr) is-dirty)
    )
)

(def set-dirty-intern (ob attr)
    (prn "set-dirty-intern for " (conn-as-string (list ob attr)))
    (set-dirty-or-clean-intern ob attr 't)
)

(def set-clean (ob attr)
    (prn "set-clean for " (conn-as-string (list ob attr)))
    (set-dirty-or-clean-intern ob attr nil)
)

(def get-forward-conns (ob-from attr-from)
    (let fcs (forward-connections* ob-from)
        (if (no fcs)
            '() ;; empty list, look better as nil
            (fcs attr-from)
        )
    )
)

(def set-dirty-connected (ob attr)

    (prn "set-dirty-connected for " (conn-as-string (list ob attr)))
    (let conns (get-forward-conns ob attr)
        (prn "    count of conns: " (len conns) " for " (conn-as-string (list ob attr)))
        (each conn conns        
            (prn "    |- " (conn-as-string (list ob attr)) " -> " (conn-as-string conn))
            (set-dirty (car conn) (cadr conn))
        )
    )
)

;; ----------------------------------------------------------------------------
;; set-dirty
;; ----------------------------------------------------------------------------

(def set-dirty (ob attr)
    (prn "set-dirty for " (conn-as-string (list ob attr)))
    (set-dirty-intern           ob attr)
    (set-dirty-affected-intern  ob attr)
    (set-dirty-connected        ob attr)
)

(def get-value-intern (ob attr)
    (let vs (values-by-object* ob)
        (vs attr)
    )
)

(def is-dirty (ob attr)
    (let dt (dirties-by-object* ob)
        (dt attr)
    )
)

(def get-value-connected (ob-to attr-to)

    (prn "get-value-connected for " (conn-as-string (list ob-to attr-to)))

    (let conn (get-backward-conn ob-to attr-to)
        (with
            (   ob-from    (car  conn)
                attr-from  (cadr conn)
            )
            (get-value ob-from attr-from)
        )
    )
)

;; ----------------------------------------------------------------------------
;; is-backward-connected
;; ----------------------------------------------------------------------------

(def is-backward-connected (ob-to attr-to)
    (let bcs (backward-connections* ob-to)
        (if (no bcs)
            nil ;; false
            (let conn (bcs attr-to)
                (if (no conn)
                    nil ;; false
                    't
                )
            )
        )
    )
)

;; ----------------------------------------------------------------------------
;; get-value
;; ----------------------------------------------------------------------------

(def set-value-connected (ob attr val)

    (prn "set-value-connected for " (conn-as-string (list ob attr)) " attr 'is-writeable:" (attr 'is-writeable))

    (if ;; cond
        (attr 'is-writeable)
        ;; then
        (do
            (set-value-intern          ob attr val)
            (set-clean                 ob attr)
            (set-dirty-affected-intern ob attr)
            val
        )
        ;; else
        (err (string (conn-as-string (list ob attr)) " is not writeable"))
    )
)

(def get-value (ob attr)
    
    (prn "get-value for " (conn-as-string (list ob attr)) " attr 'is-readable:" (attr 'is-readable))

    (if (attr 'is-readable)
        ;; then
        (do
            (if (and (is-dirty ob attr)
                     (is-backward-connected ob attr)
                )
                (let val (get-value-connected ob attr)
                    (set-value-connected ob attr val)
                )
            )

            (if (is-dirty ob attr)
                (let calc-fn (calc-fns-by-type* (ob 'type))
                    ;; TODO: on-err -> set-dirty
                    (on-err 
                        (fn (ex) 
                            (prn "Error in calc fn" (details ex))
                            (set-dirty ob attr)
                        )
                        (fn () 
                            (calc-fn ob attr)
                            (set-clean ob attr)
                        )
                    )
                )
            )
            (get-value-intern ob attr)
        )
        ;; else
        (err (string (conn-as-string (list ob attr)) " is not readable"))
    )  
)

(def get-affected-attrs (typ attr)
    (let aas (attrs-affected-by-type* typ)
        (aas attr) ;; aat = affected-attributes
    )
)

(def set-value-intern (ob attr val)
    (let vs (values-by-object* ob)
        (= (vs attr) val)
    )
)

(def attr-is-writeable (attr)
    (attr 'is-writeable)
)

(def attr-is-not-backward-connected (ob attr)
    (no (is-backward-connected ob attr))
)

;; ----------------------------------------------------------------------------
;; set-value
;; ----------------------------------------------------------------------------

(def set-value (ob attr val)
  
    (prn "set-value for " (conn-as-string (list ob attr)) " attr 'is-writeable:" (attr 'is-writeable) )
    
    (if 
        ;; cond
        (and (attr-is-writeable attr)
             (attr-is-not-backward-connected ob attr)
        )

        ;; then
        (do
            (set-value-intern          ob attr val)
            (set-clean                 ob attr)
            (set-dirty-affected-intern ob attr)
            val
        )

        ;; else
        (err (string (conn-as-string (list ob attr)) " is not writeable or connected"))
    )
) 



;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Connections
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


;; ----------------------------------------------------------------------------
;; add-forward-conn
;; ----------------------------------------------------------------------------

(def add-forward-conn (ob-from attr-from ob-to attr-to)

    (ensure-if-not-exits forward-connections* ob-from)

    (withs
        (   fcs     (forward-connections* ob-from)
            conns   (fcs attr-from) 
        )
        ;; TODO: Check of already exists
        (= (fcs attr-from) (cons (list ob-to attr-to) conns))
        't
    )
)

;; ----------------------------------------------------------------------------
;; remove-forward-conn
;; ----------------------------------------------------------------------------

(def remove-forward-conn (ob-from attr-from ob-to attr-to)
    (withs
        (   fcs     (forward-connections* ob-from)
            conns   (fcs attr-from) 
        )
        (rem 
            (fn (_) (and (is (car  _) ob-to  )
                         (is (cadr _) attr-to)
                    )
            )
            conns
        )
        't ;; TODO
    )
)

;; ----------------------------------------------------------------------------
;; add-backward-conn
;; ----------------------------------------------------------------------------

(def add-backward-conn (ob-from attr-from ob-to attr-to)
    (ensure-if-not-exits backward-connections* ob-to)

    (let bcs (backward-connections* ob-to)
        (= (bcs attr-to) (list ob-from attr-from))
        't ;; TODO
    )
)

;; ----------------------------------------------------------------------------
;; remove-backward-conn
;; ----------------------------------------------------------------------------

(def remove-backward-conn (ob-from attr-from ob-to attr-to)

    (let bcs (backward-connections* ob-to)
        (= (bcs attr-to) '())
        't ;; TODO
    )
)


;; ----------------------------------------------------------------------------
;; connect
;; ----------------------------------------------------------------------------

(def connect (ob-from attr-from ob-to attr-to)

    (if ;; cond
        (is-backward-connected ob-to attr-to)
        ;; then
        (err (string (conn-as-string (list ob-to attr-to)) " already connected!"))
        ;; else
        (if ;; cond
            (and (attr-from 'is-readable )
                 (attr-to   'is-writeable)
            )
            ;; then
            (do
                (prn "connect " (conn-as-string (list ob-from attr-from)) " with " (conn-as-string (list ob-to attr-to)))

                (add-forward-conn   ob-from attr-from 
                                    ob-to   attr-to )
                (add-backward-conn  ob-from attr-from 
                                    ob-to   attr-to )
                ;; IMPORTANT
                (set-dirty-connected ob-from attr-from)
            )
            ;; else
            (err "attr-from ("(attr-from 'is-readable )") must be readable and attr-to ("(attr-to   'is-writeable)") must be writeable")
        )
    )
)

;; ----------------------------------------------------------------------------
;; disconnect - NOT IMPLEMENTED
;; ----------------------------------------------------------------------------

(def disconnect (ob-from attr-from ob-to attr-to)
    
    (remove-forward-conn    ob-from attr-from 
                            ob-to   attr-to )
    (remove-backward-conn   ob-from attr-from 
                             ob-to  attr-to )

    ;; TODO : What todo on unconnect ?? Set-default-value ??
    ;; IMPORTANT
    ;; (set-dirty-connected ob-from attr-from)
)

;; ----------------------------------------------------------------------------
;; show-forward-conns - TODO: Refactor
;; ----------------------------------------------------------------------------

(def show-forward-conns (ob-from attr-from attr-conns)
    (with
        (   conn-from  (list ob-from attr-from)
            conns-to   (attr-conns   attr-from)
        )
        (each conn-to conns-to
            (prn (conn-as-string conn-from) " -> " (conn-as-string conn-to))
        )
    )
)

(def show-forward-conns (ob-from)
    (let attr-conns (forward-connections* ob-from)     
        (each attr-from (keys attr-conns)
           (show-forward-conns ob-from attr-from attr-conns) 
        )
    )
)

;; ----------------------------------------------------------------------------
;; show-backward-conns 
;; ----------------------------------------------------------------------------

(def show-backward-conns (ob-to)
    (let  
        attr-conns  (backward-connections* ob-to)      
        (each attr-to (keys attr-conns)
            (with
                (   conn-to    (list ob-to attr-to)
                    conn-from  (attr-conns attr-to)
                )
                (prn (conn-as-string conn-from) " <- " (conn-as-string conn-to))
            )
        )
    )
)

;; TODO: FIND BUG

;; ----------------------------------------------------------------------------
;; get-backward-conn 
;; ----------------------------------------------------------------------------

(def get-backward-conn (ob-to attr-to)
    (let bcs (backward-connections* ob-to)
        (if (no bcs)
            nil ;; TODO: Never return a NIL
            (bcs attr-to) 
        ) 
    )
)

;; ----------------------------------------------------------------------------
;; print-conns-attr
;; ----------------------------------------------------------------------------

(def print-conns-attr (ob attr)
    (let conns (get-forward-conns ob attr)
        (do
            (prn "count of conns: " (len conns) " for attr:" (attr 'name))
            (each conn conns        
                (prn " |- " (conn-as-string (list ob attr)) " -> " (conn-as-string conn))
            )
        )
    )
)

;; ----------------------------------------------------------------------------
;; print-conns
;; ----------------------------------------------------------------------------

(def print-conns (ob)
    (let attrs (attrs-by-type* (ob 'type))
        (each attr-name (keys attrs)
            (print-conns-attr ob (attrs attr-name))
        )
    )
)

;; (def sfc () (show-forward-conns  add1))
;; (def sbc () (show-backward-conns add2))






;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; VIEW - TUI
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


;; ----------------------------------------------------------------------------
;; print-left
;; ----------------------------------------------------------------------------

(def print-left (ob attr)
    (if (attr 'is-writeable)
        (pr "-|>")
        (pr " | ")
    )
)

;; ----------------------------------------------------------------------------
;; print-fw-conns
;; ----------------------------------------------------------------------------

(def print-fw-conns (ob attr)

    (withs 
        (
        conns   (get-forward-conns ob attr)
        
        cs      (map 
                    (fn (_) 
                        (conn-as-string (list (car _) (cadr _)))
                    )
                    conns
                )
        )
        (if (no cs)
            (pr "not connected")
            (pr cs)
        )
    )
)

;; ----------------------------------------------------------------------------
;; print-right
;; ----------------------------------------------------------------------------

(def print-right (ob attr)
    (if (attr 'is-readable)
        (do (pr "|>-") (print-sp) (print-fw-conns ob attr))
        (pr "|  ")
    )
)

;; ----------------------------------------------------------------------------
;; print-name
;; ----------------------------------------------------------------------------

(def print-name (ob attr)
    (pr (attr 'name))
)

;; ----------------------------------------------------------------------------
;; print-num
;; ----------------------------------------------------------------------------

(def print-num (val ls)
    (withs
        (   a     (num val)
            spcs  (- ls (len a))
        )
        (n-of spcs (pr " ")) (pr a)
    )
)

;; ----------------------------------------------------------------------------
;; print-val
;; ----------------------------------------------------------------------------

(def print-value (ob attr)
    (withs
        (   vls  (values-by-object* ob)
            val  (vls attr)
            lsp  4
        )
        (if (no val) ; never pass a nil
            (n-of ls (pr " ")) 
            (print-num val lsp)
        )
    )
)

;; ----------------------------------------------------------------------------
;; print-dirty
;; ----------------------------------------------------------------------------

(def print-dirty (ob attr)
    (if (is-dirty ob attr)
        (pr "*")
        (pr " ")
    )
)

;; ----------------------------------------------------------------------------
;; print-middle
;; ----------------------------------------------------------------------------

(def print-middle (ob attr)
    (print-name ob attr) (print-value ob attr) (print-dirty ob attr)
)

;; ----------------------------------------------------------------------------
;; print-sp
;; ----------------------------------------------------------------------------

(def print-sp ()
    (pr " ")
)

;; ----------------------------------------------------------------------------
;; print-attr
;; ----------------------------------------------------------------------------

(def print-attr (ob attr)
    (print-left ob attr) (print-sp) (print-middle ob attr) (print-sp) (print-right ob attr)
)



;; ----------------------------------------------------------------------------
;; print-obj
;; ----------------------------------------------------------------------------

;;  ----------
;; -|> a 3   |>-
;; -|> b 2   |>-
;;  |  c 5 * |>- (adder2.a)
;;  |  d 1 * |>-
;;  ----------

(def print-obj (ob)
    (withs 
        (
        
        attrs   (attrs-by-type* (ob 'type))

        pr-top      (fn () (prn "  ---------  "))
        pr-bottom   (fn () (prn "  ---------  "))
        pr-middle   (fn ()
                        (each attr-name (sort < (keys attrs))
                            (print-attr ob (attrs attr-name)) (prn)
                        )
                    )
        )
        
        (prn "")

        (pr-top)
        (pr-middle)
        (pr-bottom)
        
        (prn "")
    )
)

;;
;; Print add1 and add2 and add3
;;
(def pobs () 
    (if add1 (print-obj add1))
    (if add2 (print-obj add2))
    (if add3 (print-obj add3))
)


;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; TODO
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; 2017-12-18 [x] need also affected-by c affected by (a,b), (a,b) affects c
;; 2017-12-18 [x] attributes by type is a table with a LIST of attributes
;; 2017-12-17 [x] Use macros - Tip: Like Template/Generics List<T> 
;; 2017-12-16 [x] Create a Syntax Highlight for Arc
;;                see Example at https://github.com/bradrobertson/sublime-packages/tree/master/Lisp
;;                see Commands at file:///Users/christoph/DevelopSource/2017/Arc31/ArcReference/files.arcfn.com/doc/fnindex.html

;; ----------------------------------------------------------------------------
;; DONE
;; ----------------------------------------------------------------------------

;; 2017-12-17 [/] Dirty Propagation
;; 2017-12-17 [/] Lazy Evaluation 
;; 2017-12-17 [/] Use of Writeable/Readable

(prn ".. obj.arc loaded ..") 

(load "../Connect/obj-spec.arc")

(prn ".. obj-spec.arc loaded ..") 
 
