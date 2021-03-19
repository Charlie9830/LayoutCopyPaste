local Mocks = {}

function Mocks.initGmaMock()
    if gma == nil then
        gma = {}
        gma.textinput = function(title, previousValue)
            print("TEXT INPUT PROMPT:   " .. title)
            if previousValue ~= nil then
                print("DEFAULT VALUE:   " .. previousValue)
            end
        end
        gma.feedback = function(message)
            print("FEEDBACK:  " .. message)
        end
        gma.echo = function(message)
            print("ECHO:   "..message)
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

            if varname == "lcp_previousSourceLayoutNumber" then
                return "11"
            end

            if varname == "lcp_previousTargetLayoutNumber" then
                return "12"
            end
        end

        gma.show.setvar = function(varname, value)
        end

        gma.show.getobj = {}
        gma.show.getobj.handle = function(handle)
            if handle == "Layout 11" or handle == "Layout 12" then
                return {}
            end
        end

        gma.show.getobj.label = function(handle)
            return "DEV Object Label"
        end

        gma.gui = {}
        gma.gui.msgbox = function(title, message)
            print("\n")
            print('-- ' .. title .. ' --')
            print(message)
            print("\n")
        end
        gma.gui.confirm = function(title, message)
            print("\n")
            print('----- ' .. title .. ' -----')
            print(message)
            print("\n")

            return true;
        end

        gma.gui.progress = {}
        gma.gui.progress.start = function(title) 
            return math.floor(math.random() * 100)
        end

        gma.gui.progress.setrange = function(progressHandle, min, max)
        end

        gma.gui.progress.set = function(progressHandle, value)
        end
        
        gma.gui.progress.stop = function(progressHandle) 
        end
    end
end

return Mocks
