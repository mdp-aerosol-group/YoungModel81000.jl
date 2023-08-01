using SerialPorts
portname = "/dev/ttyUSB4"

s = SerialPorts.SerialPort(portname, 38400)
readavailable(s)



nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 100)
str = String(bytes[1:nbytes_read])

tmp = split(str, "\r") 
tmp = filter(x -> x .!= "\0", tmp)
msg = map(x -> parse.(Float64, split(x)), tmp)
msg = filter(x -> (length(x) == 6), msg)
words = join.(msg,", ")[1]
append!(dataBuffer, msg)
tc = Dates.format(now(), "yy-mm-ddTHH:MM:SS:ss")
open("foo3.txt", "a") do io
    write(io, tc * ", " * words * "\n")
end