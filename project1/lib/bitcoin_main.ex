##############################################
# Main
##############################################

defmodule BitcoinMain do
  def main(args) do
    #{success, ip} = :inet.parse_address(args)
    #val = String.to_integer(args)
    #IO.puts "Is_integer ->#{is_integer(val)}" 
    arg_first = hd(args)

    cond do
      BitcoinCommon.isInteger(arg_first) -> 
        numberOfZeros = String.to_integer(arg_first)
        BitcoinServer.start(numberOfZeros)
        IO.puts "BitcoinServer.start #{numberOfZeros}"
      true -> 
        #IO.puts "None satisfied"
        #temp
        BitcoinMiner.start(arg_first)
    end
    # if args is integer startServer
    # if args is IP then startNewNode
    
  end
end