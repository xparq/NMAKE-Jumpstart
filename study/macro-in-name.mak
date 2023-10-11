x = 1
y$(x) = x$(x)

!message y1 = $(y1)

# Order matters, as usual:
y$(a) = a$(a)
a = 2

!message y2 = $(y2)
