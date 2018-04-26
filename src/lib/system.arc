(load "../Connect/lib/common.arc") ;; Load First is used by other below

(load "../Connect/lib/attribute.arc")
(load "../Connect/lib/type.arc")        ;; Register attributes
(load "../Connect/lib/object.arc")      ;; Object use type to create inst
(load "../Connect/lib/connection.arc")  ;; Connection made with object


;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; TODO
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; 2017-12-22 [x] List of attributes instead of table with keys or both


;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Global Variables
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


;; 'adder ->  ( attr-a 
;;              attr-b 
;;              attr-c
;;              attr-d )

(= attrs-by-type* (table))


;; 'adder -> attr-a -> (attr-c attr-d)
;;           attr-b -> (attr-c attr-d)

;; this is done when you instantiate a new object

(= attrs-affected-by-type* (table))


;; 'adder   -> (fn (ob attr)
;;                  ...
;;             )

(= calc-fns-by-type* (table))


;; 'obj1 ->     attr-a ->  1
;;              attr-b ->  2
;;              attr-c ->  3
;;              attr-d -> -1

;; this is done when you instantiate a new object

(= values-by-object* (table))


;; 'obj1 ->     attr-a -> nil
;;              attr-b -> nil
;;              attr-c ->  't
;;              attr-d ->  't

;; this is done when you instantiate a new object

(= dirties-by-object* (table))


;; "obj1" -> obj1
;; "obj2" -> obj2 

(= objects-by-name* (table))


;; add1.c ---> add2.a
;;         |-> add3.b
;;
;; add1.d ---> add2.b
;;         |-> add3.a
;;
;; 'add1 -> attr.c -> ((add2 a)(add3 b))
;;       -> attr.d -> ((add2 b)(add3 a))

(= forward-connections*  (table))

;; 'add2 -> attr.a -> attr.c
;;       -> attr.c -> attr.d
;; ....

(= backward-connections*  (table))