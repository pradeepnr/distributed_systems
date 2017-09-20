##############################################
# Server
##############################################
defmodule BitcoinServer do
  
  @server :bitcoin_server
  @cookie :bitcoin_cookie
  @global_name :bitcoin_global_name
  @range 100000
  @numberOfMiners 100

  def getServer() do
    @server
  end

  def getServerCookie() do
    @cookie 
  end

  def getGlobalName() do
    @global_name
  end

  def range() do
    @range
  end

  def start(numberOfZeros) do
    init()
    receiver(numberOfZeros, 1, 0)
  end

  defp init() do
    Process.flag(:trap_exit, true)
    {:ok, [{ip, gateway, subnet}, {_, _, _}]} = :inet.getif()
    ipString = BitcoinCommon.ipToString(ip)
    serverName = :"#{getServer()}@#{ipString}"
    case Node.start(serverName) do
      {:ok, pid} ->
        Node.set_cookie(Node.self(), getServerCookie())
        res = :global.register_name(getGlobalName(), self())
        IO.puts "Server started at IP -> #{serverName}"
      {:error, reason} ->
        IO.puts "Could not start the Node because #{reason}"
        exit(:boom)
    end
    startLocalWorkers()
  end

  defp startLocalWorkers() do
    send self(), {:register, self()}
  end

  def receiver(numberOfZeros, startVal, miners) do
      receive do 
          {:register, miner_pid} -> 
              # spawn n number of miners at the given pid
              #IO.puts "Received :register request"
              endVal = startVal + range() - 1
              send miner_pid, {:spawn_workers, numberOfZeros, startVal, endVal}
              receiver(numberOfZeros, endVal+1, miners)
          
          {:bitcoin, bitcoin_str, bitcoin_hash} ->
          IO.puts "#{bitcoin_str}\t#{bitcoin_hash}"
          receiver(numberOfZeros, startVal, miners)

          {:bitcoin_list, bitcoin_list} ->
            #IO.puts "printing list received"
            Enum.map(bitcoin_list, 
              fn {bitcoin_str, bitcoin_hash} ->
                IO.puts "#{bitcoin_str}\t#{bitcoin_hash}"
              end )
          receiver(numberOfZeros, startVal, miners)

          {:spawn_workers, numberOfZeros, startVal, endVal} -> 
            #IO.puts "Receive spawn_workers msg on server"
            range1 = (endVal - startVal + 1) / @numberOfMiners
            Enum.map(1..@numberOfMiners, 
                  fn v -> 
                    st = round(range1 * (v-1) + startVal)
                    ed = round(st + range1 - 1)
                    #IO.puts "#{st} to #{ed}"
                    spawn_link(BitcoinCommon, :bitCoinFinder, [[numberOfZeros, st, ed, self()]])
                  end)
            miners = miners + @numberOfMiners;
            receiver(numberOfZeros, startVal + range() - 1, miners)
          
            {:EXIT,pid,msg} ->
              #IO.puts "Received :Exit"
              miners = miners - 1;
              if 0 == miners do
                #IO.puts "all the workers died, register as fresh"
                send self(), {:register, self()}
              end
              receiver(numberOfZeros, startVal, miners)
      end
  end

end
