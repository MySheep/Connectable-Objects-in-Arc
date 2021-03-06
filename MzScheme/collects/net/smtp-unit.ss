(module smtp-unit (lib "a-unit.ss")
  (require (lib "list.ss") (lib "kw.ss") "base64.ss" "smtp-sig.ss")

  (import)
  (export smtp^)

  (define smtp-sending-server (make-parameter "localhost"))

  (define debug-via-stdio? #f)

  (define (log . args)
    ;; (apply printf args)
    (void))

  (define (starts-with? l n)
    (and (>= (string-length l) (string-length n))
         (string=? n (substring l 0 (string-length n)))))

  (define (check-reply/accum r v w a)
    (flush-output w)
    (let ([l (read-line r (if debug-via-stdio? 'linefeed 'return-linefeed))])
      (log "server: ~a\n" l)
      (if (eof-object? l)
        (error 'check-reply "got EOF")
        (let ([n (number->string v)])
          (unless (starts-with? l n)
            (error 'check-reply "expected reply ~a; got: ~a" v l))
          (let ([n- (string-append n "-")])
            (if (starts-with? l n-)
                ;; Multi-line reply. Go again.
                (check-reply/accum r v w (if a (cons (substring l 4) a) #f))
                ;; We're finished, so add the last and reverse the result
                (when a
                  (reverse (cons (substring l 4) a)))))))))
  
  (define (check-reply/commands r v w . commands)
    ;; drop the first response, which is just the flavor text -- we expect the rest to
    ;; be a list of supported ESMTP commands.
    (let ([cmdlist (rest (check-reply/accum r v w '()))])
      (for-each (lambda (c1)
                  (unless (findf (lambda (c2) (string=? c1 c2)) cmdlist)
                    (error "expected advertisement of ESMTP command ~a" c1)))
                commands)))
  
  (define (check-reply r v w)
    (check-reply/accum r v w #f))

  (define (protect-line l)
    ;; If begins with a dot, add one more
    (if (or (equal? l #"")
            (equal? l "")
            (and (string? l)
                 (not (char=? #\. (string-ref l 0))))
            (and (bytes? l)
                 (not (= (char->integer #\.) (bytes-ref l 0)))))
      l
      (if (bytes? l)
        (bytes-append #"." l)
        (string-append "." l))))

  (define smtp-sending-end-of-message
    (make-parameter void
                    (lambda (f)
                      (unless (and (procedure? f)
                                   (procedure-arity-includes? f 0))
                        (raise-type-error 'smtp-sending-end-of-message "thunk" f))
                      f)))

  (define (smtp-send-message* r w sender recipients header message-lines
                              auth-user auth-passwd tls-encode)
    (with-handlers ([void (lambda (x)
                            (close-input-port r)
                            (close-output-port w)
                            (raise x))])
      (check-reply r 220 w)
      (log "hello\n")
      (fprintf w "EHLO ~a\r\n" (smtp-sending-server))
      (when tls-encode
        (check-reply/commands r 250 w "STARTTLS")
        (log "starttls\n")
        (fprintf w "STARTTLS\r\n")
        (check-reply r 220 w)
        (let-values ([(ssl-r ssl-w)
                      (tls-encode r w
                                   #:mode 'connect
                                   #:encrypt 'tls
                                   #:close-original? #t)])
          (set! r ssl-r)
          (set! w ssl-w))
        ;; According to RFC 3207 Sec 4.2, we must start anew with the EHLO.
        (log "tls hello\n")
        (fprintf w "EHLO ~a\r\n" (smtp-sending-server)))
      (check-reply r 250 w)

      (when auth-user
        (log "auth\n")
        (fprintf w "AUTH PLAIN ~a"
                 ;; Encoding adds CRLF
                 (base64-encode
                  (string->bytes/latin-1
                   (format "~a\0~a\0~a" auth-user auth-user auth-passwd))))
        (check-reply r 235 w))

      (log "from\n")
      (fprintf w "MAIL FROM:<~a>\r\n" sender)
      (check-reply r 250 w)

      (log "to\n")
      (for-each
       (lambda (dest)
         (fprintf w "RCPT TO:<~a>\r\n" dest)
         (check-reply r 250 w))
       recipients)

      (log "header\n")
      (fprintf w "DATA\r\n")
      (check-reply r 354 w)
      (fprintf w "~a" header)
      (for-each
       (lambda (l)
         (log "body: ~a\n" l)
         (fprintf w "~a\r\n" (protect-line l)))
       message-lines)

      ;; After we send the ".", then only break in an emergency
      ((smtp-sending-end-of-message))

      (log "dot\n")
      (fprintf w ".\r\n")
      (flush-output w)
      (check-reply r 250 w)

      ;; Once a 250 has been received in response to the . at the end of
      ;; the DATA block, the email has been sent successfully and out of our
      ;; hands.  This function should thus indicate success at this point
      ;; no matter what else happens.
      ;;
      ;; Some servers (like smtp.gmail.com) will just close the connection
      ;; on a QUIT, so instead of causing any QUIT errors to look like the
      ;; email failed, we'll just log them.
      (with-handlers ([void (lambda (x)
                              (log "error after send: ~a\n" (exn-message x)))])
        (log "quit\n")
        (fprintf w "QUIT\r\n")
        (check-reply r 221 w))

      (close-output-port w)
      (close-input-port r)))

  (define smtp-send-message
    (lambda/kw (server sender recipients header message-lines
                       #:key
                       [port-no 25]
                       [auth-user #f]
                       [auth-passwd #f]
                       [tcp-connect tcp-connect]
                       [tls-encode #f]
                       #:body
                       (#:optional [opt-port-no port-no]))
      (when (null? recipients)
        (error 'send-smtp-message "no receivers"))
      (let-values ([(r w) (if debug-via-stdio?
                              (values (current-input-port) (current-output-port))
                              (tcp-connect server opt-port-no))])
        (smtp-send-message* r w sender recipients header message-lines
                            auth-user auth-passwd tls-encode)))))
