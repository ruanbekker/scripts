# used in conjunction with:
# https://github.com/ruanbekker/test_db
FROM_DATE[1]="1986-06-25"
FROM_DATE[2]="1986-06-28"
FROM_DATE[3]="1986-07-15"
FROM_DATE[4]="1986-07-30"
FROM_DATE[5]="1986-08-14"
FROM_DATE[6]="1986-09-14"
FROM_DATE[7]="1986-10-14"
FROM_DATE[8]="1986-11-14"
FROM_DATE[9]="1985-01-01"

TO_DATE[1]="1989-06-25"
TO_DATE[2]="1992-06-28"
TO_DATE[3]="1994-07-15"
TO_DATE[4]="1996-07-30"
TO_DATE[5]="1999-08-14"
TO_DATE[6]="2000-01-01"
TO_DATE[7]="1988-04-01"
TO_DATE[8]="1989-01-01"
TO_DATE[9]="2000-01-28"


from_date_size=${#TO_DATE[@]}
to_date_size=${#FROM_DATE[@]}

while true
do
  sleep 0.5
  mysql -uroot -ppassword employees -e"SELECT last_name, COUNT(emp_no) AS num_emp FROM employees WHERE hire_date BETWEEN \"${FROM_DATE[$(($RANDOM % $from_date_size))]}\" AND \"${TO_DATE[$(($RANDOM % $to_date_size))]}\"  GROUP BY last_name ORDER BY num_emp DESC;"
done
