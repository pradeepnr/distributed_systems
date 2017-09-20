defmodule BitcoinCommon do
    def ipToString(ip) do
        {a,b,c,d} = ip
        "#{a}.#{b}.#{c}.#{d}"
    end

    def isInteger(val) do
        try do
          String.to_integer(val)
          true
        catch
          :exit, code -> false
          :throw, value -> false
          what, value -> false
        end
    end
    
    def bitCoinFinder(args) do
        [numberOfZeros, startVal, endVal, supervisorPid] = args
        #pattern = String.duplicate("0", numberOfZeros)
        mineBitcoin(startVal, endVal, numberOfZeros, supervisorPid)
    end

    def mineBitcoin(startVal, endVal, numberOfZeros, supervisorPid ) do 
        if startVal <= endVal do 
          plainText = "hbshah" <> Base.encode64(Integer.to_string(startVal))
          shaText = Base.encode16(:crypto.hash(:sha256, plainText))
          if String.slice(shaText, 0..(numberOfZeros-1)) ===  String.duplicate("0", numberOfZeros) do
            #IO.puts plainText 
            #IO.puts shaText
            send supervisorPid, {:bitcoin, plainText, shaText}
          end
          mineBitcoin(startVal+1, endVal, numberOfZeros, supervisorPid)
        else 
          exit(:shutdown)
        end
      end

end