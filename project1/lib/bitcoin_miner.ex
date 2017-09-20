##############################################
# Client
##############################################
defmodule BitcoinMiner do
  @numberOfMiners 4
  @bitcoin_bucket_size 100

  defp serverPid() do
    :global.whereis_name(BitcoinServer.getGlobalName())
  end

  def start(serverIP) do
      # spawn numberOfMiners of miners
      connectionResult = init(serverIP)
      if true == connectionResult do
        registerSupervisorWithServer()
        startReceiver()
      else
        IO.puts "Enter a valid input"
      end
  end

  defp registerSupervisorWithServer() do
    send serverPid(), {:register, self()}
  end

  defp startReceiver() do
    minerReceiver(0, 0, [])
  end

  def init(serverIP) do
    Process.flag(:trap_exit, true)
    {:ok, [{ip, gateway, subnet}, {_, _, _}]} = :inet.getif()
    ipString = BitcoinCommon.ipToString(ip)
    {:ok, hostname} = :inet.gethostname()
    Node.start(:"#{hostname}@#{ipString}")
    Node.set_cookie(BitcoinServer.getServerCookie())
    connectionResult = Node.connect(:"#{BitcoinServer.getServer()}@#{serverIP}")
    if true == connectionResult do
      :global.sync()
    end
    #IO.inspect Node.list
    connectionResult
  end

  def minerReceiver(miners, bitcoinCount, bitcoinList) do
    #IO.puts "Receiver started"
    #IO.inspect( self())
      receive do 
          {:spawn_workers, numberOfZeros, startVal, endVal} -> 
              range = (endVal - startVal + 1) / @numberOfMiners
              Enum.map(1..@numberOfMiners, 
                    fn v -> 
                      st = round(range * (v-1) + startVal)
                      ed = round(st + range - 1)
                      #IO.puts "#{st} to #{ed}"
                      spawn_link(BitcoinCommon, :bitCoinFinder, [[numberOfZeros, st, ed, self()]])
                    end)
              #IO.puts "#{round(startVal + (range * (@numberOfMiners-1) +1))} to #{endVal}"
              miners = miners + @numberOfMiners;
              minerReceiver(miners, bitcoinCount, bitcoinList)
          
          {:bitcoin, bitcoin_str, bitcoin_hash} ->
              #IO.puts "Pradeep-> #{bitcoin_str} #{bitcoin_hash}"
              bitcoinCount = bitcoinCount + 1
              bitcoinList = bitcoinList ++ [{bitcoin_str, bitcoin_hash}]
              if @bitcoin_bucket_size == bitcoinCount do
                send serverPid(), {:bitcoin_list, bitcoinList}
                minerReceiver(miners, 0, [])
              end
              minerReceiver(miners, bitcoinCount, bitcoinList)
          
          {:EXIT,pid,msg} ->
            #IO.puts "test process exited with"
            miners = miners - 1;
            if 0 == miners do
              #IO.puts "all the workers died, register as fresh"
              send serverPid(), {:register, self()}
            end
            minerReceiver(miners, bitcoinCount, bitcoinList)
      end
  end

  def test(args) do
    IO.puts "test stated from server - Hurry!!"
    IO.inspect args
    exit(:process_exit)
  end

end