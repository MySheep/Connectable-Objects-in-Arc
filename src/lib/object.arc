(load "../Connect/lib/object-intern.arc")

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; A Connectable Object with Attributes
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; TODO
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; 2017-12-22 [x] Get attributes of object (type)

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

(= nil-obj* (inst 'object 'name "empty" type 'empty))

;; ----------------------------------------------------------------------------
;; nil-obj
;; ----------------------------------------------------------------------------

(def nil-obj ()
    nil-obj*
)

;; ----------------------------------------------------------------------------
;; inst-obj
;; ----------------------------------------------------------------------------

(def inst-obj (typ name)
    (if (is-type-registered typ)
        (inst-obj-intern typ name)
        (nil-object)
    )
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
;; remove-obj
;; ----------------------------------------------------------------------------

(def remove-obj (ob)

    (let remove-obj-intern 
        ;; local function
        (fn (ob)
            (remove-values-of-obj  ob)
            (remove-dirties-of-obj ob)
            (remove-obj-by-name (ob 'name))
        )
    
    (remove-obj-intern ob)
    't
    )
)

;; ----------------------------------------------------------------------------
;; set-value
;; ----------------------------------------------------------------------------

(def set-value (ob attr val)
  
    (prdn "set-value for " (conn-as-string (list ob attr)) " attr 'is-writeable:" (attr 'is-writeable) )
    
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

        ;; else - raise exception
        (err (string (conn-as-string (list ob attr)) " is not writeable or connected"))
    )
) 

;; ----------------------------------------------------------------------------
;; get-value
;; ----------------------------------------------------------------------------

(def get-value (ob attr)
    
    (prdn "get-value for " (conn-as-string (list ob attr)) " attr 'is-readable:" (attr 'is-readable))

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
                            (prdn "Error in calc fn" (details ex))
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
