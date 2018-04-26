
(load "../Connect/lib/connection-intern.arc")

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; Connections between attributes of objects
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------
;; TODO
;; ----------------------------------------------------------------------------
;; ----------------------------------------------------------------------------

;; 2017-12-23 [x] What to do with dirties on disconnect

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
                (prdn "connect " (conn-as-string (list ob-from attr-from)) " with " (conn-as-string (list ob-to attr-to)))

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
;; disconnect
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