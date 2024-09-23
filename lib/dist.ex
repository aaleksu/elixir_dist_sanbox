defmodule Dist do

  @moduledoc """

  How to run to test:
  - open terminal window in /var/www/aa/elixir/dist/ dir
  - then run `iex --erl "-kernel inet_dist_listen_min 8001 -kernel inet_dist_listen_max 8100" --sname receiver@aa -S mix`
  - then run `Dist.go()` - it will register process with name `:aa_receiver`
  - then open another terminal window and run there `iex --erl "-kernel inet_dist_listen_min 8001 -kernel inet_dist_listen_max 8100" --sname sender@aa -S mix`
  - then run `Process.send({:aa_receiver, :"receiver@aa"}, {:ping, "hi" }, [])`
  - it should send message `{ :ping, "hi" }` to the elixir process running in first terminal
  - in first terminal you should see output: `{ :new_message, { :ping, "hi" } }`

  """


  # use Application

  def receiver do
    run_pid = spawn(fn -> tail_receiver() end)
    process_name = :aa_receiver
    Process.register(run_pid, process_name)
    {:ok, {process_name, run_pid, node()}}
  end

  def tail_receiver do
    receive do
      { msg_type, msg_content, sender, sender_node } ->
        IO.inspect { :new_message, { msg_type, msg_content } }
        Process.send({ sender, sender_node }, { :reply, "roger that" }, [])
        tail_receiver()
      _ -> :unknown_msg
    end
  end

  def sender({ receiver_process, receiver_node, msg_type, msg_content }) do
    sender_pid = spawn(fn -> tail_sender() end)
    sender_process_name = :aa_sender
    Process.register(sender_pid, sender_process_name)
    Process.send({ receiver_process, receiver_node }, { msg_type, msg_content, sender_process_name, node() }, [])
    {:ok, { sender_pid, node() }}
  end

  def send({msg_type, msg_content}) do
    Process.send({ :aa_receiver, :"receiver@aa" }, {msg_type, msg_content, :aa_sender, node()}, [])
  end

  def tail_sender do
    receive do
      msg ->
        IO.inspect { :got_reply, msg }
        tail_sender()
    end
  end

  # defp run do
  #   receive do
  #     msg ->
  #       IO.inspect { :new_message, msg }
  #       run()
  #   end
  # end

end
