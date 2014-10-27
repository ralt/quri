(in-package :cl-user)
(defpackage quri
  (:use :cl
        :quri.uri
        :quri.uri.ftp
        :quri.uri.http
        :quri.uri.ldap
        :quri.error)
  (:import-from :quri.parser
                :parse-uri)
  (:import-from :quri.decode
                :url-decode
                :url-decode-params)
  (:import-from :quri.encode
                :url-encode
                :url-encode-params)
  (:import-from :quri.port
                :scheme-default-port)
  (:export :parse-uri

           :uri
           :uri=
           :uri-p
           :uri-scheme
           :uri-userinfo
           :uri-host
           :uri-port
           :uri-path
           :uri-query
           :uri-fragment
           :uri-authority

           :urn
           :urn-p
           :urn-nid
           :urn-nss

           :uri-ftp
           :uri-ftp-p
           :uri-ftp-typecode

           :uri-http
           :uri-http-p
           :uri-query-params

           :uri-ldap
           :uri-ldap-p
           :uri-ldap-dn
           :uri-ldap-attributes
           :uri-ldap-scope
           :uri-ldap-filter
           :uri-ldap-extensions

           :render-uri

           :url-decode
           :url-decode-params
           :url-encode
           :url-encode-params

           :uri-error
           :uri-malformed-string
           :uri-invalid-scheme
           :uri-invalid-port
           :uri-malformed-urlencoded-string))
(in-package :quri)

(defun uri (data &key (start 0) end)
  (multiple-value-bind (scheme userinfo host port path query fragment)
      (parse-uri data :start start :end end)
    (funcall (cond
               ((or (eq scheme :http)
                    (eq scheme :https)) #'make-uri-http)
               ((or (eq scheme :ldap)
                    (eq scheme :ldaps)) #'make-uri-ldap)
               ((eq scheme :ftp)        #'make-uri-ftp)
               ((eq scheme :urn)        #'make-urn)
               (T                       #'make-uri))
             :port (or port
                       (scheme-default-port scheme))
             :scheme scheme
             :userinfo userinfo
             :host host
             :path path
             :query query
             :fragment fragment)))

(defun render-uri (uri &optional stream)
  (if (uri-ftp-p uri)
      (format stream
              "~:[~;~:*~(~A~):~]~:[~;~:*//~A~]~:[~;~:*~A~]~:[~;~:*;type=~A~]~:[~;~:*?~A~]~:[~;~:*#~A~]"
              (uri-scheme uri)
              (uri-authority uri)
              (uri-path uri)
              (uri-ftp-typecode uri)
              (uri-query uri)
              (uri-fragment uri))
      (format stream
              "~:[~;~:*~(~A~):~]~:[~;~:*//~A~]~:[~;~:*~A~]~:[~;~:*?~A~]~:[~;~:*#~A~]"
              (uri-scheme uri)
              (uri-authority uri)
              (uri-path uri)
              (uri-query uri)
              (uri-fragment uri))))

(defun uri= (uri1 uri2)
  (check-type uri1 uri)
  (check-type uri2 uri)
  (when (eq (type-of uri1) (type-of uri2))
    (and (eq    (uri-scheme uri1)    (uri-scheme uri2))
         (equal (uri-path uri1)      (uri-path uri2))
         (equal (uri-query uri1)     (uri-query uri2))
         (equal (uri-fragment uri1)  (uri-fragment uri2))
         (equal (uri-authority uri1) (uri-authority uri2))
         (or (not (uri-ftp-p uri1))
             (eql (uri-ftp-typecode uri1) (uri-ftp-typecode uri2))))))

(defmethod print-object ((uri uri) stream)
  (format stream "#<~S ~A>"
          (type-of uri)
          (render-uri uri)))
