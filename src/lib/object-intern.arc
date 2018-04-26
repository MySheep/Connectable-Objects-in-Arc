

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
;; add-obj-by-name
;; ----------------------------------------------------------------------------

(def add-obj-by-name (ob name)
    (= (objects-by-name* name) ob)
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

(def remove-obj-intern (ob)
    (with
        (
            remove-values-of-obj 
                (fn (ob)
                    (= (values-by-object* ob) nil)
                ) 

            remove-dirties-of-obj 
                (fn (ob)
                    (= (dirties-by-object* ob) nil)
                )

            remove-obj-by-name 
                (fn (name)
                    (= (objects-by-name* name) nil)
                )
        )
    
        (remove-values-of-obj  ob)
        (remove-dirties-of-obj ob)
        (remove-obj-by-name (ob 'name))
    )
)





;; ----------------------------------------------------------------------------
;; set-dirty-or-clean-intern
;; ----------------------------------------------------------------------------

(def set-dirty-or-clean-intern (ob attr is-dirty)
    (let dts (dirties-by-object* ob)
        (= (dts attr) is-dirty)
    )
)

;; ----------------------------------------------------------------------------
;; set-dirty-intern
;; ----------------------------------------------------------------------------

(def set-dirty-intern (ob attr)
    (prdn "set-dirty-intern for " (conn-as-string (list ob attr)))
    (set-dirty-or-clean-intern ob attr 't)
)

;; ----------------------------------------------------------------------------
;; set-dirty-affected-intern
;; ----------------------------------------------------------------------------

(def set-dirty-affected-intern (ob attr)
    (prdn "set-dirty-affected-intern for " (conn-as-string (list ob attr))) 
    (let attrs (get-affected-attrs (ob 'type) attr)   
        (each attr-affected attrs
            (set-dirty ob attr-affected)
        ) 
    )
)

;; ----------------------------------------------------------------------------
;; set-dirty-connected
;; ----------------------------------------------------------------------------

(def set-dirty-connected (ob attr)

    (prdn "set-dirty-connected for " (conn-as-string (list ob attr)))
    (let conns (get-forward-conns ob attr)
        (prdn "    count of conns: " (len conns) " for " (conn-as-string (list ob attr)))
        (each conn conns        
            (prdn "    |- " (conn-as-string (list ob attr)) " -> " (conn-as-string conn))
            (set-dirty (car conn) (cadr conn))
        )
    )
)

;; ----------------------------------------------------------------------------
;; set-dirty
;; ----------------------------------------------------------------------------

(def set-dirty (ob attr)
    (prdn "set-dirty for " (conn-as-string (list ob attr)))
    (set-dirty-intern           ob attr)
    (set-dirty-affected-intern  ob attr)
    (set-dirty-connected        ob attr)
)

;; ----------------------------------------------------------------------------
;; set-clean
;; ----------------------------------------------------------------------------

(def set-clean (ob attr)
    (prdn "set-clean for " (conn-as-string (list ob attr)))
    (set-dirty-or-clean-intern ob attr nil)
)

;; ----------------------------------------------------------------------------
;; is-dirty
;; ----------------------------------------------------------------------------

(def is-dirty (ob attr)
    (let dt (dirties-by-object* ob)
        (dt attr)
    )
)

;; ----------------------------------------------------------------------------
;; get-value-intern
;; ----------------------------------------------------------------------------

(def get-value-intern (ob attr)
    (let vs (values-by-object* ob)
        (vs attr)
    )
)

;; ----------------------------------------------------------------------------
;; get-value-connected
;; ----------------------------------------------------------------------------

(def get-value-connected (ob-to attr-to)

    (prdn "get-value-connected for " (conn-as-string (list ob-to attr-to)))

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
;; set-value-connected
;; ----------------------------------------------------------------------------

(def set-value-connected (ob attr val)

    (prdn "set-value-connected for " (conn-as-string (list ob attr)) " attr 'is-writeable:" (attr 'is-writeable))

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

;; ----------------------------------------------------------------------------
;; set-value-intern
;; ----------------------------------------------------------------------------

(def set-value-intern (ob attr val)
    (let vs (values-by-object* ob)
        (= (vs attr) val)
    )
)

;; ----------------------------------------------------------------------------
;; attr-is-writeable
;; ----------------------------------------------------------------------------

(def attr-is-writeable (attr)
    (attr 'is-writeable)
)

;; ----------------------------------------------------------------------------
;; attr-is-not-backward-connected
;; ----------------------------------------------------------------------------

(def attr-is-not-backward-connected (ob attr)
    (no (is-backward-connected ob attr))
)