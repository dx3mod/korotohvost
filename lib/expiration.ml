let of_string = function
  | "never" -> `Never
  | "10min" -> `Minutes 10
  | "1day" -> `Days 1
  | "1week" -> `Weeks 1
  | "6months" -> `Months 6
  | "1year" -> `Years 1
  | s -> raise (Invalid_argument s)

let to_string = function
  | `Never -> "NULL"
  | `Minutes minutes -> Printf.sprintf "+%d minutes" minutes
  | `Days days -> Printf.sprintf "+%d days" days
  | `Weeks weeks -> Printf.sprintf "+%d days" (weeks * 7)
  | `Months months -> Printf.sprintf "+%d months" months
  | `Years years -> Printf.sprintf "+%d years" years
