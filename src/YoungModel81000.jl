module YoungModel81000

using LibSerialPort
using Dates
using DataStructures
using Lazy
using Chain

const dataBuffer = CircularBuffer{Vector{Float64}}(500)

function config(portname::String)
    port = LibSerialPort.sp_get_port_by_name(portname)

    LibSerialPort.sp_open(port, SP_MODE_READ_WRITE)
    config = LibSerialPort.sp_get_config(port)
    LibSerialPort.sp_set_config_baudrate(config, 38400)
    LibSerialPort.sp_set_config_parity(config, SP_PARITY_NONE)
    LibSerialPort.sp_set_config_bits(config, 8)
    LibSerialPort.sp_set_config_stopbits(config, 1)

    LibSerialPort.sp_set_config(port, config)
    
    return port
end

function stream(port::Ptr{LibSerialPort.Lib.SPPort}, file::String)
    Godot = @task _ -> false

    run(`touch $(file)`)

    function read(port, file)
        try
            tc = Dates.format(now(), "yy-mm-ddTHH:MM:SS:ss")
            nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 100)
            str = String(bytes[1:nbytes_read])
            
            tmp = split(str, "\r") 
            tmp = filter(x -> x .!= "\0", tmp)
            msg = map(x -> parse.(Float64, split(x)), tmp)
            msg = filter(x -> (length(x) == 6), msg)
            words = join.(msg,", ")[1]
            append!(dataBuffer, msg)
            open(file, "a") do io
                write(io, tc * ", " * words * "\n")
            end

        catch
            #println("I fail")
        end
    end

    while(true)
        read(port, file)
        sleep(0.1)
    end

    wait(Godot)
end

function is_valid_wind(msg)
    filter(x -> (x[end] != 0. ), msg)
    return msg
end

function decode_winds(msg)
    return (u = msg[1], v = msg[2], w = msg[3], temp = msg[4], elev = msg[5])
end

function get_current_winds()
    WIND = try
        @as x begin
            deepcopy(dataBuffer[1:end])
            map(is_valid_wind, x) 
            map(decode_winds, x)
            x[end]
        end
    catch
        missing
    end
    return WIND
end

end 
