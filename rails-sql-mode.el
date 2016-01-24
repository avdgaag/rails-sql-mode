;;; rails-sql-mode.el --- open a sql-mode db prompt with Rails configuration
;;;
;;; Author:            Arjan van der Gaag <arjan@arjanvandergaag.nl>
;;; URL:               https://github.com/avdgaag/rails-sql-mode
;;; Version:           0.1.0
;;; Keywords:          rails, ruby, sql
;;; Package-Requires:  ((emacs "24.3"))
;;;
;;; License:
;;;
;;; Copyright (c) 2016 Arjan van der Gaag
;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy
;;; of this software and associated documentation files (the "Software"), to
;;; deal in the Software without restriction, including without limitation the
;;; rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
;;; sell copies of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in
;;; all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
;;; IN THE SOFTWARE.
;;;
;;; Commentary:
;;;
;;; To enable rails-sql-mode automatically when projectile-rails is loaded, use
;;; the following:
;;;
;;;     (add-hook 'projectile-rails-mode-hook 'rails-sql-mode-on)
;;;
;;; Code:

(require 'json)
(require 'cl)

(defstruct
  avdg-rails-db-conf
  adapter
  host
  username
  password
  encoding
  database
  pool)

(defvar avdg-rails-adapter-alist
  '(("mysql" . sql-mysql)
    ("mysql2" . sql-mysql)
    ("postgresql" . sql-postgres)
    ("sqlite3" . sql-sqlite))
  "Define map of Rails database adapters to Emacs SQL functions.")

(defun avdg-rails-sql-func (adapter)
  "Return the Emacs function for ADAPTER."
  (cdr (assoc adapter avdg-rails-adapter-alist)))

(defun avdg-read-rails-db-conf (env filename)
  "Read credentials for ENV from FILENAME into an alist."
  (json-read-from-string
   (shell-command-to-string
    (format "ruby -rpathname -ryaml -rerb -rjson  -e '
content = Pathname.pwd.to_enum(:ascend).map { |pn| pn.join(\"%s\") }.find(&:exist?).read
puts JSON.dump(YAML.load(ERB.new(content).result)[\"%s\"])
'"
            filename
            env))))

(defun avdg-parse-rails-db-conf (db-config)
  "Parse alist DB-CONFIG with credentials into a avdg-rails-db-conf struct."
  (make-avdg-rails-db-conf
   :adapter  (cdr (assoc 'adapter db-config))
   :host     (cdr (assoc 'host db-config))
   :encoding (cdr (assoc 'encoding db-config))
   :pool     (cdr (assoc 'pool db-config))
   :username (cdr (assoc 'username db-config))
   :database (cdr (assoc 'database db-config))
   :password (cdr (assoc 'password db-config))))

(defun avdg-get-rails-db-conf ()
  "Read config/database.yml and build an an avdg-rails-db-conf from it."
  (avdg-parse-rails-db-conf (avdg-read-rails-db-conf "development"
                                                     "config/database.yml")))

(defalias 'sql-get-login 'ignore)

(defun avdg-run-rails-sql ()
  "Run a SQL process for the current Rails project."
  (interactive)
  (let ((db-config (avdg-get-rails-db-conf)))
    (setq sql-user (or (avdg-rails-db-conf-username db-config) ""))
    (setq sql-database (or (avdg-rails-db-conf-database db-config) ""))
    (setq sql-server (or (avdg-rails-db-conf-host db-config) ""))
    (setq sql-password (or (avdg-rails-db-conf-password db-config) ""))
    (funcall (avdg-rails-sql-func (avdg-rails-db-conf-adapter db-config)))))

;;;###autoload
(define-minor-mode rails-sql-mode
  "Rails SQL mode for connecting to configured Rails database"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c r D") 'avdg-run-rails-sql)
            map))

(provide 'rails-sql-mode)
;;; rails-sql-mode.el ends here
