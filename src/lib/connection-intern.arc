
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
;; get-forward-conns
;; ----------------------------------------------------------------------------

(def get-forward-conns (ob-from attr-from)
    (let fcs (forward-connections* ob-from)
        (if (no fcs)
            '() ;; empty list, look better as nil
            (fcs attr-from)
        )
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
;; remove-backward-conn
;; ----------------------------------------------------------------------------

(def remove-backward-conn (ob-from attr-from ob-to attr-to)

    (let bcs (backward-connections* ob-to)
        (= (bcs attr-to) '())
        't ;; TODO
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
;; ----------------------------------------------------------------------------
;; FOR DEBUG
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------


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



;; ----------------------------------------------------------------------------
;; print-conns-attr
;; ----------------------------------------------------------------------------

(def print-conns-attr (ob attr)
    (let conns (get-forward-conns ob attr)
        (do
            (prdn "count of conns: " (len conns) " for attr:" (attr 'name))
            (each conn conns        
                (prdn " |- " (conn-as-string (list ob attr)) " -> " (conn-as-string conn))
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


