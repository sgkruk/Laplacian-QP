
(defun objective (x &optional (n 0) (acc 0))
  (if (null x)
      acc
      (let* ((xi (car x))
             (rest (cdr x))
             (n (max n (length x))))
        (incf acc (* xi xi (1- n)))
        (incf acc (* 2 (reduce #'(lambda (a b) (- a (* xi b))) rest :initial-value 0)))
        (objective rest n acc))))

(defun flatten (l)
  (cond ((null l) nil)
        ((atom l) (list l))
        (t (loop for a in l appending (flatten a)))))

(defun initial-mean (ranges)
  (let* ((mids (mapcar #'(lambda (range) (/ (+ (first range) (second range)) 2)) ranges))
         (l (length mids))
         (mid (truncate l 2))
         (val (nth mid (sort mids #'<))))
    (find val (sort (flatten ranges) #'<) :test #'<=)))

(defun potentials (ranges)
  (remove-duplicates (sort (flatten ranges) #'<=)))

(defun initial-index (potentials)
  (truncate (length potentials) 2))

(defun closest-element (nu range)
  (cond ((<= nu (first range)) (first range))
        ((>= nu (second range)) (second range))
        (t nu)))
(defun closest-vector (nu ranges)
  (mapcar #'(lambda (range) (closest-element nu range)) ranges))

(defun arith-mean (x)
  (/ (apply #'+ x) (length x)))

(defun solver (ranges)
  (do* ((potentials (potentials ranges))
        (i (initial-index potentials) (+ i s))
        (bar-nu (nth i potentials) (nth i potentials))
        (x (closest-vector bar-nu ranges) (closest-vector bar-nu ranges))
        (nu (arith-mean x) (arith-mean x))
        (s (signum (- nu bar-nu)))
        (steps 0 (1+ steps)))
       ((or (zerop s) (not (= s (signum (- nu bar-nu)))))
        (let* ((d (feasible-descent x ranges nu))
               (alpha (alpha nu bar-nu (length x) (abs (apply #'+ d)))))
          (values (last-step x alpha d) steps)))))

(defun feasible-descent (x ranges nu)
  (mapcar #'(lambda (xi range)
              (if (or
                   (and (< xi nu) (<= (first range) xi) (< xi (second range)))
                   (and (< nu xi) (< (first range) xi) (<= xi (second range))))
                  1 0))
          x ranges))

(defun alpha (nu nu-bar n k)
  (/ (* n (- nu nu-bar)) (- n k)))

(defun last-step (x alpha d)
  (mapcar #'(lambda (xi di) (+ xi (* alpha di))) x d))

(defun optimal-p (x ranges)
  (let ((nu (arith-mean x)))
    (every #'identity (mapcar #'(lambda (xi range)
                (or
                 (= xi (first range))
                 (= xi (second range))
                 (and (= xi nu) (<= (first range) nu (second range)))))
            x ranges))))
(defun test-solver ()
  (and 
   (= 9 (objective '(3 6)))
   (= 3 (initial-mean '((1 3) (1 3) (4 6))))
   (equal '(1 2 3 4 6) (potentials '((1 3) (2 3) (4 6))))
   (equal '(2 2 4) (closest-vector 2 '((1 3) (2 3) (4 6))))
   (= 2 (next-nu 1 (potentials '((1 3) (2 3) (4 6))) 1))
   (= 3 (next-nu 2 (potentials '((1 3) (2 3) (4 6))) 1))
   (= 2 (next-nu 3 (potentials '((1 3) (2 3) (4 6))) -1))
   (= 6 (next-nu 4 (potentials '((1 3) (2 3) (4 6))) 1))
   (= 6 (next-nu 6 (potentials '((1 3) (2 3) (4 6))) 1))
   (= 1 (next-nu 1 (potentials '((1 3) (2 3) (4 6))) -1))
   (= 1 (let* ((ranges '((1 3) (2 3) (4 6)))
               (nu 1)
               (pot (potentials ranges))
               (x (closest-vector nu ranges))
               (val (objective x)))
          (direction val nu pot ranges)))
   (equal  '(6 3 16/3 7 16/3) (solver '((6 8) (1 3) (5 9) (7 9) (2 6))))
   (equal '(3 14 14 11 100/7 16 100/7 14 100/7 28) 
          (solver '((0 3) (3 14) (6 14) (1 11) (12 38) (16 17) (5 46) (11 14) (14 23) (28 64)))))
  (dotimes (i 100)
    (let ((ranges (gen-ranges 20)))
      (when (not (optimal-p (solver ranges) ranges))
        (format t "~%ERROR: range:~a" ranges)
        )))
  t)