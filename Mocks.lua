local Mocks = {}

function Mocks.initGmaMock()
    if gma == nil then
        gma = {}
        gma.feedback = function(message)
            print("FEEDBACK:  " .. message)
        end
        gma.cmd = function(cmd)
            print("COMMAND:   " .. cmd)
        end
        gma.show = {}
        gma.show.getvar = function(varname)
            if varname == "PATH" then
                return "C:\\ProgramData\\MA Lighting Technologies\\grandma\\gma2_V_3.9.60\\"
            end
            if varname == "TEMPPATH" then
                return "C:\\ProgramData\\MA Lighting Technologies\\grandma\\gma2_V_3.9.60\\temp"
            end

            if varname == "HOSTTYPE" then
                return 'Development'
            end
        end
    end
end

return Mocks
