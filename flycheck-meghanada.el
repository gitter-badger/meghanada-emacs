;;; flycheck-meghanada.el --- Flycheck support for meghanada -*- coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 2016 Yutaka Matsubara
;; License: http://www.gnu.org/licenses/gpl.html

;;; Commentary:
;;
;; The `flycheck-meghanada' provides `flycheck-chcker' for java.

;;; Code:

(eval-when-compile
  (require 'pcase))

(require 'flycheck)
(require 'meghanada)

(defgroup flycheck-meghanada nil
  "meghanada mode's flycheck checker."
  :group 'meghanada)


(defun flycheck-meghanada--build-error (diagnostic checker buffer)
  (let ((severity (intern (nth 2 diagnostic))))
    (when (memq severity '(NOTE WARNING ERROR FATAL))
      (flycheck-error-new-at
       (nth 0 diagnostic)
       (nth 1 diagnostic)
       (pcase severity
         (`NOTE 'info)
         (`WARNING 'warning)
         ((or `ERROR `FATAL) 'error))
       (nth 3 diagnostic)
       :checker checker
       :buffer buffer))))

(defun flycheck-meghanada--build-errors (result checker buffer)
  (mapcar (lambda (r)
            (flycheck-meghanada--build-error r checker buffer)) result))

(defun flycheck-meghanada--callback (output &rest args)
  (let* ((callback (nth 0 args))
         (checker (nth 1 args))
         (buffer (nth 2 args))
         (result (read output))
         (type (car result)))
    (pcase type
      (`fatal  (funcall callback 'errored '("Meghanada diagnostics fatal error")))
      (`success (funcall callback 'finished nil))
      (`error (let* ((errors (flycheck-meghanada--build-errors (cdr result) checker buffer)))
                (funcall callback 'finished (delq nil errors))))
      (_ (progn
           (message "WARN not match type")
           (funcall callback 'finished nil))))))

(defun flycheck-meghanada--start (checker callback)
  (let ((buffer (current-buffer)))
    (meghanada-diagnostics-async
     (list #'flycheck-meghanada--callback callback checker buffer))))

(flycheck-define-generic-checker 'meghanada
  "A syntax checker for java, using meghanada-mode."
  :start #'flycheck-meghanada--start
  :modes '(java-mode meghanada-mode)
  :predicate (lambda ()
               (and (meghanada-alive-p)
                    (flycheck-buffer-saved-p))))

;;;###autoload
(defun meghanada-flycheck-enable ()
  "Enable flycheck for meghanada-mode."
  (add-to-list 'flycheck-checkers 'meghanada))

(provide 'flycheck-meghanada)

;;; flycheck-meghanada.el ends here
