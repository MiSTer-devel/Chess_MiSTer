require("lib")

reset()

move(4, 6, 4, 4)
move(0, 1, 0, 2)
select_field(5, 7)
move(5, 7, 2, 4)
move(0, 2, 0, 3)
select_field(2, 4)

wait_ns(5000000)